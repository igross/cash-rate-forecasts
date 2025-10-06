library(conflicted)
conflict_prefer_all("dplyr", quiet = TRUE)
library(tidyverse)
library(jsonlite)
library(lubridate)



# Delete scrape data files before May 2025
library(lubridate)
library(dplyr)

cutoff_date <- as.Date("2025-05-01")
# Path to your scrape data (adjust as needed)
scrape_data_path <- "daily_data/"

# Get all files ending in 1200.csv
csv_files <- list.files(scrape_data_path, pattern = "1200\\.csv$", full.names = TRUE)

cat("Found", length(csv_files), "files ending in 1200.csv\n")

# Delete each file
for (file in csv_files) {
  cat("Deleting:", file, "\n")
  file.remove(file)
}

cat("Deletion complete!\n")

json_url <- "https://asx.api.markitdigital.com/asx-research/1.0/derivatives/interest-rate/IB/futures?days=1&height=179&width=179"
json_file <- tempfile()

# download and parse
download.file(json_url, json_file)
new_data <- fromJSON(json_file) %>% 
  pluck("data", "items") %>% 
  as_tibble() %>% 
  mutate(
    # floor expiry to the month start
    date         = ymd(dateExpiry) %>% floor_date("month"),
    scrape_date  = ymd(datePreviousSettlement),
    scrape_time  = now(tzone = "Australia/Melbourne"),
    # ← fallback: if priceLastTrade is NA, use pricePreviousSettlement
    cash_rate    = 100 - coalesce(priceLastTrade, pricePreviousSettlement)
  ) %>% 
  filter(pricePreviousSettlement != 0) %>%   # keep this guard if you still
  select(date, cash_rate, scrape_date, scrape_time)


print(new_data)

# after you have new_data

# 1. Grab the single scrape_time (they should all be the same)
scrape_dt <- unique(new_data$scrape_time)

# 2. If for some reason there's more than one, fall back to Sys.Date()-1
if (length(scrape_dt) != 1) {
  scrape_dt <- Sys.Date() - 1
}

# 3. Format as YYYY-MM-DD
scrape_str <- format(scrape_dt, "%Y-%m-%d_%H%M")

# 4. Build a single file name
out_file <- file.path(
  "daily_data",
  paste0("scraped_cash_rate_", scrape_str, ".csv")
)

# 5. Write the CSV once
write_csv(new_data, out_file)


library(purrr)
library(readr)
library(dplyr)
library(lubridate)

# 1. list your files
files <- list.files(
  path       = "daily_data",
  pattern    = "\\.csv$",
  full.names = TRUE
)

df_list <- files %>% map(function(f) {
  df <- read_csv(f, col_types = cols())

  if (!"scrape_time" %in% names(df)) {
    # create a POSIXct NA in Melbourne time
    df$scrape_time <- as.POSIXct(NA, tz = "Australia/Melbourne")
  } else {
    # parse any existing scrape_time strings into POSIXct in Melbourne time
    df <- df %>%
      mutate(scrape_time = ymd_hms(scrape_time, tz = "Australia/Melbourne"))
  }

  df
})


# 3. bind them into one data‑frame
all_data <- bind_rows(df_list) %>%
  mutate(
    date        = as.Date(date),
    cash_rate   = as.double(cash_rate),    # ← use as.double()
    scrape_date = as.Date(scrape_date),
    scrape_time = if_else(
      is.na(scrape_time),
      as.POSIXct(paste(scrape_date, "12:00:00"),
                 tz = "Australia/Melbourne"),
      scrape_time
    )
  ) %>%
  filter(
    !scrape_date %in% ymd(c(
      "2022-08-06","2022-08-07","2022-08-08",
      "2023-01-18","2023-01-24","2023-01-31",
      "2023-02-02","2022-12-30","2022-12-29"
    )),
    !is.na(date),
    !is.na(cash_rate)
  )

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
archive_data <- readRDS("combined_data/archieve.Rds")

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
