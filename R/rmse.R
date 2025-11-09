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
    forecast_error = forecast_rate - actual_rate,
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
  select(forecast_date, meeting_date, days_ahead, forecast_rate, actual_rate, forecast_error)

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
# 4a. Visualise Forecast Error Distributions at Key Horizons
# =============================================

selected_horizons <- c(40, 30, 20, 10, 1)

error_distributions <- daily_forecasts %>%
  filter(days_ahead %in% selected_horizons) %>%
  mutate(days_ahead = factor(days_ahead, levels = selected_horizons))

if (nrow(error_distributions) == 0) {
  warning("No forecasts available for the requested horizons; skipping distribution plot.")
} else {
  distribution_plot <- ggplot(error_distributions, aes(x = forecast_error, y = after_stat(density))) +
    geom_histogram(
      binwidth = 0.025,
      fill = "#2C7BB6",
      colour = "white",
      alpha = 0.8
    ) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "#B2182B") +
    facet_wrap(~days_ahead, scales = "free_y", nrow = 2) +
    labs(
      title = "Forecast Errors by Horizon",
      subtitle = "Forecasted cash rate minus final outcome (percentage points)",
      x = "Forecast error",
      y = "Density"
    ) +
    theme_minimal(base_size = 12) +
    theme(
      strip.text = element_text(face = "bold"),
      panel.grid.minor = element_blank()
    )

  output_file <- "docs/forecast_error_histograms.png"

  ggsave(output_file, distribution_plot, width = 10, height = 6, dpi = 300)

  cat("\n✓ Saved forecast error distribution plot to:", output_file, "\n")
}

# =============================================
# SECTION 5: Create Adjusted RMSE Using CONSTANT Ratio
# =============================================

cat("\n=== CALCULATING DAILY-QUARTERLY ADJUSTMENT RATIO (CONSTANT) ===\n")

# Find overlapping horizons where we have both daily and quarterly data
overlap_data <- daily_rmse %>%
  inner_join(
    quarterly_rmse %>% select(days_ahead, rmse_quarterly = rmse),
    by = "days_ahead"
  ) %>%
  mutate(
    ratio = rmse / rmse_quarterly  # daily / quarterly
  ) %>%
  select(days_ahead, rmse_daily = rmse, rmse_quarterly, ratio)  

cat("Found", nrow(overlap_data), "overlapping horizons\n")

