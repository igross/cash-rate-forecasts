# Run from the repository root: Rscript tests/test-rapid-update.R
# Offline tests for the ABS release rapid-update mode. Network calls are
# replaced by fixtures; git publishing is exercised against a local bare
# remote. Chart tests need the chart packages (incl. readrba) installed.
suppressPackageStartupMessages({
  library(dplyr); library(lubridate); library(readr); library(jsonlite)
})
repo <- normalizePath(".")
source("R/abs_release_calendar.R")
source("R/market_data.R")
source("R/rba_policy_state.R")
source("R/rapid_update.R")

failures <- 0L
check <- function(name, ok) {
  ok <- isTRUE(ok)
  cat(if (ok) "PASS" else "FAIL", ": ", name, "\n", sep = "")
  if (!ok) failures <<- failures + 1L
}
`%||%` <- function(a, b) if (is.null(a)) b else a
mel <- function(x) as.POSIXct(x, tz = "Australia/Melbourne")
utc <- function(x) format(x, "%Y-%m-%d %H:%M:%S", tz = "UTC")

# ------------------------------------------------------------------------------
# 1. Release-day detection and daylight saving
# ------------------------------------------------------------------------------
cal <- load_abs_calendar()
check("calendar reuses the line-chart release table", nrow(line_chart_abs_releases()) >= 60)
check("CPI release day detected (25 Nov 2026)", identical(abs_releases_on("2026-11-25", cal)$dataset, "CPI"))
check("Labour Force release day detected (17 Dec 2026)", "Labour Force" %in% abs_releases_on("2026-12-17", cal)$dataset)
check("GDP release day detected (2 Dec 2026)", "National Accounts" %in% abs_releases_on("2026-12-02", cal)$dataset)
check("WPI release day detected (17 Feb 2027)", "WPI" %in% abs_releases_on("2027-02-17", cal)$dataset)
check("non-release day not detected (26 Nov 2026)", nrow(abs_releases_on("2026-11-26", cal)) == 0)
check("non-significant dataset ignored",
      nrow(abs_releases_on("2026-11-27", rbind(cal, data.frame(dataset = "Building Approvals", release_date = "2026-11-27",
        release_time = "11:30", title = NA, source = "test", updated_at = NA)))) == 0)
check("AEDT slots: 11:30-11:38 local = 00:30-00:38 UTC",
      identical(utc(rapid_slot_times("2026-11-25")), paste("2026-11-25", sprintf("00:%02d:00", c(30, 32, 34, 36, 38)))))
check("AEST slots: 11:30 local = 01:30 UTC (29 Jul 2026)", utc(rapid_slot_times("2026-07-29")[1]) == "2026-07-29 01:30:00")
check("DST ends 5 Apr 2026: 11:30 = 01:30 UTC, day before 00:30 UTC",
      identical(utc(rapid_slot_times(c("2026-04-04", "2026-04-05"), "11:30")), c("2026-04-04 00:30:00", "2026-04-05 01:30:00")))
check("DST starts 4 Oct 2026: 11:30 = 00:30 UTC, day before 01:30 UTC",
      identical(utc(rapid_slot_times(c("2026-10-03", "2026-10-04"), "11:30")), c("2026-10-03 01:30:00", "2026-10-04 00:30:00")))
check("melbourne_date rolls at local midnight", melbourne_date(as.POSIXct("2026-11-24 13:30:00", tz = "UTC")) == as.Date("2026-11-25"))
check("regular-run window on release day", in_rapid_window(mel("2026-11-25 11:00"), cal) && !in_rapid_window(mel("2026-11-25 12:10"), cal) &&
        !in_rapid_window(mel("2026-11-26 11:00"), cal))

