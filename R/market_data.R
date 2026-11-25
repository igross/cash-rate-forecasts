# ==============================================================================
# Shared ASX cash-rate futures helpers
# ==============================================================================
# Used by both the full pipeline (R/scrape_cash_rate.R) and the rapid ABS
# release mode (R/rapid_update.R) so that both parse, store and clean market
# data identically.  The bodies below are the original scrape_cash_rate.R code
# moved into functions; behaviour is unchanged.
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(readr)
  library(lubridate)
  library(jsonlite)
})

asx_futures_url <- "https://asx.api.markitdigital.com/asx-research/1.0/derivatives/interest-rate/IB/futures?days=1&height=179&width=179"

# Scrape dates excluded from the combined dataset (known bad snapshots).
excluded_scrape_dates <- ymd(c(
  "2022-08-06","2022-08-07","2022-08-08",
  "2023-01-18","2023-01-24","2023-01-31",
  "2023-02-02","2022-12-30","2022-12-29"
))

# Market fields that change whenever the ASX feed carries new information.
# Used to recognise a repeated (stale) payload so it is not recorded as a
# fresh observation.
asx_market_fields <- c(
  "dateLastTrade", "datePreviousSettlement", "priceAsk", "priceBid",
  "priceLastTrade", "pricePreviousSettlement", "priceContract",
  "volume", "combinedVolume"
)

# Parse an ASX futures JSON payload (file path or JSON text).
parse_asx_futures <- function(json, scrape_time = now(tzone = "Australia/Melbourne")) {
  fromJSON(json) %>%
    pluck("data", "items") %>%
    as_tibble() %>%
    mutate(
      # floor expiry to the month start
      date         = ymd(dateExpiry) %>% floor_date("month"),
      scrape_date  = ymd(datePreviousSettlement),
      scrape_time  = scrape_time,
      # choose price based on which date is more recent (trade preferred if tied)
      cash_rate    = if_else(
        !is.na(dateLastTrade) & ymd(dateLastTrade) >= ymd(datePreviousSettlement),
        100 - priceLastTrade,
        100 - pricePreviousSettlement
      ),
      cash_rate_PreviousSettlement = 100 - pricePreviousSettlement
    )
}

# daily_data/scraped_cash_rate_YYYY-MM-DD_HHMM.csv (Melbourne clock time).
scrape_file_path <- function(scrape_dt, dir = "daily_data") {
  file.path(dir, paste0("scraped_cash_rate_", format(scrape_dt, "%Y-%m-%d_%H%M"), ".csv"))
}

