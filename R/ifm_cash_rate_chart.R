# ==============================================================================
# RBA Cash Rate Expectations (IFM-style spaghetti chart)
# ==============================================================================
# Purpose: Replicate the IFM Investors "RBA Cash rate expectations" chart.
#          Shows actual RBA cash rate as a dark teal step line, successive
#          ~18-month futures strips as grey/taupe lines, and the latest
#          futures strip highlighted in orange with endpoint annotation.
# ==============================================================================

ensure_packages <- function(pkgs) {
  missing_pkgs <- pkgs[!pkgs %in% rownames(installed.packages())]
  if (length(missing_pkgs) > 0) {
    install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
  }
}

ensure_packages(c(
  "dplyr", "ggplot2", "here", "htmlwidgets", "lubridate", "purrr",
  "plotly", "readrba", "scales", "stringr", "tibble", "tidyr"
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
  library(stringr)
  library(tibble)
  library(tidyr)
})

# ------------------------------------------------------------------------------
# 1) Load and prepare data
# ------------------------------------------------------------------------------

if (!dir.exists(here("docs", "plots", "ifm_style"))) {
  dir.create(here("docs", "plots", "ifm_style"), recursive = TRUE)
}

# Load consolidated futures data
cash_rate <- readRDS("combined_data/all_data.Rds")

# One observation per (scrape_date, contract expiry)
cash_rate_daily <- cash_rate %>%
  mutate(
    scrape_date = as.Date(scrape_time),
    expiry      = as.Date(date)
  ) %>%
  group_by(scrape_date, expiry) %>%
  slice_max(scrape_time, n = 1, with_ties = FALSE) %>%
  ungroup()

# Historical actual cash rate from RBA
actual_cash_rate <- read_rba(series_id = "FIRMMCRTD") %>%
  transmute(date, actual_rate = value) %>%
  filter(date >= as.Date("2015-01-01"))

# Extend actual rate to today so step line reaches the present
last_actual <- actual_cash_rate %>% slice_max(date, n = 1)
if (last_actual$date < Sys.Date()) {
  actual_cash_rate <- bind_rows(
    actual_cash_rate,
    tibble(date = Sys.Date(), actual_rate = last_actual$actual_rate)
  )
}

# ------------------------------------------------------------------------------
# 2) Sample monthly futures strips
# ------------------------------------------------------------------------------

