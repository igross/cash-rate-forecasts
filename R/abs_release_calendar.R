# ==============================================================================
# ABS economic data release calendar
# ==============================================================================
# Base R only (no package dependencies) so the GitHub Actions gate can decide
# whether today is a release day before any packages are installed.
#
# Sources, unioned:
#   1. combined_data/abs_release_calendar.csv  - maintained automatically from
#      the ABS future-releases calendar (refresh_abs_calendar()), seeded from
#      the release dates already maintained in this repository.
#   2. the `abs_releases` table in R/line_chart.R (the existing hand-maintained
#      calendar that draws release markers on the line chart).
#
# All release times are Melbourne (= Canberra) local clock times; conversion to
# instants goes through the Australia/Melbourne tz database entry, so daylight
# saving is handled automatically.
#
# CLI (used by .github/workflows):
#   Rscript R/abs_release_calendar.R gate --from 10:30 --to 12:00
#   Rscript R/abs_release_calendar.R window --from 10:40 --to 11:50
#   Rscript R/abs_release_calendar.R refresh
#   Rscript R/abs_release_calendar.R history --from 2021-12   (one-off backfill)
# ==============================================================================

abs_tz <- "Australia/Melbourne"
abs_calendar_file <- "combined_data/abs_release_calendar.csv"
abs_source <- "abs.gov.au release calendar"
abs_page_source <- "abs.gov.au release page"
abs_authoritative <- c(abs_source, abs_page_source)
abs_calendar_cols <- c("dataset", "release_date", "release_time", "title", "source", "updated_at")

# Economically significant releases that trigger the rapid-update mode.
abs_significant_datasets <- c(
  "CPI", "CPI Indicator", "Labour Force", "National Accounts", "WPI",
  "Household Spending", "Retail Trade"
)

# ABS release titles -> dataset labels used throughout the repository.
abs_title_patterns <- c(
  "CPI Indicator"      = "Monthly Consumer Price Index Indicator",
  "CPI"                = "^Consumer Price Index, Australia",
  "Labour Force"       = "^Labour Force, Australia$",
  "WPI"                = "^Wage Price Index, Australia",
  "National Accounts"  = "^Australian National Accounts: National Income, Expenditure and Product",
  "Household Spending" = "Household Spending Indicator",
  "Retail Trade"       = "^Retail Trade, Australia$"
)

empty_calendar <- function() {
  as.data.frame(setNames(replicate(length(abs_calendar_cols), character(), simplify = FALSE),
                         abs_calendar_cols), stringsAsFactors = FALSE)
}

normalise_calendar <- function(x) {
  if (is.null(x) || !nrow(x)) return(empty_calendar())
  for (col in setdiff(abs_calendar_cols, names(x))) x[[col]] <- NA_character_
  x <- x[, abs_calendar_cols]
  x[] <- lapply(x, as.character)
  x$release_date <- format(as.Date(x$release_date))
  x$release_time <- ifelse(is.na(x$release_time) | x$release_time == "", "11:30", substr(x$release_time, 1, 5))
  x <- x[!is.na(x$release_date) & !is.na(x$dataset), , drop = FALSE]
  # On duplicates keep the ABS-sourced row (authoritative), then any other.
  x <- x[order(x$release_date, x$dataset, !x$source %in% abs_authoritative), , drop = FALSE]
  x <- x[!duplicated(x[, c("dataset", "release_date")]), , drop = FALSE]
  rownames(x) <- NULL
  x
}

read_abs_calendar_file <- function(path = abs_calendar_file) {
  if (!file.exists(path)) return(empty_calendar())
  normalise_calendar(utils::read.csv(path, colClasses = "character", na.strings = c("", "NA")))
}

write_abs_calendar_file <- function(x, path = abs_calendar_file) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(normalise_calendar(x), path, row.names = FALSE, na = "")
  invisible(path)
}

