# =============================================
# Calculate and Interpolate RMSE from Both Data Sources
# Using Spline Smoothing for Final Output
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
  filter(!is.na(forecast_rate), !is.na(actual_rate), !is.na(days_ahead))

cat("Quarterly forecasts: ", nrow(quarterly_data), "rows\n")
cat("Date range:", format(min(quarterly_data$forecast_date), "%Y-%m-%d"), "to", 
    format(max(quarterly_data$forecast_date), "%Y-%m-%d"), "\n")
cat("Horizon range:", min(quarterly_data$days_ahead, na.rm = TRUE), "to", 
    max(quarterly_data$days_ahead, na.rm = TRUE), "days\n\n")

# =============================================
# 2. Load Daily Forecast Data
# =============================================

cash_rate <- readRDS("combined_data/all_data.Rds")

# Fix timezone: convert from UTC to Australia/Melbourne
cash_rate <- cash_rate %>%
  mutate(
    scrape_time = with_tz(scrape_time, "Australia/Melbourne")
  )

cat("Updated scrape_time timezone to:", attr(cash_rate$scrape_time, "tzone"), "\n")

# Meeting schedule
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
    forecast_rate = cash_rate,
    day_of_week = lubridate::wday(forecast_date, week_start = 1)
  ) %>%
  # Remove weekends (Saturday = 6, Sunday = 7)
  filter(day_of_week %in% 1:5) %>%
  # Keep only one forecast per day per meeting
  arrange(meeting_date, forecast_date, desc(scrape_time)) %>%
  group_by(meeting_date, forecast_date) %>%
  slice(1) %>%
  ungroup() %>%
  filter(days_ahead > 0) %>%
  select(forecast_date, meeting_date, days_ahead, forecast_rate, actual_rate)

cat("\n=== DAILY FORECASTS (CLEANED) ===\n")
cat("Total rows:", nrow(daily_forecasts), "\n")
cat("Date range:", format(min(daily_forecasts$forecast_date), "%Y-%m-%d"), "to", 
    format(max(daily_forecasts$forecast_date), "%Y-%m-%d"), "\n\n")

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
    rmse = sqrt(mean(squared_error, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  arrange(days_ahead) %>%
  mutate(source = "quarterly")

cat("=== QUARTERLY RMSE ===\n")
print(quarterly_rmse %>% select(days_ahead, n_forecasts, rmse), n = 20)

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
    rmse = sqrt(mean(squared_error, na.rm = TRUE)),
    .groups = "drop"
  ) %>%
  arrange(days_ahead) %>%
  mutate(source = "daily")

cat("\n=== DAILY RMSE (sample) ===\n")
print(daily_rmse %>% select(days_ahead, n_forecasts, rmse) %>% head(20))

# =============================================
# 5. Create Three Smoothed Versions
# =============================================

cat("\n=== CREATING THREE SMOOTHED RMSE SERIES ===\n")

# Get all horizons we need to cover
min_horizon <- 1
max_horizon <- max(quarterly_rmse$days_ahead)
all_horizons <- seq(min_horizon, max_horizon, by = 1)

# Quarterly horizons (anchor points)
quarterly_horizons <- c(91, 183, 274, 365, 456, 548, 639, 730, 821, 913, 1004, 1095, 
                        1186, 1278, 1369, 1460, 1551, 1643, 1734, 1825, 1916, 2008, 
                        2099, 2190, 2281, 2373, 2464, 2555, 2646, 2738, 2829, 2920, 
                        3011, 3103, 3194, 3285, 3376, 3468, 3559, 3650)
quarterly_horizons <- quarterly_horizons[quarterly_horizons %in% quarterly_rmse$days_ahead]

# Base data for all three methods
rmse_base <- tibble(days_ahead = all_horizons) %>%
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
    rmse_combined = coalesce(rmse_quarterly, rmse_daily)
  )

# METHOD 1: Linear Interpolation
cat("\n1. Linear Interpolation...\n")
rmse_linear <- rmse_base %>%
  mutate(
    rmse_linear = na.approx(rmse_combined, x = days_ahead, na.rm = FALSE, rule = 2)
  )

# METHOD 2: LOESS Smoothing (span = 0.3)
cat("2. LOESS Smoothing (span = 0.3)...\n")
# Get non-NA data for LOESS
loess_data <- rmse_base %>%
  filter(!is.na(rmse_combined))