page <- paste0(
  '<div class="views-row"><h3><a href="/statistics/economy/price-indexes-and-inflation/consumer-price-index-australia/latest-release">Consumer Price Index, Australia</a></h3>',
  '<time datetime="2027-01-27T00:30:00Z">27/01/2027</time></div>',
  '<div class="views-row"><a href="/x">Labour Force, Australia</a><span>Release date: 18/02/2027 11:30am</span></div>',
  '<div class="views-row"><a href="/y">Labour Force, Australia, Detailed</a><span>25/02/2027</span></div>',
  '<div class="views-row"><a href="/z">Monthly Household Spending Indicator</a><p>Released 4 February 2027</p></div>',
  '<div class="views-row"><a href="/a">Wage Price Index, Australia</a><a href="/b">Labour Force, Australia</a><span>18/02/2027</span></div>')
parsed <- parse_abs_calendar_page(page, as.POSIXct("2026-11-25", tz = "UTC"))
check("ABS page parser: ISO datetime (UTC) converted to Melbourne 11:30",
      any(parsed$dataset == "CPI" & parsed$release_date == "2027-01-27" & parsed$release_time == "11:30"))
check("ABS page parser: dd/mm/yyyy, d Month yyyy; skips 'Detailed' and ambiguous blocks",
      setequal(paste(parsed$dataset, parsed$release_date),
               c("CPI 2027-01-27", "Labour Force 2027-02-18", "Household Spending 2027-02-04")))
tmp_cal <- tempfile(fileext = ".csv")
write_abs_calendar_file(cal, tmp_cal)
suppressMessages(refresh_abs_calendar(tmp_cal, fetch = function(url) stop("offline"), now = mel("2026-11-25 03:00")))
check("calendar refresh keeps entries when ABS is unreachable", nrow(read_abs_calendar_file(tmp_cal)) >= nrow(cal))
suppressMessages(refresh_abs_calendar(tmp_cal, fetch = function(url) if (grepl("page=", url)) "<html></html>" else page,
                                      now = mel("2026-11-25 03:00")))
merged <- read_abs_calendar_file(tmp_cal)
check("calendar refresh adds new ABS releases (incl. household spending)",
      any(merged$dataset == "Household Spending" & merged$release_date == "2027-02-04") &&
        any(merged$dataset == "CPI" & merged$release_date == "2026-12-30"))
check("session dedupe reads the rapid log",
      rapid_session_logged("2026-11-25", log = data.frame(release_date = "2026-11-25", mode = "release", iteration = "2", status = "published")) &&
        !rapid_session_logged("2026-11-25", log = data.frame(release_date = "2026-11-25", mode = "release", iteration = "1", status = "missed")))

# ------------------------------------------------------------------------------
# 2. Five-update scheduling (simulated clock; no real waiting)
# ------------------------------------------------------------------------------
sim_session <- function(start, date = "2026-11-25", duration = function(k) 9, fail = integer(),
                        mode = "release", force = FALSE, baseline = TRUE, log = NULL, extra = character()) {
  wd <- tempfile("sched_"); dir.create(wd)
  old <- setwd(wd); on.exit(setwd(old))
  dir.create("R"); dir.create("combined_data")
  file.copy(file.path(repo, "R/line_chart.R"), "R/")
  file.copy(file.path(repo, abs_calendar_file), "combined_data/")
  clk <- new.env(); clk$t <- mel(start)
  opts <- parse_rapid_args(c("--mode", mode, "--date", date, if (force) "--force", if (!baseline) "--no-baseline", extra))
  ctx <- new.env(); ctx$opts <- opts; ctx$session_id <- "test"
  ctx$log <- if (is.null(log)) read_rapid_log("none.csv") else log
  starts <- list()
  iterate <- function(ctx, plan, k, started_late = 0) {
    starts[[length(starts) + 1L]] <<- list(k = k, at = clk$t, late = started_late)
    clk$t <- clk$t + duration(k)
    if (k %in% fail) stop("simulated failure in iteration ", k)
    row <- new_log_row(ctx, plan, k, "published")
    add_log_row(ctx, row); row
  }
  res <- suppressMessages(capture.output(r <- run_rapid_session(opts, clock = function() clk$t,
                                                                sleep = function(s) clk$t <- clk$t + s,
                                                                iterate = iterate, ctx = ctx)))
  list(result = r, starts = starts, log = ctx$log,
       at = vapply(starts, function(s) format(s$at, "%H:%M:%S", tz = "Australia/Melbourne"), ""),
       k = vapply(starts, `[[`, 0, "k"))
}

