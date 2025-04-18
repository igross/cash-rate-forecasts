suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(lubridate)
  library(ggrepel)
  library(tidyr)
  library(scales)
  library(readabs)
  library(readrba)
library(plotly)
})
 

# 1.  Define only the meeting dates
meeting_schedule <- tibble::tibble(
  meeting_date = as.Date(c(
    "2025-02-18", "2025-04-01", "2025-05-20",
    "2025-07-08", "2025-08-12", "2025-09-30",
    "2025-11-04", "2025-12-09"
  ))
)

# 2.  Compute the expiry (first of month) automatically
meeting_schedule <- meeting_schedule %>%
  mutate(
    expiry = floor_date(meeting_date, unit = "month")
  ) %>%
  select(expiry, meeting_date)

# 3.  If you still need a vector of just the upcoming meeting dates:
rba_meeting_dates <- meeting_schedule$meeting_date

# Spread adjustment
spread     <- 0.01  # in percentage points


file.remove(list.files("docs", pattern = "\\.png$", full.names = TRUE))

cash_rate <- readRDS(file.path("combined_data", "all_data.Rds"))

load("combined_data/rmse_days.RData")

current_rate <- read_rba(series_id = "FIRMMCRTD") %>%
    filter(date == max(date)) %>%
    pull(value)




# ============================
# VIZ 6: BUCKETED RATE PROBABILITIES BY MEETING
# ============================

# Forecast path and RMSE
forecast_df <- cash_rate %>%
  filter(scrape_date == max(scrape_date)) %>%
  select(date, forecast_rate = cash_rate) %>%
filter(date >= Sys.Date() %m-% months(1))

scrape_date <- max(cash_rate$scrape_date) 

forecast_df <- forecast_df %>%
  left_join(meeting_schedule, by = c("date" = "expiry"))


forecast_df <- forecast_df %>%
  distinct()

# Iterative cash rate logic
results <- list()
rt <- forecast_df$forecast_rate[1]

for (i in 1:nrow(forecast_df)) {
  row <- forecast_df[i, ]
  dim <- days_in_month(row$date)
  if (!is.na(row$meeting_date)) {
    nb <- (day(row$meeting_date) - 1) / dim
    na <- 1 - nb
    r_tp1 <- ( (row$forecast_rate+spread) - (rt+spread) * nb) / na
  } else {
    nb <- 1
    na <- 0
    r_tp1 <- row$forecast_rate
    rt <- row$forecast_rate
  }

  results[[i]] <- tibble(
    date = row$date,
    meeting_date = row$meeting_date,
    forecast_rate = row$forecast_rate,
    implied_r_tp1 = r_tp1
  )

  if (!is.na(row$meeting_date)) {
    rt <- r_tp1
  }
}

df_result <- bind_rows(results)

# df_result$stdev <- rmse[1:nrow(df_result)]

df_result <- df_result %>%
  mutate(
    days_to_meeting = as.integer(meeting_date - scrape_date)    # difference in calendar days
  ) %>%
  left_join(rmse_days, by = "days_to_meeting") %>%       # brings in the 'rmse' column
  rename(stdev = finalrmse) %>%                               # rename for clarity
  select(date, meeting_date, forecast_rate, implied_r_tp1, stdev)

# Bucket edges
bucket_centers <- seq(0.10, 5.1, by = 0.25)
bucket_edges <- c(bucket_centers - 0.125, tail(bucket_centers, 1) + 0.125)

# Probabilities
bucket_matrix <- sapply(1:(length(bucket_edges) - 1), function(i) {
  pnorm(bucket_edges[i + 1], mean = df_result$implied_r_tp1, sd = df_result$stdev) -
    pnorm(bucket_edges[i], mean = df_result$implied_r_tp1, sd = df_result$stdev)
})
bucket_matrix[bucket_matrix < 0.01] <- 0
bucket_matrix <- apply(bucket_matrix, 1, function(row) row / sum(row)) %>% t()

colnames(bucket_matrix) <- paste0("p_", bucket_centers)
df_probs <- cbind(df_result["date"], round(bucket_matrix * 100, 2))


# 1. compute the raw pnorm‐differences matrix
raw_pm <- sapply(1:(length(bucket_edges)-1), function(i) {
  pnorm(bucket_edges[i+1],
        mean = df_result$implied_r_tp1,
        sd   = df_result$stdev) -
  pnorm(bucket_edges[i],
        mean = df_result$implied_r_tp1,
        sd   = df_result$stdev)
})
# raw_pm is an N×M matrix (N = number of dates, M = number of buckets)

