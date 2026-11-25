# ==============================================================================
# ABS data-release rapid-update mode
# ==============================================================================
# Captures and publishes the ASX cash-rate futures reaction to ABS economic data
# releases (CPI, Labour Force, GDP, WPI, household/retail spending).
#
# One warm R session runs every update so packages, the combined dataset, the
# cached RMSE table, the validated RBA policy state and RBA history are loaded
# once. Each iteration targets a wall-clock start time (default 11:30, 11:32,
# 11:34, 11:36 and 11:38 Melbourne time) and independently:
#
#   1. fetches the ASX 30-day interbank futures feed;
#   2. saves the timestamped snapshot (daily_data/scraped_cash_rate_*.csv);
#   3. appends it to combined_data/all_data.Rds and cash_rate.csv (no rebuild
#      from the 12k+ daily CSVs, no archive reprocessing);
#   4. recalculates the market-implied path and next-meeting probabilities;
#   5. regenerates ONLY the allowlisted outputs (rapid_outputs below);
#   6. commits and pushes them immediately.
#
# Deliberately not run: RMSE recalculation, heatmaps, multi-meeting probability
# charts, fan charts / distributions, per-meeting probability bar charts, the
# index page, volatility analysis and every other output of the full pipeline.
#
# A snapshot whose market fields are identical to the previous observation is
# logged as "stale" and not recorded, so no observation is fabricated. Missed
# slots are logged as "missed"; nothing is backfilled for them.
#
# Usage (from the repository root):
#   Rscript R/rapid_update.R                          # release-day schedule
#   Rscript R/rapid_update.R --force --publish        # ignore calendar
#   Rscript R/rapid_update.R --mode immediate --iterations 5 --interval 120
# Options:
#   --mode release|immediate   release: Melbourne wall-clock --slots on the
#                              release day; immediate: start at the next whole
#                              minute, then every --interval seconds
#   --slots 11:30,11:32,...    release-mode slot times (Melbourne local)
#   --iterations N --interval S  immediate-mode schedule
#   --date YYYY-MM-DD          release date to check (default: today, Melbourne)
#   --force                    run even if the calendar has no release today
#   --publish                  git commit + push after every iteration
#   --branch NAME --remote R   push target (default: current branch / origin)
#   --no-baseline              skip the pre-release snapshot (release mode)
#   --max-late-minutes M       catch-up window when the job starts late (30)
#   --outputs line,paths       chart groups to regenerate (default both)
# ==============================================================================

rapid_tz <- "Australia/Melbourne"
rapid_log_file <- "combined_data/rapid_update_log.csv"

# Explicit allowlist: the only files a rapid update may write and publish.
rapid_data_outputs <- c(
  "combined_data/all_data.Rds",
  "combined_data/cash_rate.csv",
  "docs/data/cash-rate-latest.json",
  rapid_log_file
)
rapid_chart_groups <- list(
  line = list(
    script = "R/line_chart.R",
    files = c("docs/plots/line_charts/line.png",
              "docs/plots/line_charts/line_dual.png",
              "docs/line_interactive.html")
  ),
  paths = list(
    script = "R/actual_vs_implied.R",
    files = c("docs/plots/forecast_paths/cash_rate_forecast_paths.png",
              "docs/cash_rate_forecast_paths.html")
  )
)
rapid_outputs <- c(rapid_data_outputs, unlist(lapply(rapid_chart_groups, `[[`, "files"), use.names = FALSE))
rapid_scrape_pattern <- "^daily_data/scraped_cash_rate_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4}[.]csv$"

rapid_allowed <- function(paths) paths %in% rapid_outputs | grepl(rapid_scrape_pattern, paths)

# ------------------------------------------------------------------------------
# Options and schedule
# ------------------------------------------------------------------------------