s1 <- sim_session("2026-11-25 10:50:00")
check("release day: pre-release snapshot then five updates at 11:30-11:38",
      identical(s1$at, c("11:27:30", "11:30:00", "11:32:00", "11:34:00", "11:36:00", "11:38:00")))
s2 <- sim_session("2026-11-25 10:50:00", duration = function(k) 70, baseline = FALSE)
check("start times target the wall clock (70 s updates still start every 2 min)",
      identical(s2$at, c("11:30:00", "11:32:00", "11:34:00", "11:36:00", "11:38:00")))
s3 <- sim_session("2026-11-25 10:50:00", duration = function(k) 150, baseline = FALSE)
check("overrunning updates start late; a slot whose successor is due is missed, not backfilled",
      identical(s3$at, c("11:30:00", "11:32:30", "11:35:00", "11:37:30")) &&
        identical(s3$log$status[s3$log$slot == "11:38:00"], "missed"))
s4 <- sim_session("2026-11-25 10:50:00", fail = 2, baseline = FALSE)
check("failure of update 2 does not stop updates 3-5",
      identical(s4$k, c(1, 2, 3, 4, 5)) && identical(s4$log$status, c("published", "failed", "published", "published", "published")))
s5 <- sim_session("2026-11-25 11:35:10")
check("late job start: 11:30/11:32 logged missed, 11:34 runs late, then 11:36 and 11:38 on time",
      identical(s5$at, c("11:35:10", "11:36:00", "11:38:00")) &&
        identical(s5$log$status[1:2], c("missed", "missed")) && abs(s5$starts[[1]]$late - 70) < 1e-6)
s6 <- sim_session("2026-11-25 11:50:00")
check("job starting after every slot: all missed plus one labelled catch-up update",
      sum(s6$log$status == "missed") == 5 && identical(s6$at, "11:50:00") && s6$log$slot[6] == "catch-up")
s7 <- sim_session("2026-11-25 12:30:00")
check("no catch-up beyond the 30-minute limit", length(s7$starts) == 0 && sum(s7$log$status == "missed") == 5)
s8 <- sim_session("2026-11-26 10:50:00", date = "2026-11-26")
check("non-release day: nothing runs", identical(s8$result$status, "not-release-day") && !length(s8$starts))
s9 <- sim_session("2026-07-29 10:50:00", date = "2026-07-29", baseline = FALSE)
check("AEST release day uses 11:30 local (01:30 UTC)",
      identical(utc(s9$starts[[1]]$at), "2026-07-29 01:30:00") && length(s9$starts) == 5)
s10 <- sim_session("2026-11-25 11:07:00", log = data.frame(as.list(setNames(c("x", "release", "2026-11-25", "CPI", "1", "11:30:00", "published",
  rep(NA, length(rapid_log_cols) - 7)), rapid_log_cols))))
check("second scheduled trigger after a completed session exits", identical(s10$result$status, "already-ran"))
s11 <- sim_session("2026-11-26 15:00:20", date = "2026-11-26", mode = "immediate", force = TRUE,
                   extra = c("--iterations", "5", "--interval", "120"))
check("manual immediate mode ignores the calendar: 5 updates every 120 s from the next minute",
      identical(s11$at, c("15:01:00", "15:03:00", "15:05:00", "15:07:00", "15:09:00")))
check("immediate mode rejects sub-minute intervals",
      inherits(try(plan_slots(parse_rapid_args(c("--mode", "immediate", "--interval", "20"))), silent = TRUE), "try-error"))

