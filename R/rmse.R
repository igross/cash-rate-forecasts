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
  filter(!is.na(forecast_rate), !is.na(actual_rate), !is.na(days_ahead))

cat("Quarterly forecasts: ", nrow(quarterly_data), "rows\n")
cat("Date range:", format(min(quarterly_data$forecast_date), "%Y-%m-%d"), "to", 
    format(max(quarterly_data$forecast_date), "%Y-%m-%d"), "\n")
cat("Horizon range:", min(quarterly_data$days_ahead, na.rm = TRUE), "to", 
    max(quarterly_data$days_ahead, na.rm = TRUE), "days\n\n")

# Check for any parsing issues
na_dates <- sum(is.na(quarterly_data_raw[[1]]))
na_after_parse <- quarterly_data_raw %>%
  mutate(parsed_date = dmy(.[[1]])) %>%
  pull(parsed_date) %>%
  is.na() %>%
  sum()

if (na_after_parse > na_dates) {
  cat("⚠ WARNING:", na_after_parse - na_dates, "dates failed to parse\n")
  cat("Sample of unparsed dates:\n")
  problem_dates <- quarterly_data_raw %>%
    mutate(parsed_date = dmy(.[[1]])) %>%
    filter(is.na(parsed_date)) %>%
    slice(1:5)
  print(problem_dates[[1]])
}

# =============================================
# 2. Load Daily Forecast Data
# =============================================

cash_rate <- readRDS("combined_data/all_data.Rds")

# Check timezone issues
cat("\n=== CHECKING TIMEZONE AND SCRAPE TIMING ===\n")

# Examine the scrape_time field
cat("Sample scrape_time values:\n")
print(head(cash_rate %>% select(scrape_time, date, cash_rate), 10))

cat("\nTimezone of scrape_time:", attr(cash_rate$scrape_time, "tzone"), "\n")

# Create both UTC and Melbourne time versions for comparison
cash_rate_timezone_check <- cash_rate %>%
  mutate(
    # Original scrape_time
    scrape_time_original = scrape_time,
    scrape_time_tz_orig = attr(scrape_time, "tzone"),
    
    # Convert to Melbourne time if not already
    scrape_time_melb = with_tz(scrape_time, "Australia/Melbourne"),
    scrape_date_melb = as.Date(scrape_time_melb),
    day_of_week_melb = lubridate::wday(scrape_date_melb, label = TRUE, week_start = 1),
    hour_melb = lubridate::hour(scrape_time_melb),
    
    # Also check UTC for comparison
    scrape_time_utc = with_tz(scrape_time, "UTC"),
    scrape_date_utc = as.Date(scrape_time_utc),
    day_of_week_utc = lubridate::wday(scrape_date_utc, label = TRUE, week_start = 1)
  )

# Compare weekend counts in different timezones
cat("\n=== WEEKEND DATA COMPARISON ===\n")
cat("Using original timezone:\n")
weekend_orig <- cash_rate_timezone_check %>%
  mutate(day_of_week = lubridate::wday(as.Date(scrape_time), label = TRUE, week_start = 1)) %>%
  filter(day_of_week %in% c("Sat", "Sun")) %>%
  count(day_of_week)
print(weekend_orig)

cat("\nUsing Melbourne timezone:\n")
weekend_melb <- cash_rate_timezone_check %>%
  filter(day_of_week_melb %in% c("Sat", "Sun")) %>%
  count(day_of_week_melb)
print(weekend_melb)

cat("\nUsing UTC timezone:\n")
weekend_utc <- cash_rate_timezone_check %>%
  filter(day_of_week_utc %in% c("Sat", "Sun")) %>%
  count(day_of_week_utc)
print(weekend_utc)

# Show examples of the timezone difference issue
cat("\n=== EXAMPLES OF POTENTIAL TIMEZONE ISSUES ===\n")
cat("Showing cases where day-of-week differs between timezones:\n")
timezone_diff_examples <- cash_rate_timezone_check %>%
  filter(day_of_week_melb != day_of_week_utc) %>%
  select(scrape_time_original, scrape_time_melb, scrape_time_utc, 
         day_of_week_melb, day_of_week_utc, hour_melb) %>%
  head(20)

if (nrow(timezone_diff_examples) > 0) {
  print(timezone_diff_examples)
  cat("\n⚠ Timezone differences found! The scrape_time likely needs correction.\n")
} else {
  cat("✓ No timezone differences detected\n")
}

# Fix timezone: ensure all times are in Australia/Melbourne
cat("\n=== CORRECTING TIMEZONE ===\n")
cash_rate <- cash_rate %>%
  mutate(
    scrape_time = force_tz(scrape_time, "Australia/Melbourne")
  )

cat("Updated scrape_time timezone to:", attr(cash_rate$scrape_time, "tzone"), "\n")

# Verify the fix
cat("\nAfter correction, checking day-of-week distribution:\n")
day_distribution <- cash_rate %>%
  mutate(
    scrape_date = as.Date(scrape_time),
    day_of_week = lubridate::wday(scrape_date, label = TRUE, week_start = 1)
  ) %>%
  count(day_of_week)
print(day_distribution)

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
    ),
    day_of_week = lubridate::wday(meeting_date, label = TRUE, week_start = 1)
  )

# Verify all meetings are on Tuesday
cat("\n=== VERIFYING MEETING DAYS ===\n")
non_tuesday_meetings <- meeting_schedule %>%
  filter(day_of_week != "Tue")

if (nrow(non_tuesday_meetings) > 0) {
  cat("⚠ WARNING: Found meetings not on Tuesday:\n")
  print(non_tuesday_meetings %>% select(meeting_date, day_of_week))
} else {
  cat("✓ All", nrow(meeting_schedule), "meetings are on Tuesday\n")
}

