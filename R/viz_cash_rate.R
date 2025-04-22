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

current_rate <- read_rba(series_id = "FIRMMCRTD") %>%
  filter(date == max(date)) %>%
  pull(value)

bucket_list <- vector("list", nrow(all_estimates))
for (i in seq_len(nrow(all_estimates))) {
  mu_i    <- all_estimates$implied_mean[i]
  sigma_i <- all_estimates$stdev[i]
  rc      <- current_rate  

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

  # b) build file name
  label   <- format(mt, "%b_%Y")
  out_png <- file.path("docs", paste0("rate_probabilities_", label, ".png"))

  # c) ensure old file is removed
  if (file.exists(out_png)) unlink(out_png)

  # d) create the bar chart
  p <- ggplot(bar_df, aes(factor(bucket), probability, fill = bucket)) +
    geom_col(show.legend = FALSE) +
    scale_y_continuous(labels = scales::label_percent(scale = 1)) +
    labs(
      title    = paste("Cash Rate Outcome Probabilities —", format(mt, "%d %B %Y")),
      subtitle = paste("As of", format(latest_scrape, "%d %B %Y")),
      x        = "Target Rate (%)",
      y        = "Probability (%)"
    ) +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  # e) save (overwriting if it exists)
  ggsave(
    filename = out_png,
    plot     = p,
    width    = 6,
    height   = 4,
    dpi      = 300,
    device   = "png"
  )
}

# =============================================
# Line chart: top‑3 bucket probabilities over time (latest series)
# =============================================

# 1) we already have `next_meeting` and `all_estimates_buckets` from above

# 2) build a data frame of only that meeting + its top‑3 buckets per scrape
top3_df <- all_estimates_buckets %>%
  filter(meeting_date == next_meeting) %>%      # only the next meeting
  group_by(scrape_time) %>%                     # for each scrape timestamp
  slice_max(order_by = probability, 
            n = 3, 
            with_ties = FALSE) %>%              # keep the 3 largest probs
  ungroup()

# 3) define a palette for the 3 buckets (will vary scrape‑to‑scrape)
#    or just let ggplot pick colours automatically
my_cols_top3 <- RColorBrewer::brewer.pal(3, "Dark2")

# 4) plot only those top 3 lines
line_top3 <- ggplot(top3_df, aes(
    x     = as.Date(scrape_time),
    y     = probability,
    color = bucket,            # bucket is numeric centre (e.g. 0.25, 0.50)
    group = bucket
  )) +
  geom_line(size = 1.2) +
  scale_colour_manual(
    values = my_cols_top3,
    name   = "Top 3 Buckets"
  ) +
  scale_y_continuous(labels = scales::label_percent(scale = 1)) +
  labs(
    title    = paste("Top 3 Cash‑Rate Move Probabilities — Next Meeting", 
                     format(next_meeting, "%d %b %Y")),
    subtitle = paste("Each line is one of the three most likely outcomes as of", 
                     format(latest_scrape, "%d %b %Y")),
    x        = "Forecast timestamp",
    y        = "Probability"
  ) +
  theme_bw() +
  theme(
    axis.text.x          = element_text(angle = 45, hjust = 1),
    legend.position      = c(1.02, 0.5),
    legend.justification = c("left","center")
  )

# 5) write out (overwrite if exists)
out_line <- file.path("docs", "line_top3.png")
if (file.exists(out_line)) unlink(out_line)
ggsave(
  filename = out_line,
  plot     = line_top3,
  width    = 8,
  height   = 5,
  dpi      = 300,
  device   = "png"
)

# 6) Optional: interactive version
line_int_top3 <- line_top3 +
  aes(text = paste0(
    format(scales::percent(probability, accuracy = 1)
  ))

interactive_top3 <- ggplotly(line_int_top3, tooltip = "text") %>%
  layout(
    hovermode = "x unified",
    legend    = list(x = 1.02, y = 0.5, xanchor = "left")
  )

htmlwidgets::saveWidget(
  interactive_top3,
  "docs/line_interactive_top3.html",
  selfcontained = TRUE
)
