# =============================================
# Calculate and Interpolate RMSE from Both Data Sources
# =============================================

library(dplyr)
library(tidyr)
library(lubridate)
library(readr)
library(ggplot2)
library(zoo)

# =============================================
# 1. Load Quarterly Forecast Data
# =============================================

quarterly_file <- "combined_data/f17_rmse.csv"

quarterly_data_raw <- read_csv(quarterly_file, col_types = cols())

cat("Quarterly data dimensions:", nrow(quarterly_data_raw), "x", ncol(quarterly_data_raw), "\n")

# Transform from wide to long format
quarterly_data <- quarterly_data_raw %>%
  rename(forecast_date = 1, actual_rate = Actual) %>%
  mutate(forecast_date = dmy(forecast_date)) %>%
  pivot_longer(
    cols = -c(forecast_date, actual_rate),
    names_to = "horizon",
    values_to = "forecast_rate"
  ) %>%
  mutate(
    days_ahead = as.integer(gsub("days", "", horizon))
  ) %>%
  filter(!is.na(forecast_rate), !is.na(actual_rate))

cat("Quarterly forecasts: ", nrow(quarterly_data), "rows\n")
cat("Date range:", min(quarterly_data$forecast_date), "to", max(quarterly_data$forecast_date), "\n")
cat("Horizon range:", min(quarterly_data$days_ahead), "to", max(quarterly_data$days_ahead), "days\n\n")

# =============================================
# 2. Load Daily Forecast Data
# =============================================

cash_rate <- readRDS("combined_data/all_data.Rds")

meeting_schedule <- tibble(
  meeting_date = as.Date(c(
    "2024-02-06", "2024-03-19", "2024-05-07", "2024-06-18",
    "2024-08-06", "2024-09-24", "2024-11-05", "2024-12-10",
    "2025-02-18", "2025-04-01", "2025-05-20", "2025-07-08",
    "2025-08-12", "2025-09-30", "2025-11-04", "2025-12-09"
  ))
) %>% 
  mutate(
    expiry = if_else(
      day(meeting_date) >= days_in_month(meeting_date) - 1,
      ceiling_date(meeting_date, "month"),
      floor_date(meeting_date, "month")
    )
  )

# Load actual RBA cash rate outcomes
library(readrba)
rba_actual <- read_rba(series_id = "FIRMMCRTD") %>%
  arrange(date)

meeting_outcomes <- meeting_schedule %>%
  rowwise() %>%
  mutate(
    actual_rate = {
      outcome_data <- rba_actual %>%
        filter(date > meeting_date) %>%
        slice_min(date, n = 1, with_ties = FALSE)
      if (nrow(outcome_data) > 0) outcome_data$value else NA_real_
    }
  ) %>%
  ungroup() %>%
  filter(!is.na(actual_rate))

# Prepare daily forecasts
daily_forecasts <- cash_rate %>%
  inner_join(meeting_schedule, by = c("date" = "expiry")) %>%
  inner_join(
    meeting_outcomes %>% select(meeting_date, actual_rate),
    by = "meeting_date"
  ) %>%
  mutate(
    forecast_date = as.Date(scrape_time),
    days_ahead = as.integer(meeting_date - forecast_date),
    forecast_rate = cash_rate
  ) %>%
  filter(days_ahead > 0) %>%
  select(forecast_date, meeting_date, days_ahead, forecast_rate, actual_rate)

cat("Daily forecasts:", nrow(daily_forecasts), "rows\n")
cat("Date range:", min(daily_forecasts$forecast_date), "to", max(daily_forecasts$forecast_date), "\n\n")

# =============================================
# 3. Calculate RMSE for Quarterly Forecasts
# =============================================