meeting_schedule <- meeting_schedule %>% select(-day_of_week)

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
  # Keep only one forecast per day per meeting (e.g., latest scrape of the day)
  arrange(meeting_date, forecast_date, desc(scrape_time)) %>%
  group_by(meeting_date, forecast_date) %>%
  slice(1) %>%
  ungroup() %>%
  filter(days_ahead > 0) %>%
  select(forecast_date, meeting_date, days_ahead, forecast_rate, actual_rate)

cat("\n=== DAILY FORECASTS (CLEANED) ===\n")
cat("Total rows:", nrow(daily_forecasts), "\n")
cat("Date range:", format(min(daily_forecasts$forecast_date), "%Y-%m-%d"), "to", 
    format(max(daily_forecasts$forecast_date), "%Y-%m-%d"), "\n")
cat("Unique forecast dates:", length(unique(daily_forecasts$forecast_date)), "\n")
cat("Unique meetings:", length(unique(daily_forecasts$meeting_date)), "\n")

# Verify no weekends
weekend_check <- daily_forecasts %>%
  mutate(day_of_week = lubridate::wday(forecast_date, label = TRUE, week_start = 1)) %>%
  filter(day_of_week %in% c("Sat", "Sun"))

if (nrow(weekend_check) > 0) {
  cat("⚠ WARNING: Found", nrow(weekend_check), "weekend forecasts that weren't removed\n")
} else {
  cat("✓ No weekend forecasts (Saturday/Sunday removed)\n")
}

# Check for duplicates
dup_check <- daily_forecasts %>%
  count(meeting_date, forecast_date) %>%
  filter(n > 1)

if (nrow(dup_check) > 0) {
  cat("⚠ WARNING: Found", nrow(dup_check), "duplicate date combinations\n")
} else {
  cat("✓ One forecast per date per meeting\n")
}

cat("\n")

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

# =============================================
# 9b. Additional RMSE Visualizations by Horizon
# =============================================

cat("\n=== CREATING RMSE BY HORIZON VISUALIZATIONS ===\n")

# 1. Daily RMSE over horizon (full range)
if (nrow(daily_rmse) > 0) {
  daily_rmse_plot <- ggplot(daily_rmse, aes(x = days_ahead, y = rmse)) +
    geom_line(color = "steelblue", linewidth = 1, alpha = 0.5) +
    geom_point(aes(size = n_forecasts), color = "steelblue", alpha = 0.3) +
    geom_smooth(method = "loess", span = 0.3, color = "darkblue", linewidth = 1.5, se = TRUE, alpha = 0.2) +
    scale_size_continuous(name = "N Forecasts", range = c(1, 4)) +
    labs(
      title = "Daily Forecast RMSE by Horizon",
      subtitle = "Raw data (light blue) with smoothed trend (dark blue)",
      x = "Days to Meeting",
      y = "RMSE (percentage points)"
    ) +
    theme_bw() +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      legend.position = "right"
    )
  
  ggsave("combined_data/daily_rmse_by_horizon.png",
         plot = daily_rmse_plot, width = 12, height = 7, dpi = 300)
  cat("✓ Saved: combined_data/daily_rmse_by_horizon.png\n")
  
  # Additional: Just the smoothed line for cleaner view
  daily_rmse_smooth_only <- ggplot(daily_rmse, aes(x = days_ahead, y = rmse)) +
    geom_smooth(method = "loess", span = 0.3, color = "darkblue", linewidth = 1.5, 
                se = TRUE, fill = "steelblue", alpha = 0.2) +
    labs(
      title = "Daily Forecast RMSE - Smoothed Trend",
      subtitle = "LOESS smoothing removes day-to-day fluctuations",
      x = "Days to Meeting",
      y = "RMSE (percentage points)"
    ) +
    theme_bw() +
    theme(
      plot.title = element_text(face = "bold", size = 14)
    )
  
  ggsave("combined_data/daily_rmse_smoothed.png",
         plot = daily_rmse_smooth_only, width = 12, height = 7, dpi = 300)
  cat("✓ Saved: combined_data/daily_rmse_smoothed.png\n")
}

# 2. Quarterly RMSE over horizon
if (nrow(quarterly_rmse) > 0) {
  quarterly_rmse_plot <- ggplot(quarterly_rmse, aes(x = days_ahead, y = rmse)) +
    geom_line(color = "darkred", linewidth = 1.2) +
    geom_point(aes(size = n_forecasts), color = "darkred", alpha = 0.7) +
    scale_size_continuous(name = "N Forecasts", range = c(3, 8)) +
    labs(
      title = "Quarterly Forecast RMSE by Horizon",
      subtitle = "Long-term forecast accuracy (91-day intervals)",
      x = "Days to Meeting",
      y = "RMSE (percentage points)"
    ) +
    theme_bw() +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      legend.position = "right"
    )
  
  ggsave("combined_data/quarterly_rmse_by_horizon.png",
         plot = quarterly_rmse_plot, width = 12, height = 7, dpi = 300)
  cat("✓ Saved: combined_data/quarterly_rmse_by_horizon.png\n")
}