# ------------------------------------------------------------------------------
# 3. Incremental dataset update == full rebuild
# ------------------------------------------------------------------------------
files <- tail(sort(list.files("daily_data", pattern = "[.]csv$", full.names = TRUE)), 40)
full <- rebuild_all_data(files)
inc <- append_scrape_files(rebuild_all_data(head(files, -3)), tail(files, 3))
check("incremental append equals a full rebuild", identical(inc$all_data, full))
csv_full <- tempfile(); csv_inc <- tempfile()
write_csv(full, csv_full)
write_csv(rebuild_all_data(head(files, -3)), csv_inc)
check("cash_rate.csv append path used", append_cash_rate_csv(inc$all_data, inc$new_rows, csv_inc) == "appended")
check("appended cash_rate.csv is byte-identical to a full rewrite", identical(unname(tools::md5sum(csv_full)), unname(tools::md5sum(csv_inc))))
caught <- catch_up_dataset(rebuild_all_data(head(files, -2)), dir = { d <- tempfile(); dir.create(d); file.copy(files, d); d })
check("catch-up appends only snapshots missing from the dataset", length(caught$files) == 2 && identical(caught$all_data, full))

# ------------------------------------------------------------------------------
# 4. Stale-feed detection (no fabricated observations)
# ------------------------------------------------------------------------------
latest_csv <- tail(files, 1)
raw <- read_csv(latest_csv, col_types = cols(.default = "c")) %>%
  select(-date, -scrape_date, -scrape_time, -cash_rate, -cash_rate_PreviousSettlement) %>%
  mutate(across(c(starts_with("price"), volume, combinedVolume, xid), as.numeric))
as_json <- function(df) as.character(toJSON(list(data = list(items = df)), dataframe = "rows", auto_unbox = TRUE, digits = NA, na = "null"))
stored <- rebuild_all_data(latest_csv)
same <- clean_scrape_data(parse_asx_futures(as_json(raw), mel("2026-11-25 11:30:05")))
moved <- clean_scrape_data(parse_asx_futures(as_json(mutate(raw, priceBid = priceBid - 0.005)), mel("2026-11-25 11:30:05")))
check("repeated feed payload is recognised as stale", identical(market_signature(same), latest_signature(stored)))
check("a changed bid is a new observation", !identical(market_signature(moved), latest_signature(stored)))

# ------------------------------------------------------------------------------
# 5-7. Charts, exclusions and git publishing in a sandbox repository
# ------------------------------------------------------------------------------
have_chart_pkgs <- all(vapply(c("plotly", "htmlwidgets", "ggplot2", "readrba", "viridis", "here", "glue"),
                              requireNamespace, logical(1), quietly = TRUE))
