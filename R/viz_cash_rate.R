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


if (!dir.exists("docs/meetings")) dir.create("docs/meetings", recursive = TRUE)

# =============================================
# 3) Define RBA meeting schedule
# =============================================
meeting_schedule <- tibble(
  meeting_date = as.Date(c(
    # 2025 meetings
    "2025-02-18","2025-04-01","2025-05-20","2025-07-08",
    "2025-08-12","2025-09-30","2025-11-04","2025-12-09",
    # 2026 meetings (second day of each two-day meeting)
    "2026-02-03","2026-03-17","2026-05-05","2026-06-16",
    "2026-08-11" ,"2026-09-29","2026-11-03","2026-12-08"
  ))
) %>% 
  mutate(
    expiry = if_else(
      day(meeting_date) >= days_in_month(meeting_date) - 1,   # last 1‑2 days
      ceiling_date(meeting_date, "month"),                    # → next month
      floor_date(meeting_date,  "month")                      # otherwise same
    )
  ) %>% 
  select(expiry, meeting_date)

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
                        meeting_schedule$meeting_date <= Sys.Date()])

print(last_meeting)

use_override   <- !is.null(override) &&
                  Sys.Date() - last_meeting <= 1

print(use_override)

initial_rt     <- if (use_override) override else latest_rt

  print(initial_rt)


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

print(last_meeting)
print(now_melb)
print(cutoff_time)


scrapes <- all_times[all_times >= cutoff_date | all_times > last_meeting]

tail(scrapes)

# =============================================
# 5) Build implied‐mean panel for each scrape × meeting
# =============================================
all_list <- map(scrapes, function(scr) {

  scr_date <- as.Date(scr)

  # 1) grab the last‐known price for each expiry up to this scrape
df_rates <- cash_rate %>% 
  filter(scrape_time == scr) %>%          # keep rows from *this* scrape only
  select(
    expiry        = date,                 # contract month
    forecast_rate = cash_rate,            # implied rate
    scrape_time                         # (all identical → scr)
  )


  # 2) join onto your schedule
  df <- meeting_schedule %>%
    distinct(expiry, meeting_date) %>%
    mutate(scrape_time = scr) %>%
    left_join(df_rates, by = "expiry") %>%
    arrange(expiry)

  # 3) lose exactly those expiries with no price yet
  df <- df %>% filter(!is.na(forecast_rate))
  if (nrow(df) == 0) return(NULL)



  prev_implied <- NA_real_          # will store r_tp1 from prior row
  out <- vector("list", nrow(df))

  for (i in seq_len(nrow(df))) {
    row   <- df[i, ]

    rt_in <- if (is.na(prev_implied)) initial_rt else prev_implied

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
      previous_rate   = rt_in           # = rate actually used
    )

    prev_implied <- r_tp1               # roll forward
  }

  bind_rows(out)
})

all_estimates <- all_list %>%
  compact() %>%                    # drop the NULLs
  bind_rows() %>%
  filter(days_to_meeting >= 0) %>% # only future meetings
  left_join(rmse_days, by = "days_to_meeting") %>%
  rename(stdev = finalrmse)


max_rmse <- suppressWarnings(max(rmse_days$finalrmse, na.rm = TRUE))
if (!is.finite(max_rmse)) {
  stop("No finite RMSE values found in rmse_days$finalrmse")
}

bad_sd <- !is.finite(all_estimates$stdev) | is.na(all_estimates$stdev) | all_estimates$stdev <= 0
n_bad  <- sum(bad_sd, na.rm = TRUE)

if (n_bad > 0) {
  message(sprintf("Replacing %d missing/invalid stdev(s) with max RMSE = %.4f", n_bad, max_rmse))
  all_estimates$stdev[bad_sd] <- max_rmse
}


all_estimates%>% tail(100) %>% print(n = Inf,  width = Inf)

# =============================================
# 6) Build bucketed probabilities for each row
# =============================================
bucket_centers <- seq(0.10, 6.10, by = 0.25)
half_width     <- 0.125

current_rate <- read_rba(series_id = "FIRMMCRTD") %>%
  filter(date == max(date)) %>%
  pull(value)

 current_rate <- if (use_override) override else current_rate

current_center <- bucket_centers[ which.min( abs(bucket_centers - current_rate) ) ]