parse_rapid_args <- function(args = character()) {
  value <- function(name, default) {
    i <- match(paste0("--", name), args)
    if (is.na(i) || i == length(args)) default else args[i + 1L]
  }
  flag <- function(name) paste0("--", name) %in% args
  list(
    mode = value("mode", "release"),
    slots = strsplit(value("slots", "11:30,11:32,11:34,11:36,11:38"), ",")[[1]],
    iterations = as.integer(value("iterations", "5")),
    interval = as.numeric(value("interval", "120")),
    date = value("date", NA_character_),
    force = flag("force"),
    publish = flag("publish"),
    allow_local_publish = flag("allow-local-publish"),
    branch = value("branch", NA_character_),
    remote = value("remote", "origin"),
    baseline = !flag("no-baseline"),
    max_late = as.numeric(value("max-late-minutes", "30")) * 60,
    outputs = strsplit(value("outputs", "line,paths"), ",")[[1]]
  )
}

# Planned start instants. Release mode converts Melbourne wall-clock times on
# the release date via the tz database (AEST/AEDT handled automatically).
plan_slots <- function(opts, now = Sys.time()) {
  if (identical(opts$mode, "immediate")) {
    # Snapshot files are named to the minute (as in the regular pipeline).
    if (opts$interval < 60) stop("--interval must be at least 60 seconds")
    start <- as.POSIXct(ceiling(as.numeric(now) / 60) * 60, origin = "1970-01-01", tz = rapid_tz)
    if (as.numeric(start) - as.numeric(now) < 5) start <- start + 60
    return(start + (seq_len(opts$iterations) - 1L) * opts$interval)
  }
  date <- if (is.na(opts$date)) melbourne_date(now) else as.Date(opts$date)
  rapid_slot_times(date, opts$slots)
}

# Decide what to do for slot k given the current time:
#   "wait" (slot is in the future), "run" (due; started late by <next slot),
#   "missed" (the next slot is already due, or >60 s past the final slot).
slot_action <- function(k, slots, now) {
  if (now < slots[k]) return("wait")
  limit <- if (k < length(slots)) slots[k + 1L] else slots[k] + 60
  if (now >= limit) "missed" else "run"
}

# ------------------------------------------------------------------------------
# Small utilities
# ------------------------------------------------------------------------------

fmt_time <- function(t) if (is.null(t) || all(is.na(t))) NA_character_ else format(t, "%Y-%m-%d %H:%M:%S %Z", tz = rapid_tz)
secs <- function(t0, t1 = Sys.time()) round(as.numeric(difftime(t1, t0, units = "secs")), 2)
say <- function(...) {
  cat(format(Sys.time(), "[%H:%M:%OS3 %Z] ", tz = rapid_tz), ..., "\n", sep = "")
  utils::flush.console()
}

run_git <- function(args, timeout = 60, allow_fail = FALSE) {
  out <- suppressWarnings(system2("git", shQuote(args), stdout = TRUE, stderr = TRUE, timeout = timeout))
  status <- attr(out, "status")
  if (is.null(status)) status <- 0L
  if (status != 0L && !allow_fail) {
    stop("git ", paste(args, collapse = " "), " failed (", status, "): ", paste(out, collapse = "\n"))
  }
  structure(out, status = status)
}
git_ok <- function(x) identical(attr(x, "status"), 0L)

# Default fetcher: ASX feed with a hard timeout and no caching. A test-only
# fixture directory (RAPID_FIXTURE_DIR) replays JSON payloads in name order;
# files whose name contains "fail" simulate a failed request.
make_fetcher <- function() {
  fixture_dir <- Sys.getenv("RAPID_FIXTURE_DIR")
  if (nzchar(fixture_dir)) {
    files <- sort(list.files(fixture_dir, pattern = "[.]json$", full.names = TRUE))
    i <- 0L
    return(function() {
      i <<- min(i + 1L, length(files))
      if (grepl("fail", basename(files[i]))) stop("simulated ASX request failure (", basename(files[i]), ")")
      paste(readLines(files[i], warn = FALSE), collapse = "\n")
    })
  }
  function() {
    h <- curl::new_handle(timeout = 20, connecttimeout = 10,
                          httpheader = c("Cache-Control" = "no-cache", "Pragma" = "no-cache"))
    res <- curl::curl_fetch_memory(paste0(asx_futures_url, "&_=", as.integer(Sys.time())), handle = h)
    if (res$status_code != 200) stop("ASX feed returned HTTP ", res$status_code)
    rawToChar(res$content)
  }
}