if (!have_chart_pkgs) {
  cat("SKIP: chart/publish tests (install plotly, htmlwidgets, readrba, viridis, here, glue)\n")
} else {
  rapid_load_packages()
  git <- function(dir, ...) {
    out <- suppressWarnings(system2("git", shQuote(c("-C", dir, ...)), stdout = TRUE, stderr = TRUE))
    if (!is.null(attr(out, "status"))) stop(paste(out, collapse = "\n"))
    out
  }
  sandbox <- tempfile("rapid_sandbox_")
  remote <- paste0(sandbox, ".git")
  dir.create(sandbox)
  for (d in c("R", "combined_data", "daily_data", "docs/data", "docs/plots/line_charts", "docs/plots/forecast_paths",
              "docs/plots/meeting_probabilities", "docs/meetings", "docs/meeting_lines")) dir.create(file.path(sandbox, d), recursive = TRUE)
  file.copy(list.files(file.path(repo, "R"), full.names = TRUE), file.path(sandbox, "R"))
  all_data <- readRDS(file.path(repo, "combined_data/all_data.Rds"))
  base <- all_data[all_data$scrape_time >= mel("2026-06-01"), ]
  saveRDS(base, file.path(sandbox, "combined_data/all_data.Rds"))
  write_csv(base, file.path(sandbox, "combined_data/cash_rate.csv"))
  for (f in c("combined_data/rmse_new.RData", "combined_data/rmse_new.csv", abs_calendar_file, "docs/data/rba-policy-state.json",
              "docs/data/cash-rate-latest.json", "docs/index.html", "docs/plots/line_charts/line.png",
              "docs/plots/line_charts/line_dual.png", "docs/line_interactive.html",
              "docs/plots/forecast_paths/cash_rate_forecast_paths.png", "docs/cash_rate_forecast_paths.html",
              "docs/rba_summary_data.rds"))
    file.copy(file.path(repo, f), file.path(sandbox, f))
  # Decoys standing in for outputs a rapid update must never touch.
  decoys <- c("docs/plots/meeting_probabilities/rate_probabilities_2026-12-08.png", "docs/meetings/daily_heatmap_2026-12-08.html",
              "docs/meeting_lines/line_probabilities_meeting_2026-12-08.png", "docs/plots/line_charts/line_08 Dec 2026.png")
  for (f in decoys) writeLines("decoy", file.path(sandbox, f))
  file.copy(tail(files, 1), file.path(sandbox, "daily_data"))
  git(sandbox, "init", "-q", "-b", "main")
  git(sandbox, "config", "user.name", "test"); git(sandbox, "config", "user.email", "test@example.invalid")
  git(sandbox, "add", "-A"); git(sandbox, "commit", "-qm", "base")
  system2("git", c("clone", "-q", "--bare", shQuote(sandbox), shQuote(remote)))
  git(sandbox, "remote", "add", "origin", remote); git(sandbox, "fetch", "-q", "origin")
  git(sandbox, "branch", "-q", "--set-upstream-to=origin/main", "main")
  other <- tempfile("other_writer_")
  system2("git", c("clone", "-q", shQuote(remote), shQuote(other)))
  git(other, "config", "user.name", "other"); git(other, "config", "user.email", "other@example.invalid")

  old <- setwd(sandbox)
  decoy_md5 <- tools::md5sum(c(decoys, "docs/index.html", "combined_data/rmse_new.RData", "combined_data/rmse_new.csv",
                               "docs/rba_summary_data.rds", "docs/data/rba-policy-state.json"))

  # Fixture payloads: unchanged, moved, failing request, moved again, moved again.
  fx <- tempfile("fixtures_"); dir.create(fx)
  writeLines(as_json(raw), file.path(fx, "1_same.json"))
  m1 <- mutate(raw, dateLastTrade = ifelse(is.na(priceLastTrade), dateLastTrade, "2026-11-25"), priceLastTrade = priceLastTrade + 0.02, volume = volume + 500)
  writeLines(as_json(m1), file.path(fx, "2_moved.json"))
  for (f in c("3a_fail.json", "3b_fail.json", "3c_fail.json")) writeLines("{}", file.path(fx, f))  # all retries fail
  writeLines(as_json(mutate(m1, priceLastTrade = priceLastTrade + 0.015, volume = volume + 300)), file.path(fx, "4_moved.json"))
  writeLines(as_json(mutate(m1, priceLastTrade = priceLastTrade + 0.03, volume = volume + 900)), file.path(fx, "5_moved.json"))
  Sys.setenv(RAPID_FIXTURE_DIR = fx)

  opts <- parse_rapid_args(c("--mode", "release", "--date", "2026-11-25", "--publish", "--branch", "main", "--no-baseline"))
  clk <- new.env(); clk$t <- mel("2026-11-25 11:29:00")
  ctx <- NULL
  ctx <- suppressMessages(init_context(opts, now = clk$t))
  ctx$now <- function() clk$t
  ctx$branch <- "main"
  check("chart inputs come from caches (no RMSE recalculation)", !is.null(ctx$rmse_days) && is.null(ctx$chart_error))
  timings <- list()
  concurrent <- function(k) {
    if (k == 2) {  # another writer pushes an unrelated file: rebase, then push
      writeLines("concurrent", file.path(other, "docs/index.html"))
      git(other, "commit", "-qam", "other: index"); git(other, "push", "-q", "origin", "main")
    }
    if (k == 4) {  # another writer rewrites the dataset: genuine conflict -> resync
      git(other, "pull", "-q", "--rebase", "origin", "main")
      d <- readRDS(file.path(other, "combined_data/all_data.Rds"))
      saveRDS(d, file.path(other, "combined_data/all_data.Rds"), compress = "xz")
      git(other, "commit", "-qam", "other: rewrite dataset"); git(other, "push", "-q", "origin", "main")
    }
  }
  iterate <- function(ctx, plan, k, started_late = 0) {
    concurrent(k)
    t0 <- Sys.time()
    row <- run_iteration(ctx, plan, k, started_late)
    timings[[length(timings) + 1L]] <<- as.numeric(difftime(Sys.time(), t0, units = "secs"))
    clk$t <- clk$t + 30
    row
  }
  invisible(capture.output(res <- run_rapid_session(opts, clock = function() clk$t, sleep = function(s) clk$t <- clk$t + s,
                                                    iterate = iterate, ctx = ctx)))
  st <- res$log$status
  check("five scheduled updates: stale, published, failed fetch, published (after rebase), published (after resync)",
        identical(st, c("stale", "published", "failed", "published", "published")))
  git(sandbox, "fetch", "-q", "origin")
  remote_files <- git(sandbox, "ls-tree", "-r", "--name-only", "origin/main")
  remote_log <- git(sandbox, "log", "--format=%s", "origin/main")
  check("each update was pushed as its own commit",
        sum(grepl("^Rapid ABS update \\(CPI\\) slot", remote_log)) >= 3 && any(grepl("^Rapid ABS update log", remote_log)))
  check("concurrent writers' commits preserved", any(remote_log == "other: index") && any(remote_log == "other: rewrite dataset"))
  snaps <- grep("^daily_data/scraped_cash_rate_2026-11-25_11(3[0-9])[.]csv$", remote_files, value = TRUE)
  check("all three new snapshots published (none lost in the conflict)", length(snaps) == 3)
  git(sandbox, "checkout", "-q", "origin/main")
  final <- readRDS("combined_data/all_data.Rds")
  check("published dataset = previous dataset + exactly the new snapshots (incremental)",
        identical(final, append_scrape_files(base, sort(snaps))$all_data))
  check("published cash_rate.csv matches the published dataset",
        identical(unname(tools::md5sum("combined_data/cash_rate.csv")),
                  { f <- tempfile(); write_csv(final, f); unname(tools::md5sum(f)) }))
  changed <- unique(unlist(lapply(grep("^[0-9a-f]+ Rapid ABS update", git(sandbox, "log", "--format=%H %s", "origin/main"), value = TRUE),
    function(l) git(sandbox, "show", "--name-only", "--format=", sub(" .*", "", l)))))
  check("rapid commits touch only allowlisted outputs", length(changed) && all(rapid_allowed(changed)))
  check("all allowlisted charts and data regenerated and published",
        all(c(rapid_chart_groups$line$files, rapid_chart_groups$paths$files, rapid_data_outputs) %in% changed))
  keep <- names(decoy_md5) != "docs/index.html"  # index.html was changed by the other writer
  check("excluded outputs untouched (bar charts, heatmaps, meeting lines, dated copies, RMSE, summary, policy cache)",
        identical(tools::md5sum(names(decoy_md5)[keep]), decoy_md5[keep]))
  check("no per-meeting bar charts generated", identical(list.files("docs/plots/meeting_probabilities"), basename(decoys[1])))
  rl <- read.csv("combined_data/rapid_update_log.csv", colClasses = "character")
  check("log records scrape time, publication time and durations for published updates",
        all(!is.na(rl$scraped_at[rl$status == "published"]) & nzchar(rl$published_at[rl$status == "published"]) &
              as.numeric(rl$total_s[rl$status == "published"]) > 0))
  check("refuses to publish files outside the allowlist",
        inherits(try(publish_files(ctx, "docs/index.html", "x"), silent = TRUE), "try-error"))
  cat(sprintf("INFO: per-update wall time (s): %s\n", paste(round(unlist(timings), 1), collapse = ", ")))
  print(rl[, c("slot", "status", "fetch_s", "dataset_s", "line_s", "paths_s", "publish_s", "total_s")])

  # Regular pipeline unaffected: full mode still writes bar charts and dated copies.
  git(sandbox, "checkout", "-q", "main")
  env_full <- new.env()
  invisible(capture.output(suppressWarnings(suppressMessages(source("R/line_chart.R", local = env_full)))))
  check("full mode still writes per-meeting bar charts, dated copies and summary",
        length(list.files("docs/plots/meeting_probabilities")) > 1 &&
          tools::md5sum("docs/plots/line_charts/line_08 Dec 2026.png") != decoy_md5[["docs/plots/line_charts/line_08 Dec 2026.png"]] &&
          file.mtime("docs/rba_summary_data.rds") > Sys.time() - 600)
  # Rapid mode computes the same probabilities as the full script.
  env_rapid <- new.env(parent = ctx$base_env)
  env_rapid$rapid_ctx <- list(out_dir = tempfile(), cash_rate = line_window(readRDS("combined_data/all_data.Rds"), env_full$policy_state),
                              rmse_days = env_full$rmse_days, policy_state = env_full$policy_state,
                              rba_historical = env_full$rba_historical)
  invisible(capture.output(suppressWarnings(suppressMessages(source("R/line_chart.R", local = env_rapid)))))
  check("rapid line chart data identical to full mode (top outcomes, probabilities)",
        identical(env_rapid$top3_df, env_full$top3_df) && identical(env_rapid$latest_scrape, env_full$latest_scrape))
  setwd(old)
  Sys.unsetenv("RAPID_FIXTURE_DIR")
}