bucket_list <- vector("list", nrow(all_estimates))
for (i in seq_len(nrow(all_estimates))) {
  mu_i    <- all_estimates$implied_mean[i]
  sigma_i <- all_estimates$stdev[i]
  d_i     <- all_estimates$days_to_meeting[i]
  rc      <- current_rate  

  # Probabilistic method
  p_vec <- sapply(bucket_centers, function(b) {
    lower <- b - half_width
    upper <- b + half_width
    pnorm(upper, mean = mu_i, sd = sigma_i) - pnorm(lower, mean = mu_i, sd = sigma_i)
  })
  p_vec[p_vec < 0]    <- 0
  p_vec[p_vec < 0.01] <- 0
  p_vec <- p_vec / sum(p_vec)

  # Linear method
  nearest <- order(abs(bucket_centers - mu_i))[1:2]
  b1 <- min(bucket_centers[nearest])
  b2 <- max(bucket_centers[nearest])
  w2 <- (mu_i - b1) / (b2 - b1)
  l_vec <- numeric(length(bucket_centers))
  l_vec[bucket_centers == b1] <- 1 - w2
  l_vec[bucket_centers == b2] <- w2

  # Blending
  blend <- blend_weight(d_i)
  v <- blend * l_vec + (1 - blend) * p_vec

  bucket_list[[i]] <- tibble(
    scrape_time   = all_estimates$scrape_time[i],
    meeting_date  = all_estimates$meeting_date[i],
    implied_mean  = mu_i,
    stdev         = sigma_i,
    days_to_meeting = d_i,
    bucket        = bucket_centers,
    probability_linear = l_vec,
    probability_prob   = p_vec,
    probability        = v,
    diff           = bucket_centers - current_rate,
    diff_s         = sign(bucket_centers - current_rate) * abs(bucket_centers - current_rate)^(1/4)
  )
}

all_estimates_buckets <- bind_rows(bucket_list)

all_estimates_buckets %>% 
  tail(20) %>% 
  print(n = Inf, width = Inf)

# =============================================
# 7 Bar charts for every future meeting (latest scrape)
# =============================================

# 1) Identify all future RBA meetings
future_meetings <- meeting_schedule$meeting_date
future_meetings <- future_meetings[future_meetings > Sys.Date()]

# 2) Grab the most recent scrape_time
latest_scrape <- max(all_estimates_buckets$scrape_time)

# 3) Loop through each meeting, filter & plot
for (mt in future_meetings) {
  # a) extract the slice for this meeting
  bar_df <- all_estimates_buckets %>%
    filter(
      scrape_time  == latest_scrape,
      meeting_date == mt
    )


  

  # d) create the bar chart
p <- ggplot(bar_df, aes(x = factor(bucket), y = probability, fill = diff_s)) +
  geom_col(show.legend = FALSE) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_fill_gradient2(
    midpoint = 0,
    low      = "#0022FF",    # vivid blue for cuts
    mid      = "#B3B3B3",    # white at no change
    high     = "#FF2200",    # vivid red for hikes
    limits   = range(bar_df$diff_s, na.rm = TRUE)
  ) +
    labs(
      title    = paste("Cash Rate Outcome Probabilities —", format(as.Date(mt), "%d %B %Y")),
      subtitle =paste(
  "As of", 
  format(with_tz(as.POSIXct(latest_scrape) + hours(10), tzone = "Australia/Sydney"), "%d %B %Y, %I:%M %p AEST")
),
      x        = "Target Rate (%)",
      y        = "Probability (%)"
    ) +
   theme_bw()  +
   theme(axis.text.x = element_text(angle = 45, hjust = 1))

                     
  ggsave(
      filename = paste0("docs/rate_probabilities_", gsub(" ", "_", mt), ".png"),
    plot     = p,
    width    = 6,
    height   = 4,
    dpi      = 300,
    device   = "png"
  )
}


# =============================================
# Define next_meeting
#  • If today is a meeting day, keep it until 15:30 AEST/AEDT
#    then switch to the following meeting
# =============================================
now_melb  <- lubridate::now(tzone = "Australia/Melbourne")
today_melb <- as.Date(now_melb)

cutoff <- lubridate::ymd_hm(
  paste0(today_melb, " 15:00"),
  tz = "Australia/Melbourne"
)



next_meeting <- if (today_melb %in% meeting_schedule$meeting_date &&
                    now_melb < cutoff) {
  today_melb                       # keep showing today’s meeting
} else {
  meeting_schedule %>%             # otherwise roll forward
    filter(meeting_date > today_melb) %>%
    slice_min(meeting_date) %>%
    pull(meeting_date)
}