fetch_with_retry <- function(fetch, attempts = 3, budget = 45) {
  t0 <- Sys.time()
  for (a in seq_len(attempts)) {
    res <- tryCatch(fetch(), error = function(e) e)
    if (!inherits(res, "error")) return(res)
    say("  fetch attempt ", a, " failed: ", conditionMessage(res))
    if (a == attempts || secs(t0) + 5 > budget) stop(res)
    Sys.sleep(2)
  }
}

# ------------------------------------------------------------------------------
# Session context (loaded once, reused by every iteration)
# ------------------------------------------------------------------------------

rapid_load_packages <- function() {
  suppressPackageStartupMessages({
    for (p in c("dplyr", "lubridate", "purrr", "tibble", "ggplot2", "tidyr", "plotly",
                "scales", "glue", "jsonlite", "readr", "htmlwidgets", "stringr",
                "viridis", "here", "readrba")) library(p, character.only = TRUE)
  })
  if ("conflicted" %in% loadedNamespaces()) conflicted::conflict_prefer_all("dplyr", quiet = TRUE)
}

# Append any daily CSV newer than the dataset (e.g. after a resync), in
# filename order, so all_data matches a full rebuild without performing one.
catch_up_dataset <- function(all_data, dir = "daily_data") {
  latest <- max(all_data$scrape_time, na.rm = TRUE)
  files <- sort(list.files(dir, pattern = "^scraped_cash_rate_.*[.]csv$", full.names = TRUE))
  stamp <- as.POSIXct(sub("^scraped_cash_rate_(.*)[.]csv$", "\\1", basename(files)),
                      format = "%Y-%m-%d_%H%M", tz = rapid_tz)
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

latest_signature <- function(all_data) {
  t <- max(all_data$scrape_time, na.rm = TRUE)
  market_signature(all_data[all_data$scrape_time == t, , drop = FALSE])
}

load_policy_state <- function(cache = "docs/data/rba-policy-state.json", now = Sys.time()) {
  cached <- tryCatch({
    x <- jsonlite::read_json(cache, simplifyVector = TRUE)
    rba_policy_validate(x, now)
    x
  }, error = function(e) NULL)
  if (!is.null(cached)) return(cached)
  # Cached announcement is stale: fetch afresh, writing only to a temp cache so
  # docs/data/rba-policy-state.json (not a rapid output) is left untouched.
  tmp <- tempfile(fileext = ".json")
  if (file.exists(cache)) file.copy(cache, tmp)
  rba_policy_state(cache = tmp, now = now)
}

load_rba_history <- function(attempts = 3) {
  for (a in seq_len(attempts)) {
    res <- tryCatch(readrba::read_rba(series_id = "FIRMMCRTD"), error = function(e) e)
    if (!inherits(res, "error")) return(res)
    say("RBA history attempt ", a, " failed: ", conditionMessage(res))
    Sys.sleep(3)
  }
  stop(res)
}

# Rows needed by the next-meeting line chart (its window starts at the previous
# meeting); a smaller frame makes the per-snapshot filtering much cheaper.
line_window <- function(all_data, policy_state) {
  start <- as.POSIXct(paste(as.Date(policy_state$nextMeeting) - 120, "00:00:00"), tz = rapid_tz)
  all_data[all_data$scrape_time >= start | all_data$scrape_time == max(all_data$scrape_time), , drop = FALSE]
}

init_context <- function(opts, fetch = make_fetcher(), now = Sys.time()) {
  t0 <- Sys.time()
  ctx <- new.env()
  ctx$opts <- opts
  ctx$fetch <- fetch
  ctx$now <- function() now(tzone = rapid_tz)  # scrape timestamps (injectable for tests)
  ctx$base_env <- new.env(parent = globalenv())
  for (f in c("R/market_data.R", "R/rba_policy_state.R")) sys.source(f, envir = globalenv())
  ctx$all_data <- readRDS("combined_data/all_data.Rds")
  caught <- catch_up_dataset(ctx$all_data)
  if (length(caught$files)) {
    say("Appended ", length(caught$files), " daily file(s) missing from all_data.Rds")
    ctx$all_data <- caught$all_data
  }
  ctx$last_signature <- latest_signature(ctx$all_data)
  rmse_env <- new.env()
  load("combined_data/rmse_new.RData", envir = rmse_env)  # cached; never recalculated here
  ctx$rmse_days <- rmse_env$rmse_days
  ctx$chart_error <- NULL
  ctx$policy_state <- tryCatch(load_policy_state(now = now), error = function(e) { ctx$chart_error <- e; NULL })
  ctx$rba_historical <- if (is.null(ctx$chart_error)) tryCatch(load_rba_history(), error = function(e) { ctx$chart_error <- e; NULL })
  if (!is.null(ctx$chart_error)) {
    say("WARNING: chart inputs unavailable, publishing data only: ", conditionMessage(ctx$chart_error))
  }
  ctx$log <- read_rapid_log()
  ctx$session_id <- format(now, "%Y%m%dT%H%M%S", tz = rapid_tz)
  ctx$staging <- tempfile("rapid_staging_")
  say("Context ready in ", secs(t0), " s (", nrow(ctx$all_data), " rows, latest scrape ",
      fmt_time(max(ctx$all_data$scrape_time)), ")")
  ctx
}

# ------------------------------------------------------------------------------
# Output generation
# ------------------------------------------------------------------------------

# Evaluate a chart script with the warm inputs, writing into a staging
# directory. Outputs are copied into docs/ only if the whole group succeeded,
# so a failure never leaves a half-updated chart set.
render_chart_group <- function(ctx, name) {
  group <- rapid_chart_groups[[name]]
  out_dir <- file.path(ctx$staging, name)
  unlink(out_dir, recursive = TRUE)
  dir.create(out_dir, recursive = TRUE)
  env <- new.env(parent = ctx$base_env)
  env$rapid_ctx <- list(
    out_dir = out_dir,
    cash_rate = line_window(ctx$all_data, ctx$policy_state),
    cash_rate_full = ctx$all_data,
    rmse_days = ctx$rmse_days,
    policy_state = ctx$policy_state,
    rba_historical = ctx$rba_historical
  )
  log_file <- file.path(ctx$staging, paste0(name, ".log"))
  con <- file(log_file, open = "wt")
  sink(con); sink(con, type = "message")
  on.exit({ sink(type = "message"); sink(); close(con) }, add = TRUE)
  t_start <- Sys.time()
  source(group$script, local = env, echo = FALSE)
  staged <- file.path(out_dir, group$files)
  fresh <- file.exists(staged) & file.size(staged) > 0 & file.mtime(staged) >= t_start - 1
  if (!all(fresh)) stop(name, " charts not produced: ", paste(group$files[!fresh], collapse = ", "))
  for (i in seq_along(staged)) {
    dir.create(dirname(group$files[i]), recursive = TRUE, showWarnings = FALSE)
    stopifnot(file.copy(staged[i], group$files[i], overwrite = TRUE))
  }
  group$files
}

# ------------------------------------------------------------------------------
# Logging
# ------------------------------------------------------------------------------

rapid_log_cols <- c("session_id", "mode", "release_date", "releases", "iteration", "slot",
                    "status", "planned_at", "started_at", "scraped_at", "published_at",
                    "lateness_s", "fetch_s", "save_s", "dataset_s", "line_s", "paths_s",
                    "publish_s", "total_s", "rows_added", "commit", "error")

read_rapid_log <- function(path = rapid_log_file) {
  if (!file.exists(path)) {
    return(as.data.frame(setNames(replicate(length(rapid_log_cols), character(), simplify = FALSE), rapid_log_cols)))
  }
  x <- utils::read.csv(path, colClasses = "character", na.strings = "")
  for (col in setdiff(rapid_log_cols, names(x))) x[[col]] <- NA_character_
  x[, rapid_log_cols]
}

write_rapid_log <- function(log, path = rapid_log_file) {
  utils::write.csv(log, path, row.names = FALSE, na = "")
}

new_log_row <- function(ctx, plan, k, status = NA, ...) {
  row <- as.list(setNames(rep(NA_character_, length(rapid_log_cols)), rapid_log_cols))
  row$session_id <- ctx$session_id
  row$mode <- ctx$opts$mode
  row$release_date <- plan$release_date
  row$releases <- plan$releases
  row$iteration <- as.character(k)
  row$slot <- if (k == 0) "pre-release" else if (is.na(plan$slots[k])) "catch-up" else format(plan$slots[k], "%H:%M:%S", tz = rapid_tz)
  row$planned_at <- if (k > 0 && !is.na(plan$slots[k])) fmt_time(plan$slots[k]) else NA
  row$status <- status
  extra <- list(...)
  row[names(extra)] <- lapply(extra, as.character)
  row
}

add_log_row <- function(ctx, row) {
  vals <- lapply(rapid_log_cols, function(col) {
    v <- row[[col]]
    if (length(v)) as.character(v[[1]]) else NA_character_
  })
  ctx$log <- rbind(ctx$log, as.data.frame(setNames(vals, rapid_log_cols), stringsAsFactors = FALSE))
  invisible(nrow(ctx$log))
}

# ------------------------------------------------------------------------------
# Publishing (git)
# ------------------------------------------------------------------------------

publish_files <- function(ctx, files, message) {
  files <- unique(files[file.exists(files)])
  if (!all(rapid_allowed(files))) stop("Refusing to publish non-allowlisted files: ", paste(files[!rapid_allowed(files)], collapse = ", "))
  if (!ctx$opts$publish) return(list(status = "updated"))  # local run: files written, git untouched
  run_git(c("add", "--", files))
  staged <- run_git(c("diff", "--cached", "--name-status"))
  if (!length(staged)) return(list(status = "no-changes"))
  paths <- sub("^[A-Z][0-9]*\t", "", staged)
  if (any(!startsWith(staged, "A") & !startsWith(staged, "M")) || !all(rapid_allowed(paths))) {
    stop("Unexpected staged changes: ", paste(staged, collapse = "; "))
  }
  run_git(c("commit", "-q", "-m", message))
  push_head(ctx)
}

# Push, rebasing onto any newer remote commits. Returns status "conflict" when
# a rebase cannot apply cleanly (the caller resynchronises and regenerates).
push_head <- function(ctx) {
  ref <- paste0("HEAD:refs/heads/", ctx$branch)
  for (attempt in 1:3) {
    pushed <- run_git(c("push", "-q", ctx$opts$remote, ref), timeout = 90, allow_fail = TRUE)
    if (git_ok(pushed)) {
      return(list(status = "published", published_at = Sys.time(),
                  commit = run_git(c("rev-parse", "--short", "HEAD"))))
    }
    say("  push attempt ", attempt, " rejected: ", paste(tail(pushed, 2), collapse = " | "))
    run_git(c("fetch", "-q", ctx$opts$remote, ctx$branch), timeout = 90)
    rebased <- run_git(c("rebase", "-q", "FETCH_HEAD"), allow_fail = TRUE)
    if (!git_ok(rebased)) {
      run_git(c("rebase", "--abort"), allow_fail = TRUE)
      return(list(status = "conflict"))
    }
  }
  list(status = "push-failed")
}

# After a conflicting concurrent write: keep our unpublished snapshots, adopt
# the remote branch, re-append the snapshots incrementally and regenerate.
resync_with_remote <- function(ctx) {
  run_git(c("fetch", "-q", ctx$opts$remote, ctx$branch), timeout = 90)
  ours <- run_git(c("diff", "--name-only", "--diff-filter=A", "FETCH_HEAD", "HEAD", "--", "daily_data"))
  keep <- tempfile("rapid_keep_")
  dir.create(keep)
  file.copy(ours, keep)
  run_git(c("reset", "-q", "--hard", "FETCH_HEAD"))
  for (f in ours) if (!file.exists(f)) file.copy(file.path(keep, basename(f)), f)
  ctx$all_data <- readRDS("combined_data/all_data.Rds")
  caught <- catch_up_dataset(ctx$all_data)
  ctx$all_data <- caught$all_data
  if (length(caught$files)) {
    saveRDS(ctx$all_data, "combined_data/all_data.Rds")
    append_cash_rate_csv(ctx$all_data, rebuild_all_data(caught$files))
  }
  remote_log <- read_rapid_log()
  key <- function(x) paste(x$session_id, x$iteration, x$slot)
  mine <- ctx$log$session_id == ctx$session_id & !key(ctx$log) %in% key(remote_log)
  ctx$log <- rbind(remote_log, ctx$log[mine, , drop = FALSE])
  ctx$last_signature <- latest_signature(ctx$all_data)
  say("  resynchronised with ", ctx$opts$remote, "/", ctx$branch, "; re-appended ", length(caught$files), " snapshot(s)")
}

# Before the first update, fast-forward to the remote so we build on the latest
# published state (the job may have waited ~25 minutes since checkout).
sync_before_start <- function(ctx) {
  if (!ctx$opts$publish) return(invisible())
  fetched <- run_git(c("fetch", "-q", ctx$opts$remote, ctx$branch), timeout = 90, allow_fail = TRUE)
  if (!git_ok(fetched)) return(invisible())
  same <- identical(run_git(c("rev-parse", "HEAD"))[1], run_git(c("rev-parse", "FETCH_HEAD"))[1])
  if (same) return(invisible())
  if (git_ok(run_git(c("merge", "-q", "--ff-only", "FETCH_HEAD"), allow_fail = TRUE))) {
    say("Fast-forwarded to latest ", ctx$branch, "; reloading data")
    ctx$all_data <- catch_up_dataset(readRDS("combined_data/all_data.Rds"))$all_data
    ctx$last_signature <- latest_signature(ctx$all_data)
    ctx$log <- read_rapid_log()
  }
}

# ------------------------------------------------------------------------------
# One rapid update
# ------------------------------------------------------------------------------

run_iteration <- function(ctx, plan, k, started_late = 0) {
  t0 <- Sys.time()
  row <- new_log_row(ctx, plan, k, started_at = fmt_time(t0), lateness_s = round(started_late, 1))
  label <- paste0(plan$releases, " ", row$slot)
  result <- tryCatch({
    # 1. Fetch
    t <- Sys.time()
    raw <- fetch_with_retry(ctx$fetch)
    scraped_at <- if (is.function(ctx$now)) ctx$now() else now(tzone = rapid_tz)
    new_data <- parse_asx_futures(raw, scrape_time = scraped_at)
    row$fetch_s <- secs(t)
    row$scraped_at <- fmt_time(scraped_at)
    if (nrow(new_data) < 2) stop("ASX feed returned ", nrow(new_data), " contracts")

    # Stale payload: identical market fields to the latest observation.
    sig <- market_signature(clean_scrape_data(new_data))
    if (identical(sig, ctx$last_signature)) {
      stop(structure(class = c("rapid_stale", "condition"),
                     list(message = "feed unchanged since previous observation", call = NULL)))
    }

    # 2. Save timestamped snapshot + public JSON feed
    t <- Sys.time()
    path <- scrape_file_path(scraped_at)
    if (file.exists(path)) stop("snapshot ", path, " already exists for this minute; not overwriting")
    write_csv(new_data, path)
    write_market_feed(new_data, "docs/data/cash-rate-latest.json")
    row$save_s <- secs(t)

    # 3. Incremental dataset update
    t <- Sys.time()
    upd <- append_scrape_files(ctx$all_data, path)
    ctx$all_data <- upd$all_data
    saveRDS(ctx$all_data, "combined_data/all_data.Rds")
    append_cash_rate_csv(ctx$all_data, upd$new_rows)
    ctx$last_signature <- sig
    row$rows_added <- nrow(upd$new_rows)
    row$dataset_s <- secs(t)

    # 4-5. Allowlisted charts, each group isolated
    publish <- c(path, rapid_data_outputs[rapid_data_outputs != rapid_log_file])
    errors <- character()
    for (g in intersect(names(rapid_chart_groups), ctx$opts$outputs)) {
      t <- Sys.time()
      if (!is.null(ctx$chart_error)) {
        errors <- c(errors, paste0(g, ": ", conditionMessage(ctx$chart_error)))
        next
      }
      files <- tryCatch(render_chart_group(ctx, g), error = function(e) {
        errors <<- c(errors, paste0(g, ": ", conditionMessage(e))); NULL })
      publish <- c(publish, files)
      row[[paste0(g, "_s")]] <- secs(t)
    }

    # 6. Publish this iteration immediately
    t <- Sys.time()
    write_rapid_log(ctx$log)
    msg <- sprintf("Rapid ABS update (%s) slot %s: scraped %s", plan$releases, row$slot,
                   format(scraped_at, "%H:%M:%S %Z", tz = rapid_tz))
    pub <- publish_files(ctx, c(publish, rapid_log_file), msg)
    if (identical(pub$status, "conflict")) {
      resync_with_remote(ctx)
      write_market_feed(new_data, "docs/data/cash-rate-latest.json")
      for (g in intersect(names(rapid_chart_groups), ctx$opts$outputs)) {
        if (is.null(ctx$chart_error)) try(render_chart_group(ctx, g), silent = TRUE)
      }
      write_rapid_log(ctx$log)
      pub <- publish_files(ctx, c(path, rapid_outputs), paste(msg, "(after resync)"))
    }
    row$publish_s <- secs(t)
    if (length(pub$commit)) row$commit <- pub$commit[1]
    if (!is.null(pub$published_at)) row$published_at <- fmt_time(pub$published_at)
    row$status <- switch(pub$status, published = "published", updated = "updated",
                         `no-changes` = "no-changes", "publish-failed")
    if (length(errors)) {
      row$status <- paste0(row$status, "-partial")
      row$error <- paste(errors, collapse = " | ")
    }
    row
  }, rapid_stale = function(e) {
    row$status <- "stale"
    say("  ", label, ": feed unchanged since previous observation; nothing recorded")
    row
  }, error = function(e) {
    row$status <- "failed"
    row$error <- conditionMessage(e)
    row
  })
  result$total_s <- secs(t0)
  say("  ", label, ": ", result$status, " in ", result$total_s, " s",
      if (!is.na(result$error)) paste0(" [", result$error, "]") else "")
  add_log_row(ctx, result)
  result
}

# ------------------------------------------------------------------------------
# Session
# ------------------------------------------------------------------------------

# Wait until `t` using short sleeps so the start is accurate to well under 1 s.
wait_until <- function(t, clock = Sys.time, sleep = Sys.sleep) {
  repeat {
    remaining <- as.numeric(difftime(t, clock(), units = "secs"))
    if (remaining <= 0) return(invisible())
    sleep(min(remaining, 15))
  }
}

run_rapid_session <- function(opts, clock = Sys.time, sleep = Sys.sleep,
                              iterate = run_iteration, ctx = NULL) {
  # A failure anywhere in one update (including bookkeeping) is logged and the
  # schedule continues with the next slot.
  iterate_safely <- function(ctx, plan, k, started_late = 0) {
    tryCatch(iterate(ctx, plan, k, started_late = started_late), error = function(e) {
      say("  iteration ", k, " aborted: ", conditionMessage(e))
      row <- new_log_row(ctx, plan, k, "failed", error = conditionMessage(e), lateness_s = round(started_late, 1))
      try(add_log_row(ctx, row), silent = TRUE)
      row
    })
  }
  now <- clock()
  release_date <- if (is.na(opts$date)) melbourne_date(now) else as.Date(opts$date)
  releases <- abs_releases_on(release_date, load_abs_calendar())
  if (!nrow(releases) && !opts$force) {
    say("No significant ABS release scheduled on ", release_date, "; nothing to do.")
    return(invisible(list(status = "not-release-day", log = NULL)))
  }
  plan <- list(
    release_date = format(release_date),
    releases = if (nrow(releases)) paste(unique(releases$dataset), collapse = "+") else "manual",
    slots = plan_slots(opts, now)
  )
  say("Rapid update plan for ", plan$releases, " on ", plan$release_date, ": ",
      paste(format(plan$slots, "%H:%M:%S", tz = rapid_tz), collapse = ", "), " (", rapid_tz, ")")

  if (is.null(ctx)) ctx <- init_context(opts, now = now)
  if (opts$publish) {
    ctx$branch <- if (!is.na(opts$branch)) opts$branch else {
      b <- Sys.getenv("GITHUB_REF_NAME")
      if (nzchar(b)) b else run_git(c("rev-parse", "--abbrev-ref", "HEAD"))[1]
    }
  }
  if (identical(opts$mode, "release") && !opts$force && rapid_session_logged(plan$release_date, log = ctx$log)) {
    say("A rapid-update session already ran for ", plan$release_date, "; exiting.")
    return(invisible(list(status = "already-ran", log = NULL)))
  }

  n <- length(plan$slots)
  results <- list()
  first <- plan$slots[1]

  # Pre-release snapshot (release mode): preserves the latest observation
  # immediately before the 11:30 release.
  if (identical(opts$mode, "release") && opts$baseline && clock() < first - 90) {
    wait_until(first - 150 - 60, clock, sleep)
    sync_before_start(ctx)
    wait_until(first - 150, clock, sleep)
    results[["0"]] <- iterate_safely(ctx, plan, 0)
  } else if (clock() < first - 30) {
    wait_until(first - 30, clock, sleep)
    sync_before_start(ctx)
  }

  ran <- 0L
  for (k in seq_len(n)) {
    action <- slot_action(k, plan$slots, clock())
    if (action == "wait") {
      wait_until(plan$slots[k], clock, sleep)
      action <- "run"
    }
    if (action == "missed") {
      say("  slot ", format(plan$slots[k], "%H:%M:%S", tz = rapid_tz), " missed (now ", fmt_time(clock()), ")")
      add_log_row(ctx, new_log_row(ctx, plan, k, "missed"))
      next
    }
    late <- secs(plan$slots[k], clock())
    results[[as.character(k)]] <- iterate_safely(ctx, plan, k, started_late = late)
    ran <- ran + 1L
  }

  # Job started after every slot: one real, clearly labelled catch-up update.
  if (!ran && identical(opts$mode, "release") && secs(first, clock()) <= opts$max_late) {
    plan$slots <- c(plan$slots, NA)
    results[["catch-up"]] <- iterate_safely(ctx, plan, n + 1L, started_late = secs(first, clock()))
  }

  # Final log commit records publication times of the last iteration.
  write_rapid_log(ctx$log)
  if (opts$publish) {
    tryCatch(publish_files(ctx, rapid_log_file, paste("Rapid ABS update log:", plan$releases, plan$release_date)),
             error = function(e) say("Log publish failed: ", conditionMessage(e)))
  }
  session_log <- ctx$log[ctx$log$session_id == ctx$session_id, , drop = FALSE]
  write_step_summary(session_log)
  invisible(list(status = "done", log = session_log))
}

write_step_summary <- function(log) {
  cols <- c("slot", "status", "planned_at", "scraped_at", "published_at", "lateness_s",
            "fetch_s", "dataset_s", "line_s", "paths_s", "publish_s", "total_s", "commit", "error")
  lines <- c("| " %s% paste(cols, collapse = " | ") %s% " |",
             "|" %s% paste(rep("---", length(cols)), collapse = "|") %s% "|",
             apply(log[, cols, drop = FALSE], 1, function(r) "| " %s% paste(ifelse(is.na(r), "", r), collapse = " | ") %s% " |"))
  cat("\n", paste(lines, collapse = "\n"), "\n", sep = "")
  f <- Sys.getenv("GITHUB_STEP_SUMMARY")
  if (nzchar(f)) cat("### Rapid ABS updates\n\n", paste(lines, collapse = "\n"), "\n", file = f, append = TRUE, sep = "")
}
`%s%` <- function(a, b) paste0(a, b)

rapid_main <- function(args = commandArgs(TRUE)) {
  opts <- parse_rapid_args(args)
  source("R/abs_release_calendar.R")
  if (opts$publish) {
    if (!nzchar(Sys.getenv("GITHUB_ACTIONS")) && !opts$allow_local_publish) {
      stop("--publish rewrites git history on conflict; outside GitHub Actions also pass --allow-local-publish")
    }
    dirty <- run_git(c("status", "--porcelain", "--untracked-files=no"))
    if (length(dirty)) stop("Working tree has uncommitted changes; refusing to publish:\n", paste(dirty, collapse = "\n"))
  }
  rapid_load_packages()
  res <- run_rapid_session(opts)
  if (!is.null(res$log) && any(res$log$status %in% c("failed", "publish-failed"))) {
    message("::warning title=Rapid update::One or more rapid updates failed; see the summary table.")
    quit(status = 1)
  }
  if (!is.null(res$log) && any(res$log$status == "missed")) {
    message("::warning title=Rapid update::Some slots were missed because the job started late.")
  }
}

if (sys.nframe() == 0L) rapid_main()
