# CLAUDE.md - AI Assistant Guide for cash-rate-forecasts

## Project Overview

This repository scrapes and visualizes market expectations for the Reserve Bank of Australia (RBA) cash rate based on ASX 30-day interbank futures data. It automatically collects data, generates visualizations, and publishes them to a GitHub Pages website.

**Primary Author:** Zac Gross (based on code by Matt Cowgill)
**Website:** Deployed via GitHub Pages from the `docs/` folder

## Repository Structure

```
cash-rate-forecasts/
├── R/                          # R scripts for data processing and visualization
│   ├── scrape_cash_rate.R      # Core data scraping script (runs every 5 min)
│   ├── line_chart.R            # Line chart probability visualizations
│   ├── heat_maps.R             # Current meeting heatmap visualizations
│   ├── heat_maps_old.R         # Historical heatmaps (runs monthly)
│   ├── area_charts.R           # Area chart visualizations
│   ├── daily_area_charts.R     # Daily area chart updates
│   ├── future_meeting_line_charts.R  # Multi-meeting line charts
│   ├── actual_vs_implied.R     # Actual vs implied rate comparison
│   ├── rmse.R                  # RMSE calculation for forecast calibration
│   ├── write_index_html.R      # Generates docs/index.html
│   └── shiny_heat.R            # Shiny app (not in production)
├── daily_data/                 # Individual CSV files per scrape
├── combined_data/              # Aggregated data files
│   ├── all_data.Rds            # Main combined dataset
│   ├── cash_rate.csv           # CSV export of combined data
│   ├── Archive.Rds             # Historical archive
│   ├── rmse_new.RData          # RMSE lookup table
│   └── f17_rmse.csv            # Quarterly forecast data for RMSE
├── docs/                       # GitHub Pages website output
│   ├── index.html              # Main website
│   ├── meetings/               # Meeting-specific heatmaps and CSVs
│   ├── meeting_lines/          # Line charts by meeting
│   ├── plots/                  # Additional plot outputs
│   └── *.html, *.png           # Interactive and static visualizations
├── .github/workflows/
│   └── refresh-data.yaml       # GitHub Actions workflow
├── cash-rate-scraper.Rproj     # RStudio project file
└── README.Rmd / README.md      # Project documentation
```

## Data Flow

1. **Scraping** (`scrape_cash_rate.R`):
   - Fetches JSON from ASX API: `https://asx.api.markitdigital.com/asx-research/1.0/derivatives/interest-rate/IB/futures`
   - Saves individual CSV to `daily_data/scraped_cash_rate_YYYY-MM-DD_HHMM.csv`
   - Combines all CSVs into `combined_data/all_data.Rds`

2. **Visualization Pipeline**:
   - `line_chart.R` → Probability line charts for next meeting
   - `heat_maps.R` → Interactive heatmaps for future meetings
   - `area_charts.R` → Area charts showing probability distributions
   - `actual_vs_implied.R` → Historical accuracy analysis

3. **Website Generation** (`write_index_html.R`):
   - Generates `docs/index.html` from visualization outputs
   - Includes Google Analytics tracking

## Key Data Structures

### Cash Rate Data (`all_data.Rds`)
| Column | Type | Description |
|--------|------|-------------|
| `date` | Date | Futures contract expiry month |
| `cash_rate` | double | Implied cash rate (100 - futures price) |
| `scrape_date` | Date | Date of data collection |
| `scrape_time` | POSIXct | Timestamp in Australia/Melbourne timezone |

### Meeting Schedule
Defined in `line_chart.R` and `rmse.R`. Key meetings include:
- RBA Board meetings (8 per year)
- Futures contracts expire at month-end or after meeting

### RMSE Data (`rmse_new.RData`)
Contains `rmse_days` dataframe with forecast error by days-to-meeting horizon, used to calculate probability distributions.

## GitHub Actions Workflow

**File:** `.github/workflows/refresh-data.yaml`

**Schedule:**
- Every 5 minutes (`*/5 * * * *`)
- Monthly on 1st at midnight (`0 0 1 * *`)

