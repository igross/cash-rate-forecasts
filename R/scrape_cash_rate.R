ensure_packages <- function(pkgs) {
  missing_pkgs <- pkgs[!pkgs %in% rownames(installed.packages())]

  if (length(missing_pkgs) > 0) {
        # Use session repos (RSPM in GitHub Actions) with CRAN fallback
    repos <- getOption("repos")
    if (is.null(repos) || repos["CRAN"] == "@CRAN@") {
      repos <- "https://cloud.r-project.org"
    }
    install.packages(missing_pkgs, repos = repos)
  }
}

ensure_packages(c(
  "conflicted",
  "memoise",
  "tidyverse",
  "jsonlite",
  "lubridate",
  "R6",
  "bit",
  "bit64",
  "gtable",
    "dplyr"
))

library(conflicted)
conflict_prefer_all("dplyr", quiet = TRUE)
library(tidyverse)
library(jsonlite)
library(lubridate)


source("R/market_data.R")  # shared with the rapid ABS release mode

json_url <- asx_futures_url
json_file <- tempfile()

# download and parse
download.file(json_url, json_file)
new_data <- parse_asx_futures(json_file, scrape_time = now(tzone = "Australia/Melbourne"))


print(new_data)

# after you have new_data

# 1. Grab the single scrape_time (they should all be the same)
scrape_dt <- unique(new_data$scrape_time)

# 2. If for some reason there's more than one, fall back to Sys.Date()-1
if (length(scrape_dt) != 1) {
  scrape_dt <- Sys.Date() - 1
}

# 3-4. Build a single file name (YYYY-MM-DD_HHMM)
out_file <- scrape_file_path(scrape_dt)

# 5. Write the CSV once
write_csv(new_data, out_file)

# Compact public feed for the main website's market-rate reference line.
write_market_feed(new_data, "docs/data/cash-rate-latest.json")


# 1. list your files
files <- list.files(
  path       = "daily_data",
  pattern    = "\\.csv$",
  full.names = TRUE
)

# 2-3. read every file and bind them into one data-frame (full rebuild)
all_data <- rebuild_all_data(files)

# 5. ensure the output folder exists
if (!dir.exists("combined_data")) {
  dir.create("combined_data", recursive = TRUE)
}

tail(all_data,20)

# 6. save
saveRDS(all_data, file = "combined_data/all_data.Rds")
write_csv(all_data,  file = "combined_data/cash_rate.csv")


# =============================================
# Convert archive.Rds to daily_data format
# =============================================

library(dplyr)
library(lubridate)
library(readr)

# Read the archive file
archive_data <- readRDS("combined_data/Archive.Rds")

# Filter to only dates prior to 2025-05-26
cutoff_date <- as.Date("2025-05-26")

archive_data %>%
  filter(scrape_date < cutoff_date) %>%
  group_by(scrape_date) %>%
  group_split() %>%
  walk(function(scrape_group) {
    
    # Get the scrape date
    scrape_date <- unique(scrape_group$scrape_date)
    
    # Create scrape_time: assume noon (12:00:00) in UTC
    scrape_time <- ymd_hms(paste0(scrape_date, " 12:00:00"), tz = "UTC")
    
    # Format the scrape_time as ISO 8601 with Z suffix
    scrape_time_str <- format(scrape_time, "%Y-%m-%dT%H:%M:%SZ")
    
    # Add scrape_time column to the data
    output_data <- scrape_group %>%
      mutate(scrape_time = scrape_time_str) %>%
      select(date, cash_rate, scrape_date, scrape_time)
    
    # Create filename: scraped_cash_rate_YYYY-MM-DD_HHMM.csv
    # Extract time components for filename (in UTC, so 1200 for noon)
    filename <- sprintf("daily_data/scraped_cash_rate_%s_%s.csv",
                       format(scrape_date, "%Y-%m-%d"),
                       format(scrape_time, "%H%M"))
    
    # Ensure directory exists
    
    # Write to CSV
    write_csv(output_data, filename)
    
    cat("Created:", filename, "\n")
  })

cat("\nConversion complete!\n")
