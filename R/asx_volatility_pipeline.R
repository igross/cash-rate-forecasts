ensure_packages <- function(pkgs) {
  missing_pkgs <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(missing_pkgs) > 0) {
    repos <- getOption("repos")
    if (is.null(repos) || repos["CRAN"] == "@CRAN@") repos <- "https://cloud.r-project.org"
    install.packages(missing_pkgs, repos = repos)
  }
}

ensure_packages(c("here", "readr", "ggplot2", "dplyr"))

library(here)
library(readr)
library(ggplot2)
library(dplyr)

source(here("R", "asx_volatility_data.R"))
source(here("R", "asx_volatility_analysis.R"))
source(here("R", "asx_3y_bond_uncertainty_plot.R"))

bond_csv <- Sys.getenv("ASX_BOND_CSV", unset = here("asx_data", "bond_data.csv"))
options_csv <- Sys.getenv("ASX_OPTIONS_CSV", unset = here("asx_data", "options_data.csv"))

if (!file.exists(bond_csv) || !file.exists(options_csv)) {
  message("ASX bond/options CSV inputs not found. Skipping ASX volatility pipeline.")
  message("Expected bond file: ", bond_csv)
  message("Expected options file: ", options_csv)
  quit(save = "no", status = 0)
}

asx_input <- build_asx_volatility_dataset(
  bond_csv = bond_csv,
  options_csv = options_csv,
  out_file = here("combined_data", "asx_volatility_input.rds")
)

vol <- compute_realised_volatility(asx_input)
rates <- compute_rate_changes(here("combined_data", "cash_rate.csv"))
res <- analyse_vol_rate_correlation(vol, rates)

write_csv(res$correlation, here("combined_data", "asx_vol_rate_correlation.csv"))

p1 <- plot_volatility_over_time(vol)
p2 <- plot_market_vs_rates(res)

ggsave(here("docs", "asx_volatility_over_time.png"), p1, width = 12, height = 7)
ggsave(here("docs", "asx_vol_vs_rates.png"), p2, width = 12, height = 7)

three_year_dataset <- build_3y_uncertainty_dataset(vol, here("combined_data", "cash_rate.csv"))
write_csv(three_year_dataset, here("combined_data", "asx_3y_bond_uncertainty_analysis.csv"))
p3 <- plot_3y_uncertainty_vs_prediction_and_errors(three_year_dataset)
ggsave(here("docs", "asx_3y_bond_uncertainty_vs_prediction_error.png"), p3, width = 12, height = 7)

message("ASX volatility analysis complete. Outputs written to combined_data/ and docs/.")
