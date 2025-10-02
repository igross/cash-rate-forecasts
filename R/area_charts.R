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
  library(readrba)   # for read_rba()
  library(scales)
})

# =============================================
# 2) Load data & RMSE lookup
# =============================================
cash_rate <- readRDS("combined_data/all_data.Rds")    # columns: date, cash_rate, scrape_time
cash_rate_archieve <- readRDS("combined_data/archieve.Rds")    # columns: date, cash_rate, scrape_time

cash_rate_archieve <- cash_rate_archieve %>%
  mutate(
    scrape_time = with_tz(
      ymd_hms(paste(scrape_date, "12:00:00")),
      tzone = "Australia/Sydney"  # AEST/AEDT
    )
  ) %>%
  filter(scrape_date < as.Date("2025-07-14"))

cash_rate <- bind_rows(cash_rate, cash_rate_archieve)

load("combined_data/rmse_days.RData")                 # object rmse_days: days_to_meeting ↦ finalrmse

blend_weight <- function(days_to_meeting) {
  # Linear blend from 0 to 1 over last 30 days
  pmax(0, pmin(1, 1 - days_to_meeting / 30))
}

  # 1. grab the most-recent published value only
latest_rt <- read_rba(series_id = "FIRMMCRTD") |>
             slice_max(date, n = 1, with_ties = FALSE) |>
             pull(value)

  override <- 3.60
  


spread <- 0.00
cash_rate$cash_rate <- cash_rate$cash_rate+spread

# =============================================
# 3) Define RBA meeting schedule
# =============================================
meeting_schedule <- tibble(
  meeting_date = as.Date(c(
    # 2022 meetings (11 meetings - first Tuesday of month except January)
    "2022-02-01", "2022-03-01", "2022-04-05", "2022-05-03", "2022-06-07",
    "2022-07-05", "2022-08-02", "2022-09-06", "2022-10-04", "2022-11-01",
    "2022-12-06",
    
    # 2023 meetings (11 meetings - first Tuesday of month except January)
    "2023-02-07", "2023-03-07", "2023-04-04", "2023-05-02", "2023-06-06",
    "2023-07-04", "2023-08-01", "2023-09-05", "2023-10-03", "2023-11-07",
    "2023-12-05",
    
    # 2024 meetings (8 meetings - NEW PATTERN, second day of two-day meeting)
    "2024-02-06", "2024-03-19", "2024-05-07", "2024-06-18",
    "2024-08-06", "2024-09-24", "2024-11-05", "2024-12-10",
    
    # 2025 meetings (8 meetings, second day of two-day meeting)
    "2025-02-18", "2025-04-01", "2025-05-20", "2025-07-08",
    "2025-08-12", "2025-09-30", "2025-11-04", "2025-12-09",
    
    # 2026 meetings (8 meetings, second day of two-day meeting)
    "2026-02-03", "2026-03-17", "2026-05-05", "2026-06-16",
    "2026-08-11", "2026-09-29", "2026-11-03", "2026-12-08",
    
    # 2027 meetings (8 meetings - predicted, second day of two-day meeting)
    "2027-02-02", "2027-03-16", "2027-05-04", "2027-06-15",
    "2027-08-10", "2027-09-29", "2027-11-02", "2027-12-07"
  ))
) %>%
  mutate(
    expiry = if_else(
      day(meeting_date) >= days_in_month(meeting_date) - 1,
      ceiling_date(meeting_date, "month"),
      floor_date(meeting_date, "month")
    ),
    # Add metadata about meeting pattern
    meeting_pattern = case_when(
      year(meeting_date) <= 2023 ~ "Monthly (11/year)",
      TRUE ~ "Six-weekly (8/year)"
    )
  ) %>%
  select(meeting_date, expiry, meeting_pattern)

