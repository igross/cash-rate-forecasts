library(conflicted)
conflict_prefer_all("dplyr", quiet = TRUE)

library(tidyverse)
library(lubridate)          # <‑‑ you need this for ymd(), floor_date(), now()
library(jsonlite)

json_url <- "https://asx.api.markitdigital.com/asx-research/1.0/derivatives/interest-rate/IB/futures?days=1&height=179&width=179"

json_file <- tempfile()
download.file(json_url, json_file, quiet = TRUE)

# ── 1  scrape today’s data ──────────────────────────────────────────────
new_data <- jsonlite::fromJSON(json_file) |>
  pluck("data", "items") |>
  as_tibble() |>
  mutate(
    dateExpiry  = ymd(dateExpiry) |> floor_date("month"),
    scrape_time = now(tzone = "Australia/Melbourne")
  ) |>
  filter(pricePreviousSettlement != 0) |>
  mutate(cash_rate = 100 - pricePreviousSettlement) |>
  select(
    date        = dateExpiry,
    cash_rate,
    scrape_date = date(scrape_time),
    time        = scrape_time       # <‑‑ keep the timestamp column
  )

# write the daily CSV so every scrape is archived
write_csv(
  new_data,
  file.path("daily_data",
            paste0("scraped_cash_rate_", Sys.Date(), ".csv"))
)

# ── 2  load legacy files (some lack the time column) ────────────────────
all_old <- file.path("daily_data") |>
  list.files(pattern = "\\.csv$", full.names = TRUE) |>
  read_csv(
    # allow for the new 'time' column; missing values in old files become NA
    col_types = cols(
      date        = col_date(),
      time        = col_datetime(format = ""),  # will be NA for legacy rows
      cash_rate   = col_double(),
      scrape_date = col_date()
    )
  ) |>
  filter(
    !scrape_date %in% ymd(
      "2022-08-06", "2022-08-07", "2022-08-08",
      "2023-01-18", "2023-01-24", "2023-01-31",
      "2023-02-02", "2022-12-30", "2022-12-29"
    ),
    !is.na(date), !is.na(cash_rate)
  ) |>
  # give NA timestamps a dummy midnight so type is consistent
  mutate(
    time = coalesce(
      time,
      as_datetime(paste(scrape_date, "00:00:00"),
                  tz = "Australia/Melbourne")
    )
  )

# ── 3  combine and save ─────────────────────────────────────────────────
combined <- bind_rows(all_old, new_data)

dir.create("combined_data", showWarnings = FALSE)
saveRDS(combined, file = "combined_data/all_data.Rds")
write_csv(combined, file = "combined_data/cash_rate.csv")
