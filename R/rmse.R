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

cat("\n=== CALCULATING DAILY-QUARTERLY ADJUSTMENT RATIO ===\n")

# Find overlapping horizons where we have both daily and quarterly data
overlap_data <- daily_rmse %>%
  inner_join(
    quarterly_rmse %>% select(days_ahead, rmse_quarterly = rmse),
    by = "days_ahead"
  ) %>%
  mutate(
    ratio = rmse_daily / rmse_quarterly
  ) %>%
  select(days_ahead, rmse_daily, rmse_quarterly, ratio)

cat("Found", nrow(overlap_data), "overlapping horizons\n")

if (nrow(overlap_data) > 0) {
  cat("\nSample of overlapping data:\n")
  print(head(overlap_data, 10))
  
  # Fit linear model: ratio ~ days_ahead
  ratio_model <- lm(ratio ~ days_ahead, data = overlap_data)
  
  cat("\n=== LINEAR RATIO MODEL ===\n")
  cat("Model: ratio = ", coef(ratio_model)[1], " + ", coef(ratio_model)[2], " * days_ahead\n", sep = "")
  cat("R-squared:", summary(ratio_model)$r.squared, "\n")
  
  # Extract coefficients
  intercept <- coef(ratio_model)[1]
  slope <- coef(ratio_model)[2]
} else {
  cat("⚠ No overlapping horizons found. Using ratio = 1 (no adjustment)\n")
  intercept <- 1
  slope <- 0
}

# =============================================
# 6. Create Adjusted RMSE Series (Daily Frequency, Adjusted Toward Quarterly)
# =============================================

cat("\n=== CREATING ADJUSTED RMSE SERIES ===\n")

# Get all horizons we need to cover
min_horizon <- 1
max_horizon <- max(quarterly_rmse$days_ahead)
all_horizons <- seq(min_horizon, max_horizon, by = 1)

# METHOD 1: Linear Interpolation of Quarterly (baseline)
cat("\n1. Linear Interpolation of Quarterly (baseline)...\n")
quarterly_interpolated <- tibble(days_ahead = all_horizons) %>%
  left_join(
    quarterly_rmse %>% select(days_ahead, rmse_quarterly = rmse),
    by = "days_ahead"
  ) %>%
  mutate(
    rmse_linear = na.approx(rmse_quarterly, x = days_ahead, na.rm = FALSE, rule = 2)
  )

# METHOD 2: LOESS Smoothing of Quarterly
cat("2. LOESS Smoothing of Quarterly (span = 0.3)...\n")
loess_model <- loess(rmse ~ days_ahead, data = quarterly_rmse, span = 0.3)
quarterly_loess <- tibble(days_ahead = all_horizons) %>%
  mutate(
    rmse_loess = predict(loess_model, newdata = data.frame(days_ahead = days_ahead))
  )

# METHOD 3: Ratio-Adjusted to Match Quarterly (FINAL APPROACH)
cat("3. Adjusting Daily toward Quarterly using linear ratio...\n")
cat("   Using linear ratio model: ratio = ", round(intercept, 4), " + ", 
    round(slope, 6), " * days_ahead\n", sep = "")

# Start with linearly interpolated quarterly RMSE as the target
# For days where we have daily data, adjust it toward quarterly using the inverse ratio
quarterly_adjusted <- quarterly_interpolated %>%
  left_join(quarterly_loess, by = "days_ahead") %>%
  left_join(
    daily_rmse %>% select(days_ahead, rmse_daily = rmse),
    by = "days_ahead"
  ) %>%
  mutate(
    # Calculate adjustment ratio for each day
    adjustment_ratio = intercept + slope * days_ahead,
    
    # Where we have daily data, adjust it toward quarterly by dividing by the ratio
    # This gives us daily-frequency data that's adjusted toward quarterly levels
    rmse_daily_adjusted = if_else(
      !is.na(rmse_daily),
      rmse_daily / adjustment_ratio,  # Adjust daily down to quarterly level
      NA_real_
    ),
    
    # Final combined: use adjusted daily where available, quarterly interpolation elsewhere
    rmse_combined = coalesce(rmse_daily_adjusted, rmse_linear)
  )

# Combine all three methods
rmse_all_methods <- quarterly_adjusted %>%
  select(days_ahead, rmse_linear, rmse_loess, rmse_daily, rmse_daily_adjusted, 
         rmse_combined, adjustment_ratio)

# =============================================
# 7. Create Final Output (Adjusted Toward Quarterly)
# =============================================

cat("\n=== CREATING FINAL OUTPUT (ADJUSTED TOWARD QUARTERLY) ===\n")