# 3. Combined comparison (overlay)
if (nrow(daily_rmse) > 0 && nrow(quarterly_rmse) > 0) {
  combined_comparison <- bind_rows(
    daily_rmse %>% select(days_ahead, rmse, n_forecasts) %>% mutate(source = "Daily"),
    quarterly_rmse %>% select(days_ahead, rmse, n_forecasts) %>% mutate(source = "Quarterly")
  )
  
  overlay_plot <- ggplot(combined_comparison, aes(x = days_ahead, y = rmse, color = source)) +
    geom_line(linewidth = 1) +
    geom_point(aes(size = n_forecasts), alpha = 0.6) +
    scale_color_manual(values = c("Daily" = "steelblue", "Quarterly" = "darkred")) +
    scale_size_continuous(name = "N Forecasts", range = c(1, 6)) +
    labs(
      title = "RMSE Comparison: Daily vs Quarterly Forecasts",
      subtitle = "Forecast error by horizon for both data sources",
      x = "Days to Meeting",
      y = "RMSE (percentage points)",
      color = "Source"
    ) +
    theme_bw() +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      legend.position = "right"
    )
  
  ggsave("combined_data/rmse_comparison_overlay.png",
         plot = overlay_plot, width = 12, height = 7, dpi = 300)
  cat("✓ Saved: combined_data/rmse_comparison_overlay.png\n")
}

# 4. Final interpolated RMSE (zoomed to useful range)
if (nrow(rmse_days) > 0) {
  # Short-term (0-180 days)
  short_term_plot <- ggplot(rmse_days %>% filter(days_to_meeting <= 180), 
                             aes(x = days_to_meeting, y = finalrmse)) +
    geom_line(color = "darkgreen", linewidth = 1.2) +
    geom_point(data = rmse_days %>% 
                 filter(days_to_meeting <= 180, source == "quarterly_anchor"),
               aes(color = "Quarterly Anchor"), size = 4, shape = 18) +
    geom_point(data = rmse_days %>% 
                 filter(days_to_meeting <= 180, source == "daily"),
               aes(color = "Daily"), size = 2, alpha = 0.6) +
    scale_color_manual(values = c("Quarterly Anchor" = "red", "Daily" = "steelblue"),
                       name = "Data Source") +
    labs(
      title = "Final RMSE by Horizon (0-180 Days)",
      subtitle = "Combined and interpolated forecast error",
      x = "Days to Meeting",
      y = "RMSE (percentage points)"
    ) +
    theme_bw() +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      legend.position = "right"
    )
  
  ggsave("combined_data/final_rmse_short_term.png",
         plot = short_term_plot, width = 12, height = 7, dpi = 300)
  cat("✓ Saved: combined_data/final_rmse_short_term.png\n")
  
  # Medium-term (0-365 days)
  medium_term_plot <- ggplot(rmse_days %>% filter(days_to_meeting <= 365), 
                              aes(x = days_to_meeting, y = finalrmse)) +
    geom_line(color = "darkgreen", linewidth = 1) +
    geom_point(data = rmse_days %>% 
                 filter(days_to_meeting <= 365, source == "quarterly_anchor"),
               color = "red", size = 3, shape = 18) +
    labs(
      title = "Final RMSE by Horizon (0-365 Days)",
      subtitle = "One year forecast horizon",
      x = "Days to Meeting",
      y = "RMSE (percentage points)"
    ) +
    theme_bw() +
    theme(
      plot.title = element_text(face = "bold", size = 14)
    )
  
  ggsave("combined_data/final_rmse_medium_term.png",
         plot = medium_term_plot, width = 12, height = 7, dpi = 300)
  cat("✓ Saved: combined_data/final_rmse_medium_term.png\n")
}

# 5. MAE comparison (if useful)
if (nrow(daily_rmse) > 0 && nrow(quarterly_rmse) > 0) {
  mae_comparison <- bind_rows(
    daily_rmse %>% select(days_ahead, mae, n_forecasts) %>% mutate(source = "Daily"),
    quarterly_rmse %>% select(days_ahead, mae, n_forecasts) %>% mutate(source = "Quarterly")
  )
  
  mae_plot <- ggplot(mae_comparison, aes(x = days_ahead, y = mae, color = source)) +
    geom_line(linewidth = 1) +
    geom_point(aes(size = n_forecasts), alpha = 0.6) +
    scale_color_manual(values = c("Daily" = "steelblue", "Quarterly" = "darkred")) +
    scale_size_continuous(name = "N Forecasts", range = c(1, 6)) +
    labs(
      title = "Mean Absolute Error (MAE) by Horizon",
      subtitle = "Alternative error metric: less sensitive to outliers than RMSE",
      x = "Days to Meeting",
      y = "MAE (percentage points)",
      color = "Source"
    ) +
    theme_bw() +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      legend.position = "right"
    )
  
  ggsave("combined_data/mae_comparison_by_horizon.png",
         plot = mae_plot, width = 12, height = 7, dpi = 300)
  cat("✓ Saved: combined_data/mae_comparison_by_horizon.png\n")
}

cat("\n")

# =============================================
# 10. Run CPI Event Analysis
# =============================================

cat("\n\n")
cat(strrep("=", 60), "\n")
cat("RUNNING CPI RELEASE EVENT ANALYSIS\n")
cat(strrep("=", 60), "\n\n")

# Source the CPI event analysis script
# Note: This assumes the cpi_event_analysis.R file exists
# Alternatively, we can inline the code here

# CPI Release dates
cpi_releases <- tribble(
  ~release_date,
  "2022-01-26",
  "2022-04-27",
  "2022-07-27",
  "2022-10-26",
  "2023-01-25",
  "2023-04-26",
  "2023-07-26",
  "2023-10-25",
  "2024-01-31",
  "2024-04-24",
  "2024-07-31",
  "2024-10-30",
  "2025-01-29",
  "2025-04-30",
  "2025-07-30",
  "2025-10-29"
) %>%
  mutate(release_date = as.Date(release_date))