quarterly_rmse <- quarterly_data %>%
  mutate(
    forecast_error = forecast_rate - actual_rate,
    squared_error = forecast_error^2
  ) %>%
  group_by(days_ahead) %>%
  summarise(
    n_forecasts = n(),
    mean_error = mean(forecast_error, na.rm = TRUE),
    rmse = sqrt(mean(squared_error, na.rm = TRUE)),
    mae = mean(abs(forecast_error), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(days_ahead) %>%
  mutate(source = "quarterly")

cat("=== QUARTERLY RMSE (every ~91 days) ===\n")
print(quarterly_rmse %>% select(days_ahead, n_forecasts, rmse, mae), n = 20)

# =============================================
# 4. Calculate RMSE for Daily Forecasts
# =============================================

daily_rmse <- daily_forecasts %>%
  mutate(
    forecast_error = forecast_rate - actual_rate,
    squared_error = forecast_error^2
  ) %>%
  group_by(days_ahead) %>%
  summarise(
    n_forecasts = n(),
    mean_error = mean(forecast_error, na.rm = TRUE),
    rmse = sqrt(mean(squared_error, na.rm = TRUE)),
    mae = mean(abs(forecast_error), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(days_ahead) %>%
  mutate(source = "daily")

cat("\n=== DAILY RMSE (sample) ===\n")
print(daily_rmse %>% select(days_ahead, n_forecasts, rmse, mae) %>% head(20))

# =============================================
# 5. Combine and Interpolate RMSE
# =============================================

# Combine both RMSE series
combined_rmse <- bind_rows(
  quarterly_rmse %>% select(days_ahead, rmse, n_forecasts, source),
  daily_rmse %>% select(days_ahead, rmse, n_forecasts, source)
)

# Create final RMSE series using priority rules:
# 1. Use quarterly RMSE at quarterly horizons (91, 183, 274, ...)
# 2. Use daily RMSE where available between quarterly points
# 3. Interpolate to fill any gaps

# Identify quarterly anchor points (specific horizons from the data)
quarterly_horizons <- c(91, 183, 274, 365, 456, 548, 639, 730, 821, 913, 1004, 1095, 
                        1186, 1278, 1369, 1460, 1551, 1643, 1734, 1825, 1916, 2008, 
                        2099, 2190, 2281, 2373, 2464, 2555, 2646, 2738, 2829, 2920, 
                        3011, 3103, 3194, 3285, 3376, 3468, 3559, 3650)

# Filter to only anchors that exist in our data
quarterly_horizons <- quarterly_horizons[quarterly_horizons %in% quarterly_rmse$days_ahead]

cat("\nUsing", length(quarterly_horizons), "quarterly anchor points:\n")
cat(paste(head(quarterly_horizons, 12), collapse = ", "), "...\n")

# Get all horizons we need to cover
min_horizon <- min(c(daily_rmse$days_ahead, quarterly_rmse$days_ahead))
max_horizon <- max(quarterly_rmse$days_ahead)  # Use quarterly max as upper bound
all_horizons <- seq(min_horizon, max_horizon, by = 1)

# Create priority-based RMSE values
rmse_priority <- tibble(days_ahead = all_horizons) %>%
  left_join(
    quarterly_rmse %>% 
      filter(days_ahead %in% quarterly_horizons) %>%
      select(days_ahead, rmse_quarterly = rmse),
    by = "days_ahead"
  ) %>%
  left_join(
    daily_rmse %>% select(days_ahead, rmse_daily = rmse),
    by = "days_ahead"
  ) %>%
  mutate(
    # Priority: quarterly at anchor points, daily in between, interpolate gaps
    rmse_base = coalesce(rmse_quarterly, rmse_daily)
  )

# Interpolate remaining gaps using linear interpolation
rmse_priority <- rmse_priority %>%
  mutate(
    rmse_interpolated = na.approx(rmse_base, x = days_ahead, na.rm = FALSE, rule = 2)
  )

# =============================================
# 6. Create Final RMSE Lookup Table
# =============================================

rmse_days <- rmse_priority %>%
  mutate(
    finalrmse = rmse_interpolated,
    # Track which source was used
    source = case_when(
      !is.na(rmse_quarterly) ~ "quarterly_anchor",
      !is.na(rmse_daily) ~ "daily",
      TRUE ~ "interpolated"
    )
  ) %>%
  rename(days_to_meeting = days_ahead) %>%
  select(days_to_meeting, finalrmse, source)

cat("\n=== FINAL RMSE LOOKUP TABLE (sample) ===\n")
cat("Total horizons:", nrow(rmse_days), "\n")
cat("Range:", min(rmse_days$days_to_meeting), "to", max(rmse_days$days_to_meeting), "days\n\n")

# Show samples at key horizons
sample_horizons <- c(1, 7, 14, 30, 60, 91, 120, 183, 274, 365)
print(rmse_days %>% filter(days_to_meeting %in% sample_horizons))

# =============================================
# 7. Save Results
# =============================================

save(rmse_days, file = "combined_data/rmse_days.RData")
cat("\nSaved to: combined_data/rmse_days.RData\n")

write_csv(rmse_days, "combined_data/rmse_days_combined.csv")
cat("Saved to: combined_data/rmse_days_combined.csv\n")

# Save detailed comparison
write_csv(rmse_priority, "combined_data/rmse_detailed_sources.csv")
cat("Saved detailed sources to: combined_data/rmse_detailed_sources.csv\n")

# =============================================
# 8. Visualize RMSE Series
# =============================================

# Prepare plotting data
plot_data <- rmse_priority %>%
  select(days_ahead, rmse_quarterly, rmse_daily, finalrmse = rmse_interpolated) %>%
  pivot_longer(
    cols = -days_ahead,
    names_to = "series",
    values_to = "rmse"
  ) %>%
  filter(!is.na(rmse)) %>%
  mutate(
    series = recode(series,
      "rmse_quarterly" = "Quarterly (anchor points)",
      "rmse_daily" = "Daily",
      "finalrmse" = "Final (combined & interpolated)"
    )
  )

rmse_plot <- ggplot(plot_data, aes(x = days_ahead, y = rmse, color = series)) +
  geom_line(data = plot_data %>% filter(series == "Final (combined & interpolated)"),
            linewidth = 1.2, alpha = 0.8) +
  geom_point(data = plot_data %>% filter(series == "Quarterly (anchor points)"),
             size = 3, alpha = 0.7) +
  geom_point(data = plot_data %>% filter(series == "Daily"),
             size = 1, alpha = 0.4) +
  scale_color_manual(values = c(
    "Quarterly (anchor points)" = "red",
    "Daily" = "steelblue",
    "Final (combined & interpolated)" = "darkgreen"
  )) +
  labs(
    title = "Combined RMSE by Forecast Horizon",
    subtitle = "Quarterly forecasts anchor the series, daily forecasts fill gaps, interpolation smooths",
    x = "Days to Meeting",
    y = "RMSE (percentage points)",
    color = "Data Source"
  ) +
  theme_bw() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 10)
  )

ggsave("combined_data/rmse_combined_interpolated.png",
       plot = rmse_plot, width = 12, height = 7, dpi = 300)

cat("\nSaved plot to: combined_data/rmse_combined_interpolated.png\n")

# =============================================
# 8b. Detailed Sense Check Plot
# =============================================

# Create a more detailed plot showing the interpolation process
sense_check_data <- rmse_priority %>%
  mutate(
    # Mark which values are original vs interpolated
    data_type = case_when(
      !is.na(rmse_quarterly) ~ "Quarterly Anchor",
      !is.na(rmse_daily) ~ "Daily Data",
      TRUE ~ "Interpolated"
    )
  )

sense_check_plot <- ggplot(sense_check_data, aes(x = days_ahead)) +
  # Show the final interpolated line
  geom_line(aes(y = rmse_interpolated), 
            color = "darkgreen", linewidth = 1, alpha = 0.6) +
  # Show quarterly anchor points prominently
  geom_point(data = sense_check_data %>% filter(!is.na(rmse_quarterly)),
             aes(y = rmse_quarterly), 
             color = "red", size = 4, shape = 18) +
  # Show daily data points
  geom_point(data = sense_check_data %>% filter(!is.na(rmse_daily) & is.na(rmse_quarterly)),
             aes(y = rmse_daily), 
             color = "steelblue", size = 2, alpha = 0.6) +
  # Show interpolated points
  geom_point(data = sense_check_data %>% filter(data_type == "Interpolated"),
             aes(y = rmse_interpolated), 
             color = "lightgreen", size = 0.5, alpha = 0.4) +
  # Add vertical lines at quarterly intervals for reference
  geom_vline(xintercept = seq(91, max(sense_check_data$days_ahead), by = 91),
             linetype = "dashed", alpha = 0.2, color = "gray40") +
  labs(
    title = "RMSE Interpolation Sense Check",
    subtitle = paste0(
      "Red diamonds = Quarterly anchors (", 
      sum(!is.na(sense_check_data$rmse_quarterly)), " points) | ",
      "Blue circles = Daily data (", 
      sum(!is.na(sense_check_data$rmse_daily) & is.na(sense_check_data$rmse_quarterly)), " points) | ",
      "Light green = Interpolated (", 
      sum(sense_check_data$data_type == "Interpolated"), " points)"
    ),
    x = "Days to Meeting",
    y = "RMSE (percentage points)"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 9)
  )

ggsave("combined_data/rmse_sense_check.png",
       plot = sense_check_plot, width = 14, height = 7, dpi = 300)

cat("Saved sense check plot to: combined_data/rmse_sense_check.png\n")

# =============================================
# 8c. Zoomed Plot for Short Horizons
# =============================================

# Create a zoomed-in version for first 180 days
zoom_plot <- ggplot(sense_check_data %>% filter(days_ahead <= 180), 
                     aes(x = days_ahead)) +
  geom_line(aes(y = rmse_interpolated), 
            color = "darkgreen", linewidth = 1.2) +
  geom_point(data = sense_check_data %>% 
               filter(days_ahead <= 180, !is.na(rmse_quarterly)),
             aes(y = rmse_quarterly), 
             color = "red", size = 5, shape = 18) +
  geom_point(data = sense_check_data %>% 
               filter(days_ahead <= 180, !is.na(rmse_daily), is.na(rmse_quarterly)),
             aes(y = rmse_daily), 
             color = "steelblue", size = 2.5, alpha = 0.7) +
  geom_vline(xintercept = c(91, 182), 
             linetype = "dashed", alpha = 0.3, color = "red") +
  labs(
    title = "RMSE Interpolation: First 180 Days (Zoomed)",
    subtitle = "Red diamonds = Quarterly | Blue circles = Daily | Green line = Final interpolated",
    x = "Days to Meeting",
    y = "RMSE (percentage points)"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 14)
  )

