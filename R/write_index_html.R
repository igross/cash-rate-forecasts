# write_index_html.R

suppressPackageStartupMessages({
  library(stringr)
})

intro_paragraph <- '
  <p style="max-width: 900px; margin: 0 auto 30px auto; text-align: center; font-size: 1.1rem; color: #444;">
    This website is built by Zac Gross and provides a daily snapshot of <strong>futures-implied expectations</strong> for the Reserve Bank of Australia\'s cash rate,
    based on ASX 30-day interbank futures data and historical data. These expectations update automatically based off code by Matt Cowgill.
  </p>'

# ====== Analytics snippet ======
# Replace with your own ID or domain
ga_id <- "G-5J5TP6ZN7H"   # <-- put your GA4 Measurement ID here
plausible_domain <- "isaacgross.net"  # <-- set to your actual domain (if using Plausible)

analytics_snippet <- sprintf('
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-5J5TP6ZN7H"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag("js", new Date());

  gtag("config", "G-5J5TP6ZN7H");
</script>

)
# ==============================

# Ensure target directory exists
if (!dir.exists("docs/meetings")) dir.create("docs/meetings", recursive = TRUE)

# Find meeting PNGs
png_basenames <- list.files(
  "docs/meetings",
  pattern = "^area_all_moves_\\d{4}-\\d{2}-\\d{2}\\.png$",
  full.names = FALSE
)

# Sort by the date in filename (earliest first)
if (length(png_basenames) > 0) {
  dates_chr <- str_match(png_basenames, "area_all_moves_(\\d{4}-\\d{2}-\\d{2})\\.png")[, 2]
  dates_ord <- as.Date(dates_chr, format = "%Y-%m-%d")
  ord <- order(dates_ord, decreasing = FALSE, na.last = TRUE)
  png_basenames <- png_basenames[ord]
}

png_files_rel <- file.path("meetings", png_basenames)

# Build image cards
cards <- character(0)
if (length(png_files_rel) > 0) {
cards <- vapply(
  png_files_rel,
  function(file) sprintf(
    '<div class="chart-card">\n  <img src="%s" alt="%s" loading="lazy" />\n</div>',
    file, file
  ),
  character(1)
)
}

# Optional sections for next-meeting charts
interactive_line_section <- ""
if (file.exists("docs/line.png")) {
  interactive_line_section <- '
  <h1 style="margin-top:60px; text-align:center;">
    Forecasts for the Next RBA Meeting
  </h1>
  <div style="
      display: flex;
      justify-content: center;
      margin: 40px 0;
    ">
    <img 
      src="line.png" 
      alt="Next RBA Meeting Line Chart"
      style="
        width: 80%;
        height: auto;
        border-radius: 15px;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
      "
    />
  </div>'
}

area_chart_section <- ""
if (file.exists("docs/area.png")) {
  area_chart_section <- '
  <div style="
      display: flex;
      justify-content: center;
      margin: 40px 0;
    ">
    <img 
      src="area.png" 
      alt="Next RBA Meeting Area Chart"
      style="
        width: 80%;
        height: auto;
        border-radius: 15px;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
      "
    />
  </div>'
}

# Meeting grid section
meeting_section <- if (length(cards) > 0) {
  paste('<div class="grid">', paste(cards, collapse = "\n"), '</div>')
} else {
  '<p style="text-align:center;">No upcoming RBA meeting charts available.</p>'
}

# Assemble HTML
html <- sprintf('
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>Rate Outcome Probabilities by RBA Meeting</title>
  %s
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
      grid-template-columns: repeat(auto-fill, minmax(460px, 1fr));
      gap: 30px;
      padding: 10px;
      max-width: 2200px;
      margin: 0 auto;
    }
    .chart-card {
      background: #fff;
      border-radius: 10px;
      box-shadow: 0 4px 10px rgba(0, 0, 0, 0.05);
      padding: 18px;
      text-align: center;
    }
    .chart-card img {
      width: 100%%;
      border-radius: 6px;
    }
    @media (max-width: 1024px) {
      .grid {
        grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
        max-width: 1400px;
      }
    }
    @media (max-width: 768px) {
      .grid {
        grid-template-columns: 1fr;
        max-width: 95vw;
      }
    }
  </style>
</head>
<body>

  %s

  %s

  %s

  <h1>Cash Rate Target Probabilities By RBA Meeting</h1>

  %s

</body>
</html>
', analytics_snippet, intro_paragraph, interactive_line_section, area_chart_section, meeting_section)

# Write output
writeLines(html, "docs/index.html")
message("✅ index.html written with ", length(png_files_rel), " meeting charts (earliest first).")