rmse_days <- quarterly_adjusted %>%
  select(days_to_meeting = days_ahead, finalrmse = rmse_combined)

cat("Total horizons:", nrow(rmse_days), "\n")
cat("Range:", min(rmse_days$days_to_meeting), "to", max(rmse_days$days_to_meeting), "days\n\n")

cat("Sample of final output:\n")
print(head(rmse_days, 10))

cat("\nComparison at key horizons:\n")
adjustment_sample <- quarterly_adjusted %>%
  filter(days_ahead %in% c(1, 7, 14, 30, 60, 91, 120, 183, 274, 365)) %>%
  select(days_ahead, adjustment_ratio, rmse_linear, rmse_daily, rmse_daily_adjusted, rmse_combined)
print(adjustment_sample)

cat("\nExplanation:\n")
cat("- rmse_linear = Quarterly RMSE (interpolated to daily frequency)\n")
cat("- rmse_daily = Raw daily RMSE (where available)\n")
cat("- adjustment_ratio = Daily/Quarterly ratio as f(days)\n")
cat("- rmse_daily_adjusted = rmse_daily / adjustment_ratio (daily adjusted DOWN to quarterly level)\n")
cat("- rmse_combined (final) = adjusted daily where available, else quarterly interpolated\n")

# =============================================
# 7. Save Final Output
# =============================================

save(rmse_days, file = "combined_data/rmse_new.RData")
cat("\n✓ Saved final output to: combined_data/rmse_new.RData\n")

# Also save as CSV for reference
write_csv(rmse_days, "combined_data/rmse_new.csv")
cat("✓ Saved CSV to: combined_data/rmse_new.csv\n")

# Save the adjustment details for inspection
write_csv(quarterly_adjusted, "combined_data/rmse_adjustment_details.csv")
cat("✓ Saved adjustment details to: combined_data/rmse_adjustment_details.csv\n")

# Save the ratio model summary
ratio_summary <- tibble(
  parameter = c("intercept", "slope", "r_squared"),
  value = c(intercept, slope, ifelse(exists("ratio_model"), summary(ratio_model)$r.squared, NA))
)
write_csv(ratio_summary, "combined_data/rmse_ratio_model.csv")
cat("✓ Saved ratio model to: combined_data/rmse_ratio_model.csv\n")

# =============================================
# 8. Comparison Visualization (All 3 Methods)
# =============================================

cat("\n=== CREATING COMPARISON PLOTS ===\n")

# Plot 1: All three methods overlaid with ratio visualization
comparison_data <- rmse_all_methods %>%
  select(days_ahead, rmse_linear, rmse_loess, rmse_combined) %>%
  pivot_longer(
    cols = -days_ahead,
    names_to = "method",
    values_to = "rmse"
  ) %>%
  filter(!is.na(rmse)) %>%
  mutate(
    method = recode(method,
      "rmse_linear" = "Linear Interpolation (Quarterly)",
      "rmse_loess" = "LOESS (Quarterly)",
      "rmse_combined" = "Daily Adjusted to Quarterly (Final)"
    )
  )

# Add original data points
original_quarterly <- quarterly_rmse %>%
  mutate(point_type = "Quarterly Data")

original_daily <- daily_rmse %>%
  mutate(point_type = "Daily Data")

comparison_plot <- ggplot() +
  # Smoothed lines
  geom_line(data = comparison_data, 
            aes(x = days_ahead, y = rmse, color = method, linetype = method),
            linewidth = 1) +
  # Quarterly data points
  geom_point(data = original_quarterly,
             aes(x = days_ahead, y = rmse),
             color = "red", size = 3, shape = 18, alpha = 0.7) +
  # Daily data points (showing original, before adjustment)
  geom_point(data = original_daily,
             aes(x = days_ahead, y = rmse),
             color = "gray30", size = 1, alpha = 0.3) +
  scale_color_manual(values = c(
    "Linear Interpolation (Quarterly)" = "#e41a1c",
    "LOESS (Quarterly)" = "#377eb8",
    "Daily Adjusted to Quarterly (Final)" = "#4daf4a"
  )) +
  scale_linetype_manual(values = c(
    "Linear Interpolation (Quarterly)" = "dashed",
    "LOESS (Quarterly)" = "dotted",
    "Daily Adjusted to Quarterly (Final)" = "solid"
  )) +
  labs(
    title = "RMSE Smoothing Methods Comparison",
    subtitle = paste0("Red diamonds = Quarterly data | Gray dots = Raw daily (unadjusted) | ",
                     "Final adjusts daily toward quarterly: daily ÷ [", round(intercept, 3), " + ", 
                     round(slope, 5), " × days]"),
    x = "Days to Meeting",
    y = "RMSE (percentage points)",
    color = "Smoothing Method",
    linetype = "Smoothing Method"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 9),
    legend.position = "bottom",
    legend.direction = "vertical"
  )

