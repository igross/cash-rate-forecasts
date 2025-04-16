# write_index_html.R

suppressPackageStartupMessages({
  library(lubridate)
  library(stringr)
})

# List PNGs for meeting charts
png_files <- list.files("docs", pattern = "^rate_probabilities_.*\\.png$", full.names = FALSE)

# Extract and format meeting labels
labels <- png_files |>
  str_remove("^rate_probabilities_") |>
  str_remove("\\.png$") |>
  str_replace_all("_", " ")

# Parse dates from labels
dates <- suppressWarnings(as.Date(paste0("01 ", labels), format = "%d %B %Y"))
valid_idx <- which(!is.na(dates) & dates > Sys.Date())

# Filter and sort
png_files <- png_files[valid_idx]
labels <- labels[valid_idx]
dates <- dates[valid_idx]

order_idx <- order(dates)
png_files <- png_files[order_idx]
labels <- labels[order_idx]

# Build HTML chart blocks
cards <- mapply(function(file, label) {
  sprintf('<div class="chart-card">
    <img src="%s" alt="%s" />
  </div>', file)
}, png_files, labels)

# Check if fan chart exists
fan_chart_section <- ""
if (file.exists("docs/rate_fan_chart.png")) {
  fan_chart_section <- '
  <h1 style="margin-top:60px;">Forecast Path with Uncertainty Bands</h1>
  <div class="chart-card" style="max-width: 800px; margin: 0 auto;">
    <img src="rate_fan_chart.png" alt="Fan Chart of Forecast Path">
  </div>'
}

# Assemble full HTML
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

  <h1>Rate Outcome Probabilities by RBA Meeting</h1>

  <div class="grid">
    %s
  </div>

  %s

</body>
</html>
', paste(cards, collapse = "\n"), fan_chart_section)

# Write to file
writeLines(html, "docs/index.html")
message("✅ index.html updated with ", length(png_files), " meeting charts.",
        if (fan_chart_section != "") " Fan chart included." else " Fan chart missing.")
