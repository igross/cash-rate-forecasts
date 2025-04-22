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

bucket_list <- vector("list", nrow(all_estimates))
for (i in seq_len(nrow(all_estimates))) {
  mu_i    <- all_estimates$implied_mean[i]
  sigma_i <- all_estimates$stdev[i]
  rc      <- read_rba(series_id = "FIRMMCRTD") %>%
               filter(date == max(date)) %>% pull(value)  # or use cached

  # raw pnorm diffs
  v <- numeric(length(bucket_centers))
  for (k in seq_along(bucket_centers)) {
    lower <- bucket_centers[k] - half_width
    upper <- bucket_centers[k] + half_width
    v[k] <- pnorm(upper, mean = mu_i, sd = sigma_i) -
            pnorm(lower, mean = mu_i, sd = sigma_i)
  }

  v[v < 0]    <- 0
  v[v < 0.01] <- 0
  v           <- v / sum(v)

  bucket_list[[i]] <- tibble(
    scrape_time = all_estimates$scrape_time[i],
    meeting_date= all_estimates$meeting_date[i],
    implied_mean= mu_i,
    stdev       = sigma_i,
    bucket      = bucket_centers,
    probability = v
  )
}

all_estimates_buckets <- bind_rows(bucket_list)

# =============================================
# 7) Bar chart for the next meeting at latest scrape
# =============================================
next_meeting   <- sort(unique(all_estimates_buckets$meeting_date)) %>% keep(~ .x > Sys.Date()) %>% first()
latest_scrape  <- max(all_estimates_buckets$scrape_time)

bar_df <- all_estimates_buckets %>%
  filter(scrape_time == latest_scrape, meeting_date == next_meeting)

ggplot(bar_df, aes(factor(bucket), probability, fill = bucket)) +
  geom_col(show.legend = FALSE) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(
    title    = paste("Cash Rate Outcome Probabilities —", format(next_meeting, "%d %B %Y")),
    subtitle = paste("as of", format(latest_scrape, "%d %B %Y")),
    x        = "Target Rate (%)",
    y        = "Probability (%)"
  ) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("docs/rate_probabilities_next.png", width = 6, height = 4, dpi = 300)

# =============================================
# 8) Line chart: bucket probabilities over time
# =============================================
line_df <- all_estimates_buckets %>%
  filter(meeting_date == next_meeting)

my_cols <- setNames(
  c("#004B8E", "#5FA4D4", "#BFBFBF", "#E07C7C", "#B50000"),
  as.character(bucket_centers)
)

line <- ggplot(line_df, aes(as.Date(scrape_time), probability, color = factor(bucket), group = factor(bucket))) +
  geom_line(size = 1) +
  scale_color_manual(values = my_cols) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(
    title    = paste("Evolution of Move Probabilities — Next meeting", format(next_meeting, "%d %b %Y")),
    x        = "Forecast timestamp",
    y        = "Probability",
    color    = "Bucket (%)"
  ) +
  theme_bw() +
  theme(
    axis.text.x         = element_text(angle = 45, hjust = 1),
    legend.position     = c(1.02, 0.5),
    legend.justification= c("left", "center")
  )

ggsave("docs/line.png", plot = line, width = 8, height = 5, dpi = 300)

# Interactive version
line_int <- line + aes(text = paste0(
  format(scrape_time, "%Y-%m-%d %H:%M"),
  "<br>Bucket: ", bucket, 
  "<br>Prob: ", scales::percent(probability, scale = 1)
))

interactive_line <- ggplotly(line_int, tooltip = "text") %>%
  layout(
    hovermode = "x unified",
    legend    = list(x = 1.02, y = 0.5, xanchor = "left")
  )

htmlwidgets::saveWidget(
  interactive_line,
  "docs/line_interactive.html",
  selfcontained = TRUE
)

