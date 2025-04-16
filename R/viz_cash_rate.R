suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(lubridate)
  library(ggrepel)
  library(tidyr)
          })

cash_rate <- readRDS(file.path("combined_data", "all_data.Rds")) 



spread <- 0.01  # 1bp upward adjustment to all forecast rates

forecast_df <- cash_rate %>%
  filter(scrape_date == max(scrape_date)) %>%
  select(date, forecast_rate_raw = cash_rate) %>%
  mutate(forecast_rate = forecast_rate_raw + spread) %>%
  filter(date >= as.Date("2025-04-01"),
         date <= as.Date("2026-09-01"))

# Inject known RBA meeting dates
meeting_dates <- tibble(
  expiry = as.Date(c(
    "2025-02-01", "2025-03-01", "2025-05-01", "2025-07-01",
    "2025-08-01", "2025-09-01", "2025-11-01", "2025-12-01"
  )),
  meeting_date = as.Date(c(
    "2025-02-17", "2025-03-31", "2025-05-20", "2025-07-08",
    "2025-08-12", "2025-09-30", "2025-11-04", "2025-12-09"
  ))
)

forecast_df <- forecast_df %>%
  left_join(meeting_dates, by = c("date" = "expiry"))

# Iterative cash rate logic
results <- list()
rt <- forecast_df$forecast_rate[1]

for (i in 1:nrow(forecast_df)) {
  row <- forecast_df[i, ]
  dim <- days_in_month(row$date)
  if (!is.na(row$meeting_date)) {
    nb <- (day(row$meeting_date) - 1) / dim
    na <- 1 - nb
    r_tp1 <- (row$forecast_rate - rt * nb) / na
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

# Inject RMSE (manual)
rmse <- c(
  0.045551112, 0.102312111, 0.221970531, 0.327847512, 0.412946769,
  0.468724693, 0.500403217, 0.557833521, 0.649794316, 0.69814153,
  0.778152254, 0.860217121, 0.909074616, 0.997528424, 1.065491777,
  1.131569667, 1.211783477, 1.322739338, 1.359617226
)
df_result$stdev <- rmse[1:nrow(df_result)]

# Bucket edges
bucket_centers <- seq(0.10, 4.60, by = 0.25)
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

# Reshape
df_long <- df_probs %>%
  rename_with(~ gsub("p_", "", .x), starts_with("p_")) %>%
  pivot_longer(cols = -date, names_to = "bucket", values_to = "probability") %>%
  mutate(bucket = paste0(bucket, "%"),
         month_label = format(date, "%b %Y"))

# Filter only meeting months
rba_meeting_dates <- as.Date(c(
  "2025-04-01", "2025-05-20", "2025-07-08", "2025-08-12",
  "2025-09-30", "2025-11-04", "2025-12-09"
))
meeting_months <- floor_date(rba_meeting_dates, "month")

df_long <- df_long %>%
  filter(date %in% meeting_months)
                       
# Keep only future meetings
df_long <- df_long %>%
  filter(date >= Sys.Date(), date %in% meeting_months)

# Clean the figures folder (only rate probability PNGs)
unlink("figures/rate_probabilities_*.png")

# Pull the scrape date for subtitle
scrape_label <- format(max(cash_rate$scrape_date), "%d %b %Y")

# Save one chart per future meeting month
for (m in unique(df_long$month_label)) {
  p <- ggplot(filter(df_long, month_label == m),
              aes(x = bucket, y = probability, fill = bucket)) +
    geom_bar(stat = "identity", show.legend = FALSE) +
    labs(
      title = paste("Rate Outcome Probabilities -", m),
      caption = paste("Based on futures pricing as at", scrape_label),
      x = "Target Rate Bucket",
      y = "Probability (%)"
    ) +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  ggsave(
    filename = paste0("docs/rate_probabilities_", gsub(" ", "_", m), ".png"),
    plot = p,
    width = 6,
    height = 4,
    dpi = 300
  )
}