print(next_meeting)
# —————————————————————————————————————————————————————————————————————
# build top3_df and turn the numeric bucket centers into descriptive moves
# —————————————————————————————————————————————————————————————————————
# 1) compute the true “no‐change” bucket centre once:
current_center <- bucket_centers[which.min(abs(bucket_centers - current_rate))]

top3_buckets <- all_estimates_buckets %>% 
  filter(meeting_date == next_meeting) %>%          # keep the target meeting
  group_by(bucket) %>%                              # pool all scrapes
  summarise(probability = mean(probability, na.rm = TRUE),
            .groups = "drop") %>%                   # average across scrapes
  slice_max(order_by = probability, n = 4, with_ties = FALSE) %>% 
  pull(bucket)


# B) now build top3_df by filtering all dates to those same 3 buckets
top3_df <- all_estimates_buckets %>%
  filter(
    meeting_date == next_meeting,
    bucket %in% top3_buckets
  ) %>%
  # compute diff & move exactly as before
  mutate(
    diff_center = bucket - current_center,
    move = case_when(
      near(diff_center, -0.75) ~ "-75 bp cut",
      near(diff_center, -0.50) ~ "-50 bp cut",
      near(diff_center, -0.25) ~ "-25 bp cut",
      near(diff_center,  0.00) ~ "No change",
      near(diff_center,  0.25) ~ "+25 bp hike",
      near(diff_center,  0.50) ~ "+50 bp hike",
      near(diff_center,  0.75) ~ "+75 bp hike",
      TRUE                      ~ sprintf("%+.0f bp", diff_center*100)
    ),
    move = factor(
      move,
      levels = c("-75 bp cut","-50 bp cut","-25 bp cut","No change","+25 bp hike","+50 bp hike","+75 bp hike")
    )
  ) %>%
  select(-diff_center)

top3_df <- top3_df %>% 
  mutate(
    move = factor(
      move,
      levels = c(
        "-75 bp cut",      # add
        "-50 bp cut",
        "-25 bp cut",
        "No change",
        "+25 bp hike",
        "+50 bp hike",
        "+75 bp hike"      # add
      )
    )
  )


start_xlim <- min(top3_df$scrape_time) + hours(10)
end_xlim   <- as.POSIXct(next_meeting, tz = "Australia/Melbourne") + hours(17)



# Your existing line plot
line <- ggplot(top3_df, aes(x = scrape_time + hours(10), y = probability,
                            colour = move, group = move)) +
  geom_line(linewidth = 1.2) +
  scale_colour_manual(
    values = c("-75 bp cut" = "#000080", "-50 bp cut" = "#004B8E",
               "-25 bp cut" = "#5FA4D4", "No change" = "#BFBFBF",
               "+25 bp hike" = "#E07C7C", "+50 bp hike" = "#B50000",
               "+75 bp hike" = "#800000",
              "CPI" = "#FF6B6B",
"CPI Indicator" = "#4ECDC4", 
"WPI" = "#45B7D1",
"National Accounts" = "#FFA726",
"Labour Force" = "#AB47BC"),
    name = ""   
  ) +
  scale_x_datetime(
    limits      = c(start_xlim, end_xlim),
    date_breaks = "2 day",
    date_labels = "%d %b",
    expand      = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, 1), labels = scales::percent_format(accuracy = 1),
    expand = c(0, 0)
  ) +
  labs(
    title    = glue::glue("Cash-Rate Moves for the Next Meeting on {format(next_meeting, '%d %b %Y')}"),
    subtitle = glue::glue("as of {format(as.Date(latest_scrape), '%d %b %Y')}"),
    x = "Forecast date", y = "Probability"
  ) +
  geom_vline(data = abs_releases,
             aes(xintercept = datetime, colour = dataset),
             linetype = "dashed", alpha = 0.8) +
  theme_bw() +
  theme(axis.text.x  = element_text(angle = 45, hjust = 1, size = 9),
        axis.text.y  = element_text(size = 12),
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14),
        legend.position = "right",
        legend.title = element_blank())

# Save the static plot
ggsave("docs/line.png", line, width = 10, height = 5, dpi = 300)