# Evaluate the `abs_releases` table from R/line_chart.R with base-R shims for
# tribble()/ymd_hm(), so the existing calendar is reused without loading
# packages or running the chart script.
line_chart_abs_releases <- function(path = "R/line_chart.R", name = "abs_releases") {
  if (!file.exists(path)) return(empty_calendar())
  exprs <- as.list(parse(path))
  hit <- Filter(function(e) is.call(e) && identical(e[[1]], as.name("<-")) &&
                  identical(e[[2]], as.name(name)), exprs)
  if (!length(hit)) return(empty_calendar())
  env <- new.env(parent = baseenv())
  env$ymd_hm <- function(x, tz = "UTC") as.POSIXct(x, format = "%Y-%m-%d %H:%M", tz = tz)
  env$tribble <- function(...) {
    args <- list(...)
    is_header <- vapply(args, function(a) inherits(a, "formula"), logical(1))
    cols <- vapply(args[is_header], function(f) as.character(f[[2]]), character(1))
    vals <- args[!is_header]
    n <- length(vals) / length(cols)
    out <- lapply(seq_along(cols), function(j) do.call(c, vals[seq(j, by = length(cols), length.out = n)]))
    names(out) <- cols
    out
  }
  tab <- eval(hit[[1]][[3]], env)
  dt <- tab$datetime
  normalise_calendar(data.frame(
    dataset = tab$dataset,
    release_date = format(dt, "%Y-%m-%d", tz = abs_tz),
    release_time = format(dt, "%H:%M", tz = abs_tz),
    title = NA_character_, source = path, updated_at = NA_character_,
    stringsAsFactors = FALSE
  ))
}

# Dates read from abs.gov.au (future-releases calendar or individual release
# pages) are authoritative. Within the date range they cover for a dataset,
# hand-maintained dates they do not confirm (typos, rescheduled releases) are
# dropped; outside that range hand-maintained dates are kept.
resolve_calendar_conflicts <- function(x, today = melbourne_date()) {
  auth <- x[x$source %in% abs_authoritative, , drop = FALSE]
  if (!nrow(auth)) return(x)
  ad <- as.Date(auth$release_date)
  # A future-calendar range starts today; release-page history covers its span.
  lo <- tapply(ifelse(auth$source == abs_source, pmin(as.numeric(ad), as.numeric(today)), as.numeric(ad)), auth$dataset, min)
  hi <- tapply(as.numeric(ad), auth$dataset, max)
  d <- as.numeric(as.Date(x$release_date))
  superseded <- !(x$source %in% abs_authoritative) & x$dataset %in% names(hi) &
    d >= lo[x$dataset] & d <= hi[x$dataset]
  x[!superseded %in% TRUE, , drop = FALSE]
}

load_abs_calendar <- function(path = abs_calendar_file, line_chart = "R/line_chart.R", today = melbourne_date()) {
  existing <- tryCatch(line_chart_abs_releases(line_chart), error = function(e) {
    message("Could not read release table from ", line_chart, ": ", conditionMessage(e))
    empty_calendar()
  })
  resolve_calendar_conflicts(normalise_calendar(rbind(read_abs_calendar_file(path), existing)), today)
}

melbourne_date <- function(now = Sys.time()) as.Date(format(now, "%Y-%m-%d", tz = abs_tz))

# Significant releases scheduled for a Melbourne calendar date.
abs_releases_on <- function(date, calendar = load_abs_calendar()) {
  date <- format(as.Date(date))
  calendar[calendar$release_date == date & calendar$dataset %in% abs_significant_datasets, , drop = FALSE]
}

# Wall-clock slot times (Melbourne local) on a date -> POSIXct instants. The tz
# database supplies AEST (UTC+10) or AEDT (UTC+11) for that particular date.
rapid_slot_times <- function(date, times = c("11:30", "11:32", "11:34", "11:36", "11:38")) {
  as.POSIXct(paste(format(as.Date(date)), times), format = "%Y-%m-%d %H:%M", tz = abs_tz)
}

# Is `now` within [from, to] Melbourne time on a release day?
in_rapid_window <- function(now = Sys.time(), calendar = load_abs_calendar(),
                            from = "10:40", to = "11:50") {
  day <- melbourne_date(now)
  if (!nrow(abs_releases_on(day, calendar))) return(FALSE)
  bounds <- rapid_slot_times(day, c(from, to))
  now >= bounds[1] && now <= bounds[2]
}

# Has a scheduled rapid-update session already produced updates for this
# release date? (combined_data/rapid_update_log.csv, written by R/rapid_update.R)
rapid_session_logged <- function(date, log_file = "combined_data/rapid_update_log.csv",
                                 log = if (file.exists(log_file)) utils::read.csv(log_file, colClasses = "character") else NULL) {
  if (is.null(log) || !nrow(log)) return(FALSE)
  any(log$release_date == format(as.Date(date)) & log$mode == "release" & log$iteration != "0" &
        !log$status %in% c("missed", "failed"), na.rm = TRUE)
}