if (nrow(overlap_data) > 0) {
  cat("\nSample of overlapping data:\n")
  print(head(overlap_data, 10))
  
  # Calculate CONSTANT ratio (mean of all ratios)
  constant_ratio <- mean(overlap_data$ratio, na.rm = TRUE)
  
  cat("\n=== CONSTANT RATIO MODEL ===\n")
  cat("Constant ratio (mean):", round(constant_ratio, 4), "\n")
  cat("This means daily RMSE is on average", round(constant_ratio * 100, 1), "% of quarterly RMSE\n")
  cat("Min ratio:", round(min(overlap_data$ratio), 4), "\n")
  cat("Max ratio:", round(max(overlap_data$ratio), 4), "\n")
  cat("SD of ratios:", round(sd(overlap_data$ratio), 4), "\n")
  
} else {
  cat("⚠ No overlapping horizons found. Using ratio = 1 (no adjustment)\n")
  constant_ratio <- 1
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

# METHOD 3: Constant Ratio-Adjusted to Match Quarterly (FINAL APPROACH)
cat("3. Adjusting Daily toward Quarterly using CONSTANT ratio...\n")
cat("   Using constant ratio:", round(constant_ratio, 4), "\n")

quarterly_adjusted <- quarterly_interpolated %>%
  left_join(quarterly_loess, by = "days_ahead") %>%
  left_join(
    daily_rmse %>% select(days_ahead, rmse_daily = rmse),
    by = "days_ahead"
  ) %>%
  mutate(
    # Use constant adjustment ratio for all days
    adjustment_ratio = constant_ratio,
    
    # Where we have daily data, adjust it toward quarterly by dividing by the constant ratio
    rmse_daily_adjusted = if_else(
      !is.na(rmse_daily),
      rmse_daily / constant_ratio * 0.8,  # Adjust daily up to quarterly level
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
# 7. Create Final Output (Adjusted Toward Quarterly) - WITH GAP FILLING
# =============================================

cat("\n=== CREATING FINAL RMSE BASED ON DAILY, SCALED BY CONSTANT RATIO ===\n")

# Scale daily RMSE by constant ratio (up to quarterly level)
rmse_days_raw <- daily_rmse %>% 
  mutate(
    finalrmse_0 = rmse / constant_ratio 
  ) %>%
  select(days_to_meeting = days_ahead, finalrmse_0) %>%
  mutate(
    finalrmse = predict(
      loess(finalrmse_0 ~ days_to_meeting, data = ., span = 0.75)
    )
  ) %>%
  select(days_to_meeting, finalrmse)

cat("Raw data horizons:", nrow(rmse_days_raw), "\n")
cat("Range:", min(rmse_days_raw$days_to_meeting), "to", max(rmse_days_raw$days_to_meeting), "days\n")

# Check for gaps
all_days <- seq(min(rmse_days_raw$days_to_meeting), 
                max(rmse_days_raw$days_to_meeting), 
                by = 1)
missing_days <- setdiff(all_days, rmse_days_raw$days_to_meeting)

if (length(missing_days) > 0) {
  cat("\n⚠ Found", length(missing_days), "missing days in sequence\n")
  cat("Missing days sample:", head(missing_days, 20), "\n")
  cat("Filling gaps with linear interpolation...\n")
  
  # Create complete sequence and interpolate
  rmse_days <- tibble(days_to_meeting = all_days) %>%
    left_join(rmse_days_raw, by = "days_to_meeting") %>%
    mutate(
      finalrmse = zoo::na.approx(finalrmse, x = days_to_meeting, na.rm = FALSE, rule = 2)
    )
  
  cat("✓ All gaps filled\n")
} else {
  cat("\n✓ No gaps found - sequence is complete\n")
  rmse_days <- rmse_days_raw
}

cat("\nFinal horizons:", nrow(rmse_days), "\n")
cat("Range:", min(rmse_days$days_to_meeting), "to", max(rmse_days$days_to_meeting), "days\n")
cat("Sequence check:", all(diff(rmse_days$days_to_meeting) == 1), "\n\n")

cat("Sample of final output:\n")
print(rmse_days, 30)

# =============================================
# 8. Save Final Output
# =============================================

save(rmse_days, file = "combined_data/rmse_new.RData")
cat("\n✓ Saved final output to: combined_data/rmse_new.RData\n")

write_csv(rmse_days, "combined_data/rmse_new.csv")
cat("✓ Saved CSV to: combined_data/rmse_new.csv\n")

write_csv(quarterly_adjusted, "combined_data/rmse_adjustment_details.csv")
cat("✓ Saved adjustment details to: combined_data/rmse_adjustment_details.csv\n")

# Save the constant ratio info
ratio_summary <- tibble(
  parameter = c("constant_ratio", "min_ratio", "max_ratio", "sd_ratio", "n_overlaps"),
  value = c(
    constant_ratio, 
    min(overlap_data$ratio), 
    max(overlap_data$ratio), 
    sd(overlap_data$ratio),
    nrow(overlap_data)
  )
)
write_csv(ratio_summary, "combined_data/rmse_ratio_model.csv")
cat("✓ Saved ratio info to: combined_data/rmse_ratio_model.csv\n")

# =============================================
# 9. Visualization with Constant Ratio
# =============================================

cat("\n=== CREATING COMPARISON PLOTS ===\n")

# Plot 1: Adjustment ratio visualization (now constant)
adjustment_plot <- ggplot() +
  geom_hline(yintercept = constant_ratio, 
             color = "#4daf4a", linewidth = 1.5) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "red", alpha = 0.5) +
  geom_point(data = overlap_data,
             aes(x = days_ahead, y = ratio),
             color = "steelblue", size = 3, alpha = 0.7) +
  labs(
    title = "Daily/Quarterly RMSE Ratio (Constant Adjustment)",
    subtitle = paste0("Constant ratio = ", round(constant_ratio, 4), 
                     " | Daily RMSE is divided by this to match quarterly levels"),
    x = "Days to Meeting",
    y = "Ratio (Daily/Quarterly)",
    caption = "Green line = constant ratio used for adjustment | Blue points = actual ratios at overlap"
  ) +
  theme_bw() +
  theme(
    plot.title = element_text(face = "bold", size = 14)
  )

ggsave("combined_data/rmse_adjustment_ratio.png",
       plot = adjustment_plot, width = 12, height = 7, dpi = 300)
cat("✓ Saved: combined_data/rmse_adjustment_ratio.png\n")

cat("\n=== COMPLETE ===\n")
cat("✓ Using CONSTANT ratio of", round(constant_ratio, 4), "\n")
cat("✓ rmse_new.RData saved with", nrow(rmse_days), "rows\n")