# 2. row‐wise normalise so each row sums exactly to 1
bucket_matrix <- prop.table(raw_pm, margin = 1)

# 3. (optional) drop *very* small probs and renormalise
bucket_matrix[bucket_matrix < 1e-3] <- 0
bucket_matrix <- prop.table(bucket_matrix, margin = 1)

# 4. turn into percentages
bucket_pct <- round(bucket_matrix * 100, 2)


df_probs <- data.frame(
  date = df_result$date,
  bucket_pct,
  check.names = FALSE    # preserve your p_… column names exactly
) %>%
  as_tibble()


                       
# Reshape
df_long <- df_probs %>%
  rename_with(~ gsub("p_", "", .x), starts_with("p_")) %>%
  pivot_longer(cols = -date, names_to = "bucket", values_to = "probability") %>%
  mutate(bucket = paste0(bucket, "%"),
         month_label = format(date, "%b %Y"))

# Filter only meeting months

meeting_months <- floor_date(rba_meeting_dates, "month")

meeting_months <- meeting_months[meeting_months >= floor_date(Sys.Date(), "month")]

df_long <- df_long %>%
  filter(date %in% meeting_months)

latest_scrape <- max(cash_rate$scrape_date)
                       
write.csv(df_result, "combined_data/df_result.csv", row.names = FALSE)
write.csv(df_probs,  "combined_data/df_probs.csv",  row.names = FALSE)
write.csv(df_long,   "combined_data/df_long.csv",   row.names = FALSE)

# plus binary RDS backups if you want to reload them in R exactly
saveRDS(df_result, "combined_data/df_result.rds")
saveRDS(df_probs,  "combined_data/df_probs.rds")
saveRDS(df_long,   "combined_data/df_long.rds")

                       
# Save each chart
for (m in unique(df_long$month_label)) {
  p <- ggplot(filter(df_long, month_label == m),
              aes(x = bucket, y = probability, fill = bucket)) +
    geom_bar(stat = "identity", show.legend = FALSE) +
     labs(
      title = paste("Cash Rate Outcome Probabilities -", m),
      caption = paste("Based on futures-implied rates as of", format(latest_scrape, "%d %B %Y")),
      x = "Target Rate Bucket", y = "Probability (%)"
    ) +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))


tryCatch({

  ggsave(
    filename = paste0("docs/rate_probabilities_", gsub(" ", "_", m), ".png"),
    plot = p,
    width = 6,
    height = 4,
    dpi = 300
  )
  print(m)
}, error = function(e) {
  message("❌ Failed to generate fan chart: ", e$message)
})
}


                       
 # 1. grab the latest scrape date once
scrape_latest <- max(cash_rate$scrape_date)

# 2. select your fan path, compute days_to_meeting, then join in rmse_days
fan_df <- cash_rate %>%
  filter(scrape_date == scrape_latest) %>%
  arrange(date) %>%
  transmute(
    date,
    forecast_rate = cash_rate,
    days_to_meeting = as.integer(date - scrape_latest)
  ) %>%
  left_join(rmse_days, by = "days_to_meeting") %>%   # brings in finalrmse
  mutate(
    stdev    = finalrmse,
    lower_95 = forecast_rate - qnorm(0.975) * stdev,
    upper_95 = forecast_rate + qnorm(0.975) * stdev,
    lower_65 = forecast_rate - qnorm(0.825) * stdev,
    upper_65 = forecast_rate + qnorm(0.825) * stdev
  ) %>%
  select(-days_to_meeting, -finalrmse)

# Plot the fan chart
viz_fan <- ggplot(fan_df, aes(x = date)) +
  geom_ribbon(aes(ymin = lower_95, ymax = upper_95), fill = "#a6cee3", alpha = 0.5) +  # 95% band — light blue
  geom_ribbon(aes(ymin = lower_65, ymax = upper_65), fill = "#1f78b4", alpha = 0.6) +  # 65% band — stronger blue
  geom_line(aes(y = forecast_rate), color = "#e31a1c", size = 1.2) +  # Mean path — bold red
   scale_y_continuous(labels = label_percent(scale = 1), limits = c(0, NA)) +
  scale_x_date(date_labels = "%b\n%Y", date_breaks = "3 months") +
  theme_bw() +
  labs(
    title = "Mean Path of Cash Rate with Uncertainty Bands",
    caption = paste("Shaded areas represent 65% and 95% confidence interval using historical forecast errors. Futures-implied path as of", format(max(cash_rate$scrape_date), "%d %B %Y")),
    x = NULL, y = NULL
  ) +
  theme(panel.grid.minor = element_blank())

