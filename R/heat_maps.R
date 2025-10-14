# =============================================
# 1) Setup & libraries
# =============================================
suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(purrr)
  library(tibble)
  library(ggplot2)
  library(tidyr)
  library(plotly)
  library(readrba)
  library(scales)
  library(ggpattern)
  library(ggtext)
  library(zoo)  # Added for na.locf
})

# =============================================
# 1b) Create required directories
# =============================================
required_dirs <- c(
  "docs/meetings",
  "docs/meetings/csv",
  "combined_data"
)

for (dir_path in required_dirs) {
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
    cat("Created directory:", dir_path, "\n")
  }
}

# =============================================
# 2) Load data & RMSE lookup
# =============================================
cash_rate <- readRDS("combined_data/all_data.Rds")
load("combined_data/rmse_days.RData")

# Consolidate to daily level
cash_rate_daily <- cash_rate %>%
  mutate(scrape_date = as.Date(scrape_time)) %>%
  group_by(scrape_date, date) %>%
  slice_max(scrape_time, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(scrape_date, date, cash_rate)

cat("Daily consolidation complete:\n")
cat("  Original rows:", nrow(cash_rate), "\n")
cat("  Daily rows:", nrow(cash_rate_daily), "\n")
cat("  Unique dates:", length(unique(cash_rate_daily$scrape_date)), "\n")

blend_weight <- function(days_to_meeting) {
  pmax(0, pmin(1, 1 - days_to_meeting / 30))
}

latest_rt <- read_rba(series_id = "FIRMMCRTD") |>
             slice_max(date, n = 1, with_ties = FALSE) |>
             pull(value)

spread <- 0.00
cash_rate_daily$cash_rate <- cash_rate_daily$cash_rate + spread

# =============================================
# 3) Define RBA meeting schedule
# =============================================
meeting_schedule <- tibble(
  meeting_date = as.Date(c(
    "2022-02-01","2022-03-01","2022-04-05","2022-05-03",
    "2022-06-07","2022-07-05","2022-08-02","2022-09-06",
    "2022-10-04","2022-11-01","2022-12-06",
    "2023-02-07","2023-03-07","2023-04-04","2023-05-02",
    "2023-06-06","2023-07-04","2023-08-01","2023-09-05",
    "2023-10-03","2023-11-07","2023-12-05",
    "2024-02-06","2024-03-19","2024-05-07","2024-06-18",
    "2024-08-06","2024-09-24","2024-11-05","2024-12-10",
    "2025-02-18","2025-04-01","2025-05-20",
    "2025-07-08","2025-08-12","2025-09-30","2025-11-04","2025-12-09",
    "2026-02-03","2026-03-17","2026-05-05","2026-06-16",
    "2026-08-11","2026-09-29","2026-11-03","2026-12-08"
  ))
) %>% 
  mutate(
    expiry = if_else(
      day(meeting_date) >= days_in_month(meeting_date) - 1,
      ceiling_date(meeting_date, "month"),
      floor_date(meeting_date, "month")
    )
  ) %>% 
  select(expiry, meeting_date)

# =============================================
# 3b) Define ABS data release schedule
# =============================================
abs_releases <- tribble(
  ~dataset, ~datetime,
  "CPI", ymd_hm("2025-01-29 11:30", tz = "Australia/Melbourne"),
  "CPI", ymd_hm("2025-04-30 11:30", tz = "Australia/Melbourne"),
  "CPI", ymd_hm("2025-07-30 11:30", tz = "Australia/Melbourne"),
  "CPI", ymd_hm("2025-10-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-01-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-02-26 11:30", tz = "Australia/Melbourne"),
  "WPI", ymd_hm("2025-02-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-01-16 11:30", tz = "Australia/Melbourne")
)

# =============================================
# 4) Process data and create visualizations
# =============================================
last_meeting <- max(meeting_schedule$meeting_date[meeting_schedule$meeting_date < Sys.Date()])
print(last_meeting)

current_rate <- read_rba(series_id = "FIRMMCRTD") %>%
  filter(date == max(date)) %>%
  pull(value)

initial_rt <- latest_rt
all_dates <- sort(unique(cash_rate_daily$scrape_date))

cat("Total available daily scrapes:", length(all_dates), "\n")
cat("Date range:", min(all_dates), "to", max(all_dates), "\n")

scrapes_daily <- all_dates

# Create area data
rba_historical <- read_rba(series_id = "FIRMMCRTD") %>%
  arrange(date)

all_list_area <- map(all_dates, function(scr_date) {
  historical_rate <- rba_historical %>%
    filter(date <= scr_date) %>%
    slice_max(date, n = 1, with_ties = FALSE) %>%
    pull(value)
  
  initial_rt_at_scrape <- if(length(historical_rate) > 0) historical_rate else latest_rt
  
  df_rates <- cash_rate_daily %>% 
    filter(scrape_date == scr_date) %>%
    select(expiry = date, forecast_rate = cash_rate, scrape_date)
  
  df <- meeting_schedule %>%
    distinct(expiry, meeting_date) %>%
    mutate(scrape_date = scr_date) %>%
    left_join(df_rates, by = "expiry") %>%
    arrange(expiry) %>%
    filter(!is.na(forecast_rate))
  
  if (nrow(df) == 0) return(NULL)
  
  prev_implied <- NA_real_
  out <- vector("list", nrow(df))
  
  for (i in seq_len(nrow(df))) {
    row <- df[i, ]
    rt_in <- if (is.na(prev_implied)) initial_rt_at_scrape else prev_implied
    
    r_tp1 <- if (row$meeting_date < row$expiry) {
      row$forecast_rate
    } else {
      nb <- (day(row$meeting_date)-1) / days_in_month(row$expiry)
      na <- 1 - nb
      (row$forecast_rate - rt_in * nb) / na
    }
    
    out[[i]] <- tibble(
      scrape_date = scr_date,
      meeting_date = row$meeting_date,
      implied_mean = r_tp1,
      days_to_meeting = as.integer(row$meeting_date - scr_date),
      previous_rate = rt_in
    )
    prev_implied <- r_tp1
  }
  bind_rows(out)
})

all_estimates_area <- all_list_area %>%
  compact() %>%
  bind_rows() %>%
  filter(days_to_meeting >= 0) %>%
  left_join(rmse_days, by = "days_to_meeting") %>%
  rename(stdev = finalrmse)

max_rmse <- suppressWarnings(max(rmse_days$finalrmse, na.rm = TRUE))
if (!is.finite(max_rmse)) stop("No finite RMSE values found")

bad_sd <- !is.finite(all_estimates_area$stdev) | is.na(all_estimates_area$stdev) | all_estimates_area$stdev <= 0
n_bad <- sum(bad_sd, na.rm = TRUE)

if (n_bad > 0) {
  message(sprintf("Replacing %d missing/invalid stdev(s) with max RMSE = %.4f", n_bad, max_rmse))
  all_estimates_area$stdev[bad_sd] <- max_rmse
}

# Extended range bucketing
bp_span <- 300L
step_bp <- 25L
sd_fallback <- suppressWarnings(stats::median(all_estimates_area$stdev[is.finite(all_estimates_area$stdev)], na.rm = TRUE))
if (!is.finite(sd_fallback) || sd_fallback <= 0) sd_fallback <- 0.01

current_center_ext <- current_rate
bucket_min <- 0.1
bucket_max <- 6.1
bucket_centers_ext <- seq(bucket_min, bucket_max, by = 0.25)
half_width_ext <- 0.125

cat("Creating extended buckets for", nrow(all_estimates_area), "estimate rows\n")

bucket_list_ext <- vector("list", nrow(all_estimates_area))
for (i in seq_len(nrow(all_estimates_area))) {
  mu_i <- all_estimates_area$implied_mean[i]
  sigma_i <- all_estimates_area$stdev[i]
  d_i <- all_estimates_area$days_to_meeting[i]

  if (!is.finite(mu_i)) next
  if (!is.finite(sigma_i) || sigma_i <= 0) sigma_i <- sd_fallback

  p_vec <- sapply(bucket_centers_ext, function(b) {
    lower <- b - half_width_ext
    upper <- b + half_width_ext
    pnorm(upper, mean = mu_i, sd = sigma_i) - pnorm(lower, mean = mu_i, sd = sigma_i)
  })

  p_vec[!is.finite(p_vec) | p_vec < 0] <- 0
  p_vec[p_vec < 0.01] <- 0
  s <- sum(p_vec, na.rm = TRUE)
  if (is.finite(s) && s > 0) {
    p_vec <- p_vec / s
  } else {
    p_vec[] <- 0
  }

  nearest <- order(abs(bucket_centers_ext - mu_i))[1:2]
  b1 <- min(bucket_centers_ext[nearest])
  b2 <- max(bucket_centers_ext[nearest])
  denom <- (b2 - b1)
  w2 <- if (denom > 0) (mu_i - b1) / denom else 0
  w2 <- min(max(w2, 0), 1)
  l_vec <- numeric(length(bucket_centers_ext))
  l_vec[which(bucket_centers_ext == b1)] <- 1 - w2
  l_vec[which(bucket_centers_ext == b2)] <- w2

  blend <- blend_weight(d_i)
  v <- blend * l_vec + (1 - blend) * p_vec

  bucket_list_ext[[i]] <- tibble::tibble(
    scrape_date = all_estimates_area$scrape_date[i],
    meeting_date = all_estimates_area$meeting_date[i],
    implied_mean = mu_i,
    stdev = sigma_i,
    days_to_meeting = d_i,
    bucket = bucket_centers_ext,
    probability = v
  )
}

all_estimates_buckets_ext <- dplyr::bind_rows(bucket_list_ext) %>%
  dplyr::mutate(
    diff_bps = as.integer(round((bucket - current_center_ext) * 100L)),
    diff_bps = pmax(pmin(diff_bps, bp_span), -bp_span),
    move = sprintf("%.2f%%", bucket)
  )

rate_levels <- sort(unique(all_estimates_buckets_ext$bucket))
rate_labels <- sprintf("%.2f%%", rate_levels)

all_estimates_buckets_ext <- all_estimates_buckets_ext %>%
  dplyr::mutate(move = factor(move, levels = rate_labels))

future_meetings_all <- meeting_schedule %>%
  dplyr::mutate(meeting_date = as.Date(meeting_date)) %>%
  dplyr::pull(meeting_date)

cat("Future meetings found:", length(future_meetings_all), "\n")

fmt_date <- function(x) format(as.Date(x), "%d %B %Y")
fmt_file <- function(x) format(as.Date(x), "%Y-%m-%d")


# =============================================
# HEATMAP-STYLE VISUALIZATIONS
# =============================================
cat("\n=== Creating heatmap visualizations ===\n")

for (mt in future_meetings_all) {
  cat("\n=== Processing heatmap for meeting:", as.character(as.Date(mt)), "===\n")
  
  df_mt_heat <- all_estimates_buckets_ext %>%
    dplyr::filter(as.Date(meeting_date) == as.Date(mt)) %>%
    dplyr::group_by(scrape_date, move, bucket) %>%
    dplyr::summarise(probability = sum(probability, na.rm = TRUE), .groups = "drop") %>%
    dplyr::arrange(scrape_date, move)
  
  if (nrow(df_mt_heat) == 0) {
    cat("Skipping - no data for meeting\n")
    next 
  }
  
  bucket_lookup <- all_estimates_buckets_ext %>%
    dplyr::select(move, bucket) %>%
    dplyr::distinct()
  
  df_mt_heat <- df_mt_heat %>%
    dplyr::filter(
      !is.na(scrape_date), !is.na(probability),
      is.finite(probability), probability >= 0, !is.na(move)
    ) %>%
    dplyr::mutate(
      probability = pmin(probability, 1.0),
      probability = pmax(probability, 0.0)
    )
  
  if (nrow(df_mt_heat) == 0) next
  
  meeting_date_proper <- as.Date(mt) - days(1)
  start_xlim_mt <- min(df_mt_heat$scrape_date, na.rm = TRUE)
  end_xlim_mt <- meeting_date_proper
  
  available_moves <- unique(df_mt_heat$move[!is.na(df_mt_heat$move)])
  valid_move_levels <- rate_labels[rate_labels %in% available_moves]
  
  df_mt_heat <- df_mt_heat %>%
    dplyr::filter(move %in% valid_move_levels) %>%
    dplyr::mutate(move = factor(move, levels = valid_move_levels)) %>%
    dplyr::filter(!is.na(move))
  
  if (nrow(df_mt_heat) == 0) next
  
  # Forward fill missing days
  all_dates_seq <- seq.Date(from = start_xlim_mt, to = end_xlim_mt, by = "day")
  
  complete_grid <- expand.grid(
    scrape_date = all_dates_seq,
    move = valid_move_levels,
    stringsAsFactors = FALSE
  ) %>%
    dplyr::mutate(move = factor(move, levels = valid_move_levels)) %>%
    dplyr::left_join(bucket_lookup, by = "move")
  
  df_mt_heat <- complete_grid %>%
    dplyr::left_join(
      df_mt_heat %>% dplyr::select(scrape_date, move, probability),
      by = c("scrape_date", "move")
    )
  
  last_data_dates <- df_mt_heat %>%
    dplyr::filter(!is.na(probability)) %>%
    dplyr::group_by(move) %>%
    dplyr::summarise(last_date = max(scrape_date), .groups = "drop")
  
  df_mt_heat <- df_mt_heat %>%
    dplyr::left_join(last_data_dates, by = "move") %>%
    dplyr::group_by(move) %>%
    dplyr::arrange(scrape_date) %>%
    dplyr::mutate(
      probability = ifelse(scrape_date <= last_date,
                          zoo::na.locf(probability, na.rm = FALSE),
                          NA_real_)
    ) %>%
    dplyr::select(-last_date) %>%
    dplyr::ungroup()
  
  # Fill any remaining NAs at the start with 0
  df_mt_heat <- df_mt_heat %>%
    dplyr::group_by(move) %>%
    dplyr::mutate(
      first_non_na = min(scrape_date[!is.na(probability)], na.rm = TRUE),
      probability = ifelse(is.na(probability) & scrape_date < first_non_na, 0, probability)
    ) %>%
    dplyr::select(-first_non_na) %>%
    dplyr::ungroup()
  
  # Calculate percentile lines
percentile_lines <- all_estimates_area %>%
  dplyr::filter(as.Date(meeting_date) == as.Date(mt)) %>%
  dplyr::filter(!is.na(implied_mean), !is.na(stdev), stdev > 0) %>%
  dplyr::mutate(
    # Calculate percentiles using normal distribution
    p25 = qnorm(0.25, mean = implied_mean, sd = stdev),
    p50 = implied_mean,  # Median equals mean for normal distribution
    p75 = qnorm(0.75, mean = implied_mean, sd = stdev)
  ) %>%
  dplyr::select(scrape_date, p25, p50, p75) %>%
  dplyr::distinct() %>%
  dplyr::mutate(
    # Convert actual rates to positions in the factor levels
    p25_pos = sapply(p25, function(val) {
      which.min(abs(as.numeric(gsub("%", "", valid_move_levels)) - val))
    }),
    p50_pos = sapply(p50, function(val) {
      which.min(abs(as.numeric(gsub("%", "", valid_move_levels)) - val))
    }),
    p75_pos = sapply(p75, function(val) {
      which.min(abs(as.numeric(gsub("%", "", valid_move_levels)) - val))
    })
  )
  
  # Prepare actual cash rate line
  actual_rate_line <- rba_historical %>%
    dplyr::filter(date >= start_xlim_mt, date <= end_xlim_mt) %>%
    dplyr::mutate(rate_label = sprintf("%.2f%%", value)) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      closest_level = valid_move_levels[which.min(abs(as.numeric(gsub("%", "", valid_move_levels)) - value))],
      rate_position = which(levels(df_mt_heat$move) == closest_level)
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(date, value, rate_position)
  
  # Check for actual outcome
  actual_outcome <- NULL
  is_past_meeting <- meeting_date_proper < Sys.Date()
  
  if (is_past_meeting) {
    actual_outcome_data <- rba_historical %>%
      dplyr::filter(date > meeting_date_proper + 2) %>%
      dplyr::slice_min(date, n = 1, with_ties = FALSE)
    
    if (nrow(actual_outcome_data) > 0) {
      actual_outcome <- actual_outcome_data$value
      cat("Actual outcome for heatmap:", actual_outcome, "%\n")
    }
  }
  
  # RBA meetings in range
  rba_meetings_in_range <- meeting_schedule %>%
    dplyr::filter(meeting_date > start_xlim_mt, meeting_date < meeting_date_proper)
  
  filename <- paste0("docs/meetings/daily_heatmap_", fmt_file(meeting_date_proper), ".png")
  
  tryCatch({
    start_month <- lubridate::floor_date(start_xlim_mt, "month")
    end_month <- lubridate::ceiling_date(end_xlim_mt, "month")
    breaks_vec <- seq.Date(from = start_month, to = end_month, by = "month")
    date_labels <- function(x) format(x, "%b-%Y")
    
# Create base heatmap with rainbow colors (light yellow to dark purple)
    heatmap_mt <- ggplot2::ggplot(df_mt_heat, ggplot2::aes(x = scrape_date, y = move, fill = probability)) +
      ggplot2::geom_tile() +
      ggplot2::scale_fill_gradientn(
        colors = c("#FFFACD", "#FFD700", "#FFA500", "#FF6347", "#FF1493", "#8B008B", "#4B0082", "#2E0854"),
        values = c(0.01, 0.15, 0.30, 0.45, 0.60, 0.75, 0.90, 1.0),
        limits = c(0, 1),
        labels = scales::percent_format(accuracy = 1),
        na.value = "transparent",
        name = "Probability"
      )
    
    # Add percentile lines with legend entries
    if (nrow(percentile_lines) > 0) {
      heatmap_mt <- heatmap_mt +
        ggplot2::geom_line(
          data = percentile_lines,
          aes(x = scrape_date, y = p25_pos, linetype = "25th Percentile"),
          color = "#4B0082",
          linewidth = 0.25,
          inherit.aes = FALSE
        ) +
        ggplot2::geom_line(
          data = percentile_lines,
          aes(x = scrape_date, y = p50_pos, linetype = "Median (50th)"),
          color = "#4B0082",
          linewidth = 0.5,
          inherit.aes = FALSE
        ) +
        ggplot2::geom_line(
          data = percentile_lines,
          aes(x = scrape_date, y = p75_pos, linetype = "75th Percentile"),
          color = "#4B0082",
          linewidth = 0.25,
          inherit.aes = FALSE
        )
    }
    
    # Add actual cash rate line with legend entry
    if (nrow(actual_rate_line) > 0) {
      heatmap_mt <- heatmap_mt +
        ggplot2::geom_line(
          data = actual_rate_line,
          aes(x = date, y = rate_position, color = "Actual Cash Rate"),
          linewidth = 1.0,
          linetype = "solid",
          inherit.aes = FALSE
        )
    }
    
    # Add actual outcome line with legend entry
    if (!is.null(actual_outcome)) {
      actual_outcome_label <- sprintf("%.2f%%", actual_outcome)
      outcome_position <- which(levels(df_mt_heat$move) == actual_outcome_label)
      if (length(outcome_position) > 0) {
        heatmap_mt <- heatmap_mt +
          ggplot2::geom_hline(
            aes(yintercept = outcome_position, color = "Actual Outcome"),
            linewidth = 0.85,
            linetype = "dotted"
          )
      }
    }
    
    # Add RBA meeting lines with legend entry
    if (nrow(rba_meetings_in_range) > 0) {
      heatmap_mt <- heatmap_mt +
        ggplot2::geom_vline(
          data = rba_meetings_in_range,
          aes(xintercept = as.numeric(meeting_date), color = "RBA Meetings"),
          linetype = "dashed",
          linewidth = 0.5,
          alpha = 0.7
        )
    }
    
    # Add manual color and linetype scales for legend
    heatmap_mt <- heatmap_mt +
      ggplot2::scale_color_manual(
        name = "Lines",
        values = c(
          "Actual Cash Rate" = "#0066CC",
          "Actual Outcome" = "black",
          "RBA Meetings" = "grey30"
        ),
        breaks = c("Contemporaneous Cash Rate", "Cash Rate Decision", "RBA Meetings")
      ) +
      ggplot2::scale_linetype_manual(
        name = "Percentiles",
        values = c(
          "25th Percentile" = "dashed",
          "Median (50th)" = "dashed",
          "75th Percentile" = "dashed"
        )
      ) +
      ggplot2::guides(
        fill = ggplot2::guide_colorbar(order = 1),
        color = ggplot2::guide_legend(order = 2, override.aes = list(linewidth = 1)),
        linetype = ggplot2::guide_legend(order = 3, override.aes = list(color = "#0e610e", linewidth = 0.5))
      )
    
    # Add scales and theme
    heatmap_mt <- heatmap_mt +
      ggplot2::scale_x_date(
        limits = c(start_xlim_mt, end_xlim_mt),
        breaks = breaks_vec,
        labels = date_labels,
        expand = c(0, 0)
      ) +
      ggplot2::scale_y_discrete(expand = c(0, 0)) +
      ggplot2::labs(
        title = paste("Cash Rate Probabilities for Meeting on", fmt_date(meeting_date_proper)),
        x = "Date",
        y = "Cash Rate"
      ) +
      ggplot2::theme_bw() +
      ggplot2::theme(
        axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 10),
        axis.text.y = ggplot2::element_text(size = 9),
        axis.title.x = ggplot2::element_text(size = 14),
        axis.title.y = ggplot2::element_text(size = 14),
        plot.subtitle = ggplot2::element_text(size = 10),
        legend.position = "right",
        panel.grid.major = ggplot2::element_blank(),
        panel.grid.minor = ggplot2::element_blank()
      )
    
    temp_filename <- paste0(filename, ".tmp")
    ggplot2::ggsave(filename = temp_filename, plot = heatmap_mt, width = 12, height = 8, dpi = 300, device = "png")
    
    if (file.exists(temp_filename)) {
      file.rename(temp_filename, filename)
      cat("✓ Saved heatmap:", filename, "\n")
    } else {
      cat("✗ Temp file was not created\n")
    }
    
  }, error = function(e) {
    cat("✗ Error creating heatmap:", e$message, "\n")
  })
}

