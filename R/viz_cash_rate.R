suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(lubridate)
  library(ggrepel)
          })

cash_rate <- readRDS(file.path("combined_data", "all_data.Rds"))

viz_1 <- cash_rate |>
  ggplot(aes(x = date, y = cash_rate, col = scrape_date, group = scrape_date)) +
  geom_line() +
  geom_line(data = ~filter(., scrape_date == max(scrape_date)),
            colour = "red",
            linewidth = 1.5) +
  geom_text(data = ~filter(.,
                           scrape_date == max(scrape_date)) |>
              filter(date == max(date)),
            colour = "red",
            hjust = 0,
            lineheight = 0.8,
            aes(label = format(scrape_date, "%e %b\n%Y"))) +
  scale_colour_date(date_labels = "%b '%y") +
  scale_x_date(expand = expansion(c(0, 0.1)),
               date_labels = "%b\n%Y",
               breaks = seq(max(cash_rate$date),
                            min(cash_rate$date),
                            by = "-1 year")) +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  theme_minimal() +
  labs(subtitle = "Expected future cash rate",
       colour = "Expected\nas at:",
       x = "Date") +
  theme(panel.grid.minor = element_blank(),
        axis.title = element_blank())

max_scrape_date <- max(cash_rate$scrape_date)
week_ago <- max_scrape_date - weeks(1)
year_ago <- max_scrape_date - years(1)
month_ago <- max_scrape_date - months(1)
yesterday <- max(cash_rate$scrape_date[cash_rate$scrape_date < max_scrape_date])

viz_2 <- cash_rate |>
  filter(scrape_date %in% c(max_scrape_date,
                            min(scrape_date[scrape_date >= week_ago]),
                            min(scrape_date[scrape_date >= month_ago]),
                            max(scrape_date[scrape_date != max(scrape_date)]))) |>
  distinct() |>
  ggplot(aes(x = date, y = cash_rate,
             col = factor(scrape_date),
             group = scrape_date)) +
  geom_line() +
  geom_text_repel(data = ~group_by(., scrape_date) |>
                    filter(date == max(date)),
                  hjust = 0,
                  nudge_x = 10,
                  min.segment.length = 10000,
                  aes(label = format(scrape_date, "%d %b %Y"))) +
  scale_x_date(expand = expansion(c(0.05, 0.15)),
               date_labels = "%b\n%Y",
               breaks = seq(max(cash_rate$date),
                            min(cash_rate$date),
                            by = "-6 months")) +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  theme_minimal() +
  theme(legend.position = "none") +
  labs(subtitle = "Expected future cash rate",
       x = "Date") +
  theme(panel.grid.minor = element_blank(),
        axis.title = element_blank())

viz_3 <- cash_rate |>
  group_by(scrape_date) |>
  filter(cash_rate == max(cash_rate)) |>
  ggplot(aes(x = scrape_date, y = cash_rate)) +
  geom_line() +
  theme_minimal() +
  scale_x_date(date_labels = "%b\n%Y",
               date_breaks = "3 months") +
  labs(x = "Expected as at",
       subtitle = "Expected peak cash rate") +
  scale_y_continuous(labels = \(x) paste0(x, "%"),
                     breaks = seq(0, 100, 0.25)) +
  theme(panel.grid.minor = element_blank(),
        axis.title = element_blank())


viz_4 <- cash_rate |>
  group_by(scrape_date) |>
  summarise(peak_date = min(date[cash_rate == max(cash_rate)])) |>
  ggplot(aes(x = scrape_date, y = peak_date)) +
  geom_point() +
  geom_smooth(method = "loess",
              formula = y ~ x,
              span = 0.1,
              se = FALSE) +
  theme_minimal() +
  scale_x_date(date_labels = "%b\n%Y",
               date_breaks = "3 months") +
  scale_y_date(date_labels = "%b\n%Y",
               date_breaks = "3 months") +
  labs(x = "Expected as at",
       y = "Expected to peak in") +
  theme(panel.grid.minor = element_blank())

viz_5 <- cash_rate |>
  group_by(scrape_date) |>
  mutate(next_month = floor_date(scrape_date + months(1), "month"),
         current_rate = mean(cash_rate[date == next_month])) |>
  filter(date >= scrape_date) |>
  mutate(diff = cash_rate - current_rate) |>
  filter(diff <= -0.25) |>
  filter(date == min(date)) |>
  ggplot(aes(x = scrape_date,
             y = date)) +
  geom_point() +
  geom_line() +
  scale_x_date("Expected as at",
               limits = ymd("2024-01-01",
                            max(cash_rate$scrape_date)),
               breaks = seq(max(cash_rate$scrape_date),
                            min(cash_rate$scrape_date),
                            by = "-1 months"),
               date_labels = "%d %b\n%Y") +
  scale_y_date("Expected date of first cut",
               date_labels = "%b\n%Y",
               date_breaks = "3 months",
               limits = \(x) ymd("2024-01-01",
                                 x[2])) +
  theme_minimal() +
  labs(subtitle = "Expected date of first rate cut",
       caption = "Refers to the first date at which futures pricing imply a 100% or greater chance of a 25bp cut relative to the then-current rate.")




# ============================
# VIZ 6: BUCKETED RATE PROBABILITIES BY MEETING
# ============================

# Forecast path and RMSE
forecast_df <- cash_rate %>%
  filter(scrape_date == max(scrape_date)) %>%
  select(date, forecast_rate = cash_rate) %>%
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

# Save each chart
for (m in unique(df_long$month_label)) {
  p <- ggplot(filter(df_long, month_label == m),
              aes(x = bucket, y = probability, fill = bucket)) +
    geom_bar(stat = "identity", show.legend = FALSE) +
    labs(
      title = paste("Rate Outcome Probabilities -", m),
      x = "Target Rate Bucket", y = "Probability (%)"
    ) +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))

  ggsave(
    filename = paste0("figures/rate_probabilities_", gsub(" ", "_", m), ".png"),
    plot = p,
    width = 6,
    height = 4,
    dpi = 300
  )
}
