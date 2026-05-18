ensure_packages <- function(pkgs) {
  missing_pkgs <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(missing_pkgs) > 0) {
    repos <- getOption("repos")
    if (is.null(repos) || repos["CRAN"] == "@CRAN@") repos <- "https://cloud.r-project.org"
    install.packages(missing_pkgs, repos = repos)
  }
}

ensure_packages(c("dplyr", "readr", "lubridate", "ggplot2", "stringr", "readrba"))

library(dplyr)
library(readr)
library(lubridate)
library(ggplot2)
library(stringr)
library(readrba)

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

build_3y_uncertainty_dataset <- function(vol_data,
                                         cash_rate_file = "combined_data/cash_rate.csv") {
  three_year_vol <- vol_data %>%
    filter(market_type == "bond", str_detect(str_to_upper(symbol), "3Y|3_Y|3-Y|3YEAR")) %>%
    group_by(date) %>%
    summarise(three_year_bond_uncertainty = mean(realised_vol, na.rm = TRUE), .groups = "drop") %>%
    mutate(scrape_date = as.Date(date))

  mean_prediction <- read_csv(cash_rate_file, show_col_types = FALSE) %>%
    mutate(scrape_date = as.Date(scrape_date)) %>%
    group_by(scrape_date) %>%
    summarise(mean_prediction = mean(cash_rate, na.rm = TRUE), .groups = "drop") %>%
    arrange(scrape_date) %>%
    mutate(change_in_mean_prediction_bps = (mean_prediction - lag(mean_prediction)) * 100)

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

  forecast_error_daily <- read_csv(cash_rate_file, show_col_types = FALSE) %>%
    mutate(scrape_date = as.Date(scrape_date), expiry = as.Date(date)) %>%
    inner_join(meeting_schedule, by = "expiry") %>%
    inner_join(meeting_outcomes %>% select(meeting_date, actual_rate), by = "meeting_date") %>%
    mutate(days_ahead = as.integer(meeting_date - scrape_date)) %>%
    filter(days_ahead > 0) %>%
    group_by(scrape_date, meeting_date) %>%
    slice_tail(n = 1) %>%
    ungroup() %>%
    mutate(abs_forecast_error = abs(cash_rate - actual_rate)) %>%
    group_by(scrape_date) %>%
    summarise(mean_abs_forecast_error = mean(abs_forecast_error, na.rm = TRUE), .groups = "drop")

  three_year_vol %>%
    left_join(mean_prediction, by = "scrape_date") %>%
    left_join(forecast_error_daily, by = "scrape_date") %>%
    filter(!is.na(three_year_bond_uncertainty))
}

plot_3y_uncertainty_vs_prediction_and_errors <- function(x) {
  ggplot(x, aes(x = scrape_date)) +
    geom_line(aes(y = three_year_bond_uncertainty, colour = "3Y bond uncertainty"), linewidth = 0.9) +
    geom_line(aes(y = change_in_mean_prediction_bps / 100, colour = "Change in mean prediction (scaled)"), linewidth = 0.8) +
    geom_line(aes(y = mean_abs_forecast_error, colour = "Mean abs forecast error"), linewidth = 0.8) +
    labs(
      title = "3Y Bond Uncertainty vs Prediction Changes and Forecast Errors",
      x = NULL,
      y = "Uncertainty / error / scaled change",
      colour = NULL
    ) +
    theme_minimal(base_size = 12)
}