# ------------------------------------------------------------------------------
# 8. Workflows: shared concurrency group, gate, manual trigger
# ------------------------------------------------------------------------------
if (requireNamespace("yaml", quietly = TRUE)) {
  rapid_wf <- yaml::read_yaml(".github/workflows/rapid-update.yaml")
  regular_wf <- yaml::read_yaml(".github/workflows/refresh-data.yaml")
  on_rapid <- rapid_wf[["on"]] %||% rapid_wf[["TRUE"]]  # YAML 1.1 reads `on` as TRUE
  on_regular <- regular_wf[["on"]] %||% regular_wf[["TRUE"]]
  check("rapid and regular publishing share one non-cancelling concurrency group",
        rapid_wf$jobs$`rapid-update`$concurrency$group == "cash-rate-publish" &&
          grepl("cash-rate-publish", regular_wf$jobs$`refresh-data`$concurrency$group) &&
          isFALSE(rapid_wf$jobs$`rapid-update`$concurrency$`cancel-in-progress`) &&
          isFALSE(regular_wf$jobs$`refresh-data`$concurrency$`cancel-in-progress`))
  check("rapid workflow has a manual trigger", !is.null(on_rapid$workflow_dispatch$inputs$schedule))
  check("regular schedule left intact", identical(vapply(on_regular$schedule, `[[`, "", "cron"), c("*/10 * * * *", "0 3 * * *", "0 0 1 * *")))
  crons <- vapply(on_rapid$schedule, `[[`, "", "cron")
  fire <- function(cron, date) {  # UTC trigger instants on a Melbourne date
    p <- strsplit(cron, " ")[[1]]
    t <- as.POSIXct(sprintf("%s %02d:%02d", date, as.integer(p[2]), as.integer(p[1])), tz = "UTC")
    c(t - 86400, t)
  }
  covered <- function(date) {
    times <- do.call(c, lapply(crons, fire, date = date))
    local <- format(times, "%Y-%m-%d %H:%M", tz = "Australia/Melbourne")
    sum(substr(local, 1, 10) == date & substr(local, 12, 16) >= "10:30" & substr(local, 12, 16) <= "11:20")
  }
  check("two early triggers on AEDT and AEST release days", covered("2026-11-25") == 2 && covered("2026-07-29") == 2)
}

cat(if (failures) sprintf("\n%d FAILED\n", failures) else "\nALL RAPID-UPDATE TESTS PASSED\n")
if (failures) quit(status = 1)
