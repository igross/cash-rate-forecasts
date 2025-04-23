#!/usr/bin/env Rscript

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

blend_weight <- function(h, k = 3) h / (h + k)

# =============================================
# 3) Define RBA meeting schedule
# =============================================
meeting_schedule <- tibble(
  meeting_date = as.Date(c(
    "2025-02-18","2025-04-01","2025-05-20","2025-07-08",
    "2025-08-12","2025-09-30","2025-11-04","2025-12-09"
  ))
) %>%
  mutate(expiry = floor_date(meeting_date, "month")) %>%
  select(expiry, meeting_date)

# =============================================
# 4) Identify last meeting, collect scrapes
# =============================================
last_meeting <- max(meeting_schedule$meeting_date[meeting_schedule$meeting_date <= Sys.Date()])

all_times <- sort(unique(cash_rate$scrape_time))
scrapes   <- all_times[all_times > last_meeting]   # every scrape after the last decision

# =============================================
# 5) Build implied‐mean panel for each scrape × meeting
# =============================================
all_list <- map(scrapes, function(scr) {
  scr_date <- as.Date(scr)  # convert POSIXct to Date

  df <- cash_rate %>%
    filter(scrape_time == scr) %>%
    select(date, forecast_rate = cash_rate) %>%
    filter(date >= min(meeting_schedule$expiry),
           date <= max(meeting_schedule$expiry)) %>%
    left_join(meeting_schedule, by = c("date" = "expiry")) %>%
    distinct() %>% 
    arrange(date)

  rt  <- df$forecast_rate[1]
  out <- vector("list", nrow(df))

  for (i in seq_len(nrow(df))) {
    row <- df[i, ]
    dim <- days_in_month(row$date)

    if (!is.na(row$meeting_date)) {
      nb    <- (day(row$meeting_date) - 1) / dim
      na    <- 1 - nb
      r_tp1 <- (row$forecast_rate - rt * nb) / na
    } else {
      r_tp1 <- row$forecast_rate
    }

    out[[i]] <- tibble(
      scrape_time     = scr,
      meeting_date    = row$meeting_date,
      implied_mean    = r_tp1,
      days_to_meeting = as.integer(row$meeting_date - scr_date)
    )

    if (!is.na(row$meeting_date)) rt <- r_tp1
  }

  bind_rows(out)
})

all_estimates <- bind_rows(all_list) %>%
  filter(!is.na(meeting_date)) %>%
  left_join(rmse_days, by = "days_to_meeting") %>%
  rename(stdev = finalrmse)

# =============================================
# 6) Build bucketed probabilities for each row
# =============================================
bucket_centers <- seq(0.10, 5.10, by = 0.25)
half_width     <- 0.125

current_rate <- read_rba(series_id = "FIRMMCRTD") %>%
  filter(date == max(date)) %>%
  pull(value)

current_center <- bucket_centers[ which.min( abs(bucket_centers - current_rate) ) ]

bucket_list <- vector("list", nrow(all_estimates))
for (i in seq_len(nrow(all_estimates))) {
  mu_i    <- all_estimates$implied_mean[i]
  sigma_i <- all_estimates$stdev[i]
  h_i     <- all_estimates$days_to_meeting[i] / 30  # convert to months approx.
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

  # Blend
  w <- blend_weight(h_i)
  v <- w * p_vec + (1 - w) * l_vec

  bucket_list[[i]] <- tibble(
    scrape_time = all_estimates$scrape_time[i],
    meeting_date= all_estimates$meeting_date[i],
    implied_mean= mu_i,
    stdev       = sigma_i,
    bucket      = bucket_centers,
    probability = v, 
    diff       = bucket_centers - current_rate,
    diff_s     = sign(bucket_centers - current_rate) * abs(bucket_centers - current_rate)^(1/4)
  )
}

all_estimates_buckets <- bind_rows(bucket_list)

print(all_estimates_buckets, n=20, width = Inf)

# =============================================
# (Rest of code continues unchanged)
