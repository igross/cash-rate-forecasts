source('R/rba_policy_state.R')
page <- function(rate,effective,next_date) paste0('<div class="landing-page-chart-statistic"><p class="landing-page-chart-statistic-value">',rate,' %</p><p>Effective date ',effective,'</p><p>Next update 2.30 pm, ',next_date,'</p></div>')
decisions <- function(day) paste0('<a href="/media-releases/2026/test.html">',day,'</a>')
clock <- function(x) as.POSIXct(paste('2026-09-29',x),tz='Australia/Sydney')
old <- rba_policy_parse(page(4.35,'12 August 2026','29 September 2026'),decisions('11 August 2026'),clock('14:29:59'))
stopifnot(inherits(try(rba_policy_validate(old,clock('14:30:00')),silent=TRUE),'try-error'))
x <- rba_policy_parse(page(4.60,'30 September 2026','3 November 2026'),decisions('29 September 2026'),clock('14:30:00'))
stopifnot(x$rate==4.60,x$nextMeeting=='2026-11-03',x$effectiveDate=='2026-09-30')
h <- data.frame(date=as.Date('2026-09-28'),value=4.35)
stopifnot(rba_rate_at_snapshot(clock('14:29:59'),x,h)==4.35,
 rba_rate_at_snapshot(clock('14:30:00'),x,h)==4.60,
 rba_rate_at_snapshot(as.POSIXct('2026-09-30 10:00:00',tz='Australia/Sydney'),x,h)==4.60)
# The next decision is in daylight-saving time; expire by Sydney clock, not UTC.
rba_policy_validate(x,as.POSIXct('2026-11-03 14:29:59',tz='Australia/Sydney'))
stopifnot(inherits(try(rba_policy_validate(x,as.POSIXct('2026-11-03 14:30:00',tz='Australia/Sydney')),silent=TRUE),'try-error'))
# Reject asynchronously updated official pages rather than backdating a new rate.
stopifnot(inherits(try(rba_policy_parse(page(4.60,'30 September 2026','3 November 2026'),decisions('11 August 2026'),clock('14:31:00')),silent=TRUE),'try-error'))
# No-change decisions may retain an earlier effective date.
hold <- rba_policy_parse(page(4.35,'12 August 2026','3 November 2026'),decisions('29 September 2026'),clock('14:31:00'))
stopifnot(hold$rate==4.35)
cache <- tempfile(fileext='.json');jsonlite::write_json(x,cache,auto_unbox=TRUE)
failure <- function(url) stop('Simulated network outage')
stopifnot(suppressWarnings(rba_policy_state(cache,clock('15:00:00'),failure))$rate==4.60)
jsonlite::write_json(old,cache,auto_unbox=TRUE)
stopifnot(inherits(try(rba_policy_state(cache,clock('15:00:00'),failure),silent=TRUE),'try-error'))
unlink(cache)
cat('PASS: announcement cutoff, workbook lag, unchanged rates, valid cache, expired-cache rejection\n')
