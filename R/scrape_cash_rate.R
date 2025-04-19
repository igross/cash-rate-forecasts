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

# read + combine all snapshots
all_data <- list.files(
    path       = "daily_data",
    pattern    = "\\.csv$",
    full.names = TRUE
  ) %>%
  read_csv(col_types = cols(
    date        = col_date(),
    cash_rate   = col_double(),
    scrape_date = col_date(),
    # ensure we parse using Melbourne tz
    scrape_time = col_datetime(format = "", tz = "Australia/Melbourne")
  )) %>%
  filter(
    !scrape_date %in% ymd(c(
      "2022-08-06","2022-08-07","2022-08-08",
      "2023-01-18","2023-01-24","2023-01-31",
      "2023-02-02","2022-12-30","2022-12-29"
    )),
    !is.na(date),
    !is.na(cash_rate)
  )


all_data <- all_data %>%
  mutate(
    scrape_time = if_else(
      is.na(scrape_time),
      # build a POSIXct at 12:00:00 on the scrape_date in Melbourne TZ
      as.POSIXct(paste(scrape_date, "12:00:00"),
                 tz = "Australia/Melbourne"),
      scrape_time
    )
  )

# save for downstream work
saveRDS(all_data, file = "combined_data/all_data.Rds")
write_csv(all_data, file = "combined_data/cash_rate.csv")
