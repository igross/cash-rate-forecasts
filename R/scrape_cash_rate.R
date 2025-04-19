library(conflicted)
conflict_prefer_all("dplyr", quiet = TRUE)
library(tidyverse)
library(jsonlite)

json_url <- "https://asx.api.markitdigital.com/asx-research/1.0/derivatives/interest-rate/IB/futures?days=1&height=179&width=179"

json_file <- tempfile()

# download and parse
download.file(json_url, json_file)
new_data <- fromJSON(json_file) %>%
  pluck("data", "items") %>%
  as_tibble() %>%
  mutate(
    # define `date` straight away, floor to start of month
    date         = ymd(dateExpiry) %>% floor_date("month"),
    scrape_date  = ymd(datePreviousSettlement),
    scrape_time  = now(tzone = "Australia/Melbourne"),
    cash_rate    = 100 - pricePreviousSettlement
  ) %>%
  filter(pricePreviousSettlement != 0) %>%
  select(date, cash_rate, scrape_date, scrape_time)


write_csv(
  new_data,
  file.path("daily_data", paste0("scraped_cash_rate_", Sys.Date() - 1, ".csv"))
)

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

# 6. save
saveRDS(all_data, file = "combined_data/all_data.Rds")
write_csv(all_data,  file = "combined_data/cash_rate.csv")

