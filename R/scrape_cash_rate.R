library(conflicted)
conflict_prefer_all("dplyr", quiet = TRUE)
library(tidyverse)
library(jsonlite)
library(lubridate)

cat("=== STEP 1: CLEANING WEEKEND FILES ===\n")

# list all CSVs in daily_data
old_csvs <- list.files(
  path       = "daily_data",
  pattern    = "\\.csv$",
  full.names = TRUE
)

cat("Total CSV files found:", length(old_csvs), "\n")

dates_in_name <- str_match(basename(old_csvs),
                           "scraped_cash_rate_(\\d{4}-\\d{2}-\\d{2})")[,2]

# 3. parse to Date
file_dates <- as.Date(dates_in_name, format = "%Y-%m-%d")

cat("Successfully parsed dates:", sum(!is.na(file_dates)), "\n")
cat("Failed to parse dates:", sum(is.na(file_dates)), "\n")

# 4. compute cutoff
is_weekend   <- !is.na(file_dates) & lubridate::wday(file_dates) %in% c(1, 7)
to_remove    <- old_csvs[is_weekend]

cat("Weekend files to remove:", length(to_remove), "\n")
if (length(to_remove) > 0) {
  cat("Removing files:\n")
  print(basename(to_remove))
  file.remove(to_remove)
}

cat("\n=== STEP 2: DOWNLOADING NEW DATA ===\n")

json_url <- "https://asx.api.markitdigital.com/asx-research/1.0/derivatives/interest-rate/IB/futures?days=1&height=179&width=179"
json_file <- tempfile()

tryCatch({
  download.file(json_url, json_file, quiet = TRUE)
  cat("✓ Successfully downloaded JSON data\n")
}, error = function(e) {
  cat("✗ ERROR downloading JSON:", e$message, "\n")
  stop("Download failed")
})

tryCatch({
  raw_json <- fromJSON(json_file)
  cat("✓ Successfully parsed JSON\n")
  
  items <- pluck(raw_json, "data", "items")
  cat("  Items found in JSON:", nrow(items), "\n")
  
  new_data <- items %>% 
    as_tibble() %>% 
    mutate(
      date         = ymd(dateExpiry) %>% floor_date("month"),
      scrape_date  = ymd(datePreviousSettlement),
      scrape_time  = now(tzone = "Australia/Melbourne"),
      cash_rate    = 100 - coalesce(priceLastTrade, pricePreviousSettlement)
    )
  
  cat("  Data after initial processing:", nrow(new_data), "rows\n")
  
  new_data <- new_data %>%
    filter(pricePreviousSettlement != 0) %>%
    select(date, cash_rate, scrape_date, scrape_time)
  
  cat("  Data after filtering zeros:", nrow(new_data), "rows\n")
  cat("  Date range:", as.character(min(new_data$date)), "to", as.character(max(new_data$date)), "\n")
  cat("  Scrape time:", as.character(unique(new_data$scrape_time)), "\n")
  
}, error = function(e) {
  cat("✗ ERROR processing JSON:", e$message, "\n")
  stop("JSON processing failed")
})

print(new_data)

cat("\n=== STEP 3: SAVING NEW DATA ===\n")

scrape_dt <- unique(new_data$scrape_time)

if (length(scrape_dt) != 1) {
  cat("⚠ Warning: Multiple scrape times found, using fallback\n")
  scrape_dt <- Sys.Date() - 1
}

scrape_str <- format(scrape_dt, "%Y-%m-%d_%H%M")
out_file <- file.path("daily_data", paste0("scraped_cash_rate_", scrape_str, ".csv"))

tryCatch({
  write_csv(new_data, out_file)
  cat("✓ Saved:", out_file, "\n")
}, error = function(e) {
  cat("✗ ERROR saving CSV:", e$message, "\n")
})

cat("\n=== STEP 4: COMBINING ALL DATA ===\n")

library(purrr)
library(readr)

files <- list.files(
  path       = "daily_data",
  pattern    = "\\.csv$",
  full.names = TRUE
)

cat("Total files to process:", length(files), "\n")

# Track processing stats
successful_reads <- 0
failed_reads <- 0
missing_scrape_time <- 0