loess_model <- loess(rmse_combined ~ days_ahead, data = loess_data, span = 0.3)
rmse_loess <- rmse_base %>%
  mutate(
    rmse_loess = predict(loess_model, newdata = data.frame(days_ahead = days_ahead))
  )

# METHOD 3: Natural Cubic Spline (RECOMMENDED)
cat("3. Natural Cubic Spline...\n")
# Get non-NA data for spline
spline_data <- rmse_base %>%
  filter(!is.na(rmse_combined))

# Fit natural cubic spline with appropriate degrees of freedom
# Using df based on data complexity (roughly 1 df per 100 days)
df_spline <- min(round(nrow(spline_data) / 100), 20)
cat("   Using", df_spline, "degrees of freedom\n")

spline_model <- smooth.spline(
  x = spline_data$days_ahead,
  y = spline_data$rmse_combined,
  df = df_spline
)

rmse_spline <- rmse_base %>%
  mutate(
    rmse_spline = predict(spline_model, x = days_ahead)$y
  )

# Combine all three methods
rmse_all_methods <- rmse_linear %>%
  left_join(
    rmse_loess %>% select(days_ahead, rmse_loess),
    by = "days_ahead"
  ) %>%
  left_join(
    rmse_spline %>% select(days_ahead, rmse_spline),
    by = "days_ahead"
  )

# =============================================
# 6. Create Final Output (Spline Method)
# =============================================

cat("\n=== CREATING FINAL OUTPUT (SPLINE METHOD) ===\n")

rmse_days <- rmse_spline %>%
  select(days_to_meeting = days_ahead, finalrmse = rmse_spline)

cat("Total horizons:", nrow(rmse_days), "\n")
cat("Range:", min(rmse_days$days_to_meeting), "to", max(rmse_days$days_to_meeting), "days\n\n")

cat("Sample of final output:\n")
print(head(rmse_days, 10))

# =============================================
# 7. Save Final Output
# =============================================

save(rmse_days, file = "combined_data/rmse_new.RData")
cat("\n✓ Saved final output to: combined_data/rmse_new.RData\n")

# Also save as CSV for reference
write_csv(rmse_days, "combined_data/rmse_new.csv")
cat("✓ Saved CSV to: combined_data/rmse_new.csv\n")

# =============================================
# 8. Comparison Visualization (All 3 Methods)
# =============================================

cat("\n=== CREATING COMPARISON PLOTS ===\n")

# Plot 1: All three methods overlaid
comparison_data <- rmse_all_methods %>%
  select(days_ahead, rmse_linear, rmse_loess, rmse_spline) %>%
  pivot_longer(
    cols = -days_ahead,
    names_to = "method",
    values_to = "rmse"
  ) %>%
  filter(!is.na(rmse)) %>%
  mutate(
    method = recode(method,
      "rmse_linear" = "Linear Interpolation",
      "rmse_loess" = "LOESS (span=0.3)",
      "rmse_spline" = "Natural Cubic Spline"
    )
  )

# Add original data points
original_data <- rmse_base %>%
  filter(!is.na(rmse_quarterly) | !is.na(rmse_daily)) %>%
  mutate(
    point_type = case_when(
      !is.na(rmse_quarterly) ~ "Quarterly Anchor",
      !is.na(rmse_daily) ~ "Daily Data",
      TRUE ~ "Other"
    )
  )

comparison_plot <- ggplot() +
  # Smoothed lines
  geom_line(data = comparison_data, 
            aes(x = days_ahead, y = rmse, color = method, linetype = method),
            linewidth = 1) +
  # Original data points
  geom_point(data = original_data %>% filter(point_type == "Quarterly Anchor"),
             aes(x = days_ahead, y = rmse_quarterly),
             color = "red", size = 3, shape = 18, alpha = 0.7) +
  geom_point(data = original_data %>% filter(point_type == "Daily Data"),
             aes(x = days_ahead, y = rmse_daily),
             color = "gray30", size = 1, alpha = 0.3) +
  scale_color_manual(values = c(
    "Linear Interpolation" = "#e41a1c",
    "LOESS (span=0.3)" = "#377eb8",
    "Natural Cubic Spline" = "#4daf4a"
  )) +
  scale_linetype_manual(values = c(
    "Linear Interpolation" = "dashed",
    "LOESS (span=0.3)" = "dotted",
    "Natural Cubic Spline" = "solid"
  )) +
  labs(
    title = "RMSE Smoothing Methods Comparison",
    subtitle = "Red diamonds = Quarterly anchors | Gray dots = Daily data | Final output uses Spline",
    x = "Days to Meeting",
    y = "RMSE (percentage points)",
    color = "Smoothing Method",
    linetype = "Smoothing Method"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom",
    legend.direction = "vertical"
  )