**Pipeline Steps:**
1. `R/rmse.R` - Calculate forecast errors (push/monthly only)
2. `R/scrape_cash_rate.R` - Scrape new data
3. `R/line_chart.R` - Generate line charts
4. `R/future_meeting_line_charts.R` - Multi-meeting charts
5. `R/heat_maps.R` - Generate heatmaps (not on workflow_dispatch)
6. `R/daily_area_charts.R` - Daily area updates
7. `R/area_charts.R` - Area chart generation
8. `R/actual_vs_implied.R` - Accuracy visualization
9. `R/heat_maps_old.R` - Historical heatmaps (monthly only)
10. `R/write_index_html.R` - Regenerate website

## Development Guidelines

### R Coding Style
- Use 2 spaces for indentation (per `.Rproj` settings)
- UTF-8 encoding
- Strip trailing whitespace
- Auto-append newlines

### Required R Packages
```r
# Core data manipulation
tidyverse, dplyr, tidyr, purrr, lubridate, readr

# Visualization
ggplot2, plotly, viridis, ggrepel, ggpattern, ggtext, scales

# Data sources
jsonlite, readrba, readabs

# Other
conflicted, here, rprojroot, zoo, vroom, cachem, memoise
```

### Running Locally

1. Open `cash-rate-scraper.Rproj` in RStudio
2. Install required packages (scripts auto-install via `ensure_packages()`)
3. Run scripts in order:
   ```r
   source("R/scrape_cash_rate.R")  # Fetch new data
   source("R/line_chart.R")        # Generate visualizations
   source("R/write_index_html.R")  # Rebuild website
   ```

### Key Configuration Parameters

In `line_chart.R`:
- `spread` - Adjustment for cash rate (default: 0.00)
- `override` - Manual rate override (default: 3.60)
- `hours_tz` - Timezone offset (default: 11 for AEDT)

In `write_index_html.R`:
- `ga_id` - Google Analytics ID: `G-5J5TP6ZN7H`
- `plausible_domain` - Analytics domain: `isaacgross.net`

## Data Quality Notes

- **Data Gap:** Collection was interrupted between July 1-20 due to ASX website changes
- **Filtered Dates:** Some dates are excluded due to data quality issues:
  - 2022-08-06 to 2022-08-08
  - 2023-01-18, 2023-01-24, 2023-01-31, 2023-02-02
  - 2022-12-29, 2022-12-30

## Important Files for AI Assistants

When making changes, pay attention to:

1. **`R/scrape_cash_rate.R`** - Core data pipeline. Changes here affect all downstream processing.

2. **`R/line_chart.R`** - Contains meeting schedule and probability calculation logic. Update `meeting_schedule` when new RBA meetings are announced.

3. **`R/rmse.R`** - Forecast error calibration. Contains CPI and meeting date schedules.

4. **`.github/workflows/refresh-data.yaml`** - Automation pipeline. Uses `continue-on-error: true` for resilience.

5. **`R/write_index_html.R`** - Website generation. Handles both future and past meeting displays.

## Common Tasks

### Adding New RBA Meeting Dates
Update the `meeting_schedule` tibble in:
- `R/line_chart.R`
- `R/rmse.R`

### Modifying Visualizations
- Line charts: `R/line_chart.R`
- Heatmaps: `R/heat_maps.R`
- Website layout: `R/write_index_html.R`

### Debugging Data Issues
1. Check `daily_data/` for recent scrapes
2. Verify `combined_data/all_data.Rds` loads correctly
3. Run `tail(all_data, 20)` to inspect recent data

### Timezone Handling
All times should use `Australia/Melbourne` timezone:
```r
now(tzone = "Australia/Melbourne")
ymd_hms(timestamp, tz = "Australia/Melbourne")
```

## Git Workflow

- Main branch: `main`
- Automated commits: "refreshing data"
- Git user: `igross`
- Push happens automatically via GitHub Actions

## API Dependencies

**ASX Futures Data:**
```
https://asx.api.markitdigital.com/asx-research/1.0/derivatives/interest-rate/IB/futures?days=1&height=179&width=179
```

**RBA Data (via `readrba` package):**
- Historical cash rate targets
- Actual rate decisions