ggsave("combined_data/rmse_sense_check_zoom.png",
       plot = zoom_plot, width = 12, height = 6, dpi = 300)

cat("Saved zoomed sense check plot to: combined_data/rmse_sense_check_zoom.png\n\n")

# =============================================
# 9. Summary Statistics
# =============================================

cat("\n=== SUMMARY STATISTICS ===\n")
cat("Data source breakdown:\n")
print(rmse_days %>% count(source))

cat("\nRMSE at key horizons:\n")
key_points <- rmse_days %>%
  filter(days_to_meeting %in% c(7, 30, 60, 91, 120, 183, 274, 365)) %>%
  select(days_to_meeting, finalrmse, source)
print(key_points)

cat("\nQuarterly vs Daily comparison at overlapping points:\n")
overlap_comparison <- daily_rmse %>%
  inner_join(
    quarterly_rmse %>% select(days_ahead, rmse_quarterly = rmse),
    by = "days_ahead"
  ) %>%
  mutate(
    difference = rmse - rmse_quarterly,
    pct_difference = (rmse - rmse_quarterly) / rmse_quarterly * 100
  ) %>%
  select(days_ahead, rmse_daily = rmse, rmse_quarterly, difference, pct_difference)

if (nrow(overlap_comparison) > 0) {
  print(head(overlap_comparison, 10))
  cat("\nMean absolute difference:", mean(abs(overlap_comparison$difference)), "\n")
  cat("Mean percentage difference:", mean(abs(overlap_comparison$pct_difference)), "%\n")
} else {
  cat("No overlapping horizons between daily and quarterly data\n")
}