ggsave("docs/rate_fan_chart.png", plot = viz_fan, width = 8, height = 5, dpi = 300)


# ────────────────────────────────────────────────────────────────────────────────
# 2.  Identify the last and next meetings ---------------------------------------
today <- Sys.Date()  
last_meeting     <- max(meeting_schedule$meeting_date[meeting_schedule$meeting_date <= today])
next_meeting_row <- meeting_schedule %>% filter(meeting_date >  today) %>% slice_min(meeting_date)

last_expiry      <- meeting_schedule$expiry [meeting_schedule$meeting_date == last_meeting]
next_expiry      <- next_meeting_row$expiry
current_expiry <- next_meeting_row$expiry %m-% months(1)   # exactly 1 month earlier
next_meeting     <- next_meeting_row$meeting_date      # scalar date

# ────────────────────────────────────────────────────────────────────────────────
# 3.  Bring in every scrape since the last meeting, but only the months           #
#     we need (from the month *after* the last meeting up to the next expiry).    #
forecast_df <- cash_rate %>%
  filter(
    scrape_date  >  last_meeting+1,         # all scrapes since the last decision
    date         >= last_expiry,          # start at the month that covers it
    date         <= next_expiry           # stop at the month of the next meeting
  ) %>%
   arrange(scrape_date, date)  %>% 
  distinct()                  

unique_scrapes <- sort(unique(forecast_df$scrape_date))
results        <- vector("list", length(unique_scrapes))

results <- tibble(
  scrape_date       = as.Date(character()),
  current_expiry    = as.Date(character()),
  next_expiry       = as.Date(character()),
  cash_rate_current = numeric(),
  cash_rate_next    = numeric(),
  implied_r_tp1     = numeric()
)

for (j in seq_along(unique_scrapes)) {
  df_scr <- filter(forecast_df, scrape_date == unique_scrapes[j])
  
  row_next    <- filter(df_scr, date == next_expiry)
  row_current <- filter(df_scr, date == current_expiry)
  if (nrow(row_next) == 0 || nrow(row_current) == 0) next  # skip incomplete scrape
  
  dim <- days_in_month(next_meeting)
  nb  <- (day(next_meeting) - 1) / dim
  na  <- 1 - nb
  
  r_tp1 <- ((row_next$cash_rate+spread ) -
              (row_current$cash_rate+spread ) * nb) / na
  
  results <- add_row(
    results,
    scrape_date       = unique_scrapes[j],
    current_expiry    = current_expiry,
    next_expiry       = next_expiry,
    cash_rate_current = row_current$cash_rate,
    cash_rate_next    = row_next$cash_rate,
    implied_r_tp1     = r_tp1
  )
}



results <- results %>%
  # 1) compute the days-to-meeting
  mutate(days_to_meeting = as.integer(next_meeting - scrape_date)) %>%
  
  # 2) join on your rmse_days lookup
  left_join(rmse_days, by = "days_to_meeting") %>%
  
  # 3) rename the joined column
  rename(RMSE = finalrmse) %>%
  
  # 4) (optional) drop the helper column
  select(-days_to_meeting)

## ── 1.  Bucket definition ------------------------------------------------------
bucket_centers <- seq(0.10, 5.1, by = 0.25)
bucket_edges   <- c(bucket_centers - 0.125,
                    tail(bucket_centers, 1) + 0.125)
nbuckets <- length(bucket_centers)

## ── 2.  Outer loop over each row in `results` ----------------------------------
bucket_list <- vector("list", nrow(results))   # pre‑allocate

for (j in seq_len(nrow(results))) {
  mu    <- results$implied_r_tp1[j]
  sigma <- results$RMSE[j]
  
  # Skip if either is NA or sigma == 0
  if (is.na(mu) || is.na(sigma) || sigma == 0) next
  
  probs <- numeric(nbuckets)
  
  for (k in seq_len(nbuckets)) {
    lower <- bucket_edges[k]
    upper <- bucket_edges[k + 1]
    probs[k] <- pnorm(upper, mean = mu, sd = sigma) -
      pnorm(lower, mean = mu, sd = sigma)
  }
  
  # Normalise just in case of tiny numerical drift
  probs <- probs / sum(probs)
  
  bucket_list[[j]] <- tibble(
    scrape_date = results$scrape_date[j],
    bucket      = sprintf("%.2f%%", bucket_centers),
    probability = probs
  )
}