abs_releases <- tribble(
  ~dataset,           ~datetime,
  
  # CPI (quarterly)
  "CPI",  ymd_hm("2025-01-29 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2025-04-30 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2025-07-30 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2025-10-29 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2026-01-28 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2026-04-29 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2026-07-29 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2026-10-28 11:30", tz = "Australia/Melbourne"),
  
  # CPI Indicator (monthly)
  "CPI Indicator", ymd_hm("2025-01-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-02-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-03-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-04-30 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-05-28 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-06-25 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-07-30 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-08-27 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-09-24 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-10-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-11-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-12-31 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-01-28 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-02-25 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-03-25 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-04-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-05-27 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-06-24 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-07-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-08-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-09-30 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-10-28 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-11-25 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-12-30 11:30", tz = "Australia/Melbourne"),
  
  # WPI (quarterly)
  "WPI",  ymd_hm("2025-02-19 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2025-05-14 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2025-08-13 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2025-11-12 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2026-02-18 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2026-05-13 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2026-08-12 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2026-11-11 11:30", tz = "Australia/Melbourne"),
  
  # National Accounts (quarterly)
  "National Accounts", ymd_hm("2025-03-05 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2025-06-04 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2025-09-03 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2025-12-03 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2026-03-04 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2026-06-03 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2026-09-02 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2026-12-02 11:30", tz = "Australia/Melbourne"),
  
  # Labour Force (monthly)
  "Labour Force", ymd_hm("2025-01-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-02-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-03-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-04-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-05-15 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-06-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-07-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-08-14 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-09-18 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-10-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-11-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-12-18 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-01-15 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-02-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-03-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-04-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-05-14 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-06-18 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-07-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-08-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-09-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-10-15 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-11-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-12-17 11:30", tz = "Australia/Melbourne")
)

# =============================================
# 4) Identify last meeting, collect scrapes
# =============================================
last_meeting   <- max(meeting_schedule$meeting_date[
                        meeting_schedule$meeting_date < Sys.Date()])

print(last_meeting)

use_override   <- !is.null(override) &&
                  Sys.Date() - last_meeting <= 1

print(use_override)

current_rate <- read_rba(series_id = "FIRMMCRTD") %>%
  filter(date == max(date)) %>%
  pull(value)

initial_rt     <- if (use_override) override else latest_rt

all_times <- sort(unique(cash_rate$scrape_time))

# New logic for filtering scrapes based on 2:30 PM AEST cutoff
now_melb <- lubridate::now(tzone = "Australia/Melbourne")
cutoff_time <- lubridate::ymd_hm(paste0(Sys.Date(), " 14:30"), tz = "Australia/Melbourne")

# If it's before 2:30 PM AEST, include yesterday's data
if (now_melb < cutoff_time) {
  # Include data from yesterday onwards
  cutoff_date <- Sys.Date() - 1
} else {
  # After 2:30 PM, only include today's data
  cutoff_date <- Sys.Date()
}

scrapes <- all_times[all_times >= cutoff_date | all_times > last_meeting]

# MAKE AREA DATA

rba_historical <- read_rba(series_id = "FIRMMCRTD") %>%
  arrange(date)

