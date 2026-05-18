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

ensure_packages(c("readr", "dplyr", "tidyr", "lubridate", "stringr", "purrr"))

library(readr)
library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)
library(purrr)

#' Normalise ASX bond and options volatility data from CSV extracts.
#'
#' Expected columns (case-insensitive; common aliases supported):
#' - date / trade_date
#' - symbol / contract
#' - settlement / close / price
#' - implied_vol / iv (optional)
#' - open_interest (optional)
#' - volume (optional)
#'
#' @param input_path File path to ASX export CSV.
#' @param market_type One of "bond" or "options".
#' @return Tibble with a standard schema.
read_asx_market_data <- function(input_path, market_type = c("bond", "options")) {
  market_type <- match.arg(market_type)

  raw <- read_csv(input_path, show_col_types = FALSE)
  names(raw) <- names(raw) %>%
    str_to_lower() %>%
    str_replace_all("[^a-z0-9]+", "_")

  date_col <- intersect(c("date", "trade_date", "trading_date"), names(raw)) %>% first()
  symbol_col <- intersect(c("symbol", "contract", "instrument", "ticker"), names(raw)) %>% first()
  settle_col <- intersect(c("settlement", "settle", "close", "price", "last"), names(raw)) %>% first()
  iv_col <- intersect(c("implied_vol", "iv", "implied_volatility"), names(raw)) %>% first()
  oi_col <- intersect(c("open_interest", "oi"), names(raw)) %>% first()
  volume_col <- intersect(c("volume", "qty", "quantity"), names(raw)) %>% first()

  required <- c(date_col, symbol_col, settle_col)
  if (any(is.na(required))) {
    stop("Input data missing required columns (date, symbol, settlement/price).")
  }

  out <- raw %>%
    transmute(
      date = as.Date(.data[[date_col]]),
      symbol = as.character(.data[[symbol_col]]),
      settlement = as.numeric(.data[[settle_col]]),
      implied_vol = if (!is.na(iv_col)) as.numeric(.data[[iv_col]]) else NA_real_,
      open_interest = if (!is.na(oi_col)) as.numeric(.data[[oi_col]]) else NA_real_,
      volume = if (!is.na(volume_col)) as.numeric(.data[[volume_col]]) else NA_real_,
      market_type = market_type
    ) %>%
    filter(!is.na(date), !is.na(symbol), !is.na(settlement))

  out
}

#' Build a combined ASX volatility dataset and write it to disk.
#' @param bond_csv Path to ASX bond/futures data extract.
#' @param options_csv Path to ASX options data extract.
#' @param out_file Output RDS file.
#' @return Combined tibble invisibly.
build_asx_volatility_dataset <- function(bond_csv,
                                         options_csv,
                                         out_file = "combined_data/asx_volatility_input.rds") {
  bond <- read_asx_market_data(bond_csv, market_type = "bond")
  opts <- read_asx_market_data(options_csv, market_type = "options")

  combined <- bind_rows(bond, opts) %>% arrange(date, market_type, symbol)

  dir.create(dirname(out_file), showWarnings = FALSE, recursive = TRUE)
  saveRDS(combined, out_file)
  invisible(combined)
}
