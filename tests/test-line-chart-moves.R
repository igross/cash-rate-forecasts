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
    probability_linear = rep(c(0,.4,.6,0),each=n_times),
    probability = rep(c(.1,.2,.3,.4),each=n_times)
  )
  for (name in c('buckets_with_moves','move_levels','top3_buckets','comparison_buckets','display_buckets','top3_df','move_colors','extra_moves')) {
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
    probability_pct=100*probability,linear_pct=100*probability_linear,
    hover_text=as.character(move),linear_hover=paste(move,"linear"))
  loop <- Filter(function(e) is.call(e) && identical(e[[1]],as.name('for')) &&
    identical(e[[2]],as.name('mv')),as.list(expressions))
  stopifnot(length(loop)==1L)
  eval(loop[[1]],env)
  traces <- plotly_build(env$interactive_line)$x$data
  stopifnot(length(traces)==8L)
  for (t in traces) stopifnot(length(t$x)==n_times,
    identical(t$mode, if(n_times==1L) 'lines+markers' else 'lines'),
    identical(t$line$color,unname(env$move_colors[[t$legendgroup]])))
  for (t in traces[seq(2,8,2)]) stopifnot(t$opacity==.45,
    t$line$dash=='dash', identical(t$showlegend,FALSE))
}
cat('PASS: standard, large-cut and large-hike outcomes retain labels and Plotly colours\n')
# A linear outcome outside the standard model's top four must still be shown.
env <- new.env(parent=globalenv())
env$buckets_with_moves <- data.frame(bucket=1:5,move=letters[1:5],
  probability=c(.4,.3,.2,.09,.01),probability_linear=c(0,0,0,.4,.6))
for(name in c('top3_buckets','comparison_buckets','display_buckets')) eval(assignment(name),env)
stopifnot(length(env$top3_buckets)==4L,5 %in% env$display_buckets)
cat('PASS: linear comparison includes an outcome outside the standard top four\n')