all_list_area <- map(all_times, function(scr) {
  
  scr_date <- as.Date(scr)
  
  # Determine the initial rate AT THIS SCRAPE TIME
  # Find the last meeting before this scrape
  last_meeting_at_scrape <- max(meeting_schedule$meeting_date[
    meeting_schedule$meeting_date < scr_date
  ])
  
  # If this scrape is within 1 day of that meeting, check for override
  use_override_at_scrape <- !is.null(override) &&
                            scr_date - last_meeting_at_scrape <= 1
  
  # Get the rate that was current at this scrape time
  if (use_override_at_scrape) {
    initial_rt_at_scrape <- override
  } else {
    # Look up the rate from the pre-loaded data
    historical_rate <- rba_historical %>%
      filter(date <= scr_date) %>%
      slice_max(date, n = 1, with_ties = FALSE) %>%
      pull(value)
    
    initial_rt_at_scrape <- if(length(historical_rate) > 0) historical_rate else latest_rt
  }
  
  # Rest of your existing code...
  df_rates <- cash_rate %>% 
    filter(scrape_time == scr) %>%
    select(
      expiry        = date,
      forecast_rate = cash_rate,
      scrape_time
    )
  
  df <- meeting_schedule %>%
    distinct(expiry, meeting_date) %>%
    mutate(scrape_time = scr) %>%
    left_join(df_rates, by = "expiry") %>%
    arrange(expiry)
  
  df <- df %>% filter(!is.na(forecast_rate))
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
      scrape_time     = scr,
      meeting_date    = row$meeting_date,
      implied_mean    = r_tp1,
      days_to_meeting = as.integer(row$meeting_date - scr_date),
      previous_rate   = rt_in
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
if (!is.finite(max_rmse)) {
  stop("No finite RMSE values found in rmse_days$finalrmse")
}

bad_sd <- !is.finite(all_estimates_area$stdev) | is.na(all_estimates_area$stdev) | all_estimates_area$stdev <= 0
n_bad  <- sum(bad_sd, na.rm = TRUE)

if (n_bad > 0) {
  message(sprintf("Replacing %d missing/invalid stdev(s) with max RMSE = %.4f", n_bad, max_rmse))
  all_estimates_area$stdev[bad_sd] <- max_rmse
}




# Extended range bucketing (±300 bp range in 25 bp steps)
bp_span <- 300L
step_bp <- 25L

# Fallback SD if any invalid values remain
sd_fallback <- suppressWarnings(stats::median(all_estimates_area$stdev[is.finite(all_estimates_area$stdev)], na.rm = TRUE))
if (!is.finite(sd_fallback) || sd_fallback <= 0) sd_fallback <- 0.01

# Re-anchor the "no change" centre to nearest 25bp
current_center_ext <- current_rate

# Bucket support: current ± 300 bp, non-negative rates
bucket_min <- 0.1
bucket_max <- 6.1
bucket_centers_ext <- seq(bucket_min, bucket_max, by = 0.25)
half_width_ext <- 0.125   # 25 bp-wide buckets

# Check if all_estimates exists and has data
if (!exists("all_estimates_area") || nrow(all_estimates_area) == 0) {
  stop("all_estimates object not found or empty. Make sure the earlier bucketing code ran successfully.")
}

cat("Creating extended buckets for", nrow(all_estimates_area), "estimate rows\n")
cat("Bucket range:", min(bucket_centers_ext), "to", max(bucket_centers_ext), "\n")

# Compute bucketed probabilities across the extended support
bucket_list_ext <- vector("list", nrow(all_estimates_area))
for (i in seq_len(nrow(all_estimates_area))) {
  mu_i    <- all_estimates_area$implied_mean[i]
  sigma_i <- all_estimates_area$stdev[i]
  d_i     <- all_estimates_area$days_to_meeting[i]

  if (!is.finite(mu_i)) next
  if (!is.finite(sigma_i) || sigma_i <= 0) sigma_i <- sd_fallback

  # Probabilistic component
  p_vec <- sapply(bucket_centers_ext, function(b) {
    lower <- b - half_width_ext
    upper <- b + half_width_ext
    pnorm(upper, mean = mu_i, sd = sigma_i) - pnorm(lower, mean = mu_i, sd = sigma_i)
  })

  # Clean and normalise
  p_vec[!is.finite(p_vec) | p_vec < 0] <- 0
  p_vec[p_vec < 0.01] <- 0
  s <- sum(p_vec, na.rm = TRUE)
  if (is.finite(s) && s > 0) {
    p_vec <- p_vec / s
  } else {
    p_vec[] <- 0
  }

  # Linear component (two nearest buckets), clamped
  nearest <- order(abs(bucket_centers_ext - mu_i))[1:2]
  b1 <- min(bucket_centers_ext[nearest])
  b2 <- max(bucket_centers_ext[nearest])
  denom <- (b2 - b1)
  w2 <- if (denom > 0) (mu_i - b1) / denom else 0
  w2 <- min(max(w2, 0), 1)
  l_vec <- numeric(length(bucket_centers_ext))
  l_vec[which(bucket_centers_ext == b1)] <- 1 - w2
  l_vec[which(bucket_centers_ext == b2)] <- w2

  # Blend by days to meeting
  blend <- blend_weight(d_i)
  v <- blend * l_vec + (1 - blend) * p_vec

  bucket_list_ext[[i]] <- tibble::tibble(
    scrape_time     = all_estimates_area$scrape_time[i],
    meeting_date    = all_estimates_area$meeting_date[i],
    implied_mean    = mu_i,
    stdev           = sigma_i,
    days_to_meeting = d_i,
    bucket          = bucket_centers_ext,
    probability     = v
  )
}

# Combine all buckets
all_estimates_buckets_ext <- dplyr::bind_rows(bucket_list_ext) %>%
  dplyr::mutate(
    diff_bps = as.integer(round((bucket - current_center_ext) * 100L)),
    diff_bps = pmax(pmin(diff_bps, bp_span), -bp_span)
  )

all_estimates_buckets_ext <- all_estimates_buckets_ext %>%
  dplyr::mutate(
    # Use actual bucket rate as the label
    move = sprintf("%.2f%%", bucket),
    # Keep diff_bps for reference
    diff_bps = as.integer(round((bucket - current_center_ext) * 100L))
  )

# Create ordered factor levels based on bucket rates (ascending order)
rate_levels <- sort(unique(all_estimates_buckets_ext$bucket))
rate_labels <- sprintf("%.2f%%", rate_levels)

all_estimates_buckets_ext <- all_estimates_buckets_ext %>%
  dplyr::mutate(
    move = factor(move, levels = rate_labels)
  )



future_meetings_all <- meeting_schedule %>%
  dplyr::mutate(meeting_date = as.Date(meeting_date)) %>%
#  dplyr::filter(meeting_date > Sys.Date()) %>%
  dplyr::pull(meeting_date)

# Debug output to verify
cat("Future meetings found:", length(future_meetings_all), "\n")
cat("Meetings:", paste(future_meetings_all, collapse = ", "), "\n")

# 1. Define helper functions
fmt_date <- function(x) format(as.Date(x), "%d %B %Y")
fmt_file <- function(x) format(as.Date(x), "%Y-%m-%d")

# 2. Create the fill_map for all possible moves
# First, get all unique moves from the extended buckets
all_moves <- unique(all_estimates_buckets_ext$move)
all_moves <- all_moves[!is.na(all_moves)]

# Initialize with default grey
# Get all unique rates
all_rates <- sort(unique(all_estimates_buckets_ext$bucket))

# Create fill_map with blue (below current), grey (current), red (above current)
fill_map <- setNames(character(length(all_rates)), sprintf("%.2f%%", all_rates))

for (i in seq_along(all_rates)) {
  rate <- all_rates[i]
  diff_from_current <- rate - current_rate
  
  if (abs(diff_from_current) < 0.01) {
    # Current rate - grey
    fill_map[i] <- "#BFBFBF"
  } else if (diff_from_current < 0) {
    # Below current rate - shades of blue (darker for bigger cuts)
    bp_below <- abs(diff_from_current) * 100
    if (bp_below >= 125) {
      fill_map[i] <- "#000080"  # very dark blue for large cuts
    } else if (bp_below >= 100) {
      fill_map[i] <- "#0033A0"  # dark blue
    } else if (bp_below >= 75) {
      fill_map[i] <- "#004B8E"  # medium-dark blue
    } else if (bp_below >= 50) {
      fill_map[i] <- "#1A5CB0"  # medium blue
    } else {
      fill_map[i] <- "#5FA4D4"  # light blue (25bp)
    }
  } else {
    # Above current rate - shades of red (darker for bigger hikes)
    bp_above <- diff_from_current * 100
    if (bp_above >= 125) {
      fill_map[i] <- "#800000"  # very dark red for large hikes
    } else if (bp_above >= 100) {
      fill_map[i] <- "#A00000"  # dark red
    } else if (bp_above >= 75) {
      fill_map[i] <- "#B50000"  # medium-dark red
    } else if (bp_above >= 49) {
      fill_map[i] <- "#C71010"  # medium red
    } else {
      fill_map[i] <- "#E07C7C"  # light red (25bp)
    }
  }
}

cat("Fill map created with", length(fill_map), "colors\n")
cat("Sample rates:", paste(head(names(fill_map), 10), collapse = ", "), "\n")

# Replace your existing plotting loop with this enhanced version

for (mt in future_meetings_all) {
  cat("\n=== Processing meeting:", as.character(as.Date(mt)), "===\n")
  
  df_mt <- all_estimates_buckets_ext %>%
    dplyr::filter(as.Date(meeting_date) == as.Date(mt)) %>%
    dplyr::group_by(scrape_time, move) %>%
    dplyr::summarise(probability = sum(probability, na.rm = TRUE), .groups = "drop") %>%
    tidyr::complete(scrape_time, move, fill = list(probability = 0)) %>%
    dplyr::arrange(scrape_time, move)

  print(df_mt, n = 5)
  
  cat("Initial df_mt dimensions:", nrow(df_mt), "x", ncol(df_mt), "\n")
  
  if (nrow(df_mt) == 0) {
    cat("Skipping - no data for meeting\n")
    next 
  }
  
  # ENHANCED DATA CLEANING WITH DETAILED LOGGING
  cat("Pre-cleaning data summary:\n")
  cat("  - NA scrape_time:", sum(is.na(df_mt$scrape_time)), "\n")
  cat("  - NA probability:", sum(is.na(df_mt$probability)), "\n")
  cat("  - NA move:", sum(is.na(df_mt$move)), "\n")
  cat("  - Negative probability:", sum(df_mt$probability < 0, na.rm = TRUE), "\n")
  cat("  - Infinite probability:", sum(!is.finite(df_mt$probability)), "\n")
  
  df_mt <- df_mt %>%
    dplyr::filter(
      !is.na(scrape_time),
      is.finite(as.numeric(scrape_time)),
      !is.na(probability),
      is.finite(probability),
      probability >= 0,
      !is.na(move)
    ) %>%
    dplyr::mutate(
      probability = pmin(probability, 1.0),
      probability = pmax(probability, 0.0)
    )
  
  cat("After cleaning dimensions:", nrow(df_mt), "x", ncol(df_mt), "\n")
  
  if (nrow(df_mt) == 0) {
    cat("Skipping - no valid data after cleaning\n")
    next
  }
  
  # DETAILED DATA VALIDATION
  unique_times <- length(unique(df_mt$scrape_time))
  unique_moves <- length(unique(df_mt$move))
  cat("Unique times:", unique_times, "\n")
  cat("Unique moves:", unique_moves, "\n")
  
  if (unique_times < 2) {
    cat("Skipping - insufficient time points\n")
    next
  }
  
  # TIME RANGE ANALYSIS
  meeting_date_proper <- as.Date(mt)
  time_range <- range(df_mt$scrape_time, na.rm = TRUE)
  cat("Raw time range:", as.character(time_range), "\n")
  
  start_xlim_mt <- min(df_mt$scrape_time, na.rm = TRUE) + lubridate::hours(10)
  end_xlim_mt   <- lubridate::as_datetime(meeting_date_proper, tz = "Australia/Melbourne") + lubridate::hours(17)
  
  cat("Plot time limits:", as.character(start_xlim_mt), "to", as.character(end_xlim_mt), "\n")
  cat("Time span (days):", as.numeric(end_xlim_mt - start_xlim_mt) / (24 * 3600), "\n")
  
  # FACTOR LEVEL ANALYSIS
  available_moves <- unique(df_mt$move[!is.na(df_mt$move)])
  cat("Available moves (", length(available_moves), "):", paste(head(available_moves, 10), collapse = ", "), "\n")
  
  valid_move_levels <- rate_labels[rate_labels %in% available_moves]
  
  cat("Valid move levels (", length(valid_move_levels), "):", paste(head(valid_move_levels, 10), collapse = ", "), "\n")
  
  df_mt <- df_mt %>%
    dplyr::filter(move %in% valid_move_levels) %>%
    dplyr::mutate(
      move = factor(move, levels = rev(valid_move_levels))
    ) %>%
    dplyr::filter(!is.na(move))
  
  cat("Final data dimensions:", nrow(df_mt), "x", ncol(df_mt), "\n")
  
  if (nrow(df_mt) == 0) {
    cat("Skipping - no data after factor processing\n")
    next
  }
  
  # PROBABILITY VALIDATION
  prob_stats <- summary(df_mt$probability)
  cat("Probability statistics:\n")
  print(prob_stats)
  
  # Check for stacking issues
  prob_sums_by_time <- df_mt %>%
    dplyr::group_by(scrape_time) %>%
    dplyr::summarise(total_prob = sum(probability, na.rm = TRUE), .groups = "drop")
  
  cat("Probability sums by time (should be around 1.0):\n")
  cat("  Min:", min(prob_sums_by_time$total_prob, na.rm = TRUE), "\n")
  cat("  Max:", max(prob_sums_by_time$total_prob, na.rm = TRUE), "\n")
  cat("  Mean:", mean(prob_sums_by_time$total_prob, na.rm = TRUE), "\n")
  
  # Create legend breaks - subset of rates around current rate
  legend_min <- current_rate - 1.00
  legend_max <- current_rate + 1.00
  
  # Get rates within this range
  legend_rates <- all_rates[all_rates >= legend_min & all_rates <= legend_max]
  
  # Ensure we include current rate if it's a bucket center
  if (current_rate %in% all_rates && !(current_rate %in% legend_rates)) {
    legend_rates <- sort(c(legend_rates, current_rate))
  }
  
  legend_breaks <- sprintf("%.2f%%", legend_rates)
  
  # *** NEW: Prepare RBA meeting dates for vertical lines ***
  # Get all RBA meetings that fall within the plot's time range
  # Exclude the target meeting itself (it's the endpoint)
  rba_meetings_in_range <- meeting_schedule %>%
    dplyr::filter(
      meeting_date > as.Date(start_xlim_mt),
      meeting_date < meeting_date_proper
    ) %>%
    dplyr::mutate(
      meeting_datetime = lubridate::as_datetime(meeting_date, tz = "Australia/Melbourne") + lubridate::hours(10)
    )
  
  cat("RBA meetings in plot range:", nrow(rba_meetings_in_range), "\n")
  
  # PLOTTING WITH ENHANCED ERROR HANDLING
  filename <- paste0("docs/meetings/area_all_moves_", fmt_file(meeting_date_proper), ".png")
  cat("Attempting to create plot and save to:", filename, "\n")
  
  plot_success <- FALSE
  
  tryCatch({
    cat("Building complete ggplot object with complexity reduction...\n")
    
    # Determine if meeting is in 2026 or later
    meeting_year <- lubridate::year(meeting_date_proper)
    
    if (meeting_year >= 2026) {
      # For 2026+ meetings: monthly ticks on the 1st of each month
      start_month <- lubridate::floor_date(start_xlim_mt, "month")
      end_month <- lubridate::ceiling_date(end_xlim_mt, "month")
      
      breaks_vec <- seq.Date(
        from = as.Date(start_month),
        to = as.Date(end_month),
        by = "month"
      )
      breaks_vec <- lubridate::as_datetime(breaks_vec, tz = "Australia/Melbourne")
      
      date_labels <- function(x) strftime(x, "%b-%Y")
      
    } else {
      # For 2025 meetings: keep current 30-tick format
      n_ticks <- 30L
      breaks_vec <- seq(from = start_xlim_mt, to = end_xlim_mt, length.out = n_ticks)
      date_labels <- function(x) strftime(x, "%d %b")
    }
    
    area_mt <- ggplot2::ggplot(
      df_mt,
      ggplot2::aes(x = scrape_time + lubridate::hours(10), y = probability, fill = move)
    ) +
      ggplot2::geom_area(position = "stack", alpha = 0.95, colour = NA) +
      # *** NEW: Add grey dashed horizontal line at 50% ***
      ggplot2::geom_hline(yintercept = 0.5, linetype = "dashed", 
                         color = "grey40", linewidth = 0.7, alpha = 0.8) +
      # *** NEW: Add vertical lines for RBA meetings ***
      {if(nrow(rba_meetings_in_range) > 0) 
        ggplot2::geom_vline(data = rba_meetings_in_range,
                           aes(xintercept = as.numeric(meeting_datetime)),
                           linetype = "solid", color = "white", 
                           linewidth = 0.6, alpha = 0.6)
      } +
      ggplot2::scale_fill_manual(
        values = fill_map,
        breaks = legend_breaks,
        drop = FALSE,
        name = "Cash Rate",
        guide = ggplot2::guide_legend(override.aes = list(alpha = 1))
      ) +
      ggplot2::scale_x_datetime(
        limits = c(start_xlim_mt, end_xlim_mt),
        breaks = breaks_vec,
        labels = date_labels,
        expand = c(0, 0)
      ) +
      ggplot2::scale_y_continuous(
        limits = c(0, 1),
        labels = scales::percent_format(accuracy = 1),
        expand = c(0, 0)
      ) +
      ggplot2::labs(
        title = paste("Cash Rate Scenarios up to the Meeting on", fmt_date(meeting_date_proper)),
        subtitle = "Probability distribution across cash rate levels (25 bp steps)",
        x = "Forecast date", 
        y = "Probability"
      ) +
      ggplot2::theme_bw() +
      ggplot2::theme(
        axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 10),
        axis.text.y = ggplot2::element_text(size = 12),
        axis.title.x = ggplot2::element_text(size = 14),
        axis.title.y = ggplot2::element_text(size = 14),
        legend.position = "right",
        legend.title = ggplot2::element_blank()
      )
    
    cat("Saving plot to temporary file...\n")
    temp_filename <- paste0(filename, ".tmp")
    
    ggplot2::ggsave(
      filename = temp_filename,
      plot = area_mt,
      width = 12,
      height = 5,
      dpi = 600,
      device = "png"
    )
    
    if (file.exists(temp_filename)) {
      file.rename(temp_filename, filename)
      plot_success <- TRUE
      cat("✓ Successfully saved plot for", as.character(meeting_date_proper), "\n")
    } else {
      cat("✗ Temp file was not created\n")
    }
    
  }, error = function(e) {
    cat("DETAILED ERROR INFORMATION:\n")
    cat("Error class:", class(e), "\n")
    cat("Error message:", e$message, "\n")
  })
  
  if (!plot_success) {
    cat("✗ Failed to create plot for meeting", as.character(meeting_date_proper), "\n")
  }
}

cat("\nPlotting loop completed.\n")

# 5. FIXED CSV Export section
for (mt in future_meetings_all) {
  df_mt_csv <- all_estimates_buckets_ext %>%
    dplyr::filter(as.Date(meeting_date) == as.Date(mt)) %>%
    dplyr::group_by(scrape_time, move, diff_bps, bucket) %>%
    dplyr::summarise(probability = sum(probability, na.rm = TRUE), .groups = "drop") %>%
    tidyr::complete(scrape_time, move, fill = list(probability = 0)) %>%
    dplyr::arrange(scrape_time, diff_bps) %>%
    dplyr::mutate(
      scrape_datetime_aest = format(scrape_time + lubridate::hours(10), "%Y-%m-%d %H:%M:%S"),
      meeting_date = as.Date(mt),
      bucket_rate = bucket
    ) %>%
    dplyr::select(
      meeting_date,
      scrape_time,
      scrape_datetime_aest,
      move,
      diff_bps,
      bucket_rate,
      probability
    )
  
  # Skip if no data
  if (nrow(df_mt_csv) == 0) {
    cat("Skipping CSV export - no data for meeting", as.character(mt), "\n")
    next
  }
  
  meeting_date_proper <- as.Date(mt)
  csv_filename <- paste0("docs/meetings/csv/area_data_", fmt_file(meeting_date_proper), ".csv")
  
  tryCatch({
    write.csv(df_mt_csv, csv_filename, row.names = FALSE)
    cat("CSV exported:", csv_filename, "\n")
  }, error = function(e) {
    cat("Error exporting CSV for meeting", as.character(meeting_date_proper), ":", e$message, "\n")
  })
}

# 6. Combined CSV export - FIXED VERSION
combined_csv <- all_estimates_buckets_ext %>%
  dplyr::filter(as.Date(meeting_date) %in% future_meetings_all) %>%
  dplyr::group_by(meeting_date, scrape_time, move, diff_bps, bucket) %>%
  dplyr::summarise(probability = sum(probability, na.rm = TRUE), .groups = "drop") %>%
  dplyr::arrange(meeting_date, scrape_time, diff_bps) %>%
  dplyr::mutate(
    scrape_datetime_aest = format(scrape_time + lubridate::hours(10), "%Y-%m-%d %H:%M:%S"),
    meeting_date = as.Date(meeting_date),
    bucket_rate = bucket
  ) %>%
  dplyr::select(
    meeting_date,
    scrape_time,
    scrape_datetime_aest,
    move,
    diff_bps,
    bucket_rate,
    probability
  )

# Export combined CSV
if (nrow(combined_csv) > 0) {
  tryCatch({
    write.csv(combined_csv, "docs/meetings/csv/all_meetings_area_data.csv", row.names = FALSE)
    cat("Combined CSV exported: docs/meetings/csv/all_meetings_area_data.csv\n")
  }, error = function(e) {
    cat("Error exporting combined CSV:", e$message, "\n")
  })
}

# 7. Verification output
cat("\nVerification - Sample bucket_rate values:\n")
if (nrow(combined_csv) > 0) {
  sample_rates <- unique(combined_csv$bucket_rate)
  sample_rates <- sort(sample_rates)[1:min(20, length(sample_rates))]
  cat("First 20 unique bucket rates:", paste(sample_rates, collapse = ", "), "\n")
  
  decimals <- (sample_rates * 100) %% 100
  unique_decimals <- unique(decimals)
  cat("Decimal endings (should be 10, 35, 60, 85):", paste(unique_decimals, collapse = ", "), "\n")
}

cat("Analysis completed successfully!\n")
