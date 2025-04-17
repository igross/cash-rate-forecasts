# write_index_html.R

suppressPackageStartupMessages({
  library(lubridate)
  library(stringr)
})

# Find PNGs for meeting charts
png_files <- list.files("docs", pattern = "^rate_probabilities_.*\\.png$", full.names = FALSE)

# Extract and parse meeting month names
labels <- png_files |>
  str_remove("^rate_probabilities_") |>
  str_remove("\\.png$") |>
  str_replace_all("_", " ")  # e.g. "May 2025"

intro_paragraph <- '
  <p style="max-width: 800px; margin: 0 auto 30px auto; text-align: center; font-size: 1.1rem; color: #444;">
    This website is by Zac Gross and provides a daily snapshot of <strong>futures-implied expectations</strong> for the Reserve Bank of Australia\'s cash rate,
    based on ASX 30-day interbank futures data and historical data. These expectations update automatically using code provided by Matt Cowgill.
  </p>'

# Parse to dates (assume 1st of each month)
dates <- suppressWarnings(as.Date(paste0("01 ", labels), format = "%d %B %Y"))
valid_idx <- which(!is.na(dates) & dates > Sys.Date())

# Filter and sort by future dates
png_files <- png_files[valid_idx]
labels <- labels[valid_idx]
dates <- dates[valid_idx]

order_idx <- order(dates)
png_files <- png_files[order_idx]
labels <- labels[order_idx]

# Build image cards (no visible labels)
cards <- character(0)
if (length(png_files) > 0) {
  cards <- mapply(function(file, label) {
    sprintf('<div class="chart-card">
      <img src="%s" alt="%s" />
    </div>', file, label)
  }, png_files, labels)
}

# Optional fan chart
fan_chart_section <- ""
if (file.exists("docs/rate_fan_chart.png")) {
  fan_chart_section <- '
  <h1 style="margin-top:60px;">Forecast Path with Uncertainty Bands</h1>
  <div class="chart-card" style="max-width: 800px; margin: 0 auto;">
    <img src="rate_fan_chart.png" alt="Fan Chart of Forecast Path">
  </div>'
}

# Optional fan chart
line_chart_section <- ""
if (file.exists("docs/line.png")) {
  line_chart_section <- '
  <h1 style="margin-top:60px;">Daily Forecasts for RBA Next Meeting</h1>
  <div class="chart-card" style="max-width: 800px; margin: 0 auto;">
    <img src="line.png" alt="Next RBA Meeting">
  </div>'
}

# Compose main chart section
meeting_section <- if (length(cards) > 0) {
  paste('<div class="grid">', paste(cards, collapse = "\n"), '</div>')
} else {
  '<p style="text-align:center;">No upcoming RBA meeting charts available.</p>'
}

html <- sprintf('
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Rate Outcome Probabilities by RBA Meeting</title>
  <style>
    body {
      font-family: "Segoe UI", Roboto, sans-serif;
      background-color: #f5f7fa;
      color: #333;
      margin: 0;
      padding: 40px 20px;
    }
    h1 {
      text-align: center;
      margin-bottom: 30px;
      font-size: 2rem;
      color: #2c3e50;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
      gap: 30px;
      padding: 10px;
      max-width: 1200px;
      margin: 0 auto;
    }
    .chart-card {
      background: #fff;
      border-radius: 10px;
      box-shadow: 0 4px 10px rgba(0, 0, 0, 0.05);
      padding: 15px;
      text-align: center;
    }
    .chart-card img {
      width: 100%%;
      border-radius: 6px;
    }
  </style>
</head>
<body>

 

  <h1>Cash Rate Forecasting</h1>
  %s
  
<h2>Expected Outcomes By RBA Meeting </h2>

  %s

  %s

</body>
</html>
', line_chart_section,meeting_section, intro_paragraph)


# Write output
writeLines(html, "docs/index.html")
message("✅ index.html written with ", length(png_files), " charts.",
        if (fan_chart_section != "") " Fan chart included." else " No fan chart.")
