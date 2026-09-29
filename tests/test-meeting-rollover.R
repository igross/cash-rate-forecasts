suppressPackageStartupMessages({library(dplyr);library(lubridate)})
expr <- as.list(parse('R/line_chart.R'))
get_expr <- function(name) Filter(function(e) is.call(e) && identical(e[[1]],as.name('<-')) && identical(e[[2]],as.name(name)),expr)[[1]]
meeting_schedule <- data.frame(meeting_date=as.Date(c('2026-08-11','2026-09-29','2026-11-03')))
for (clock in c('14:29:59','14:30:00','14:30:01')) {
 now_melb <- as.POSIXct(paste('2026-09-29',clock),tz='Australia/Melbourne')
 today_melb <- as.Date('2026-09-29')
 cutoff <- as.POSIXct('2026-09-29 14:30:00',tz='Australia/Melbourne')
 eval(get_expr('next_meeting'))
 stopifnot(next_meeting==as.Date(if(clock=='14:29:59') '2026-09-29' else '2026-11-03'))
}
# Check the exact selection block for a single post-rollover scrape, a morning
# scrape, and a last-available scrape from yesterday (before new data arrives).
i <- which(vapply(expr,function(e) identical(e,get_expr('window_start')),logical(1)))
j <- which(vapply(expr,function(e) is.call(e) && identical(e[[1]],as.name('print')) && identical(e[[2]],'Latest scrapes:'),logical(1)))
previous_meeting <- as.Date('2026-09-29')
for (stamp in c('2026-09-29 15:12:00','2026-09-29 08:00:00','2026-09-28 21:00:00')) {
 cash_rate <- data.frame(scrape_time=as.POSIXct(stamp,tz='Australia/Melbourne'))
 for (e in expr[i:(j-1)]) eval(e)
 stopifnot(length(scrapes)==1L, identical(as.numeric(scrapes),as.numeric(cash_rate$scrape_time)))
 top3_df <- cash_rate
 eval(get_expr('start_xlim'))
 stopifnot(scrapes > start_xlim)
}
cat('PASS: 14:30 meeting rollover, one snapshot, Melbourne morning and stale-snapshot fallback\n')
