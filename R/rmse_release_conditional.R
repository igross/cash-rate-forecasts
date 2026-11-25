# ==============================================================================
# Alternative RMSE: days to decision + remaining CPI / Labour Force releases
# ==============================================================================
# Experimental companion to R/rmse.R (which models forecast error by days to
# the meeting only). Here the expected squared error of the futures-implied
# post-meeting cash rate depends on
#   * days to the decision, and
#   * whether a CPI release (quarterly CPI or monthly CPI/CPI indicator) and/or
#     a Labour Force release is still scheduled between the forecast and the
#     14:30 decision.
#
# Sample: forecasts for the NEXT meeting (made after the previous decision),
# the window in which "is a release still to come?" actually varies. For longer
# horizons both releases always remain, so the alternative coincides with the
# days-only measure.
#
# Forecast = implied post-meeting rate, decomposed exactly as in
# R/line_chart.R; error = forecast - realised target after the meeting.
# Outcomes come from readrba (RBA F1 cash rate target) when available,
# otherwise the "Actual" column of combined_data/f17_rmse.csv. Release dates
# come from the repository calendar (R/abs_release_calendar.R), backfilled from
# official ABS release pages from January 2022, so the sample runs from the
# start of the futures archive (April 2022).
#
# Approach 1 (main): daily-revision variance decomposition. If the implied
# rate is an efficient forecast, its error is the sum of the remaining daily
# revisions plus the decision-day surprise, so
#   E[e^2] = quiet_days * v_quiet + n_cpi * v_cpi + n_lf * v_lf + v_decision,
# with v_* estimated from every trading-day revision (including meetings not
# yet decided) - far more data than realised meeting outcomes alone.
# Approach 2: direct regression of realised squared errors on a days spline
# and the two release flags. Both are compared with days-only versions by
# leave-one-meeting-out cross-validation (Gaussian log score, calibration).
#
# Outputs (does not modify rmse_new.RData or any published chart):
#   combined_data/rmse_release_conditional.csv       lookup table
#   combined_data/rmse_release_conditional_eval.csv  cross-validation scores
#   combined_data/rmse_release_conditional_cells.csv raw RMSE by horizon bucket
#   docs/plots/rmse/rmse_release_conditional.png
# ==============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(lubridate); library(readr)
  library(ggplot2); library(splines)
})
source("R/abs_release_calendar.R")

tz <- "Australia/Melbourne"

# ---- Meetings ---------------------------------------------------------------
meetings <- as.Date(c(
  "2022-02-01", "2022-03-01", "2022-04-05", "2022-05-03", "2022-06-07", "2022-07-05",
  "2022-08-02", "2022-09-06", "2022-10-04", "2022-11-01", "2022-12-06",
  "2023-02-07", "2023-03-07", "2023-04-04", "2023-05-02", "2023-06-06", "2023-07-04",
  "2023-08-01", "2023-09-05", "2023-10-03", "2023-11-07", "2023-12-05",
  "2024-02-06", "2024-03-19", "2024-05-07", "2024-06-18", "2024-08-06", "2024-09-24",
  "2024-11-05", "2024-12-10",
  "2025-02-18", "2025-04-01", "2025-05-20", "2025-07-08", "2025-08-12", "2025-09-30",
  "2025-11-04", "2025-12-09",
  "2026-02-03", "2026-03-17", "2026-05-05", "2026-06-16", "2026-08-11", "2026-09-29",
  "2026-11-03", "2026-12-08", "2027-02-09"
))
meeting_tbl <- tibble(meeting_date = meetings[-1], previous_meeting = meetings[-length(meetings)]) %>%
  mutate(
    decision_time = as.POSIXct(paste(meeting_date, "14:30:00"), tz = tz),
    window_start = as.POSIXct(paste(previous_meeting, "14:30:00"), tz = tz),
    expiry = if_else(day(meeting_date) >= days_in_month(meeting_date) - 1,
                     ceiling_date(meeting_date, "month"), floor_date(meeting_date, "month"))
  )

# ---- Realised cash-rate target ---------------------------------------------
target_series <- tryCatch({
  x <- readrba::read_rba(series_id = "FIRMMCRTD")
  message("Outcomes: readrba FIRMMCRTD")
  transmute(x, date = as.Date(date), rate = value)
}, error = function(e) {
  message("Outcomes: readrba unavailable (", conditionMessage(e), "); using f17_rmse.csv Actual")
  f17 <- read_csv("combined_data/f17_rmse.csv", col_types = cols(.default = "c"), name_repair = "minimal")
  tibble(date = dmy(f17[[1]]), rate = as.numeric(f17[["Actual"]])) %>%
    filter(!is.na(date), !is.na(rate))
}) %>% arrange(date)
rate_on <- function(d) {
  i <- findInterval(as.numeric(d), as.numeric(target_series$date))
  ifelse(i > 0, target_series$rate[pmax(i, 1)], NA_real_)
}
last_rate_date <- max(target_series$date)