df_list <- files %>% map(function(f) {
  tryCatch({
    df <- read_csv(f, col_types = cols(), show_col_types = FALSE)
    successful_reads <<- successful_reads + 1
    
    if (!"scrape_time" %in% names(df)) {
      missing_scrape_time <<- missing_scrape_time + 1
      df$scrape_time <- as.POSIXct(NA, tz = "Australia/Melbourne")
    } else {
      df <- df %>%
        mutate(scrape_time = ymd_hms(scrape_time, tz = "Australia/Melbourne"))
    }
    
    df
  }, error = function(e) {
    failed_reads <<- failed_reads + 1
    cat("  ✗ Failed to read:", basename(f), "-", e$message, "\n")
    return(NULL)
  })
})

cat("Successfully read:", successful_reads, "files\n")
cat("Failed to read:", failed_reads, "files\n")
cat("Files missing scrape_time:", missing_scrape_time, "\n")

# Remove NULL entries from failed reads
df_list <- compact(df_list)

cat("\n=== STEP 5: DATA CLEANING ===\n")

all_data_raw <- bind_rows(df_list)
cat("Total rows before cleaning:", nrow(all_data_raw), "\n")

all_data <- all_data_raw %>%
  mutate(
    date        = as.Date(date),
    cash_rate   = as.double(cash_rate),
    scrape_date = as.Date(scrape_date),
    scrape_time = if_else(
      is.na(scrape_time),
      as.POSIXct(paste(scrape_date, "12:00:00"),
                 tz = "Australia/Melbourne"),
      scrape_time
    )
  )

cat("Rows with NA date:", sum(is.na(all_data$date)), "\n")
cat("Rows with NA cash_rate:", sum(is.na(all_data$cash_rate)), "\n")
cat("Rows with NA scrape_date:", sum(is.na(all_data$scrape_date)), "\n")

excluded_dates <- ymd(c(
  "2022-08-06","2022-08-07","2022-08-08",
  "2023-01-18","2023-01-24","2023-01-31",
  "2023-02-02","2022-12-30","2022-12-29"
))

rows_excluded_dates <- sum(all_data$scrape_date %in% excluded_dates, na.rm = TRUE)
cat("Rows with excluded scrape_dates:", rows_excluded_dates, "\n")

all_data <- all_data %>%
  filter(
    !scrape_date %in% excluded_dates,
    !is.na(date),
    !is.na(cash_rate)
  )

cat("Total rows after cleaning:", nrow(all_data), "\n")

cat("\n=== DATA SUMMARY ===\n")
cat("Date range:", as.character(min(all_data$date)), "to", as.character(max(all_data$date)), "\n")
cat("Scrape date range:", as.character(min(all_data$scrape_date)), "to", as.character(max(all_data$scrape_date)), "\n")
cat("Unique dates:", n_distinct(all_data$date), "\n")
cat("Unique scrape_dates:", n_distinct(all_data$scrape_date), "\n")
cat("Unique scrape_times:", n_distinct(all_data$scrape_time), "\n")
cat("Cash rate range:", min(all_data$cash_rate), "to", max(all_data$cash_rate), "\n")

cat("\nLast 20 rows:\n")
print(tail(all_data, 20))

cat("\n=== STEP 6: SAVING COMBINED DATA ===\n")

if (!dir.exists("combined_data")) {
  dir.create("combined_data", recursive = TRUE)
  cat("Created combined_data directory\n")
}

tryCatch({
  saveRDS(all_data, file = "combined_data/all_data.Rds")
  cat("✓ Saved: combined_data/all_data.Rds\n")
}, error = function(e) {
  cat("✗ ERROR saving RDS:", e$message, "\n")
})

tryCatch({
  write_csv(all_data, file = "combined_data/cash_rate.csv")
  cat("✓ Saved: combined_data/cash_rate.csv\n")
}, error = function(e) {
  cat("✗ ERROR saving CSV:", e$message, "\n")
})

cat("\n=== PIPELINE COMPLETE ===\n")
cat("Final dataset: ", nrow(all_data), " rows, ", ncol(all_data), " columns\n")
