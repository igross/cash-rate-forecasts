ensure_packages <- function(pkgs) {
  missing_pkgs <- pkgs[!pkgs %in% rownames(installed.packages())]

  if (length(missing_pkgs) > 0) {
    repos <- getOption("repos")
    if (is.null(repos) || repos["CRAN"] == "@CRAN@") {
      repos <- "https://cloud.r-project.org"
    }
    install.packages(missing_pkgs, repos = repos)
  }
}

ensure_packages(c("dplyr", "tidyr", "lubridate", "ggplot2", "readr", "slider"))

library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(readr)
library(slider)

#' Compute daily realised volatility from settlement prices.
#' @param x Tibble from build_asx_volatility_dataset().
#' @param lookback Rolling window size in trading days.
#' @return Tibble with realised volatility per symbol and market.
compute_realised_volatility <- function(x, lookback = 20L) {
  x %>%
    arrange(symbol, date) %>%
    group_by(market_type, symbol) %>%
    mutate(
      log_return = log(settlement / lag(settlement)),
      realised_vol = slider::slide_dbl(
        log_return,
        .f = ~ sd(.x, na.rm = TRUE) * sqrt(252),
        .before = lookback - 1,
        .complete = TRUE
      )
    ) %>%
    ungroup()
}

#' Build daily RBA path changes from existing cash-rate pipeline output.
#' @param cash_rate_file Path to combined_data/cash_rate.csv.
#' @return Tibble with average daily implied cash rate and day-on-day change.
compute_rate_changes <- function(cash_rate_file = "combined_data/cash_rate.csv") {
  read_csv(cash_rate_file, show_col_types = FALSE) %>%
    mutate(scrape_date = as.Date(scrape_date)) %>%
    group_by(scrape_date) %>%
    summarise(avg_implied_cash_rate = mean(cash_rate, na.rm = TRUE), .groups = "drop") %>%
    arrange(scrape_date) %>%
    mutate(rate_change_bps = (avg_implied_cash_rate - lag(avg_implied_cash_rate)) * 100)
}

#' Join volatility and rate changes and compute correlations.
#' @param vol_data Output of compute_realised_volatility().
#' @param rate_changes Output of compute_rate_changes().
#' @return List containing merged data and summary correlations.
analyse_vol_rate_correlation <- function(vol_data, rate_changes) {
  merged <- vol_data %>%
    mutate(scrape_date = as.Date(date)) %>%
    left_join(rate_changes, by = "scrape_date")

  corr <- merged %>%
    group_by(market_type, symbol) %>%
    summarise(
      n = sum(!is.na(realised_vol) & !is.na(rate_change_bps)),
      corr_vol_vs_rate_change = cor(realised_vol, rate_change_bps, use = "complete.obs"),
      .groups = "drop"
    ) %>%
    arrange(desc(abs(corr_vol_vs_rate_change)))

  list(data = merged, correlation = corr)
}

#' Plot volatility over time for all symbols.
plot_volatility_over_time <- function(vol_data) {
  ggplot(vol_data, aes(x = date, y = realised_vol, colour = symbol)) +
    geom_line(alpha = 0.7) +
    facet_wrap(~market_type, scales = "free_y") +
    labs(
      title = "ASX Bond/Options Realised Volatility Over Time",
      x = NULL,
      y = "Annualised realised volatility"
    ) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "bottom")
}

#' Plot market-level volatility against cash-rate expectation changes.
plot_market_vs_rates <- function(analysis_result) {
  market_daily <- analysis_result$data %>%
    group_by(scrape_date, market_type) %>%
    summarise(
      market_realised_vol = mean(realised_vol, na.rm = TRUE),
      rate_change_bps = first(rate_change_bps),
      .groups = "drop"
    )

  ggplot(market_daily, aes(x = scrape_date)) +
    geom_line(aes(y = market_realised_vol, colour = "Volatility"), linewidth = 0.8) +
    geom_line(aes(y = rate_change_bps / 100, colour = "Rate change (scaled)"), linewidth = 0.8) +
    facet_wrap(~market_type, scales = "free_y") +
    labs(
      title = "ASX Volatility vs. Daily Changes in Implied Cash Rate",
      x = NULL,
      y = "Volatility / Scaled rate change",
      colour = NULL
    ) +
    theme_minimal(base_size = 12)
}

# Example driver (kept isolated from current pipeline):
# asx_input <- readRDS("combined_data/asx_volatility_input.rds")
# vol <- compute_realised_volatility(asx_input)
# rates <- compute_rate_changes("combined_data/cash_rate.csv")
# res <- analyse_vol_rate_correlation(vol, rates)
# write_csv(res$correlation, "combined_data/asx_vol_rate_correlation.csv")
# ggsave("docs/asx_volatility_over_time.png", plot_volatility_over_time(vol), width = 12, height = 7)
# ggsave("docs/asx_vol_vs_rates.png", plot_market_vs_rates(res), width = 12, height = 7)
