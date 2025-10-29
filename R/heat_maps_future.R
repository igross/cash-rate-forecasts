source(file.path("R", "heat_maps_shared.R"))

future_meeting_filter <- function(meeting_dates, meeting_schedule) {
  today <- Sys.Date()
  meetings <- meeting_schedule$meeting_date[(meeting_schedule$meeting_date - 1) >= today]
  sort(unique(as.Date(meetings)))
}

run_heatmap_pipeline(
  meeting_filter = future_meeting_filter,
  run_label = "future meetings"
)