cat("\nHeatmap visualizations completed!\n")
cat("\nDaily analysis completed successfully!\n")



# =============================================
# INTERACTIVE PLOTLY HEATMAP VISUALIZATIONS
# =============================================
cat("\n=== Creating interactive heatmap visualizations ===\n")

for (mt in future_meetings_all) {
  cat("\n=== Processing interactive heatmap for meeting:", as.character(as.Date(mt)), "===\n")
  
  df_mt_heat <- all_estimates_buckets_ext %>%
    dplyr::filter(as.Date(meeting_date) == as.Date(mt)) %>%
    dplyr::group_by(scrape_date, move, bucket) %>%
    dplyr::summarise(probability = sum(probability, na.rm = TRUE), .groups = "drop") %>%
    dplyr::arrange(scrape_date, move)
  
  if (nrow(df_mt_heat) == 0) {
    cat("Skipping - no data for meeting\n")
    next 
  }
  
  bucket_lookup <- all_estimates_buckets_ext %>%
    dplyr::select(move, bucket) %>%
    dplyr::distinct()
  
  df_mt_heat <- df_mt_heat %>%
    dplyr::filter(
      !is.na(scrape_date), !is.na(probability),
      is.finite(probability), probability >= 0, !is.na(move)
    ) %>%
    dplyr::mutate(
      probability = pmin(probability, 1.0),
      probability = pmax(probability, 0.0)
    )
  
  if (nrow(df_mt_heat) == 0) next
  
  meeting_date_proper <- as.Date(mt) - days(1)
  start_xlim_mt <- min(df_mt_heat$scrape_date, na.rm = TRUE)
  end_xlim_mt <- meeting_date_proper
  
  available_moves <- unique(df_mt_heat$move[!is.na(df_mt_heat$move)])
  valid_move_levels <- rate_labels[rate_labels %in% available_moves]
  
  df_mt_heat <- df_mt_heat %>%
    dplyr::filter(move %in% valid_move_levels) %>%
    dplyr::mutate(move = factor(move, levels = valid_move_levels)) %>%
    dplyr::filter(!is.na(move))
  
  if (nrow(df_mt_heat) == 0) next
  
  # Forward fill missing days
  all_dates_seq <- seq.Date(from = start_xlim_mt, to = end_xlim_mt, by = "day")
  
  complete_grid <- expand.grid(
    scrape_date = all_dates_seq,
    move = valid_move_levels,
    stringsAsFactors = FALSE
  ) %>%
    dplyr::mutate(move = factor(move, levels = valid_move_levels)) %>%
    dplyr::left_join(bucket_lookup, by = "move")
  
  df_mt_heat <- complete_grid %>%
    dplyr::left_join(
      df_mt_heat %>% dplyr::select(scrape_date, move, probability),
      by = c("scrape_date", "move")
    )
  
  last_data_dates <- df_mt_heat %>%
    dplyr::filter(!is.na(probability)) %>%
    dplyr::group_by(move) %>%
    dplyr::summarise(last_date = max(scrape_date), .groups = "drop")
  
  df_mt_heat <- df_mt_heat %>%
    dplyr::left_join(last_data_dates, by = "move") %>%
    dplyr::group_by(move) %>%
    dplyr::arrange(scrape_date) %>%
    dplyr::mutate(
      probability = ifelse(scrape_date <= last_date,
                          zoo::na.locf(probability, na.rm = FALSE),
                          NA_real_)
    ) %>%
    dplyr::select(-last_date) %>%
    dplyr::ungroup()
  
  # Fill any remaining NAs at the start with 0
  df_mt_heat <- df_mt_heat %>%
    dplyr::group_by(move) %>%
    dplyr::mutate(
      first_non_na = min(scrape_date[!is.na(probability)], na.rm = TRUE),
      probability = ifelse(is.na(probability) & scrape_date < first_non_na, 0, probability)
    ) %>%
    dplyr::select(-first_non_na) %>%
    dplyr::ungroup()
  
  # Calculate percentile lines
  percentile_lines <- all_estimates_area %>%
    dplyr::filter(as.Date(meeting_date) == as.Date(mt)) %>%
    dplyr::filter(!is.na(implied_mean), !is.na(stdev), stdev > 0) %>%
    dplyr::mutate(
      p25 = qnorm(0.25, mean = implied_mean, sd = stdev),
      p50 = implied_mean,
      p75 = qnorm(0.75, mean = implied_mean, sd = stdev)
    ) %>%
    dplyr::select(scrape_date, p25, p50, p75) %>%
    dplyr::distinct()
  
  # Prepare actual cash rate line
  actual_rate_line <- rba_historical %>%
    dplyr::filter(date >= start_xlim_mt, date <= end_xlim_mt) %>%
    dplyr::mutate(rate_label = sprintf("%.2f%%", value)) %>%
    dplyr::select(date, value)
  
  # Check for actual outcome
  actual_outcome <- NULL
  is_past_meeting <- meeting_date_proper < Sys.Date()
  
  if (is_past_meeting) {
    actual_outcome_data <- rba_historical %>%
      dplyr::filter(date > meeting_date_proper + 2) %>%
      dplyr::slice_min(date, n = 1, with_ties = FALSE)
    
    if (nrow(actual_outcome_data) > 0) {
      actual_outcome <- actual_outcome_data$value
      cat("Actual outcome for interactive heatmap:", actual_outcome, "%\n")
    }
  }
  
  # RBA meetings in range
  rba_meetings_in_range <- meeting_schedule %>%
    dplyr::filter(meeting_date > start_xlim_mt, meeting_date < meeting_date_proper)
  
  # Prepare data for Plotly (pivot wider for heatmap)
  heat_matrix <- df_mt_heat %>%
    tidyr::pivot_wider(
      id_cols = scrape_date,
      names_from = move,
      values_from = probability
    ) %>%
    dplyr::arrange(scrape_date)
  
  dates <- heat_matrix$scrape_date
  heat_matrix <- heat_matrix %>% dplyr::select(-scrape_date)
  
  # Create custom hover text with date, rate, and probability
  hover_text <- matrix("", nrow = nrow(heat_matrix), ncol = ncol(heat_matrix))
  for (i in seq_len(nrow(heat_matrix))) {
    for (j in seq_len(ncol(heat_matrix))) {
      prob_val <- heat_matrix[i, j]
      if (!is.na(prob_val)) {
        hover_text[i, j] <- paste0(
          "Date: ", format(dates[i], "%d %b %Y"), "<br>",
          "Cash Rate: ", colnames(heat_matrix)[j], "<br>",
          "Probability: ", sprintf("%.1f%%", prob_val * 100)
        )
      }
    }
  }
  
  # Create the interactive heatmap
  filename_html <- paste0("docs/meetings/daily_heatmap_", fmt_file(meeting_date_proper), ".html")
  
  tryCatch({
    fig <- plotly::plot_ly(
      x = dates,
      y = colnames(heat_matrix),
      z = t(as.matrix(heat_matrix)),
      type = "heatmap",
      colorscale = list(
        c(0.00, "#FFFACD"),
        c(0.15, "#FFD700"),
        c(0.30, "#FFA500"),
        c(0.45, "#FF6347"),
        c(0.60, "#FF1493"),
        c(0.75, "#8B008B"),
        c(0.90, "#4B0082"),
        c(1.00, "#2E0854")
      ),
      zmin = 0,
      zmax = 1,
      hoverinfo = "text",
      text = t(hover_text),
      colorbar = list(
        title = "Probability",
        tickformat = ".0%",
        len = 0.8
      )
    )
    

    
    # Add actual cash rate line
    if (nrow(actual_rate_line) > 0) {
      fig <- fig %>%
        plotly::add_trace(
          x = actual_rate_line$date,
          y = actual_rate_line$value,
          type = "scatter",
          mode = "lines",
          name = "Actual Cash Rate",
          line = list(color = "#0066CC", width = 2),
          hovertemplate = paste0("Date: %{x|%d %b %Y}<br>",
                                "Actual Rate: %{y:.2f}%<extra></extra>")
        )
    }
    
    # Add actual outcome line
    if (!is.null(actual_outcome)) {
      fig <- fig %>%
        plotly::add_trace(
          x = c(start_xlim_mt, end_xlim_mt),
          y = c(actual_outcome, actual_outcome),
          type = "scatter",
          mode = "lines",
          name = "Actual Outcome",
          line = list(color = "black", width = 2, dash = "dot"),
          hovertemplate = paste0("Actual Outcome: ", sprintf("%.2f%%", actual_outcome), "<extra></extra>")
        )
    }
    
    # Add RBA meeting lines
    if (nrow(rba_meetings_in_range) > 0) {
      for (i in seq_len(nrow(rba_meetings_in_range))) {
        mtg_date <- rba_meetings_in_range$meeting_date[i]
        y_range <- range(as.numeric(gsub("%", "", colnames(heat_matrix))))
        
        fig <- fig %>%
          plotly::add_trace(
            x = c(mtg_date, mtg_date),
            y = y_range,
            type = "scatter",
            mode = "lines",
            name = if(i == 1) "RBA Meetings" else NA,
            showlegend = (i == 1),
            line = list(color = "grey30", width = 1, dash = "dash"),
            hovertemplate = paste0("RBA Meeting: ", format(mtg_date, "%d %b %Y"), "<extra></extra>")
          )
      }
    }
    
    # Update layout
    fig <- fig %>%
      plotly::layout(
        title = list(
          text = paste("Cash Rate Probabilities for Meeting on", fmt_date(meeting_date_proper)),
          font = list(size = 16)
        ),
        xaxis = list(
          title = "Date",
          tickformat = "%b-%Y",
          dtick = "M1"
        ),
        yaxis = list(
          title = "Cash Rate (%)",
          type = "category"
        ),
        hovermode = "closest",
        plot_bgcolor = "#FFFFFF",
        paper_bgcolor = "#FFFFFF"
      )
    
    # Save the interactive plot
    htmlwidgets::saveWidget(
      plotly::as_widget(fig),
      file = filename_html,
      selfcontained = TRUE
    )
    
    cat("✓ Saved interactive heatmap:", filename_html, "\n")
    
  }, error = function(e) {
    cat("✗ Error creating interactive heatmap:", e$message, "\n")
  })
}

cat("\nInteractive heatmap visualizations completed!\n")