ggsave("combined_data/rmse_methods_comparison.png",
       plot = comparison_plot, width = 12, height = 8, dpi = 300)
cat("✓ Saved: combined_data/rmse_methods_comparison.png\n")

# Plot 2: Zoomed comparison (first 180 days)
zoom_plot <- ggplot() +
  geom_line(data = comparison_data %>% filter(days_ahead <= 180), 
            aes(x = days_ahead, y = rmse, color = method, linetype = method),
            linewidth = 1.2) +
  geom_point(data = original_data %>% 
               filter(days_ahead <= 180, point_type == "Quarterly Anchor"),
             aes(x = days_ahead, y = rmse_quarterly),
             color = "red", size = 4, shape = 18) +
  geom_point(data = original_data %>% 
               filter(days_ahead <= 180, point_type == "Daily Data"),
             aes(x = days_ahead, y = rmse_daily),
             color = "gray30", size = 1.5, alpha = 0.5) +
  scale_color_manual(values = c(
    "Linear Interpolation" = "#e41a1c",
    "LOESS (span=0.3)" = "#377eb8",
    "Natural Cubic Spline" = "#4daf4a"
  )) +
  scale_linetype_manual(values = c(
    "Linear Interpolation" = "dashed",
    "LOESS (span=0.3)" = "dotted",
    "Natural Cubic Spline" = "solid"
  )) +
  labs(
    title = "RMSE Smoothing Methods: First 180 Days (Zoomed)",
    subtitle = "Comparing linear, LOESS, and spline approaches",
    x = "Days to Meeting",
    y = "RMSE (percentage points)",
    color = "Smoothing Method",
    linetype = "Smoothing Method"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    legend.position = "bottom"
  )

ggsave("combined_data/rmse_methods_comparison_zoom.png",
       plot = zoom_plot, width = 12, height = 7, dpi = 300)
cat("✓ Saved: combined_data/rmse_methods_comparison_zoom.png\n")

# Plot 3: Final spline output with confidence
final_plot <- ggplot() +
  geom_line(data = rmse_days, 
            aes(x = days_to_meeting, y = finalrmse),
            color = "#4daf4a", linewidth = 1.5) +
  geom_point(data = original_data %>% filter(point_type == "Quarterly Anchor"),
             aes(x = days_ahead, y = rmse_quarterly),
             color = "red", size = 4, shape = 18, alpha = 0.8) +
  geom_point(data = original_data %>% filter(point_type == "Daily Data"),
             aes(x = days_ahead, y = rmse_daily),
             color = "gray30", size = 1, alpha = 0.3) +
  labs(
    title = "Final RMSE by Forecast Horizon (Natural Cubic Spline)",
    subtitle = "This is the rmse_new.RData output | Red diamonds = Quarterly anchors | Gray = Daily data",
    x = "Days to Meeting",
    y = "RMSE (percentage points)"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 14)
  )

ggsave("combined_data/rmse_final_spline.png",
       plot = final_plot, width = 12, height = 7, dpi = 300)
cat("✓ Saved: combined_data/rmse_final_spline.png\n")

# =============================================
# 9. Summary Statistics
# =============================================

cat("\n=== SUMMARY STATISTICS ===\n")
cat("Final output format (head):\n")
print(head(rmse_days))

cat("\nRMSE at key horizons:\n")
key_points <- rmse_days %>%
  filter(days_to_meeting %in% c(1, 7, 14, 30, 60, 91, 120, 183, 274, 365))
print(key_points)

cat("\n=== COMPLETE ===\n")
cat("✓ rmse_new.RData saved with", nrow(rmse_days), "rows\n")
cat("✓ Format: days_to_meeting, finalrmse\n")
cat("✓ Method: Natural Cubic Spline with", df_spline, "degrees of freedom\n")