meeting_tbl <- meeting_tbl %>%
  mutate(actual_after = if_else(meeting_date + 1 <= last_rate_date, rate_on(meeting_date + 1), NA_real_))

# ---- Releases ---------------------------------------------------------------
cal <- load_abs_calendar()
rel <- cal %>%
  filter(dataset %in% c("CPI", "CPI Indicator", "Labour Force")) %>%
  transmute(type = if_else(dataset == "Labour Force", "lf", "cpi"),
            at = as.POSIXct(paste(release_date, release_time), format = "%Y-%m-%d %H:%M", tz = tz)) %>%
  distinct()
cal_start <- min(rel$at)

# ---- Daily next-meeting snapshots -------------------------------------------
cash <- readRDS("combined_data/all_data.Rds") %>%
  mutate(scrape_time = with_tz(scrape_time, tz), forecast_date = as.Date(scrape_time, tz = tz))

snaps <- cash %>%
  inner_join(meeting_tbl, by = c("date" = "expiry"), relationship = "many-to-many") %>%
  filter(scrape_time > window_start, forecast_date < meeting_date,
         window_start >= cal_start,                        # release calendar covers the window
         wday(forecast_date, week_start = 1) <= 5) %>%
  group_by(meeting_date, forecast_date) %>%
  slice_max(scrape_time, n = 1, with_ties = FALSE) %>%     # latest snapshot each weekday
  ungroup() %>%
  mutate(
    days_ahead = as.integer(meeting_date - forecast_date),
    # rate in force: the previous decision applies from its 14:30 announcement
    rate_before = rate_on(forecast_date + (forecast_date == previous_meeting)),
    # date = contract month; decomposition as in R/line_chart.R
    nb = if_else(meeting_date < date, 0, (day(meeting_date) - 1) / days_in_month(date)),
    implied = (cash_rate - rate_before * nb) / (1 - nb),
    error = implied - actual_after,
    error_contract = cash_rate - actual_after              # R/rmse.R definition (sensitivity)
  ) %>%
  filter(is.finite(implied)) %>%
  arrange(meeting_date, scrape_time)

# Releases of a type between two instants, counting each release day once
# (quarterly CPI and the monthly indicator were often published together).
n_between <- function(type, from, to) {
  vapply(seq_along(from), function(i) {
    hit <- rel$type == type & rel$at > from[i] & rel$at < to[i]
    length(unique(rel$at[hit]))
  }, integer(1))
}
weekdays_between <- function(from, to) {   # weekdays in (from, to]
  vapply(seq_along(from), function(i) {
    if (is.na(from[i]) || is.na(to[i])) return(NA_integer_)
    if (to[i] <= from[i]) return(0L)
    d <- seq(from[i] + 1, to[i], by = "day"); sum(wday(d, week_start = 1) <= 5)
  }, integer(1))
}
release_days_between <- function(from_time, to_date) {
  vapply(seq_along(from_time), function(i) {
    hit <- rel$at > from_time[i] & as.Date(rel$at, tz = tz) <= to_date[i]
    length(unique(as.Date(rel$at[hit], tz = tz)))
  }, integer(1))
}

# Releases still to come before the decision, counted up to the last
# pre-decision trading day (a release on decision morning is part of the
# decision-day surprise).
snaps <- snaps %>%
  mutate(cutoff = as.POSIXct(paste(meeting_date, "00:00:00"), tz = tz),
         n_cpi = n_between("cpi", scrape_time, cutoff),
         n_lf = n_between("lf", scrape_time, cutoff),
         cpi_remaining = n_cpi > 0, lf_remaining = n_lf > 0,
         n_weekdays = weekdays_between(forecast_date, meeting_date - 1),
         n_release_days = release_days_between(scrape_time, meeting_date - 1),
         releases_remaining = case_when(cpi_remaining & lf_remaining ~ "CPI and Labour Force",
                                        cpi_remaining ~ "CPI only", lf_remaining ~ "Labour Force only",
                                        TRUE ~ "None"))
forecasts <- snaps %>% filter(!is.na(actual_after)) %>% mutate(e2 = error^2)

cat(sprintf("Snapshots: %d weekday next-meeting forecasts for %d meetings (%s to %s); %d meetings have outcomes\n",
            nrow(snaps), n_distinct(snaps$meeting_date), min(snaps$meeting_date), max(snaps$meeting_date),
            n_distinct(forecasts$meeting_date)))
