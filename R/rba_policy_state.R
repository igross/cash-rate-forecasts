# Announcement-day policy state: independent of the lagging statistical workbook.
rba_policy_parse <- function(overview, decisions, now = Sys.time()) {
  doc <- xml2::read_html(overview)
  text <- function(xpath) trimws(gsub('[[:space:]]+', ' ', xml2::xml_text(xml2::xml_find_first(doc,xpath))))
  root <- "//div[contains(@class,'landing-page-chart-statistic')]"
  rate <- suppressWarnings(as.numeric(gsub('[^0-9.]','',text(paste0(root,"/p[contains(@class,'statistic-value')]")))))
  effective <- sub('Effective date *','',text(paste0(root,"/p[contains(.,'Effective date')]")))
  next_date <- sub('.*pm, *','',text(paste0(root,"/p[contains(.,'Next update')]")))
  effective <- as.Date(effective,'%d %B %Y'); next_date <- as.Date(next_date,'%d %B %Y')
  dd <- xml2::read_html(decisions)
  links <- xml2::xml_find_all(dd,"//a[contains(@href,'/media-releases/')]")
  dates <- as.Date(trimws(xml2::xml_text(links)),'%d %B %Y')
  keep <- !is.na(dates)
  if (!any(keep)) stop('No dated RBA policy decision found')
  dates <- dates[keep]; links <- links[keep]; k <- which.max(dates)
  announcement <- as.POSIXct(paste(dates[k],'14:30:00'),tz='Australia/Sydney')
  state <- list(rate=rate, effectiveDate=as.character(effective),
    announcedAt=format(announcement,'%Y-%m-%dT%H:%M:%SZ',tz='UTC'),
    nextMeeting=as.character(next_date), source='https://www.rba.gov.au/cash-rate-target-overview.html',
    decisionUrl=paste0('https://www.rba.gov.au',xml2::xml_attr(links[k],'href')),
    fetchedAt=format(now,'%Y-%m-%dT%H:%M:%SZ',tz='UTC'))
  rba_policy_validate(state,now)
  state
}
rba_policy_validate <- function(state, now=Sys.time()) {
  announcement <- as.POSIXct(state$announcedAt,format='%Y-%m-%dT%H:%M:%SZ',tz='UTC')
  next_at <- as.POSIXct(paste(state$nextMeeting,'14:30:00'),tz='Australia/Sydney')
  effective <- as.Date(state$effectiveDate)
  valid <- is.finite(state$rate) && state$rate>=0 && state$rate<=20 &&
    !is.na(announcement) && as.numeric(announcement)<=as.numeric(now) && !is.na(next_at) && as.numeric(next_at)>as.numeric(now) &&
    !is.na(effective) && effective<=as.Date(announcement,tz='Australia/Sydney')+1 &&
    effective<=as.Date(next_at,tz='Australia/Sydney') &&
    as.numeric(announcement)<as.numeric(next_at)
  if (!isTRUE(valid)) stop('RBA policy state is stale or inconsistent; refusing to publish probabilities until the decision is confirmed.')
  invisible(TRUE)
}
rba_policy_state <- function(cache='docs/data/rba-policy-state.json', now=Sys.time(),
  fetch=function(url) rawToChar(curl::curl_fetch_memory(url,
    handle=curl::new_handle(timeout=20, httpheader=c('Cache-Control'='no-cache')))$content)) {
  state <- tryCatch(rba_policy_parse(fetch('https://www.rba.gov.au/cash-rate-target-overview.html'),
    fetch(paste0('https://www.rba.gov.au/monetary-policy/int-rate-decisions/',format(now,'%Y',tz='Australia/Sydney'),'/')),now),
    error=function(e) {
      if (!file.exists(cache)) stop(e)
      cached <- jsonlite::read_json(cache,simplifyVector=TRUE)
      rba_policy_validate(cached,now)
      warning('RBA request failed; using validated cached announcement: ',conditionMessage(e))
      cached
    })
  dir.create(dirname(cache),recursive=TRUE,showWarnings=FALSE)
  jsonlite::write_json(state,cache,auto_unbox=TRUE,pretty=TRUE)
  state
}
# Announced target for expectations; never backdate it into pre-release snapshots.
rba_rate_at_snapshot <- function(timestamp,state,history) {
  announcement <- as.POSIXct(state$announcedAt,format='%Y-%m-%dT%H:%M:%SZ',tz='UTC')
  if (as.numeric(timestamp)>=as.numeric(announcement)) return(state$rate)
  day <- as.Date(timestamp,tz='Australia/Sydney')
  rows <- history[as.Date(history$date)<=day & is.finite(history$value),]
  if (!nrow(rows)) stop('No historical rate available for this snapshot')
  rows$value[which.max(as.Date(rows$date))]
}