## ── 3.  Bind into one tidy frame ----------------------------------------------
bucket_probs <- bind_rows(bucket_list)

print(bucket_probs, n = 30)        # show first 30 rows

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(ggplot2)
})

## ── 1. Bucket definition relative to the current rate -------------------------
bucket_def <- tibble(
  label = factor(c("-50 bp cut", "-25 bp cut", "No change",
                   "+25 bp hike", "+50 bp hike"),
                 levels = c("-50 bp cut", "-25 bp cut", "No change",
                            "+25 bp hike", "+50 bp hike")),
  shift = c(-0.50, -0.25, 0.00, +0.25, +0.50)   # shift in % pts (== 50/25 bp)
)
half_width <- 0.125                             # ±12.5 bp around each centre


## ── 2. Compute bucket probabilities for every scrape (plain loops) ------------
prob_rows <- vector("list", nrow(results))

for (j in seq_len(nrow(results))) {
  mu     <- results$implied_r_tp1[j]
  sigma  <- results$RMSE[j]
  r_curr <- results$cash_rate_current[j]
  
  # skip if NA or sigma == 0
  if (is.na(mu) || is.na(sigma) || sigma == 0) next
  
  probs <- numeric(nrow(bucket_def))
  
  for (k in seq_len(nrow(bucket_def))) {
    lower <- r_curr + bucket_def$shift[k] - half_width
    upper <- r_curr + bucket_def$shift[k] + half_width
    probs[k] <- pnorm(upper, mean = mu, sd = sigma) -
      pnorm(lower, mean = mu, sd = sigma)
  }
  
  prob_rows[[j]] <- tibble(
    scrape_date = results$scrape_date[j],
    bucket      = bucket_def$label,
    probability = probs / sum(probs)          # renormalise, tiny numerical drift
  )
}

bucket_probs <- bind_rows(prob_rows)


## ── 3. Keep the *top‑4* buckets per scrape ------------------------------------
top3_norm <- bucket_probs %>%
  group_by(scrape_date) %>%
  slice_max(order_by = probability, n = 3, with_ties = FALSE) %>%
  # re‐normalise so they sum to 1
  mutate(
    probability = probability / sum(probability),
    pct         = probability * 100  # if you want 0–100%
  ) %>%
  ungroup()



## ── 4. Stacked‑bar plot -------------------------------------------------------
stacked<-ggplot(top3_norm, aes(x = scrape_date, y = probability, fill = bucket)) +
  geom_col(width = 0.9) +
  scale_y_continuous(labels = scales::percent) +
  labs(title = "Top‑4 policy‑move buckets per scrape date",
       x = "Scrape date",
       y = "Probability (stacked to 100 %)",
       fill = "Meeting‑day move") +
  theme_bw() +
  theme(legend.position = "right")

ggsave("docs/stacked.png", plot = stacked, width = 8, height = 5, dpi = 300)

line<-ggplot(top3_norm,
       aes(x = scrape_date,
           y = probability,
           colour = bucket,
           group  = bucket)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  scale_colour_manual(
    values = c(
      "-50 bp cut" = "#004B8E",  # deepest blue  (largest cut)
      "-25 bp cut" = "#5FA4D4",  # lighter blue  (half‑size cut)
      "No change"  = "#BFBFBF",  # neutral grey
      "+25 bp hike"= "#E07C7C",  # lighter red   (half‑size hike)
      "+50 bp hike"= "#B50000"   # deepest red   (largest hike)
    )
  ) +
  scale_y_continuous(labels = scales::percent) +
  labs(  title  = paste0("Cash Rate probabilities for the next RBA meeting"),
       x      = "Forecast date",
       y      = "Probability",
       colour = "Meeting‑day move") +
  theme_bw() +
  theme(legend.position = "right")
  
ggsave("docs/line.png", plot = line, width = 8, height = 5, dpi = 300)


                       # 1. add a `text` aesthetic for custom hover info
line_int <- line +
  aes(text = paste0(
    "Date: ", format(scrape_date, "%Y-%m-%d"),
    "<br>Move: ", bucket,
    "<br>Probability: ", scales::percent(probability, accuracy = 0.1)
  ))

# 2. convert to a plotly htmlwidget
library(plotly)
interactive_line <- ggplotly(line_int, tooltip = "text") %>%
  layout(
    hovermode = "x unified",
    legend = list(x = 1.02, y = 1)
  )

# 3. save it as a self‑contained HTML (to embed via iframe or link on your site)
htmlwidgets::saveWidget(
  interactive_line,
  "docs/line_interactive.html",
  selfcontained = TRUE
)