# NOW create line_int for interactive plot
line_int <- line +
  aes(text = paste0(
    "Time: ", format(scrape_time + hours(10), "%d %b %H:%M"), "<br>",
    "Move: ", move, "<br>",
    "Probability: ", scales::percent(probability, accuracy = 1)
  ))

# Convert to plotly
interactive_line <- ggplotly(line_int, tooltip = "text") %>%
  layout(
    hovermode = "x unified",
    legend = list(x = 1.02, y = 0.5, xanchor = "left"),
    showlegend = TRUE
  )


htmlwidgets::saveWidget(
  interactive_line,
  file          = "docs/line_interactive.html",
  selfcontained = TRUE
)



# Extended range bucketing (±300 bp range in 25 bp steps)
bp_span <- 300L
step_bp <- 25L

# Fallback SD if any invalid values remain
sd_fallback <- suppressWarnings(stats::median(all_estimates$stdev[is.finite(all_estimates$stdev)], na.rm = TRUE))
if (!is.finite(sd_fallback) || sd_fallback <= 0) sd_fallback <- 0.01

# Re-anchor the "no change" centre to nearest 25bp
current_center_ext <- round(current_rate / 0.25) * 0.25

# Bucket support: current ± 300 bp, non-negative rates
bucket_min <- max(0, floor((current_center_ext - bp_span/100) / 0.25) * 0.25)
bucket_max <- ceiling((current_center_ext + bp_span/100) / 0.25) * 0.25
bucket_centers_ext <- seq(bucket_min, bucket_max, by = 0.25)
half_width_ext <- 0.125   # 25 bp-wide buckets

# Check if all_estimates exists and has data
if (!exists("all_estimates") || nrow(all_estimates) == 0) {
  stop("all_estimates object not found or empty. Make sure the earlier bucketing code ran successfully.")
}

cat("Creating extended buckets for", nrow(all_estimates), "estimate rows\n")
cat("Bucket range:", min(bucket_centers_ext), "to", max(bucket_centers_ext), "\n")

# Compute bucketed probabilities across the extended support
bucket_list_ext <- vector("list", nrow(all_estimates))
for (i in seq_len(nrow(all_estimates))) {
  mu_i    <- all_estimates$implied_mean[i]
  sigma_i <- all_estimates$stdev[i]
  d_i     <- all_estimates$days_to_meeting[i]

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
    scrape_time     = all_estimates$scrape_time[i],
    meeting_date    = all_estimates$meeting_date[i],
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

# Move levels ordered from biggest CUT to biggest HIKE (for proper stacking)
move_levels_bps <- seq(-bp_span, bp_span, by = step_bp)  # -300, -275, -250, ..., 275, 300
label_move <- function(x) if (x < 0) paste0(abs(x), " bp cut") else if (x == 0) "No change" else paste0("+", x, " bp hike")
move_levels_lbl <- vapply(move_levels_bps, label_move, character(1))

# Legend breaks (for the -100 to +100 range, ordered cut→hike for consistency)
legend_bps    <- seq(-100, 100, by = 25)  # -100, -75, -50, -25, 0, 25, 50, 75, 100
legend_breaks <- vapply(legend_bps, label_move, character(1))

# Add move labels
all_estimates_buckets_ext <- all_estimates_buckets_ext %>%
  dplyr::mutate(
    move = dplyr::case_when(
      diff_bps == 0L ~ "No change",
      diff_bps <  0L ~ paste0(abs(diff_bps), " bp cut"),
      TRUE           ~ paste0("+", diff_bps, " bp hike")
    ),
    move = factor(move, levels = move_levels_lbl)  # Now properly ordered cut→hike
  )

cat("Extended buckets created:", nrow(all_estimates_buckets_ext), "rows\n")
cat("Unique moves:", length(unique(all_estimates_buckets_ext$move)), "\n")

# Verify the object was created successfully
if (!exists("all_estimates_buckets_ext") || nrow(all_estimates_buckets_ext) == 0) {
  stop("Failed to create all_estimates_buckets_ext")
} else {
  cat("✓ all_estimates_buckets_ext created successfully\n")
}

# For the main area chart (top3_df):
top3_df <- top3_df %>%
  # make sure every scrape_time × move pair exists:
  complete(
    scrape_time,
    move,
    fill = list(probability = 0)
  ) %>%
  # CRITICAL: Reverse the factor levels so stacking works correctly
  # We want: biggest cuts at bottom, no change in middle, biggest hikes at top
  mutate(
    move = factor(
      move,
      levels = rev(c(  # <- Note the rev() here!
        "-75 bp cut",
        "-50 bp cut",
        "-25 bp cut",
        "No change",
        "+25 bp hike",
        "+50 bp hike",
        "+75 bp hike"
      ))
    )
  )

# Update the color mapping to match the reversed levels
my_fill_cols <- c(
  "-75 bp cut" = "#000080",  # navy blue
  "-50 bp cut" = "#004B8E",
  "-25 bp cut" = "#5FA4D4",
  "No change"  = "#BFBFBF",
  "+25 bp hike" = "#E07C7C",
  "+50 bp hike" = "#B50000",
  "+75 bp hike" = "#800000"   # dark red
)

# Create area chart with corrected stacking
area <- ggplot(top3_df, aes(x = scrape_time + hours(10), y = probability,
                            fill = move)) +  # Remove group = move
  geom_area(position = "stack", alpha = 0.9, colour = NA) +  # Use default stacking
  scale_fill_manual(
    values = my_fill_cols,
    # Show legend in logical order (cuts to hikes)
    breaks = c("-75 bp cut", "-50 bp cut", "-25 bp cut", "No change", 
               "+25 bp hike", "+50 bp hike", "+75 bp hike"),
    drop = FALSE, 
    name = "", 
    na.value = "grey80"
  ) +
  scale_x_datetime(
    limits      = c(start_xlim, end_xlim),
    date_breaks = "1 day",
    date_labels = "%d %b",
    expand      = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, 1), labels = scales::percent_format(accuracy = 1),
    expand = c(0, 0)
  ) +
  labs(
    title    = glue::glue("Cash Rate Scenarios up to the Meeting on {format(next_meeting, '%d %b %Y')}"),
    x = "Forecast date", y = "Probability"
  ) +
  theme_bw() +
  theme(axis.text.x  = element_text(angle = 45, hjust = 1, size = 12),
        axis.text.y  = element_text(size = 12),
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14))