# Future coverage per dataset, used to warn when the calendar runs dry.
abs_calendar_coverage <- function(calendar = load_abs_calendar(), today = melbourne_date()) {
  sig <- calendar[calendar$dataset %in% abs_significant_datasets &
                    as.Date(calendar$release_date) >= today, , drop = FALSE]
  if (!nrow(sig)) return(data.frame(dataset = character(), next_release = character(), last_release = character()))
  do.call(rbind, lapply(split(sig, sig$dataset), function(d) data.frame(
    dataset = d$dataset[1], next_release = min(d$release_date), last_release = max(d$release_date))))
}

# ------------------------------------------------------------------------------
# Automatic maintenance from the ABS future-releases calendar
# ------------------------------------------------------------------------------

html_to_text <- function(x) {
  x <- gsub("(?s)<(script|style)[^>]*>.*?</\\1>", " ", x, perl = TRUE)
  x <- gsub("<[^>]+>", " ", x)
  x <- gsub("&amp;", "&", x, fixed = TRUE)
  x <- gsub("&nbsp;|&#160;", " ", x)
  trimws(gsub("[[:space:]]+", " ", x))
}

# Extract the first release date/time in a fragment of an ABS calendar page.
# Accepts <time datetime="..."> attributes, dd/mm/yyyy and "d Month yyyy".
parse_release_datetime <- function(fragment) {
  iso <- regmatches(fragment, regexpr('datetime="[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9:]{5}[^"]*"', fragment))
  if (length(iso)) {
    stamp <- sub('^datetime="([^"]+)"$', "\\1", iso)
    utc <- grepl("(Z|[+-]00:?00)$", stamp)
    t <- as.POSIXct(substr(stamp, 1, 16), format = "%Y-%m-%dT%H:%M", tz = if (utc) "UTC" else abs_tz)
    if (!is.na(t)) return(list(date = format(t, "%Y-%m-%d", tz = abs_tz), time = format(t, "%H:%M", tz = abs_tz)))
  }
  text <- html_to_text(fragment)
  time <- regmatches(text, regexpr("\\b[0-9]{1,2}[:.][0-9]{2} ?[ap]m\\b", text, ignore.case = TRUE))
  hhmm <- "11:30"
  if (length(time)) {
    p <- as.POSIXct(paste("2000-01-01", toupper(gsub("[.] ?", ":", sub(" ", "", time)))), format = "%Y-%m-%d %I:%M%p", tz = "UTC")
    if (!is.na(p)) hhmm <- format(p, "%H:%M")
  }
  dmy <- regmatches(text, regexpr("\\b[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}\\b", text))
  if (length(dmy)) {
    d <- as.Date(dmy, format = "%d/%m/%Y")
    if (!is.na(d)) return(list(date = format(d), time = hhmm))
  }
  long <- regmatches(text, regexpr(paste0("\\b[0-9]{1,2} (", paste(month.name, collapse = "|"), ") [0-9]{4}\\b"), text))
  if (length(long)) {
    d <- as.Date(long, format = "%d %B %Y")
    if (!is.na(d)) return(list(date = format(d), time = hhmm))
  }
  NULL
}

