# Run from the repository root: Rscript tests/test-forecast-window.R
suppressPackageStartupMessages(library(lubridate))
expressions <- as.list(parse("R/actual_vs_implied.R"))
assignment <- Filter(function(e) is.call(e) &&
  identical(e[[1]], as.name("<-")) && identical(e[[2]], as.name("x_end")),
  expressions)
stopifnot(length(assignment) == 1L)

cases <- data.frame(
  start = as.Date(c("2026-10-31", "2026-08-31", "2025-08-31",
                    "2024-02-29", "2026-01-31", "2026-10-15")),
  expected = as.Date(c("2028-04-30", "2028-02-29", "2027-02-28",
                       "2025-08-29", "2027-07-31", "2028-04-15"))
)
stopifnot(is.na(cases$start[1] + months(18)))
for (i in seq_len(nrow(cases))) {
  latest_scrape_date <- cases$start[i]
  eval(assignment[[1]])
  stopifnot(!is.na(x_end), identical(x_end, cases$expected[i]))
}
cat("PASS: forecast window covers month ends, leap years and ordinary dates\n")
