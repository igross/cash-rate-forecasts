# ==============================================================================
# Actual vs Forecast Implied Cash Rate
# ==============================================================================
# Purpose: Create charts comparing the historical RBA cash rate with
#          weekly snapshots of futures-implied forecast paths. Static and
#          interactive outputs are written to the docs/ directory.
# ==============================================================================

ensure_packages <- function(pkgs) {
  missing_pkgs <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(missing_pkgs) > 0) {
    install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
  }
}

ensure_packages(c(
  "dplyr", "ggplot2", "here", "htmlwidgets", "lubridate", "purrr",
  "plotly", "readrba", "scales", "viridis", "stringr", "tibble",
  "tidyr", "evaluate"
))

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(here)
  library(htmlwidgets)
  library(lubridate)
  library(purrr)
  library(plotly)
  library(readrba)
  library(scales)
  library(viridis)
  library(stringr)
  library(tibble)
  library(tidyr)
})

# ------------------------------------------------------------------------------
# 1) Load and prepare data
# ------------------------------------------------------------------------------

# Ensure output directory exists
if (!dir.exists(here("docs"))) {
  dir.create(here("docs"), recursive = TRUE)
}

# Load consolidated futures data (columns: date, cash_rate, scrape_time)
cash_rate <- readRDS("combined_data/all_data.Rds")

# Latest observation per contract per scrape date
cash_rate_daily <- cash_rate %>%
  mutate(
    scrape_date = as.Date(scrape_time),
    expiry = as.Date(date)
  ) %>%
  group_by(scrape_date, expiry) %>%
  slice_max(scrape_time, n = 1, with_ties = FALSE) %>%
  ungroup()

# Front-month implied rate per day (earliest available contract)
front_month <- cash_rate_daily %>%
  group_by(scrape_date) %>%
  arrange(expiry, .by_group = TRUE) %>%
  slice(1) %>%
  ungroup() %>%
  transmute(
    date = scrape_date,
    implied_rate = cash_rate
  )

# Historical actual cash rate
actual_cash_rate <- read_rba(series_id = "FIRMMCRTD") %>%
  transmute(
    date,
    actual_rate = value
  )

# Limit actual series to overlap with futures-derived data
plot_actual <- actual_cash_rate %>%
  filter(date >= min(front_month$date, na.rm = TRUE))


# ------------------------------------------------------------------------------
# 2) Build weekly forecast paths from all available scrapes
# ------------------------------------------------------------------------------

# Take one snapshot per calendar week (last scrape of each week)
weekly_scrapes <- cash_rate %>%
  mutate(scrape_week = floor_date(scrape_time, unit = "week")) %>%
  group_by(scrape_week) %>%
  slice_max(scrape_time, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  distinct(scrape_time)

# Build forecast paths: for each weekly scrape, get all contract expiries
forecast_paths <- cash_rate %>%
  filter(scrape_time %in% weekly_scrapes$scrape_time) %>%
  mutate(expiry = as.Date(date)) %>%
  select(scrape_time, expiry, cash_rate) %>%
  # Only keep expiries within two years of the scrape
  filter(expiry <= as.Date(scrape_time) + years(2))

latest_scrape_date <- max(as.Date(forecast_paths$scrape_time), na.rm = TRUE)

x_start <- latest_scrape_date - years(1)
x_end <- latest_scrape_date + months(18)

plot_actual_filtered <- plot_actual %>%
  filter(date >= x_start)

forecast_paths_window <- forecast_paths %>%
  mutate(scrape_date = as.Date(scrape_time)) %>%
  mutate(
    tooltip_text = str_glue(
      "Week of: {format(floor_date(scrape_time, 'week'), '%d %b %Y')}<br>",
      "Scrape: {format(scrape_time, '%d %b %Y %H:%M %Z')}<br>",
      "Expiry: {format(expiry, '%b %Y')}<br>",
      "Implied rate: {scales::number(cash_rate, accuracy = 0.001)}%"
    )
  ) %>%
  filter(expiry >= x_start, expiry <= x_end) %>%
  arrange(scrape_time, expiry)

latest_path <- forecast_paths_window %>%
  filter(scrape_time == max(scrape_time))

  forecast_plot <- ggplot() +
    geom_line(
      data = plot_actual_filtered,
      aes(x = date, y = actual_rate, text = "Actual cash rate"),
      linewidth = 1,
      color = "#2b2b2b"
    ) +
    geom_line(
      data = forecast_paths_window,
      aes(
        x = expiry,
        y = cash_rate,
        group = scrape_time,
        color = scrape_date,
        text = tooltip_text
      ),
      alpha = 0.5
    ) +
    scale_color_gradientn(
      colors = viridis(9),
      name = "Scrape date",
      guide = guide_colorbar(barheight = unit(5, "cm"), barwidth = unit(0.4, "cm"))
    ) +
  scale_y_continuous(labels = number_format(accuracy = 0.05)) +
  scale_x_date(
    limits = c(x_start, x_end),
    date_labels = "%b %Y",
    date_breaks = "2 months",
    expand = c(0.01, 0)
  ) +
  labs(
    title = "Cash Rate Forecast Paths",
    subtitle = paste0(
      "Weekly snapshots up to ",
      format(latest_scrape_date, "%d %B %Y")
    ),
    x = "Futures contract expiry",
    y = "Implied cash rate (%)",
    caption = "Forecasts include a mix of previous settlement and last trade data which can create a non-linearity along the forecast path"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 15),
    plot.caption = element_text(margin = margin(t = 10))
  )

forecast_plot_interactive <- ggplotly(forecast_plot, tooltip = "text") %>%
  layout(showlegend = FALSE,
         annotations = list(
           list(
             text = "Forecasts include a mix of previous settlement and last trade data which can create a non-linearity along the forecast path",
             x = 0,
             xref = "paper",
             xanchor = "left",
             y = -0.15,
             yref = "paper",
             yanchor = "top",
             align = "left",
             showarrow = FALSE,
             font = list(size = 10)
           )
         ))

# ------------------------------------------------------------------------------
# 3) Save outputs
# ------------------------------------------------------------------------------

# Static forecast path overlay
forecast_plot_dir <- here("docs", "plots", "forecast_paths")
if (!dir.exists(forecast_plot_dir)) {
  dir.create(forecast_plot_dir, recursive = TRUE)
}

forecast_path_png <- file.path(forecast_plot_dir, "cash_rate_forecast_paths.png")
ggsave(
  filename = forecast_path_png,
  plot = forecast_plot,
  width = 10,
  height = 6,
  dpi = 300
)

# Interactive widget
forecast_path_html <- here("docs", "cash_rate_forecast_paths.html")
saveWidget(
  widget = forecast_plot_interactive,
  file = forecast_path_html,
  selfcontained = TRUE
)

cat("Saved chart to", forecast_path_png, "\n")
cat("Saved interactive chart to", forecast_path_html, "\n")
