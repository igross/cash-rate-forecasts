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
      rmse_daily / constant_ratio,  # Adjust daily up to quarterly level
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
cat("- adjustment_ratio = CONSTANT", round(constant_ratio, 4), "(mean of daily/quarterly ratios)\n")
cat("- rmse_linear = Quarterly RMSE (interpolated to daily frequency)\n")
cat("- rmse_daily = Raw daily RMSE (where available)\n")
cat("- rmse_daily_adjusted = rmse_daily /", round(constant_ratio, 4), "(daily adjusted UP to quarterly level)\n")
cat("- rmse_combined (final) = adjusted daily where available, else quarterly interpolated\n")

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