# Pick one scrape per month (closest to mid-month)
sampled_scrapes <- cash_rate_daily %>%
  distinct(scrape_date) %>%
  mutate(
    ym   = floor_date(scrape_date, "month"),
    dist = abs(day(scrape_date) - 15)
  ) %>%
  group_by(ym) %>%
  slice_min(dist, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  pull(scrape_date)

# Always include the latest scrape
latest_scrape <- max(cash_rate_daily$scrape_date)
sampled_scrapes <- unique(c(sampled_scrapes, latest_scrape))

# Build strips: keep only ~18 months forward from each scrape date
strips <- cash_rate_daily %>%
  filter(scrape_date %in% sampled_scrapes) %>%
  filter(expiry <= scrape_date + months(18)) %>%
  arrange(scrape_date, expiry)

old_strips    <- strips %>% filter(scrape_date != latest_scrape)
latest_strip  <- strips %>% filter(scrape_date == latest_scrape)

# Endpoint for annotation
endpoint <- latest_strip %>% slice_max(expiry, n = 1)

# ------------------------------------------------------------------------------
# 3) Build static ggplot (IFM style)
# ------------------------------------------------------------------------------

ifm_teal   <- "#1a6e6e"
ifm_taupe  <- "#b5a99a"
ifm_orange <- "#e8731a"

p <- ggplot() +
  # Old futures strips — grey/taupe
  geom_line(
    data = old_strips,
    aes(x = expiry, y = cash_rate, group = scrape_date),
    colour    = ifm_taupe,
    linewidth = 0.4,
    alpha     = 0.55
  ) +
  # Latest futures strip — orange
  geom_line(
    data = latest_strip,
    aes(x = expiry, y = cash_rate),
    colour    = ifm_orange,
    linewidth = 1.8
  ) +
  # Actual cash rate — dark teal step line
  geom_step(
    data = actual_cash_rate,
    aes(x = date, y = actual_rate),
    colour    = ifm_teal,
    linewidth = 1.2,
    direction = "hv"
  ) +
  # Endpoint annotation
  annotate(
    "label",
    x     = endpoint$expiry,
    y     = endpoint$cash_rate,
    label = paste0(sprintf("%.2f", endpoint$cash_rate), "%"),
    colour    = ifm_orange,
    fill      = "white",
    fontface  = "bold",
    size      = 4,
    label.padding = unit(0.3, "lines"),
    label.size    = 0.8,
    hjust = -0.2
  ) +
  # Text annotations
  annotate(
    "text",
    x = as.Date("2023-06-01"), y = 5.15,
    label    = "RBA cash rate\n& futures pricing",
    fontface = "bold.italic",
    colour   = "#2b2b2b",
    size     = 3.5,
    hjust    = 0.5
  ) +
  annotate(
    "text",
    x = as.Date("2018-06-01"), y = 2.9,
    label    = "*Successive 18 month\n  futures strips",
    fontface = "italic",
    colour   = ifm_taupe,
    size     = 3.2,
    hjust    = 0.5
  ) +
  # Scales
  scale_x_date(
    limits      = c(as.Date("2015-01-01"), as.Date("2027-06-01")),
    date_labels = "'%y",
    date_breaks = "1 year",
    expand      = c(0.01, 0)
  ) +
  scale_y_continuous(
    limits = c(-0.1, 5.5),
    breaks = seq(0, 5.5, 0.5),
    labels = number_format(accuracy = 0.1)
  ) +
  labs(
    title   = "RBA Cash rate expectations*",
    y       = "%pa",
    x       = NULL,
    caption = "Source: ASX, Bloomberg"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title       = element_text(face = "bold", size = 16, colour = "#2b2b2b",
                                    margin = margin(b = 10)),
    axis.title.y     = element_text(angle = 0, vjust = 1.05, hjust = 1, size = 11),
    axis.text        = element_text(colour = "#555555", size = 11),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.grid.major.y = element_line(colour = "#e0e0e0", linewidth = 0.3),
    plot.caption     = element_text(colour = "#999999", size = 8,
                                    hjust = 0, margin = margin(t = 10)),
    plot.background  = element_rect(fill = "white", colour = NA),
    panel.background = element_rect(fill = "white", colour = NA)
  )

# Save static PNG
ggsave(
  filename = here("docs", "plots", "ifm_style", "rba_cash_rate_expectations.png"),
  plot     = p,
  width    = 10,
  height   = 6.5,
  dpi      = 300
)

# ------------------------------------------------------------------------------
# 4) Build interactive plotly version
# ------------------------------------------------------------------------------

# Rebuild with tooltip-friendly aesthetics
p_interactive <- ggplot() +
  geom_line(
    data = old_strips %>%
      mutate(
        tooltip_text = str_glue(
          "Strip date: {format(scrape_date, '%d %b %Y')}\n",
          "Expiry: {format(expiry, '%b %Y')}\n",
          "Implied rate: {number(cash_rate, accuracy = 0.001)}%"
        )
      ),
    aes(x = expiry, y = cash_rate, group = scrape_date, text = tooltip_text),
    colour    = ifm_taupe,
    linewidth = 0.4,
    alpha     = 0.55
  ) +
  geom_line(
    data = latest_strip %>%
      mutate(
        tooltip_text = str_glue(
          "Latest strip: {format(scrape_date, '%d %b %Y')}\n",
          "Expiry: {format(expiry, '%b %Y')}\n",
          "Implied rate: {number(cash_rate, accuracy = 0.001)}%"
        )
      ),
    aes(x = expiry, y = cash_rate, text = tooltip_text),
    colour    = ifm_orange,
    linewidth = 1.8
  ) +
  geom_step(
    data = actual_cash_rate %>%
      mutate(tooltip_text = str_glue("Actual rate: {actual_rate}%\nDate: {format(date, '%d %b %Y')}")),
    aes(x = date, y = actual_rate, text = tooltip_text),
    colour    = ifm_teal,
    linewidth = 1.2,
    direction = "hv"
  ) +
  scale_x_date(
    limits      = c(as.Date("2015-01-01"), as.Date("2027-06-01")),
    date_labels = "'%y",
    date_breaks = "1 year",
    expand      = c(0.01, 0)
  ) +
  scale_y_continuous(
    limits = c(-0.1, 5.5),
    breaks = seq(0, 5.5, 0.5),
    labels = number_format(accuracy = 0.1)
  ) +
  labs(
    title = "RBA Cash rate expectations*",
    y     = "%pa",
    x     = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title       = element_text(face = "bold", size = 16, colour = "#2b2b2b"),
    axis.title.y     = element_text(angle = 0, vjust = 1.05, hjust = 1),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    panel.grid.major.y = element_line(colour = "#e0e0e0", linewidth = 0.3),
    plot.background  = element_rect(fill = "white", colour = NA),
    panel.background = element_rect(fill = "white", colour = NA)
  )

p_plotly <- ggplotly(p_interactive, tooltip = "text") %>%
  layout(
    showlegend = FALSE,
    annotations = list(
      list(
        text = "Source: ASX, Bloomberg",
        x = 0, xref = "paper", xanchor = "left",
        y = -0.10, yref = "paper", yanchor = "top",
        showarrow = FALSE,
        font = list(size = 9, color = "#999999")
      )
    )
  )

saveWidget(
  widget       = p_plotly,
  file         = here("docs", "rba_cash_rate_expectations.html"),
  selfcontained = TRUE
)

cat("Saved static chart to docs/plots/ifm_style/rba_cash_rate_expectations.png\n")
cat("Saved interactive chart to docs/rba_cash_rate_expectations.html\n")