print(count(forecasts, releases_remaining))

# ---- Raw RMSE by horizon bucket x remaining releases -----------------------
cells <- forecasts %>%
  mutate(horizon = cut(days_ahead, c(0, 7, 14, 21, 28, 35, 70),
                       labels = c("1-7", "8-14", "15-21", "22-28", "29-35", "36+"))) %>%
  group_by(horizon, releases_remaining) %>%
  summarise(n = n(), meetings = n_distinct(meeting_date), rmse = sqrt(mean(e2)),
            rmse_contract = sqrt(mean(error_contract^2)), .groups = "drop")
cat("\nRealised RMSE (pp) by horizon and releases still to come:\n")
print(as.data.frame(cells), digits = 3)

# ---- Approach 1: daily-revision variance decomposition ---------------------
# Revisions between consecutive trading-day snapshots, classified by whether a
# CPI and/or Labour Force release fell between them.
revisions <- snaps %>%
  group_by(meeting_date) %>%
  mutate(prev_time = lag(scrape_time), prev_date = lag(forecast_date), revision = implied - lag(implied)) %>%
  ungroup() %>%
  filter(!is.na(revision)) %>%
  filter(weekdays_between(prev_date, forecast_date) == 1L) %>%   # consecutive trading days only
  mutate(cpi_day = n_between("cpi", prev_time, scrape_time) > 0,
         lf_day = n_between("lf", prev_time, scrape_time) > 0,
         day_type = case_when(cpi_day & lf_day ~ "CPI+LF", cpi_day ~ "CPI", lf_day ~ "LF", TRUE ~ "quiet"))
decision_surprises <- forecasts %>%
  group_by(meeting_date) %>% slice_max(scrape_time, n = 1, with_ties = FALSE) %>% ungroup() %>%
  transmute(meeting_date, surprise = -error)

estimate_variances <- function(rev, dec) {
  v <- function(x) if (length(x)) mean(x^2) else NA_real_
  out <- list(quiet = v(rev$revision[rev$day_type == "quiet"]),
              cpi = v(rev$revision[rev$day_type == "CPI"]),
              lf = v(rev$revision[rev$day_type == "LF"]),
              all = v(rev$revision),
              decision = v(dec$surprise))
  out$cpi[is.na(out$cpi)] <- out$all; out$lf[is.na(out$lf)] <- out$all
  out
}
predict_sd <- function(d, v, release_aware = TRUE) {
  if (!release_aware) return(sqrt(d$n_weekdays * v$all + v$decision))
  quiet <- pmax(d$n_weekdays - d$n_release_days, 0)
  sqrt(quiet * v$quiet + d$n_cpi * v$cpi + d$n_lf * v$lf + v$decision)
}
v_full <- estimate_variances(revisions, decision_surprises)
rev_summary <- revisions %>% group_by(day_type) %>%
  summarise(n = n(), rms_revision_bp = 100 * sqrt(mean(revision^2)), .groups = "drop")
cat("\nDaily revisions of the implied next-meeting rate (all windows, incl. meetings not yet decided):\n")
print(as.data.frame(rev_summary), digits = 3)
cat(sprintf("Decision-day surprise RMS: %.1f bp over %d meetings\n", 100 * sqrt(v_full$decision), nrow(decision_surprises)))

# ---- Approach 2: direct regression of realised squared errors ---------------
fit_glms <- function(d) list(
  baseline = glm(e2 ~ ns(days_ahead, df = 3), family = quasipoisson(link = "log"), data = d),
  release = glm(e2 ~ ns(days_ahead, df = 3) + cpi_remaining + lf_remaining,
                family = quasipoisson(link = "log"), data = d))
glm_full <- fit_glms(forecasts)
cat("\nDirect regression (log variance multipliers on realised errors):\n")
print(summary(glm_full$release)$coefficients[c("cpi_remainingTRUE", "lf_remainingTRUE"), , drop = FALSE], digits = 3)