ggsave("combined_data/rmse_methods_comparison.png",
       plot = comparison_plot, width = 12, height = 8, dpi = 300)
cat("✓ Saved: combined_data/rmse_methods_comparison.png\n")

# Plot 2: Adjustment ratio visualization
adjustment_plot <- ggplot() +
  geom_line(data = quarterly_adjusted,
            aes(x = days_ahead, y = adjustment_ratio),
            color = "#4daf4a", linewidth = 1.5) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_point(data = overlap_data,
             aes(x = days_ahead, y = ratio),
             color = "steelblue", size = 3, alpha = 0.7) +
  labs(
    title = "Daily/Quarterly RMSE Ratio (Used for Adjustment)",
    subtitle = paste0("Linear model: ratio = ", round(intercept, 4), " + ", 
                     round(slope, 6), " × days_ahead | Daily is divided by this ratio to match quarterly"),
    x = "Days to Meeting",
    y = "Ratio (Daily/Quarterly)",
    caption = "Red dashed line = no adjustment (ratio = 1) | Blue points = actual ratios at overlap"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 14)
  )

ggsave("combined_data/rmse_adjustment_ratio.png",
       plot = adjustment_plot, width = 12, height = 7, dpi = 300)
cat("✓ Saved: combined_data/rmse_adjustment_ratio.png\n")

# Plot 2: Zoomed comparison (first 180 days)
zoom_plot <- ggplot() +
  geom_line(data = comparison_data %>% filter(days_ahead <= 180), 
            aes(x = days_ahead, y = rmse, color = method, linetype = method),
            linewidth = 1.2) +
  geom_point(data = original_quarterly %>% filter(days_ahead <= 180),
             aes(x = days_ahead, y = rmse),
             color = "red", size = 4, shape = 18) +
  geom_point(data = original_daily %>% filter(days_ahead <= 180),
             aes(x = days_ahead, y = rmse),
             color = "gray30", size = 1.5, alpha = 0.5) +
  scale_color_manual(values = c(
    "Linear Interpolation (Quarterly)" = "#e41a1c",
    "LOESS (Quarterly)" = "#377eb8",
    "Daily Adjusted to Quarterly (Final)" = "#4daf4a"
  )) +
  scale_linetype_manual(values = c(
    "Linear Interpolation (Quarterly)" = "dashed",
    "LOESS (Quarterly)" = "dotted",
    "Daily Adjusted to Quarterly (Final)" = "solid"
  )) +
  labs(
    title = "RMSE Smoothing Methods: First 180 Days (Zoomed)",
    subtitle = "Daily data adjusted downward to match quarterly baseline",
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

# Plot 3: Final ratio-adjusted output
final_plot <- ggplot() +
  geom_line(data = rmse_days, 
            aes(x = days_to_meeting, y = finalrmse),
            color = "#4daf4a", linewidth = 1.5) +
  geom_point(data = original_quarterly,
             aes(x = days_ahead, y = rmse),
             color = "red", size = 4, shape = 18, alpha = 0.8) +
  geom_point(data = original_daily,
             aes(x = days_ahead, y = rmse),
             color = "gray30", size = 1, alpha = 0.3) +
  labs(
    title = "Final RMSE by Forecast Horizon (Daily Adjusted to Quarterly)",
    subtitle = paste0("This is the rmse_new.RData output | Daily frequency, adjusted toward quarterly baseline"),
    x = "Days to Meeting",
    y = "RMSE (percentage points)"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 14)
  )

ggsave("combined_data/rmse_final_adjusted_to_quarterly.png",
       plot = final_plot, width = 12, height = 7, dpi = 300)
cat("✓ Saved: combined_data/rmse_final_adjusted_to_quarterly.png\n")

# Plot 4: Comprehensive view - Raw Daily, Smoothed Daily, Quarterly, Final
cat("\n=== CREATING COMPREHENSIVE COMPARISON PLOT ===\n")

# Prepare smoothed daily RMSE using LOESS
daily_rmse_extended <- daily_rmse %>%
  arrange(days_ahead)

# Create LOESS model for daily data
if (nrow(daily_rmse_extended) > 10) {
  daily_loess <- loess(rmse ~ days_ahead, data = daily_rmse_extended, span = 0.3)
  
  # Predict for all daily horizons
  daily_horizons <- seq(min(daily_rmse_extended$days_ahead), 
                        max(daily_rmse_extended$days_ahead), 
                        by = 1)
  
  daily_smoothed <- tibble(
    days_ahead = daily_horizons,
    rmse_smoothed = predict(daily_loess, newdata = data.frame(days_ahead = daily_horizons))
  )
} else {
  daily_smoothed <- tibble(days_ahead = integer(), rmse_smoothed = numeric())
}