# Parse one ABS calendar page into calendar rows. Each release entry is a
# block containing exactly one recognised release title and a date; blocks
# naming several different releases are skipped rather than guessed.
parse_abs_calendar_page <- function(html, retrieved_at = Sys.time()) {
  splitter <- if (grepl("views-row", html, fixed = TRUE)) "<div[^>]*views-row" else "<(li|article|tr)[ >]"
  blocks <- strsplit(html, splitter, perl = TRUE)[[1]]
  rows <- lapply(blocks, function(b) {
    anchors <- regmatches(b, gregexpr("(?s)<(a|h[1-6])[^>]*>.*?</\\1>", b, perl = TRUE))[[1]]
    titles <- unique(vapply(anchors, html_to_text, character(1)))
    datasets <- unique(unlist(lapply(titles, function(t)
      names(abs_title_patterns)[vapply(abs_title_patterns, grepl, logical(1), x = t)])))
    if (length(datasets) != 1) return(NULL)
    when <- parse_release_datetime(b)
    if (is.null(when)) return(NULL)
    title <- titles[vapply(titles, grepl, logical(1), pattern = abs_title_patterns[[datasets]])][1]
    data.frame(dataset = datasets, release_date = when$date, release_time = when$time,
               title = title, source = abs_source,
               updated_at = format(retrieved_at, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
               stringsAsFactors = FALSE)
  })
  normalise_calendar(do.call(rbind, rows))
}

fetch_url_text <- function(url, timeout = 30) {
  old <- options(timeout = timeout); on.exit(options(old))
  f <- tempfile(); on.exit(unlink(f), add = TRUE)
  utils::download.file(url, f, quiet = TRUE, headers = c("User-Agent" = "cash-rate-forecasts release calendar"))
  paste(readLines(f, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

# Refresh the calendar file from the ABS website and the existing line-chart
# table. Never removes entries if the ABS page cannot be read or parsed.
refresh_abs_calendar <- function(path = abs_calendar_file, fetch = fetch_url_text,
                                 base_url = "https://www.abs.gov.au/release-calendar/future-releases",
                                 max_months = 9, now = Sys.time()) {
  current <- read_abs_calendar_file(path)
  scraped <- list()
  # The calendar is published one page per month: <base_url>/YYYYMM.
  first_month <- as.Date(format(melbourne_date(now), "%Y-%m-01"))
  months <- seq(first_month, by = "month", length.out = max_months)
  for (m in format(months, "%Y%m")) {
    url <- paste0(base_url, "/", m)
    html <- tryCatch(fetch(url), error = function(e) {
      message("ABS calendar fetch failed (", url, "): ", conditionMessage(e)); NULL })
    if (is.null(html) || !grepl("views-row", html, fixed = TRUE)) break   # beyond the published horizon
    scraped[[length(scraped) + 1L]] <- parse_abs_calendar_page(html, now)
  }
  scraped <- normalise_calendar(do.call(rbind, scraped))
  today <- melbourne_date(now)
  scraped <- scraped[as.Date(scraped$release_date) >= today - 1 &
                       as.Date(scraped$release_date) <= today + 550, , drop = FALSE]
  message("ABS calendar: parsed ", nrow(scraped), " significant future releases from abs.gov.au")
  if (nrow(scraped)) {
    # Future entries for a dataset the ABS page now lists are superseded by the
    # ABS dates (handles rescheduling); past entries are kept as history.
    covered <- unique(scraped$dataset)
    stale <- current$dataset %in% covered & as.Date(current$release_date) >= today &
      current$source %in% abs_source
    current <- current[!stale, , drop = FALSE]
  }
  existing <- tryCatch(line_chart_abs_releases(), error = function(e) empty_calendar())
  merged <- resolve_calendar_conflicts(normalise_calendar(rbind(scraped, current, existing)), today)
  write_abs_calendar_file(merged, path)
  cov <- abs_calendar_coverage(merged, today)
  for (ds in setdiff(c("CPI", "Labour Force", "National Accounts", "WPI"), cov$dataset[as.Date(cov$last_release) >= today + 35])) {
    message("::warning title=ABS release calendar::No ", ds,
            " release scheduled more than 35 days ahead; rapid updates need ",
            path, " (or the abs_releases table in R/line_chart.R) to be extended.")
  }
  invisible(merged)
}

# ------------------------------------------------------------------------------
# Release history from individual ABS release pages ("Released dd/mm/yyyy")
# ------------------------------------------------------------------------------

abs_history_series <- list(
  list(dataset = "Labour Force", path = "statistics/labour/employment-and-unemployment/labour-force-australia",
       slugs = function(m) format(m, "%b-%Y")),
  list(dataset = "CPI", path = "statistics/economy/price-indexes-and-inflation/consumer-price-index-australia",
       # quarterly releases (slug changed from "mar-2022" to "dec-quarter-2022"),
       # then the full monthly CPI from the October 2025 reference month
       slugs = function(m) if (as.integer(format(m, "%m")) %% 3 == 0 && m < as.Date("2025-10-01"))
         c(format(m, "%b-quarter-%Y"), format(m, "%b-%Y")) else if (m >= as.Date("2025-10-01")) format(m, "%b-%Y") else character()),
  list(dataset = "CPI Indicator", path = "statistics/economy/price-indexes-and-inflation/monthly-consumer-price-index-indicator",
       slugs = function(m) if (m >= as.Date("2022-09-01") && m <= as.Date("2025-09-01")) format(m, "%b-%Y") else character())
)

parse_release_page_date <- function(html) {
  m <- regmatches(html, regexpr('field__label">Released</div><div class="field__item">[^<]*', html))
  if (!length(m)) return(NA_character_)
  d <- as.Date(trimws(sub(".*field__item\">", "", m)), format = "%d/%m/%Y")
  if (is.na(d)) NA_character_ else format(d)
}

# Official release dates for reference months from..to (YYYY-MM). Release
# pages give the date only; ABS releases these series at 11:30 Canberra time.
fetch_abs_release_history <- function(from = "2021-12", to = format(Sys.Date() - 31, "%Y-%m"),
                                      fetch = fetch_url_text, pause = 0.2, now = Sys.time()) {
  months <- seq(as.Date(paste0(from, "-01")), as.Date(paste0(to, "-01")), by = "month")
  rows <- list()
  for (s in abs_history_series) for (i in seq_along(months)) {
    for (slug in tolower(s$slugs(months[i]))) {
      html <- tryCatch(fetch(paste0("https://www.abs.gov.au/", s$path, "/", slug)), error = function(e) NULL)
      Sys.sleep(pause)
      date <- if (is.null(html)) NA_character_ else parse_release_page_date(html)
      if (!is.na(date)) {
        rows[[length(rows) + 1L]] <- data.frame(dataset = s$dataset, release_date = date, release_time = "11:30",
          title = paste0(s$dataset, " (", format(months[i], "%b %Y"), ")"), source = abs_page_source,
          updated_at = format(now, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), stringsAsFactors = FALSE)
        break
      }
    }
  }
  normalise_calendar(do.call(rbind, rows))
}

update_abs_release_history <- function(path = abs_calendar_file, ...) {
  hist <- fetch_abs_release_history(...)
  message("ABS release pages: ", nrow(hist), " historical releases (",
          paste(names(table(hist$dataset)), table(hist$dataset), sep = " ", collapse = ", "), ")")
  merged <- resolve_calendar_conflicts(normalise_calendar(rbind(hist, read_abs_calendar_file(path),
                                                                line_chart_abs_releases())))
  write_abs_calendar_file(merged, path)
  invisible(merged)
}

# ------------------------------------------------------------------------------
# Command line
# ------------------------------------------------------------------------------

abs_calendar_cli <- function(args = commandArgs(TRUE)) {
  opt <- function(name, default = NULL) {
    i <- match(paste0("--", name), args)
    if (is.na(i) || i == length(args)) default else args[i + 1L]
  }
  out <- function(key, value) {
    cat(key, "=", value, "\n", sep = "")
    gh <- Sys.getenv("GITHUB_OUTPUT")
    if (nzchar(gh)) cat(key, "=", value, "\n", sep = "", file = gh, append = TRUE)
  }
  cmd <- if (length(args)) args[1] else "gate"
  now <- Sys.time()
  if (cmd == "gate") {
    # Should a scheduled rapid-update job start now? Release day, inside the
    # start window, and no session has already run for this release.
    date <- as.Date(opt("date", format(melbourne_date(now))))
    rel <- abs_releases_on(date)
    win <- rapid_slot_times(date, c(opt("from", "10:30"), opt("to", "12:00")))
    in_win <- now >= win[1] && now <= win[2]
    ran <- rapid_session_logged(date)
    out("release_day", tolower(nrow(rel) > 0))
    out("releases", if (nrow(rel)) paste(unique(rel$dataset), collapse = "+") else "")
    out("in_window", tolower(in_win))
    out("already_ran", tolower(ran))
    out("run", tolower(nrow(rel) > 0 && in_win && !ran))
    out("melbourne_now", format(now, "%Y-%m-%d %H:%M:%S %Z", tz = abs_tz))
  } else if (cmd == "window") {
    out("in_window", tolower(in_rapid_window(now, from = opt("from", "10:40"), to = opt("to", "11:45"))))
  } else if (cmd == "refresh") {
    refresh_abs_calendar()
  } else if (cmd == "history") {
    update_abs_release_history(from = opt("from", "2021-12"), to = opt("to", format(Sys.Date() - 31, "%Y-%m")))
  } else stop("Unknown command: ", cmd)
}

if (sys.nframe() == 0L) abs_calendar_cli()
