library(conflicted)
conflict_prefer_all("dplyr", quiet = TRUE)

library(tidyverse)
library(lubridate)
library(jsonlite)

json_url <- "https://asx.api.markitdigital.com/asx-research/1.0/derivatives/interest-rate/IB/futures?days=1&height=179&width=179"

json_file <- tempfile()
download.file(json_url, json_file, quiet = TRUE)

# ── scrape today's data ────────────────────────────────────────────────
new_data <- jsonlite::fromJSON(json_file) |>
  pluck("data", "items") |>
  as_tibble() |>
  mutate(
    dateExpiry  = ymd(dateExpiry) |> floor_date("month"),
    scrape_time = now(tzone = "Australia/Melbourne"),
    cash_rate   = 100 - pricePreviousSettlement
  ) |>
  filter(pricePreviousSettlement != 0) |>
  mutate(scrape_date = as_date(scrape_time)) |>
  select(
    date  = dateExpiry,
    time  = scrape_time,
    cash_rate,
    scrape_date
  )

write_csv(
  new_data,
  file.path("daily_data",
            paste0("scraped_cash_rate_", Sys.Date(), ".csv"))
)

# ── load legacy files and combine ──────────────────────────────────────
all_old <- file.path("daily_data") |>
  list.files(pattern = "\\.csv$", full.names = TRUE) |>
  read_csv(col_types = cols(
    date        = col_date(),
    time        = col_datetime(),
    cash_rate   = col_double(),
    scrape_date = col_date()
  )) |>
  filter(
    !scrape_date %in% ymd(
      "2022-08-06", "2022-08-07", "2022-08-08",
      "2023-01-18", "2023-01-24", "2023-01-31",
      "2023-02-02", "2022-12-30", "2022-12-29"
    ),
    !is.na(date), !is.na(cash_rate)
  ) |>
  mutate(
    time = coalesce(
      time,
      as_datetime(paste(scrape_date, "00:00:00"),
                  tz = "Australia/Melbourne")
    )
  )

combined <- bind_rows(all_old, new_data)

dir.create("combined_data", showWarnings = FALSE)
saveRDS(combined, file = "combined_data/all_data.Rds")
write_csv(combined, file = "combined_data/cash_rate.csv")