# Compact public feed for the main website's market-rate reference line.
# Preserve the ASX monthly-average rate definition; do not extend the horizon.
write_market_feed <- function(new_data, path = "docs/data/cash-rate-latest.json") {
  market_points <- new_data %>%
    filter(!is.na(date), is.finite(cash_rate)) %>%
    arrange(date) %>%
    transmute(month = format(date, "%Y-%m"), ratePct = cash_rate)
  stopifnot(nrow(market_points) >= 2, !anyDuplicated(market_points$month))
  market_feed <- list(
    schemaVersion = 1L,
    source = "igross/cash-rate-forecasts",
    sourceUrl = "https://github.com/igross/cash-rate-forecasts",
    definition = "ASX cash-rate futures-implied monthly average (100 minus contract price)",
    scrapedAt = format(max(new_data$scrape_time), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    quoteDate = format(max(c(ymd(new_data$dateLastTrade), new_data$scrape_date), na.rm = TRUE), "%Y-%m-%d"),
    points = market_points
  )
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  jsonlite::write_json(market_feed, path,
                       auto_unbox = TRUE, dataframe = "rows", digits = 15,
                       pretty = TRUE, na = "null")
  invisible(path)
}

# Read one daily_data CSV with Melbourne-time scrape timestamps.
read_scrape_file <- function(f) {
  df <- read_csv(f, col_types = cols())

  if (!"scrape_time" %in% names(df)) {
    # create a POSIXct NA in Melbourne time
    df$scrape_time <- as.POSIXct(NA, tz = "Australia/Melbourne")
  } else {
    # read_csv already parses ISO timestamps as instants. Reparsing their UTC
    # clock text as Melbourne time shifts observations by 10/11 hours.
    if (inherits(df$scrape_time, "POSIXt")) {
      df$scrape_time <- with_tz(df$scrape_time, "Australia/Melbourne")
    } else {
      df$scrape_time <- ymd_hms(df$scrape_time, tz = "Australia/Melbourne")
    }
  }

  df
}

# Row-wise type normalisation and filtering applied to the combined dataset.
clean_scrape_data <- function(df) {
  df %>%
    mutate(
      date        = as.Date(date),
      cash_rate   = as.double(cash_rate),
      scrape_date = as.Date(scrape_date),
      scrape_time = coalesce(
        scrape_time,
        as.POSIXct(scrape_date, tz = "Australia/Melbourne") + hours(12)
      )
    ) %>%
    filter(
      !scrape_date %in% excluded_scrape_dates,
      !is.na(scrape_date),
      !is.na(date),
      !is.na(cash_rate)
    )
}

# Full rebuild from every daily CSV (regular pipeline).
rebuild_all_data <- function(files) {
  files %>% map(read_scrape_file) %>% bind_rows() %>% clean_scrape_data()
}

# Incremental update: append only the given new CSV files. Because cleaning is
# row-wise and files are appended in filename (= chronological) order, the
# result equals rebuild_all_data() over all files.
append_scrape_files <- function(all_data, files) {
  new_rows <- rebuild_all_data(files)
  list(all_data = bind_rows(all_data, new_rows), new_rows = new_rows)
}

# Incremental update without a full rebuild: append every daily CSV that is
# newer than the dataset and not yet in it, in filename (chronological) order.
# The result equals rebuild_all_data() over all files (tested).
catch_up_dataset <- function(all_data, dir = "daily_data") {
  latest <- max(all_data$scrape_time, na.rm = TRUE)
  files <- sort(list.files(dir, pattern = "^scraped_cash_rate_.*[.]csv$", full.names = TRUE))
  stamp <- as.POSIXct(sub("^scraped_cash_rate_(.*)[.]csv$", "\\1", basename(files)),
                      format = "%Y-%m-%d_%H%M", tz = "Australia/Melbourne")
  cand <- files[!is.na(stamp) & stamp >= latest - 120]
  if (!length(cand)) return(list(all_data = all_data, files = character()))
  known <- unique(as.numeric(all_data$scrape_time))
  keep <- cand[vapply(cand, function(f) {
    st <- read_scrape_file(f)$scrape_time
    any(!is.na(st)) && !any(round(as.numeric(st)) %in% round(known))
  }, logical(1))]
  if (!length(keep)) return(list(all_data = all_data, files = character()))
  list(all_data = append_scrape_files(all_data, keep)$all_data, files = keep)
}

# Append new rows to combined_data/cash_rate.csv instead of rewriting 30+ MB.
# Falls back to a full rewrite if the header no longer matches the dataset.
append_cash_rate_csv <- function(all_data, new_rows, path = "combined_data/cash_rate.csv") {
  header <- if (file.exists(path)) names(read_csv(path, n_max = 0, col_types = cols(.default = "c"))) else character()
  if (identical(header, names(all_data)) && all(names(new_rows) %in% header)) {
    if (nrow(new_rows)) write_csv(new_rows[, header], path, append = TRUE, na = "NA")
    "appended"
  } else {
    write_csv(all_data, path)
    "rewritten"
  }
}

# Normalised fingerprint of the market information in a snapshot. Two
# snapshots with equal signatures carry no new market information.
market_signature <- function(df) {
  fields <- intersect(c("symbol", asx_market_fields), names(df))
  if (!"symbol" %in% fields) return(NA_character_)
  x <- as.data.frame(df)[, fields, drop = FALSE]
  x <- x[order(x$symbol), , drop = FALSE]
  norm <- function(v) {
    if (inherits(v, c("Date", "POSIXt"))) return(format(as.Date(v)))
    if (is.numeric(v)) return(ifelse(is.na(v), "NA", formatC(round(v, 6), format = "f", digits = 6)))
    v <- as.character(v)
    # JSON dates arrive as text; CSV round trips parse them to Date.
    is_date <- !is.na(v) & grepl("^\\d{4}-\\d{2}-\\d{2}", v)
    v[is_date] <- substr(v[is_date], 1, 10)
    ifelse(is.na(v), "NA", v)
  }
  paste(do.call(paste, c(lapply(x, norm), sep = "|")), collapse = "\n")
}