future_meetings_all <- meeting_schedule %>%
  dplyr::mutate(meeting_date = as.Date(meeting_date)) %>%
  dplyr::filter(meeting_date > Sys.Date()) %>%
  dplyr::pull(meeting_date)

# Debug output to verify
cat("Future meetings found:", length(future_meetings_all), "\n")
cat("Meetings:", paste(future_meetings_all, collapse = ", "), "\n")

# For the extended area charts (all future meetings):
for (mt in future_meetings_all) {
  df_mt <- all_estimates_buckets_ext %>%
    dplyr::filter(as.Date(meeting_date) == as.Date(mt)) %>%
    dplyr::group_by(scrape_time, move) %>%
    dplyr::summarise(probability = sum(probability, na.rm = TRUE), .groups = "drop") %>%
    tidyr::complete(scrape_time, move, fill = list(probability = 0)) %>%
    dplyr::arrange(scrape_time, move)

  # Enhanced debugging and validation
  cat("Processing meeting:", as.character(mt), "\n")
  cat("df_mt dimensions:", nrow(df_mt), "x", ncol(df_mt), "\n")
  
  # Check for empty or invalid data
  if (nrow(df_mt) == 0) {
    cat("Skipping - no data for meeting\n")
    next 
  }
  
  # Check for valid scrape_time data
  valid_times <- !is.na(df_mt$scrape_time) & is.finite(as.numeric(df_mt$scrape_time))
  if (!any(valid_times)) {
    cat("Skipping - no valid scrape times\n")
    next
  }
  
  # Filter to only valid data
  df_mt <- df_mt %>%
    dplyr::filter(
      !is.na(scrape_time),
      is.finite(as.numeric(scrape_time)),
      !is.na(probability),
      is.finite(probability)
    )
  
  if (nrow(df_mt) == 0) {
    cat("Skipping - no valid data after filtering\n")
    next
  }
  
  # Check we have at least 2 time points for a meaningful plot
  unique_times <- length(unique(df_mt$scrape_time))
  if (unique_times < 2) {
    cat("Skipping - insufficient time points (", unique_times, ")\n")
    next
  }

  start_xlim_mt <- min(df_mt$scrape_time, na.rm = TRUE) + lubridate::hours(10)
  end_xlim_mt   <- lubridate::as_datetime(as.Date(mt), tz = "Australia/Melbourne") + lubridate::hours(17)

  # Ensure we have valid time limits
  if (!is.finite(as.numeric(start_xlim_mt)) || !is.finite(as.numeric(end_xlim_mt))) {
    cat("Skipping - invalid time limits\n")
    next
  }

  # CRITICAL FIX: Proper factor ordering for stacking
  df_mt <- df_mt %>%
    dplyr::mutate(
      # Convert move to factor with REVERSED levels for proper stacking
      # This ensures biggest cuts stack at bottom, hikes at top
      move = factor(move, levels = rev(move_levels_lbl))
    ) %>%
    # Remove any rows with moves not in our levels
    dplyr::filter(!is.na(move))

  # Final check after all processing
  if (nrow(df_mt) == 0) {
    cat("Skipping - no data after final processing\n")
    next
  }

  # Build exactly 30 equally spaced ticks
  n_ticks    <- 30L
  breaks_vec <- seq(from = start_xlim_mt, to = end_xlim_mt, length.out = n_ticks)

  cat("Creating plot with", nrow(df_mt), "data points\n")
  
  # Try-catch around the plotting to handle any remaining issues
  tryCatch({
    area_mt <- ggplot2::ggplot(
      df_mt,
      ggplot2::aes(
        x    = scrape_time + lubridate::hours(10),
        y    = probability,
        fill = move
      )  # Removed group and order - let ggplot handle it
    ) +
      ggplot2::geom_area(
        position = "stack",  # Use simple stacking
        alpha    = 0.95,
        colour   = NA
      ) +
      ggplot2::scale_fill_manual(
        values = fill_map,
        # Show legend in stacking order (biggest cut to biggest hike)
        breaks = legend_breaks,  # This should now reflect cut→hike order  
        drop   = FALSE,
        name   = ""
      ) +
      ggplot2::scale_x_datetime(
        limits = c(start_xlim_mt, end_xlim_mt),
        breaks = breaks_vec,
        labels = function(x) strftime(x, "%d %b"),
        expand = c(0, 0)
      ) +
      ggplot2::scale_y_continuous(
        limits = c(0, 1),
        labels = scales::percent_format(accuracy = 1),
        expand = c(0, 0)
      ) +
      ggplot2::labs(
        title    = paste("Cash Rate Scenarios up to the Meeting on", fmt_date(mt)),
        subtitle = "Move bands shown from -300 bp to +300 bp (25 bp steps)",
        x = "Forecast date", y = "Probability"
      ) +
      ggplot2::theme_bw() +
      ggplot2::theme(
        axis.text.x  = ggplot2::element_text(angle = 45, hjust = 1, size = 10),
        axis.text.y  = ggplot2::element_text(size = 12),
        axis.title.x = ggplot2::element_text(size = 14),
        axis.title.y = ggplot2::element_text(size = 14),
        legend.position = "right",
        legend.title    = ggplot2::element_blank()
      )

    filename <- paste0("docs/meetings/area_all_moves_", fmt_file(mt), ".png")
    cat("Saving to:", filename, "\n")
    
    ggplot2::ggsave(
      filename = filename,
      plot     = area_mt,
      width    = 12,
      height   = 5,
      dpi      = 300
    )
    
    cat("Successfully saved plot for", as.character(mt), "\n")
    
  }, error = function(e) {
    cat("Error creating plot for meeting", as.character(mt), ":", e$message, "\n")
    cat("Data summary:\n")
    print(summary(df_mt))
  })


# Add this code right after the area chart loop, before the final closing brace

# Define helper functions if they don't exist
if (!exists("fmt_date")) {
  fmt_date <- function(x) format(as.Date(x), "%d %B %Y")
}
if (!exists("fmt_file")) {
  fmt_file <- function(x) format(as.Date(x), "%Y-%m-%d")
}

# Also need to define fill_map if it doesn't exist
if (!exists("fill_map")) {
  # Create a comprehensive fill map for all possible moves
  all_moves <- unique(all_estimates_buckets_ext$move)
  all_moves <- all_moves[!is.na(all_moves)]
  
  # Generate colors: blue for cuts, grey for no change, red for hikes
  n_moves <- length(all_moves)
  fill_map <- setNames(rep("#BFBFBF", n_moves), all_moves)  # default grey
  
  # Apply colors based on move type
  for (mv in all_moves) {
    if (grepl("cut", mv, ignore.case = TRUE)) {
      # Cuts: shades of blue (darker = bigger cut)
      if (grepl("300|275|250|225|200", mv)) fill_map[mv] <- "#000080"  # very dark blue
      else if (grepl("175|150|125|100", mv)) fill_map[mv] <- "#0033A0"
      else if (grepl("75", mv)) fill_map[mv] <- "#004B8E"
      else if (grepl("50", mv)) fill_map[mv] <- "#1A5CB0"
      else if (grepl("25", mv)) fill_map[mv] <- "#5FA4D4"
    } else if (grepl("hike", mv, ignore.case = TRUE)) {
      # Hikes: shades of red (darker = bigger hike)
      if (grepl("300|275|250|225|200", mv)) fill_map[mv] <- "#800000"  # very dark red
      else if (grepl("175|150|125|100", mv)) fill_map[mv] <- "#A00000"
      else if (grepl("75", mv)) fill_map[mv] <- "#B50000"
      else if (grepl("50", mv)) fill_map[mv] <- "#C71010"
      else if (grepl("25", mv)) fill_map[mv] <- "#E07C7C"
    } else if (grepl("No change", mv, ignore.case = TRUE)) {
      fill_map[mv] <- "#BFBFBF"  # grey for no change
    }
  }
}

# Export data for all future meetings as CSV files - FIXED VERSION
for (mt in future_meetings_all) {
  df_mt_csv <- all_estimates_buckets_ext %>%
    dplyr::filter(as.Date(meeting_date) == as.Date(mt)) %>%
    dplyr::group_by(scrape_time, move, diff_bps, bucket) %>%  # ADD bucket to group_by
    dplyr::summarise(probability = sum(probability, na.rm = TRUE), .groups = "drop") %>%
    tidyr::complete(scrape_time, move, fill = list(probability = 0)) %>%
    dplyr::arrange(scrape_time, diff_bps) %>%
    dplyr::mutate(
      # Add formatted datetime columns for easier reading
      scrape_datetime_aest = format(scrape_time + lubridate::hours(10), "%Y-%m-%d %H:%M:%S"),
      meeting_date = as.Date(mt),
      # FIXED: Use the actual bucket value instead of calculating from current_center_ext
      bucket_rate = bucket  # This preserves the original 25bp-aligned bucket values
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
  
  # Export to CSV using the same format as your PNG files
  csv_filename <- paste0("docs/meetings/csv/area_data_", fmt_file(mt), ".csv")
  
  tryCatch({
    write.csv(df_mt_csv, csv_filename, row.names = FALSE)
    cat("CSV exported:", csv_filename, "\n")
  }, error = function(e) {
    cat("Error exporting CSV for meeting", as.character(mt), ":", e$message, "\n")
  })
}

# Also create a combined CSV with all meetings data - FIXED VERSION
combined_csv <- all_estimates_buckets_ext %>%
  dplyr::filter(as.Date(meeting_date) %in% future_meetings_all) %>%
  dplyr::group_by(meeting_date, scrape_time, move, diff_bps, bucket) %>%  # ADD bucket to group_by
  dplyr::summarise(probability = sum(probability, na.rm = TRUE), .groups = "drop") %>%
  dplyr::arrange(meeting_date, scrape_time, diff_bps) %>%
  dplyr::mutate(
    # Add formatted datetime columns for easier reading
    scrape_datetime_aest = format(scrape_time + lubridate::hours(10), "%Y-%m-%d %H:%M:%S"),
    meeting_date = as.Date(meeting_date),
    # FIXED: Use the actual bucket value instead of calculating from current_center_ext  
    bucket_rate = bucket  # This preserves the original 25bp-aligned bucket values
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

# Verification: Print some sample bucket_rate values to confirm they're on the RBA grid
cat("\nVerification - Sample bucket_rate values:\n")
if (nrow(combined_csv) > 0) {
  sample_rates <- unique(combined_csv$bucket_rate)
  sample_rates <- sort(sample_rates)[1:min(20, length(sample_rates))]
  cat("First 20 unique bucket rates:", paste(sample_rates, collapse = ", "), "\n")
  
  # Check the decimal places
  decimals <- (sample_rates * 100) %% 100
  unique_decimals <- unique(decimals)
  cat("Decimal endings (should be 10, 35, 60, 85):", paste(unique_decimals, collapse = ", "), "\n")
}

cat("CSV export completed with corrected bucket_rate values\n")
  
}
