# write_index_html.R (improved)

suppressPackageStartupMessages({
  library(lubridate)
  library(stringr)
})

# ----- Configuration -----
docs_dir      <- "docs"
data_dir      <- "docs"    # images are in docs
index_file    <- file.path(docs_dir, "index.html")

# Find PNGs for meeting charts
png_files <- list.files(data_dir, pattern = "^rate_probabilities_.*\\.png$", full.names = FALSE)

# Extract and parse meeting month names
labels <- png_files |> 
  str_remove("^rate_probabilities_") |> 
  str_remove("\\.png$") |> 
  str_replace_all("_", " ")  # e.g. "May 2025"

# Prepare dates for filtering future meetings
dates_raw <- suppressWarnings(as.Date(paste0("01 ", labels), format = "%d %B %Y"))
valid_idx <- which(!is.na(dates_raw) & dates_raw > Sys.Date())

png_files <- png_files[valid_idx]
labels    <- labels[valid_idx]
dates     <- dates_raw[valid_idx]

ord <- order(dates)
png_files <- png_files[ord]
labels    <- labels[ord]
dates     <- dates[ord]

# Build relative URL slugs for anchors
to_slug <- function(x) str_replace_all(str_to_lower(x), "\\s+", "-")
slugs <- to_slug(labels)

# Intro paragraph
today_label <- format(Sys.Date(), "%d %B %Y")
intro_paragraph <- sprintf(
  '<p style="max-width:800px;margin:0 auto 30px auto;text-align:center;font-size:1.1rem;color:#444;">
    This site by Zac Gross provides a snapshot (updated %s) of <strong>futures-implied</strong>
    RBA cash-rate expectations, sourced automatically from ASX 30-day interbank futures.
  </p>',
  today_label
)

# --- Generate TOC ---
toc_items <- mapply(function(slug, label) {
  sprintf('<li><a href="#%s">%s</a></li>', slug, label)
}, slugs, labels, USE.NAMES = FALSE)
toc_html <- sprintf('<nav class="toc"><ul>%s</ul></nav>', paste(toc_items, collapse = "\n"))

# --- Build image cards ---
cards <- mapply(function(file, slug, label) {
  sprintf(
    '<div class="chart-card" id="%s">\n  <img src="%s" alt="%s" />\n</div>',
    slug, file, label
  )
}, png_files, slugs, labels, USE.NAMES = FALSE)
meeting_section <- sprintf('<div class="grid">\n%s\n</div>', paste(cards, collapse = "\n"))

# Optional sections if fan/line charts exist
fan_section <- if (file.exists(file.path(data_dir, "rate_fan_chart.png"))) sprintf(
  '<h2 style="text-align:center;margin-top:60px;">Forecast Path with Uncertainty Bands</h2>\n<div class="chart-card" style="max-width:800px;margin:0 auto;" id="fan-chart">\n  <img src="rate_fan_chart.png" alt="Fan Chart of Forecast Path" />\n</div>'
) else ''

line_section <- if (file.exists(file.path(data_dir, "line.png"))) sprintf(
  '<h2 style="text-align:center;margin-top:60px;">Forecasts for the next RBA meeting</h2>\n<div class="chart-card" style="max-width:800px;margin:0 auto;" id="next-meeting">\n  <img src="line.png" alt="Next RBA Meeting" />\n</div>'
) else ''

# ----- Compose HTML -----
html <- sprintf(
  '<!DOCTYPE html>\n<html lang="en">\n<head>\n  <meta charset="UTF-8"/>\n  <title>RBA Cash Rate Forecasts</title>\n  <link rel="icon" href="favicon.ico"/>\n  <style>\n    body { font-family:"Segoe UI", Roboto, sans-serif; background:#f5f7fa; color:#333; margin:0; padding:20px;}\n    header { text-align:center; margin-bottom:20px;}\n    header h1 { font-size:2.5rem; color:#2c3e50; margin:0;}\n    header nav { margin-top:5px;}\n    header nav a { margin:0 10px; color:#007acc; text-decoration:none;}\n    .update-banner { text-align:center; font-size:0.9rem; color:#555; margin-bottom:20px;}\n    .toc ul { list-style:none; padding:0; display:flex; justify-content:center; gap:15px; margin-bottom:30px;}\n    .toc a { color:#2c3e50; text-decoration:none; font-weight:500;}\n    .grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(320px,1fr)); gap:30px; max-width:1200px; margin:0 auto;}\n    .chart-card { background:#fff; border-radius:10px; box-shadow:0 4px 10px rgba(0,0,0,0.05); padding:15px; text-align:center;}\n    .chart-card img { width:100%; aspect-ratio:4/3; object-fit:cover; border-radius:6px;}\n    h2 { text-align:center; color:#2c3e50; margin-top:60px;}\n  </style>\n</head>\n<body>\n  <header>\n    <h1>Rate Outcome Probabilities by RBA Meeting</h1>\n    <nav>\n      <a href="index.html">Home</a> | <a href="https://github.com/igross/cash-rate-forecasts">GitHub Repo</a>\n    </nav>\n  </header>\n  <div class="update-banner">Updated: %s</div>\n  %s\n  %s\n  %s\n  %s\n</body>\n</html>',
  today_label,
  intro_paragraph,
  toc_html,
  line_section,
  meeting_section,
  fan_section
)

# Write and confirm
writeLines(html, index_file)
message("✅ " , index_file, " written with ", length(png_files), " meeting charts.")
