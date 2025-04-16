# Load libraries
suppressPackageStartupMessages({
  library(lubridate)
  library(stringr)
})

# Read PNG filenames
png_files <- list.files("docs", pattern = "^rate_probabilities_.*\\.png$", full.names = FALSE)

# Extract and parse meeting dates
labels <- png_files |>
  str_remove("^rate_probabilities_") |>
  str_remove("\\.png$") |>
  str_replace_all("_", " ")  # "May 2025"

# Convert to dates (assume 1st of month)
dates <- suppressWarnings(as.Date(paste0("01 ", labels), format = "%d %B %Y"))
valid_idx <- which(!is.na(dates) & dates > Sys.Date())

# Subset to future meetings
png_files <- png_files[valid_idx]
labels <- labels[valid_idx]

# Sort by date
order_idx <- order(dates[valid_idx])
png_files <- png_files[order_idx]
labels <- labels[order_idx]

# Create individual cards
cards <- mapply(function(file, label) {
  sprintf('<div class="chart-card">
    <img src="%s" alt="%s" />
    <div class="chart-label">%s</div>
  </div>', file, label, label)
}, png_files, labels)

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
    .chart-label {
      margin-top: 12px;
      font-size: 1rem;
      color: #555;
    }
  </style>
</head>
<body>

  <h1>Rate Outcome Probabilities by RBA Meeting</h1>
  <div class="grid">
    %s
  </div>

</body>
</html>
', paste(cards, collapse = "\n"))


# Write to file
writeLines(html, "docs/index.html")
message("✅ index.html updated with ", length(png_files), " charts.")
