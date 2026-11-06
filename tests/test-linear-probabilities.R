# Exercise the production two-outcome calculation without any error distribution.
suppressPackageStartupMessages({library(dplyr); library(tibble)})
for (path in c('R/line_chart.R','R/future_meeting_line_charts.R')) {
  expressions <- as.list(parse(path))
  loop <- Filter(function(e) is.call(e) && identical(e[[1]],as.name('for')) &&
    identical(e[[3]],quote(seq_len(nrow(all_estimates)))),expressions)[[1]]
  body <- as.list(loop[[4]])[-1]
  assigns <- vapply(body,function(e) if(is.call(e)&&identical(e[[1]],as.name('<-'))) paste(deparse(e[[2]]),collapse='') else '',character(1))
  block <- body[which(assigns=='nearest'):which(assigns=='l_vec[bucket_centers == b2]')]
  bucket_centers <- seq(.10,6.10,.25)
  for(mu_i in c(bucket_centers,seq(.10,6.10,length.out=1001),4.475,4.60-1e-12,4.60+1e-12)) {
    for(e in block) eval(e)
    stopifnot(min(l_vec)>=-1e-10,max(l_vec)<=1+1e-10,
      abs(sum(l_vec)-1)<1e-10, sum(l_vec>1e-10)<=2,
      abs(sum(bucket_centers*l_vec)-mu_i)<1e-10)
  }
  mu_i <- 4.475
  for(e in block) eval(e)
  stopifnot(max(abs(l_vec[l_vec>0]-.5))<1e-10)
}
cat('PASS: linear probabilities bounded, sum to one and reproduce the implied mean; exact outcomes and midpoint checked\n')