comprehensive_plot <- ggplot() +
  # Raw daily RMSE (light, in background)
  geom_point(data = daily_rmse,
             aes(x = days_ahead, y = rmse, color = "Raw Daily"),
             size = 1.5, alpha = 0.3) +
  # Smoothed daily RMSE
  geom_line(data = daily_smoothed,
            aes(x = days_ahead, y = rmse_smoothed, color = "Smoothed Daily"),
            linewidth = 1, alpha = 0.7) +
  # Quarterly RMSE
  geom_line(data = quarterly_rmse,
            aes(x = days_ahead, y = rmse, color = "Quarterly"),
            linewidth = 1.2) +
  geom_point(data = quarterly_rmse,
             aes(x = days_ahead, y = rmse, color = "Quarterly"),
             size = 3, shape = 18) +
  # Final interpolated RMSE (spline)
  geom_line(data = rmse_days,
            aes(x = days_to_meeting, y = finalrmse, color = "Final (Spline)"),
            linewidth = 1.5) +
  scale_color_manual(
    name = "RMSE Series",
    values = c(
      "Raw Daily" = "gray60",
      "Smoothed Daily" = "steelblue",
      "Quarterly" = "darkred",
      "Final (Spline)" = "#4daf4a"
    ),
    breaks = c("Raw Daily", "Smoothed Daily", "Quarterly", "Final (Spline)")
  ) +
  labs(
    title = "Comprehensive RMSE Comparison: Raw Daily, Smoothed Daily, Quarterly, and Final",
    subtitle = "Final (green) uses spline interpolation anchored to quarterly data with daily fills",
    x = "Days to Meeting",
    y = "RMSE (percentage points)"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(size = 10),
    legend.position = "bottom",
    legend.title = element_text(face = "bold")
  ) +
  guides(color = guide_legend(override.aes = list(
    linewidth = c(0, 1.5, 1.5, 2),
    size = c(3, NA, 4, NA),
    alpha = c(0.5, 0.8, 1, 1)
  )))

ggsave("combined_data/rmse_comprehensive_comparison.png",
       plot = comprehensive_plot, width = 14, height = 8, dpi = 300)
cat("✓ Saved: combined_data/rmse_comprehensive_comparison.png\n")

# Also create a zoomed version for short horizons
comprehensive_zoom_plot <- ggplot() +
  geom_point(data = daily_rmse %>% filter(days_ahead <= 180),
             aes(x = days_ahead, y = rmse, color = "Raw Daily"),
             size = 2, alpha = 0.4) +
  geom_line(data = daily_smoothed %>% filter(days_ahead <= 180),
            aes(x = days_ahead, y = rmse_smoothed, color = "Smoothed Daily"),
            linewidth = 1.2, alpha = 0.8) +
  geom_line(data = quarterly_rmse %>% filter(days_ahead <= 180),
            aes(x = days_ahead, y = rmse, color = "Quarterly"),
            linewidth = 1.3) +
  geom_point(data = quarterly_rmse %>% filter(days_ahead <= 180),
             aes(x = days_ahead, y = rmse, color = "Quarterly"),
             size = 4, shape = 18) +
  geom_line(data = rmse_days %>% filter(days_to_meeting <= 180),
            aes(x = days_to_meeting, y = finalrmse, color = "Final (Spline)"),
            linewidth = 1.8) +
  scale_color_manual(
    name = "RMSE Series",
    values = c(
      "Raw Daily" = "gray60",
      "Smoothed Daily" = "steelblue",
      "Quarterly" = "darkred",
      "Final (Spline)" = "#4daf4a"
    ),
    breaks = c("Raw Daily", "Smoothed Daily", "Quarterly", "Final (Spline)")
  ) +
  labs(
    title = "RMSE Comparison: First 180 Days (Zoomed)",
    subtitle = "Detailed view of raw daily volatility vs smoothed outputs",
    x = "Days to Meeting",
    y = "RMSE (percentage points)"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "bottom",
    legend.title = element_text(face = "bold")
  ) +
  guides(color = guide_legend(override.aes = list(
    linewidth = c(0, 1.5, 1.5, 2),
    size = c(3, NA, 4, NA),
    alpha = c(0.5, 0.8, 1, 1)
  )))

ggsave("combined_data/rmse_comprehensive_comparison_zoom.png",
       plot = comprehensive_zoom_plot, width = 14, height = 8, dpi = 300)
cat("✓ Saved: combined_data/rmse_comprehensive_comparison_zoom.png\n")

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