cat("=== CPI RELEASES ===\n")
cat("Total CPI releases:", nrow(cpi_releases), "\n")
cat("Date range:", format(min(cpi_releases$release_date), "%Y-%m-%d"), "to",
    format(max(cpi_releases$release_date), "%Y-%m-%d"), "\n\n")

# Analyze CPI releases
window_days <- 5
cat("=== ANALYZING CPI RELEASES (window =", window_days, "days) ===\n\n")

all_comparisons <- list()

for (i in 1:nrow(cpi_releases)) {
  cpi_date <- cpi_releases$release_date[i]
  
  cat("CPI Release #", i, ":", format(cpi_date, "%Y-%m-%d"), "\n", sep = "")
  
  # Get forecasts made within window_days of this CPI release
  forecasts_around_cpi <- daily_forecasts %>%
    filter(
      meeting_date > cpi_date,  # Only meetings after this CPI
      abs(as.integer(forecast_date - cpi_date)) <= window_days  # Within window
    ) %>%
    mutate(
      days_from_cpi = as.integer(forecast_date - cpi_date),
      period = ifelse(days_from_cpi < 0, "before", "after")
    ) %>%
    filter(days_from_cpi != 0)  # Exclude exact CPI date
  
  forecasts_before <- forecasts_around_cpi %>% filter(period == "before")
  forecasts_after <- forecasts_around_cpi %>% filter(period == "after")
  
  cat("  Forecasts before CPI:", nrow(forecasts_before), "\n")
  cat("  Forecasts after CPI:", nrow(forecasts_after), "\n")
  
  if (nrow(forecasts_before) == 0 || nrow(forecasts_after) == 0) {
    cat("  Insufficient data for comparison\n\n")
    next
  }
  
  # Calculate RMSE for each period
  combined <- bind_rows(forecasts_before, forecasts_after) %>%
    mutate(squared_error = (forecast_rate - actual_rate)^2)
  
  rmse_by_group <- combined %>%
    group_by(period, meeting_date, days_ahead) %>%
    summarise(
      n = n(),
      rmse = sqrt(mean(squared_error, na.rm = TRUE)),
      mean_forecast = mean(forecast_rate),
      .groups = "drop"
    )
  
  # Match before and after
  rmse_before <- rmse_by_group %>%
    filter(period == "before") %>%
    select(meeting_date, days_ahead, rmse_before = rmse, n_before = n, 
           forecast_before = mean_forecast)
  
  rmse_after <- rmse_by_group %>%
    filter(period == "after") %>%
    select(meeting_date, days_ahead, rmse_after = rmse, n_after = n,
           forecast_after = mean_forecast)
  
  comparison <- rmse_before %>%
    inner_join(rmse_after, by = c("meeting_date", "days_ahead")) %>%
    mutate(
      cpi_date = cpi_date,
      rmse_change = rmse_after - rmse_before,
      rmse_pct_change = (rmse_after - rmse_before) / rmse_before * 100,
      forecast_change = forecast_after - forecast_before
    )
  
  cat("  Valid comparisons:", nrow(comparison), "\n\n")
  
  if (nrow(comparison) > 0) {
    all_comparisons[[i]] <- comparison
  }
}

