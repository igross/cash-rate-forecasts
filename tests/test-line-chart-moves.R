# Run from the repository root: Rscript tests/test-line-chart-moves.R
suppressPackageStartupMessages({library(dplyr); library(plotly)})
expressions <- parse('R/line_chart.R')
assignment <- function(name) {
  found <- Filter(function(e) is.call(e) && identical(e[[1]], as.name('<-')) &&
    identical(e[[2]], as.name(name)), as.list(expressions))
  stopifnot(length(found) == 1L)
  found[[1]]
}
for (n_times in c(1L, 2L)) for (offsets in list(c(-.75, -.25, 0, .75), c(-1.25, -.25, 0, 1), c(0, .25, .5, 1.25))) {
  env <- new.env(parent = globalenv())
  env$current_center <- 4.35
  env$next_meeting <- as.Date('2026-09-29')
  env$all_estimates_buckets <- data.frame(
    meeting_date = env$next_meeting,
    bucket = rep(env$current_center + offsets, each = n_times),
    scrape_time = rep(as.POSIXct(c('2026-09-27','2026-09-28'), tz='UTC')[seq_len(n_times)],4),
    probability = rep(c(.1,.2,.3,.4),each=n_times)
  )
  for (name in c('buckets_with_moves','move_levels','top3_buckets','top3_df','move_colors','extra_moves')) {
    eval(assignment(name), env)
  }
  extension <- Filter(function(e) is.call(e) && identical(e[[1]], as.name('if')) &&
    identical(e[[2]], quote(length(extra_moves))), as.list(expressions))
  stopifnot(length(extension)==1L)
  eval(extension[[1]],env)
  labels <- unique(as.character(env$top3_df$move))
  stopifnot(length(labels)==4L, !anyNA(labels),
    all(labels %in% names(env$move_colors)),
    identical(env$move_colors[['No change']], '#BFBFBF'))
  # Exercise the actual trace loop, including named colour lookup and grouping.
  env$interactive_line <- plot_ly()
  env$line_int_plot <- env$top3_df %>% mutate(local_time=scrape_time,
    probability_pct=100*probability,hover_text=as.character(move))
  loop <- Filter(function(e) is.call(e) && identical(e[[1]],as.name('for')) &&
    identical(e[[2]],as.name('mv')),as.list(expressions))
  stopifnot(length(loop)==1L)
  eval(loop[[1]],env)
  traces <- plotly_build(env$interactive_line)$x$data
  stopifnot(length(traces)==4L)
  for (t in traces) stopifnot(length(t$x)==n_times,
    identical(t$mode, if(n_times==1L) 'lines+markers' else 'lines'),
    identical(t$line$color,unname(env$move_colors[[t$name]])))
}
cat('PASS: standard, large-cut and large-hike outcomes retain labels and Plotly colours\n')