# ---- Leave-one-meeting-out evaluation ---------------------------------------
floor_sd <- 0.005   # 0.5 bp floor so near-certain forecasts are not infinitely confident
cv <- bind_rows(lapply(unique(forecasts$meeting_date), function(m) {
  test <- filter(forecasts, meeting_date == m)
  v <- estimate_variances(filter(revisions, meeting_date != m), filter(decision_surprises, meeting_date != m))
  g <- fit_glms(filter(forecasts, meeting_date != m))
  sds <- list(
    `days only (spline, rmse.R-style)` = sqrt(predict(g$baseline, newdata = test, type = "response")),
    `days + releases (direct regression)` = sqrt(predict(g$release, newdata = test, type = "response")),
    `days only (revision decomposition)` = predict_sd(test, v, release_aware = FALSE),
    `days + releases (revision decomposition)` = predict_sd(test, v, release_aware = TRUE))
  bind_rows(lapply(names(sds), function(nm) tibble(model = nm, meeting_date = m, days_ahead = test$days_ahead,
                                                    error = test$error, sd = pmax(sds[[nm]], floor_sd))))
}))
eval_tbl <- cv %>%
  group_by(model) %>%
  summarise(n = n(), mean_log_score = mean(dnorm(error, 0, sd, log = TRUE)),
            mean_z2 = mean((error / sd)^2), coverage_90 = mean(abs(error) <= qnorm(0.95) * sd),
            mean_sd_bp = 100 * mean(sd), .groups = "drop") %>%
  arrange(desc(mean_log_score))
eval_by_meeting <- cv %>%
  group_by(meeting_date, model) %>%
  summarise(mean_log_score = mean(dnorm(error, 0, sd, log = TRUE)), .groups = "drop")
cat("\nLeave-one-meeting-out evaluation (higher log score is better; mean_z2 near 1 and coverage near 0.90 are calibrated):\n")
print(as.data.frame(eval_tbl), digits = 3)
wins <- eval_by_meeting %>% tidyr::pivot_wider(names_from = model, values_from = mean_log_score)
cat(sprintf("Revision decomposition: release-aware beats days-only for %d of %d held-out meetings\n",
            sum(wins$`days + releases (revision decomposition)` > wins$`days only (revision decomposition)`), nrow(wins)))

# ---- Lookup table (revision decomposition) ------------------------------------
# One release of each flagged type; trading days approximated as 5/7 of days.
max_days <- max(snaps$days_ahead)
lookup <- expand_grid(days_to_meeting = 1:max_days, cpi_remaining = c(FALSE, TRUE), lf_remaining = c(FALSE, TRUE)) %>%
  mutate(n_weekdays = pmax(round((days_to_meeting - 1) * 5 / 7), 0),
         n_cpi = as.integer(cpi_remaining), n_lf = as.integer(lf_remaining),
         n_release_days = pmin(n_cpi + n_lf, n_weekdays)) %>%
  filter(n_cpi + n_lf <= n_weekdays | (n_cpi + n_lf == 0)) %>%
  mutate(rmse_release = predict_sd(., v_full, TRUE),
         rmse_days_only = predict_sd(., v_full, FALSE),
         ratio = rmse_release / rmse_days_only) %>%
  select(days_to_meeting, cpi_remaining, lf_remaining, rmse_release, rmse_days_only, ratio)

dir.create("docs/plots/rmse", recursive = TRUE, showWarnings = FALSE)
write_csv(lookup, "combined_data/rmse_release_conditional.csv")
write_csv(bind_rows(mutate(eval_tbl, scope = "all"),
                    mutate(eval_by_meeting, scope = "by meeting")),
          "combined_data/rmse_release_conditional_eval.csv")
write_csv(cells, "combined_data/rmse_release_conditional_cells.csv")

scen <- function(cpi, lf) case_when(cpi & lf ~ "CPI and Labour Force still to come", cpi ~ "Only CPI still to come",
                                    lf ~ "Only Labour Force still to come", TRUE ~ "No CPI or Labour Force release left")
p <- ggplot() +
  geom_point(data = mutate(forecasts, scenario = scen(cpi_remaining, lf_remaining)),
             aes(days_ahead, abs(error) * 100, colour = scenario), alpha = 0.4, size = 1.3) +
  geom_line(data = mutate(lookup, scenario = scen(cpi_remaining, lf_remaining)),
            aes(days_to_meeting, rmse_release * 100, colour = scenario), linewidth = 1) +
  geom_line(data = distinct(lookup, days_to_meeting, rmse_days_only),
            aes(days_to_meeting, rmse_days_only * 100), colour = "grey20", linetype = "dashed") +
  scale_x_reverse() +
  labs(title = "Forecast error of the implied post-meeting cash rate",
       subtitle = sprintf("Lines: release-aware RMSE (revision decomposition); dashed: days only. Points: |realised error|, %d meetings",
                          n_distinct(forecasts$meeting_date)),
       x = "Days to decision", y = "Basis points", colour = NULL) +
  theme_minimal(base_size = 12) + theme(legend.position = "bottom", plot.title = element_text(face = "bold"))
ggsave("docs/plots/rmse/rmse_release_conditional.png", p, width = 10, height = 6, dpi = 200)
cat("\nSaved combined_data/rmse_release_conditional*.csv and docs/plots/rmse/rmse_release_conditional.png\n")