# Analyze results
if (length(all_comparisons) == 0) {
  cat("⚠ NO COMPARISONS FOUND FOR CPI ANALYSIS\n\n")
} else {
  cpi_analysis <- bind_rows(all_comparisons)
  
  cat("=== CPI ANALYSIS RESULTS ===\n")
  cat("Total comparisons:", nrow(cpi_analysis), "\n")
  cat("CPI releases with data:", length(unique(cpi_analysis$cpi_date)), "\n")
  cat("Meetings analyzed:", length(unique(cpi_analysis$meeting_date)), "\n\n")
  
  # Summary statistics
  summary_stats <- cpi_analysis %>%
    summarise(
      n_comparisons = n(),
      mean_rmse_change = mean(rmse_change, na.rm = TRUE),
      median_rmse_change = median(rmse_change, na.rm = TRUE),
      pct_improved = mean(rmse_change < 0, na.rm = TRUE) * 100,
      mean_pct_change = mean(rmse_pct_change, na.rm = TRUE),
      sd_pct_change = sd(rmse_pct_change, na.rm = TRUE)
  )
  
  cat("Summary Statistics:\n")
  print(summary_stats)
  
  cat("\nInterpretation:\n")
  if (summary_stats$mean_rmse_change < 0) {
    cat("✓ RMSE decreased on average after CPI releases (forecasts improved)\n")
  } else {
    cat("✗ RMSE increased on average after CPI releases (forecasts worse)\n")
  }
  
  cat("- Average change:", round(summary_stats$mean_rmse_change, 4), "percentage points\n")
  cat("- Percentage of cases that improved:", round(summary_stats$pct_improved, 1), "%\n\n")
  
  # Statistical test
  cat("=== STATISTICAL TEST ===\n")
  t_test_result <- t.test(cpi_analysis$rmse_change, alternative = "less")
  
  cat("Null hypothesis: Mean RMSE change >= 0 (no improvement)\n")
  cat("Alternative: Mean RMSE change < 0 (improvement)\n\n")
  cat("t-statistic:", round(t_test_result$statistic, 3), "\n")
  cat("p-value:", format.pval(t_test_result$p.value, digits = 3), "\n")
  cat("95% CI upper bound:", round(t_test_result$conf.int[2], 4), "\n\n")
  
  if (t_test_result$p.value < 0.05) {
    cat("✓ SIGNIFICANT: RMSE significantly decreases after CPI releases (p < 0.05)\n")
  } else {
    cat("✗ NOT SIGNIFICANT: No significant change in RMSE after CPI releases\n")
  }
  
  # Save results
  write_csv(cpi_analysis, "combined_data/cpi_event_analysis.csv")
  cat("\n✓ Saved CPI analysis: combined_data/cpi_event_analysis.csv\n")
  
  # Visualizations
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    
    # Histogram
    hist_plot <- ggplot(cpi_analysis, aes(x = rmse_pct_change)) +
      geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
      geom_vline(xintercept = 0, color = "red", linetype = "dashed", linewidth = 1) +
      geom_vline(xintercept = median(cpi_analysis$rmse_pct_change), 
                 color = "darkgreen", linetype = "solid", linewidth = 1) +
      labs(
        title = "RMSE Change After CPI Releases",
        subtitle = paste0("Negative = Improvement | Median = ", 
                         round(median(cpi_analysis$rmse_pct_change), 2), "%"),
        x = "RMSE Change (%)",
        y = "Count"
      ) +
      theme_bw() +
      theme(plot.title = element_text(face = "bold", size = 14))
    
    ggsave("combined_data/cpi_rmse_changes_histogram.png",
           plot = hist_plot, width = 10, height = 6, dpi = 300)
    cat("✓ Saved histogram: combined_data/cpi_rmse_changes_histogram.png\n")
    
    # Before vs After boxplot
    before_after_data <- cpi_analysis %>%
      select(cpi_date, meeting_date, days_ahead, rmse_before, rmse_after) %>%
      pivot_longer(cols = c(rmse_before, rmse_after), 
                   names_to = "period", values_to = "rmse") %>%
      mutate(period = ifelse(period == "rmse_before", "Before CPI", "After CPI"))
    
    box_plot <- ggplot(before_after_data, aes(x = period, y = rmse, fill = period)) +
      geom_boxplot(alpha = 0.7, outlier.alpha = 0.5) +
      scale_fill_manual(values = c("Before CPI" = "lightcoral", "After CPI" = "lightgreen")) +
      labs(
        title = "Forecast RMSE: Before vs After CPI Releases",
        subtitle = paste0("Based on ", nrow(cpi_analysis), " comparisons across ", 
                         length(unique(cpi_analysis$cpi_date)), " CPI releases"),
        x = "",
        y = "RMSE (percentage points)"
      ) +
      theme_bw() +
      theme(
        plot.title = element_text(face = "bold", size = 14),
        legend.position = "none"
      )
    
    ggsave("combined_data/cpi_rmse_before_after_boxplot.png",
           plot = box_plot, width = 10, height = 6, dpi = 300)
    cat("✓ Saved boxplot: combined_data/cpi_rmse_before_after_boxplot.png\n")
  }
}

cat("\n=== RMSE CALCULATION AND CPI ANALYSIS COMPLETE ===\n")

# =============================================
# 10. Analyze RMSE Changes Around Key Events
# =============================================

cat("\n\n=== ANALYZING RMSE CHANGES AROUND KEY EVENTS ===\n")

# Define event schedule
abs_releases <- tribble(
  ~dataset,           ~datetime,
  
  # CPI (quarterly) - back to 2022
  "CPI",  ymd_hm("2022-01-26 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2022-04-27 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2022-07-27 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2022-10-26 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2023-01-25 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2023-04-26 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2023-07-26 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2023-10-25 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2024-01-31 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2024-04-24 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2024-07-31 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2024-10-30 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2025-01-29 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2025-04-30 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2025-07-30 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2025-10-29 11:30", tz = "Australia/Melbourne"),
  
  # CPI Indicator (monthly) - started in 2022
  "CPI Indicator", ymd_hm("2022-10-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2022-11-30 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2022-12-21 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2023-01-25 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2023-02-22 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2023-03-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2023-04-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2023-05-31 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2023-06-28 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2023-07-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2023-08-30 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2023-09-27 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2023-10-25 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2023-11-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2023-12-20 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2024-01-31 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2024-02-28 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2024-03-27 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2024-04-24 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2024-05-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2024-06-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2024-07-31 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2024-08-28 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2024-09-25 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2024-10-30 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2024-11-27 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2024-12-30 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-01-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-02-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-03-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-04-30 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-05-28 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-06-25 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-07-30 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-08-27 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-09-24 11:30", tz = "Australia/Melbourne"),
  
  # WPI (quarterly) - back to 2022
  "WPI",  ymd_hm("2022-02-23 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2022-05-18 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2022-08-17 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2022-11-16 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2023-02-22 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2023-05-17 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2023-08-16 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2023-11-15 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2024-02-21 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2024-05-15 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2024-08-14 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2024-11-13 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2025-02-19 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2025-05-14 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2025-08-13 11:30", tz = "Australia/Melbourne"),
  
  # National Accounts (quarterly) - back to 2022
  "National Accounts", ymd_hm("2022-03-02 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2022-06-01 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2022-09-07 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2022-12-07 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2023-03-01 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2023-05-31 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2023-09-06 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2023-12-06 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2024-03-06 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2024-06-05 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2024-09-04 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2024-12-04 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2025-03-05 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2025-06-04 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2025-09-03 11:30", tz = "Australia/Melbourne"),
  
  # Labour Force (monthly) - back to 2022
  "Labour Force", ymd_hm("2022-01-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2022-02-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2022-03-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2022-04-14 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2022-05-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2022-06-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2022-07-14 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2022-08-18 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2022-09-15 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2022-10-13 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2022-11-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2022-12-15 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2023-01-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2023-02-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2023-03-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2023-04-13 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2023-05-18 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2023-06-15 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2023-07-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2023-08-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2023-09-14 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2023-10-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2023-11-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2023-12-14 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2024-01-18 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2024-02-15 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2024-03-21 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2024-04-18 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2024-05-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2024-06-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2024-07-18 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2024-08-15 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2024-09-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2024-10-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2024-11-21 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2024-12-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-01-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-02-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-03-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-04-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-05-15 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-06-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-07-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-08-14 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-09-18 11:30", tz = "Australia/Melbourne"),
  
  # Retail Trade (monthly) - back to 2022
  "Retail Trade", ymd_hm("2022-02-04 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2022-03-04 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2022-04-07 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2022-05-06 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2022-06-08 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2022-07-08 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2022-08-05 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2022-09-07 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2022-10-07 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2022-11-04 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2022-12-07 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2023-02-03 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2023-03-03 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2023-04-06 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2023-05-05 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2023-06-07 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2023-07-07 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2023-08-04 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2023-09-06 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2023-10-06 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2023-11-03 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2023-12-06 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2024-02-02 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2024-03-01 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2024-04-05 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2024-05-03 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2024-06-05 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2024-07-05 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2024-08-02 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2024-09-04 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2024-10-04 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2024-11-08 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2024-12-06 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2025-02-07 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2025-03-07 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2025-04-04 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2025-05-02 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2025-06-06 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2025-07-04 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2025-08-01 11:30", tz = "Australia/Melbourne"),
  "Retail Trade", ymd_hm("2025-09-05 11:30", tz = "Australia/Melbourne")
) %>%
  mutate(release_date = as.Date(datetime))

# Analyze RMSE changes around events
analyze_rmse_around_events <- function(forecasts_df, event_dates, event_name, window_days = 7) {
  
  cat("\n  Analyzing", event_name, "...\n")
  cat("  Events to check:", length(event_dates), "\n")
  cat("  Event date range:", format(min(event_dates), "%Y-%m-%d"), "to", 
      format(max(event_dates), "%Y-%m-%d"), "\n")
  
  # Debug: check date classes
  cat("  Event date class:", class(event_dates), "\n")
  cat("  Forecast date class:", class(forecasts_df$forecast_date), "\n")
  cat("  Meeting date class:", class(forecasts_df$meeting_date), "\n")
  
  # Debug: show sample dates
  cat("  Sample event dates:", paste(format(head(event_dates, 3), "%Y-%m-%d"), collapse = ", "), "\n")
  cat("  Sample forecast dates:", paste(format(head(forecasts_df$forecast_date, 3), "%Y-%m-%d"), collapse = ", "), "\n")
  cat("  Sample meeting dates:", paste(format(head(unique(forecasts_df$meeting_date), 3), "%Y-%m-%d"), collapse = ", "), "\n")
  
  results <- list()
  events_with_data <- 0
  
  for (i in seq_along(event_dates)) {
    event_date <- event_dates[i]
    
    # For each meeting, look at forecasts made before and after this event
    event_analysis <- forecasts_df %>%
      filter(meeting_date > event_date) %>%  # Only meetings after the event
      mutate(
        days_from_event = as.integer(forecast_date - event_date),
        period = case_when(
          days_from_event >= -window_days & days_from_event < 0 ~ "before",
          days_from_event >= 0 & days_from_event <= window_days ~ "after",
          TRUE ~ "other"
        )
      ) %>%
      filter(period %in% c("before", "after"))
    
    if (nrow(event_analysis) == 0) next
    
    # Calculate RMSE before and after
    rmse_by_period <- event_analysis %>%
      mutate(squared_error = (forecast_rate - actual_rate)^2) %>%
      group_by(period, meeting_date, days_ahead) %>%
      summarise(
        n = n(),
        rmse = sqrt(mean(squared_error, na.rm = TRUE)),
        .groups = "drop"
      )
    
    # Compare before vs after for same horizon
    # Split into before and after, then join
    rmse_before <- rmse_by_period %>%
      filter(period == "before") %>%
      select(meeting_date, days_ahead, rmse_before = rmse, n_before = n)
    
    rmse_after <- rmse_by_period %>%
      filter(period == "after") %>%
      select(meeting_date, days_ahead, rmse_after = rmse, n_after = n)
    
    comparison <- rmse_before %>%
      inner_join(rmse_after, by = c("meeting_date", "days_ahead")) %>%
      mutate(
        rmse_change = rmse_after - rmse_before,
        rmse_pct_change = (rmse_after - rmse_before) / rmse_before * 100,
        event_date = event_date,
        event_name = event_name
      )
    
    if (nrow(comparison) > 0) {
      results[[i]] <- comparison
      events_with_data <- events_with_data + 1
    }
  }
  
  cat("  Events with usable data:", events_with_data, "/", length(event_dates), "\n")
  
  final_result <- bind_rows(results)
  
  if (nrow(final_result) == 0) {
    cat("  ⚠ No comparisons found. Debugging first event...\n")
    
    # Debug the first event in detail
    event_date <- event_dates[1]
    cat("  First event date:", format(event_date, "%Y-%m-%d"), "(class:", class(event_date), ")\n")
    
    # Check meetings after this event
    meetings_after <- forecasts_df %>%
      filter(meeting_date > event_date) %>%
      distinct(meeting_date) %>%
      arrange(meeting_date)
    
    cat("  Meetings after this event:", nrow(meetings_after), "\n")
    if (nrow(meetings_after) > 0) {
      cat("  First few meetings:", paste(format(head(meetings_after$meeting_date, 3), "%Y-%m-%d"), collapse = ", "), "\n")
      
      # Check forecasts for first meeting
      first_meeting <- meetings_after$meeting_date[1]
      forecasts_for_meeting <- forecasts_df %>%
        filter(meeting_date == first_meeting)
      
      cat("  Forecasts for first meeting (", format(first_meeting, "%Y-%m-%d"), "):", nrow(forecasts_for_meeting), "\n")
      cat("  Forecast date range:", format(min(forecasts_for_meeting$forecast_date), "%Y-%m-%d"), "to",
          format(max(forecasts_for_meeting$forecast_date), "%Y-%m-%d"), "\n")
      
      if (nrow(forecasts_for_meeting) > 0) {
        # Check dates relative to event
        forecasts_with_timing <- forecasts_for_meeting %>%
          mutate(days_from_event = as.integer(forecast_date - event_date)) %>%
          filter(abs(days_from_event) <= window_days)
        
        cat("  Within", window_days, "days of event:", nrow(forecasts_with_timing), "\n")
        
        if (nrow(forecasts_with_timing) > 0) {
          timing_summary <- forecasts_with_timing %>%
            mutate(period = ifelse(days_from_event < 0, "before", "after")) %>%
            count(period)
          cat("  Breakdown:\n")
          print(timing_summary)
        } else {
          cat("  ⚠ No forecasts within", window_days, "days of event\n")
          cat("  Days from event range:", min(forecasts_for_meeting$forecast_date - event_date), "to",
              max(forecasts_for_meeting$forecast_date - event_date), "\n")
        }
      }
    } else {
      cat("  ⚠ No meetings found after this event date\n")
      cat("  Latest forecast meeting date:", format(max(forecasts_df$meeting_date), "%Y-%m-%d"), "\n")
    }
  }
  
  final_result
}

# Analyze for each event type
cat("\nAnalyzing RMSE changes around RBA meetings...\n")
rba_meeting_analysis <- analyze_rmse_around_events(
  daily_forecasts,
  meeting_schedule$meeting_date,
  "RBA Meeting",
  window_days = 5
)
cat("Found", nrow(rba_meeting_analysis), "RBA meeting comparisons\n")

cat("Analyzing RMSE changes around CPI releases...\n")
cpi_analysis <- analyze_rmse_around_events(
  daily_forecasts,
  abs_releases %>% filter(dataset == "CPI") %>% pull(release_date),
  "CPI Release",
  window_days = 5
)
cat("Found", nrow(cpi_analysis), "CPI release comparisons\n")

cat("Analyzing RMSE changes around Labour Force releases...\n")
labour_analysis <- analyze_rmse_around_events(
  daily_forecasts,
  abs_releases %>% filter(dataset == "Labour Force") %>% pull(release_date),
  "Labour Force Release",
  window_days = 5
)
cat("Found", nrow(labour_analysis), "Labour Force release comparisons\n")

# Combine all analyses
all_event_analysis <- bind_rows(rba_meeting_analysis, cpi_analysis, labour_analysis)

cat("\nTotal event comparisons:", nrow(all_event_analysis), "\n")

# Only proceed if we have data
if (nrow(all_event_analysis) == 0) {
  cat("\n⚠ WARNING: No event comparisons found. This could mean:\n")
  cat("  - Forecast data doesn't overlap with event dates\n")
  cat("  - Not enough forecasts within the window before/after events\n")
  cat("  - Date range mismatch between forecasts and events\n\n")
  
  # Better date range display
  cat("DIAGNOSTICS:\n")
  cat("Daily forecasts:\n")
  cat("  Count:", nrow(daily_forecasts), "\n")
  cat("  Date range:", format(min(daily_forecasts$forecast_date), "%Y-%m-%d"), "to", 
      format(max(daily_forecasts$forecast_date), "%Y-%m-%d"), "\n")
  cat("  Meeting dates in forecasts:", length(unique(daily_forecasts$meeting_date)), "\n")
  
  cat("\nEvents:\n")
  cat("  Total events:", nrow(abs_releases), "\n")
  cat("  Date range:", format(min(abs_releases$release_date), "%Y-%m-%d"), "to", 
      format(max(abs_releases$release_date), "%Y-%m-%d"), "\n")
  
  cat("\nRBA Meetings:\n")
  cat("  Total meetings:", nrow(meeting_schedule), "\n")
  cat("  Date range:", format(min(meeting_schedule$meeting_date), "%Y-%m-%d"), "to", 
      format(max(meeting_schedule$meeting_date), "%Y-%m-%d"), "\n")
  
  # Check overlap
  forecast_range <- interval(min(daily_forecasts$forecast_date), max(daily_forecasts$forecast_date))
  event_range <- interval(min(abs_releases$release_date), max(abs_releases$release_date))
  meeting_range <- interval(min(meeting_schedule$meeting_date), max(meeting_schedule$meeting_date))
  
  cat("\nOverlap check:\n")
  cat("  Forecasts overlap with events:", int_overlaps(forecast_range, event_range), "\n")
  cat("  Forecasts overlap with meetings:", int_overlaps(forecast_range, meeting_range), "\n")
  
  # Sample of what we're looking for
  cat("\nSample events in forecast period:\n")
  events_in_range <- abs_releases %>%
    filter(release_date >= min(daily_forecasts$forecast_date),
           release_date <= max(daily_forecasts$forecast_date)) %>%
    count(dataset) %>%
    arrange(desc(n))
  print(events_in_range)
  
  # Check if there are forecasts around a sample event
  sample_event <- abs_releases %>%
    filter(release_date >= min(daily_forecasts$forecast_date),
           release_date <= max(daily_forecasts$forecast_date)) %>%
    slice(1)
  
  if (nrow(sample_event) > 0) {
    cat("\nChecking forecasts around sample event:", format(sample_event$release_date[1], "%Y-%m-%d"), 
        "(", sample_event$dataset[1], ")\n")
    
    window <- 5
    forecasts_around_event <- daily_forecasts %>%
      filter(forecast_date >= sample_event$release_date[1] - window,
             forecast_date <= sample_event$release_date[1] + window) %>%
      mutate(
        days_from_event = as.integer(forecast_date - sample_event$release_date[1]),
        period = case_when(
          days_from_event < 0 ~ "before",
          days_from_event > 0 ~ "after",
          TRUE ~ "on_day"
        )
      )
    
    cat("  Forecasts before event:", sum(forecasts_around_event$period == "before"), "\n")
    cat("  Forecasts after event:", sum(forecasts_around_event$period == "after"), "\n")
    cat("  Forecasts on event day:", sum(forecasts_around_event$period == "on_day"), "\n")
    
    if (nrow(forecasts_around_event) > 0) {
      cat("\n  Sample of these forecasts:\n")
      print(forecasts_around_event %>% 
              select(forecast_date, meeting_date, days_ahead, period) %>% 
              head(10))
    }
  }
  
  cat("\nSkipping event analysis...\n")
} else {

  # Summary statistics
  cat("\n=== RMSE CHANGES AFTER KEY EVENTS ===\n")
  cat("(Comparing forecasts made within 5 days before vs after each event)\n\n")

  event_summary <- all_event_analysis %>%
    group_by(event_name) %>%
    summarise(
      n_comparisons = n(),
      mean_rmse_change = mean(rmse_change, na.rm = TRUE),
      median_rmse_change = median(rmse_change, na.rm = TRUE),
      pct_improved = mean(rmse_change < 0, na.rm = TRUE) * 100,
      mean_pct_change = mean(rmse_pct_change, na.rm = TRUE),
      .groups = "drop"
    )

  print(event_summary)

  cat("\nInterpretation:\n")
  cat("- Negative mean_rmse_change = RMSE decreased (forecasts improved) after event\n")
  cat("- pct_improved = percentage of cases where RMSE decreased\n\n")

  # Statistical test: does RMSE significantly decrease after events?
  cat("=== STATISTICAL TESTS ===\n")
  
  for (evt in unique(all_event_analysis$event_name)) {
    evt_data <- all_event_analysis %>% filter(event_name == evt)
    
    if (nrow(evt_data) >= 3) {
      test_result <- t.test(evt_data$rmse_change, alternative = "less")
      
      cat("\n", evt, ":\n", sep = "")
      cat("  Mean RMSE change:", round(mean(evt_data$rmse_change), 4), "\n")
      cat("  t-statistic:", round(test_result$statistic, 3), "\n")
      cat("  p-value:", format.pval(test_result$p.value, digits = 3), "\n")
      cat("  ", ifelse(test_result$p.value < 0.05, 
                      "✓ Significant decrease in RMSE", 
                      "✗ No significant decrease"), "\n", sep = "")
    } else {
      cat("\n", evt, ": Insufficient data (n=", nrow(evt_data), ")\n", sep = "")
    }
  }
}

# =============================================
# 11. Visualize RMSE Changes Around Events
# =============================================

if (nrow(all_event_analysis) > 0) {
  
  # Plot distribution of RMSE changes
  rmse_change_plot <- ggplot(all_event_analysis, 
                              aes(x = rmse_pct_change, fill = event_name)) +
    geom_histogram(bins = 30, alpha = 0.7, position = "identity") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "red", linewidth = 1) +
    facet_wrap(~event_name, ncol = 1, scales = "free_y") +
    labs(
      title = "Distribution of RMSE Changes After Key Events",
      subtitle = "Negative values = Forecast accuracy improved after event",
      x = "RMSE Change (%)",
      y = "Count",
      fill = "Event Type"
    ) +
    theme_bw() +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      legend.position = "none"
    )
  
  ggsave("combined_data/rmse_changes_after_events.png",
         plot = rmse_change_plot, width = 10, height = 8, dpi = 300)
  
  cat("\n\nSaved RMSE change distribution to: combined_data/rmse_changes_after_events.png\n")
  
  # Box plot comparing before vs after
  rmse_before_after <- all_event_analysis %>%
    select(event_name, event_date, meeting_date, days_ahead, rmse_before, rmse_after) %>%
    pivot_longer(cols = c(rmse_before, rmse_after), 
                 names_to = "period", values_to = "rmse") %>%
    mutate(period = ifelse(period == "rmse_before", "Before Event", "After Event"))
  
  box_plot <- ggplot(rmse_before_after, aes(x = period, y = rmse, fill = period)) +
    geom_boxplot(alpha = 0.7) +
    facet_wrap(~event_name, scales = "free_y") +
    scale_fill_manual(values = c("Before Event" = "lightcoral", "After Event" = "lightgreen")) +
    labs(
      title = "RMSE Before vs After Key Events",
      subtitle = "Lower RMSE after event = Improved forecast accuracy",
      x = "",
      y = "RMSE (percentage points)",
      fill = "Period"
    ) +
    theme_bw() +
    theme(
      plot.title = element_text(face = "bold", size = 14),
      legend.position = "bottom"
    )
  
  ggsave("combined_data/rmse_before_after_events.png",
         plot = box_plot, width = 12, height = 6, dpi = 300)
  
  cat("Saved before/after comparison to: combined_data/rmse_before_after_events.png\n")
  
  # Save detailed results
  write_csv(all_event_analysis, "combined_data/rmse_event_analysis_detailed.csv")
  cat("Saved detailed event analysis to: combined_data/rmse_event_analysis_detailed.csv\n")
}
