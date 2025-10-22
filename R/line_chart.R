# ==============================================================================
# RBA CASH RATE PROBABILITY ANALYSIS
# ==============================================================================
# Purpose: Analyze and visualize RBA cash rate futures data to calculate
#          probabilities of different rate outcomes for upcoming meetings
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. SETUP & LIBRARY LOADING
# ------------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(purrr)
  library(tibble)
  library(ggplot2)
  library(tidyr)
  library(plotly)
  library(readrba)   # For RBA data access
  library(scales)
  library(glue)
})

# ------------------------------------------------------------------------------
# 2. DATA LOADING & CONFIGURATION
# ------------------------------------------------------------------------------

# Load cash rate futures data (columns: date, cash_rate, scrape_time)
cash_rate <- readRDS("combined_data/all_data.Rds")

# Load RMSE lookup table (days_to_meeting → forecast error)
load("combined_data/rmse_new.RData")

print(head(rmse_days$finalrmse, 30))

# Configuration parameters
spread <- 0.00  # Spread adjustment for cash rate
override <- 3.60  # Manual override for current rate (if needed)

# Apply spread adjustment
cash_rate$cash_rate <- cash_rate$cash_rate + spread

# Create output directory structure
if (!dir.exists("docs/meetings")) dir.create("docs/meetings", recursive = TRUE)




# ------------------------------------------------------------------------------
# 3. HELPER FUNCTIONS
# ------------------------------------------------------------------------------

# Linear blend weight: transitions from discrete (0) to probabilistic (1)
# over the last 30 days before a meeting
blend_weight <- function(days_to_meeting) {
  pmax(0, pmin(1, 1 - days_to_meeting / 30))
}

# Helper function to convert UTC times to Melbourne time
# This automatically handles DST transitions
utc_to_melbourne <- function(utc_time) {
  with_tz(utc_time, tzone = "Australia/Melbourne")
}

# ------------------------------------------------------------------------------
# 4. DEFINE RBA MEETING SCHEDULE
# ------------------------------------------------------------------------------

meeting_schedule <- tibble(
  meeting_date = as.Date(c(
    # 2025 meetings
    "2025-02-18", "2025-04-01", "2025-05-20", "2025-07-08",
    "2025-08-12", "2025-09-30", "2025-11-04", "2025-12-09",
    # 2026 meetings (second day of each two-day meeting)
    "2026-02-03", "2026-03-17", "2026-05-05", "2026-06-16",
    "2026-08-11", "2026-09-29", "2026-11-03", "2026-12-08"
  ))
) %>% 
  mutate(
    # Determine futures contract expiry month
    # If meeting is in last 1-2 days of month, contract expires next month
    expiry = if_else(
      day(meeting_date) >= days_in_month(meeting_date) - 1,
      ceiling_date(meeting_date, "month"),
      floor_date(meeting_date, "month")
    )
  ) %>% 
  select(expiry, meeting_date)

now_melb <- now(tzone = "Australia/Melbourne")
today_melb <- as.Date(now_melb)
cutoff <- ymd_hm(paste0(today_melb, " 15:00"), tz = "Australia/Melbourne")

next_meeting <- if (today_melb %in% meeting_schedule$meeting_date &&
                    now_melb < cutoff) {
  today_melb
} else {
  meeting_schedule %>%
    filter(meeting_date > today_melb) %>%
    slice_min(meeting_date) %>%
    pull(meeting_date)
}

print(paste("Next meeting:", next_meeting))

# ------------------------------------------------------------------------------
# 5. DEFINE ABS DATA RELEASE SCHEDULE
# ------------------------------------------------------------------------------

abs_releases <- tribble(
  ~dataset, ~datetime,
  
  # CPI (quarterly releases at 11:30 AM Melbourne time)
  "CPI", ymd_hm("2025-01-29 11:30", tz = "Australia/Melbourne"),
  "CPI", ymd_hm("2025-04-30 11:30", tz = "Australia/Melbourne"),
  "CPI", ymd_hm("2025-07-30 11:30", tz = "Australia/Melbourne"),
  "CPI", ymd_hm("2025-10-29 11:30", tz = "Australia/Melbourne"),
  "CPI", ymd_hm("2026-01-28 11:30", tz = "Australia/Melbourne"),
  "CPI", ymd_hm("2026-04-29 11:30", tz = "Australia/Melbourne"),
  "CPI", ymd_hm("2026-07-29 11:30", tz = "Australia/Melbourne"),
  "CPI", ymd_hm("2026-10-28 11:30", tz = "Australia/Melbourne"),
  
  # CPI Indicator (monthly releases)
  "CPI Indicator", ymd_hm("2025-01-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-02-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-03-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-04-30 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-05-28 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-06-25 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-07-30 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-08-27 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-09-24 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-11-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2025-12-31 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-02-25 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-03-25 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-04-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-05-27 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-06-24 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-07-29 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-08-26 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-09-30 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-10-28 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-11-25 11:30", tz = "Australia/Melbourne"),
  "CPI Indicator", ymd_hm("2026-12-30 11:30", tz = "Australia/Melbourne"),
  
  # WPI (quarterly releases)
  "WPI", ymd_hm("2025-02-19 11:30", tz = "Australia/Melbourne"),
  "WPI", ymd_hm("2025-05-14 11:30", tz = "Australia/Melbourne"),
  "WPI", ymd_hm("2025-08-13 11:30", tz = "Australia/Melbourne"),
  "WPI", ymd_hm("2025-11-12 11:30", tz = "Australia/Melbourne"),
  "WPI", ymd_hm("2026-02-18 11:30", tz = "Australia/Melbourne"),
  "WPI", ymd_hm("2026-05-13 11:30", tz = "Australia/Melbourne"),
  "WPI", ymd_hm("2026-08-12 11:30", tz = "Australia/Melbourne"),
  "WPI", ymd_hm("2026-11-11 11:30", tz = "Australia/Melbourne"),
  
  # National Accounts (quarterly releases)
  "National Accounts", ymd_hm("2025-03-05 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2025-06-04 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2025-09-03 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2025-12-03 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2026-03-04 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2026-06-03 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2026-09-02 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2026-12-02 11:30", tz = "Australia/Melbourne"),
  
  # Labour Force (monthly releases)
  "Labour Force", ymd_hm("2025-01-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-02-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-03-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-04-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-05-15 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-06-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-07-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-08-14 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-09-18 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-10-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-11-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2025-12-18 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-01-15 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-02-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-03-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-04-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-05-14 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-06-18 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-07-16 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-08-20 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-09-17 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-10-15 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-11-19 11:30", tz = "Australia/Melbourne"),
  "Labour Force", ymd_hm("2026-12-17 11:30", tz = "Australia/Melbourne")
)

# ------------------------------------------------------------------------------
# 6. DETERMINE CURRENT RATE & MEETING CONTEXT
# ------------------------------------------------------------------------------

# Find the most recent past meeting
last_meeting <- max(meeting_schedule$meeting_date[
  meeting_schedule$meeting_date <= Sys.Date()
])

# Determine whether to use manual override or live RBA data
use_override <- !is.null(override) && (Sys.Date() - last_meeting <= 1)

# Get current rate (either from override or latest RBA publication)
if (use_override) {
  initial_rt <- override
  current_rate <- override
} else {
  latest_rt <- read_rba(series_id = "FIRMMCRTD") %>%
    slice_max(date, n = 1, with_ties = FALSE) %>%
    pull(value)
  initial_rt <- latest_rt
  current_rate <- latest_rt
}

# Print diagnostics
print(paste("Last meeting:", last_meeting))
print(paste("Using override:", use_override))
print(paste("Current rate:", current_rate))

# ------------------------------------------------------------------------------
# 7. PROCESS CASH RATE DATA
# ------------------------------------------------------------------------------

# Convert scrape_time to Melbourne timezone if it's in UTC
# Assuming the input data has scrape_time in UTC
cash_rate <- cash_rate %>%
  mutate(
    # Convert UTC to Melbourne time (handles DST automatically)
    scrape_time_melb = if (!"POSIXct" %in% class(scrape_time)) {
      ymd_hms(scrape_time, tz = "UTC") %>% with_tz("Australia/Melbourne")
    } else if (tz(scrape_time) == "UTC") {
      with_tz(scrape_time, "Australia/Melbourne")
    } else {
      scrape_time
    }
  )

# Get latest scrape time in Melbourne timezone
latest_scrape <- max(cash_rate$scrape_time_melb)

# ------------------------------------------------------------------------------
# 8. CALCULATE IMPLIED RATES & PROBABILITIES FOR EACH MEETING
# ------------------------------------------------------------------------------

meeting_probs <- meeting_schedule %>%
  filter(meeting_date >= Sys.Date()) %>%
  mutate(
    meeting_data = map2(expiry, meeting_date, function(exp, meet) {
      # Filter cash rate data for this meeting's contract
      meeting_cash <- cash_rate %>%
        filter(
          floor_date(date, "month") == exp,
          scrape_time_melb <= meet
        ) %>%
        arrange(scrape_time_melb) %>%
        mutate(
          # Calculate days until meeting
          days_to_meeting = as.numeric(difftime(meet, as.Date(scrape_time_melb), units = "days")),
          
          # Get RMSE for forecast error based on days remaining
          rmse = map_dbl(days_to_meeting, function(d) {
            if (d < 0) return(0)
            idx <- which.min(abs(rmse_days$finalrmse$days - d))
            rmse_days$finalrmse$rmse[idx]
          }),
          
          # Calculate blend weight for discrete vs probabilistic approach
          blend = blend_weight(days_to_meeting),
          
          # Implied rate from futures
          implied_rate = cash_rate,
          
          # Expected change from current rate
          expected_change = implied_rate - initial_rt,
          
          # Round to nearest 25bp for discrete outcomes
          discrete_outcome = round(expected_change * 4) / 4,
          
          # Calculate probabilities for different rate moves
          prob_data = pmap(list(expected_change, rmse, blend, discrete_outcome), 
                          function(exp_chg, rm, bl, disc) {
            # Define possible rate changes (-75bp to +75bp in 25bp increments)
            rate_changes <- seq(-0.75, 0.75, 0.25)
            
            if (rm > 0) {
              # Probabilistic: use normal distribution
              probs_prob <- pnorm(
                rate_changes + 0.125,
                mean = exp_chg,
                sd = rm
              ) - pnorm(
                rate_changes - 0.125,
                mean = exp_chg,
                sd = rm
              )
            } else {
              probs_prob <- rep(0, length(rate_changes))
            }
            
            # Discrete: 100% probability on rounded outcome
            probs_disc <- ifelse(rate_changes == disc, 1, 0)
            
            # Blend the two approaches
            probs <- bl * probs_prob + (1 - bl) * probs_disc
            
            # Normalize to ensure probabilities sum to 1
            probs <- probs / sum(probs)
            
            tibble(
              rate_change = rate_changes,
              probability = probs
            )
          })
        )
      
      # Unnest probability data
      meeting_cash %>%
        select(scrape_time_melb, days_to_meeting, expected_change, 
               discrete_outcome, blend, rmse, prob_data) %>%
        unnest(prob_data)
    })
  ) %>%
  unnest(meeting_data)

# ------------------------------------------------------------------------------
# 9. FOCUS ON NEXT MEETING & PREPARE VISUALIZATION DATA
# ------------------------------------------------------------------------------

next_meeting_probs <- meeting_probs %>%
  filter(meeting_date == next_meeting) %>%
  mutate(
    # Create descriptive labels for rate moves
    move = case_when(
      rate_change == -0.75 ~ "-75 bp cut",
      rate_change == -0.50 ~ "-50 bp cut",
      rate_change == -0.25 ~ "-25 bp cut",
      rate_change == 0 ~ "No change",
      rate_change == 0.25 ~ "+25 bp hike",
      rate_change == 0.50 ~ "+50 bp hike",
      rate_change == 0.75 ~ "+75 bp hike",
      TRUE ~ as.character(rate_change)
    ),
    move = factor(move, levels = c(
      "-75 bp cut", "-50 bp cut", "-25 bp cut", "No change",
      "+25 bp hike", "+50 bp hike", "+75 bp hike"
    ))
  )

# ------------------------------------------------------------------------------
# 10. IDENTIFY TOP 3 MOST LIKELY OUTCOMES AT LATEST FORECAST
# ------------------------------------------------------------------------------

latest_probs <- next_meeting_probs %>%
  filter(scrape_time_melb == max(scrape_time_melb)) %>%
  arrange(desc(probability)) %>%
  slice(1:3)

top3_moves <- latest_probs$move

print("Top 3 most likely outcomes:")
print(latest_probs %>% select(move, probability))

# Filter data to only include top 3 scenarios
top3_df <- next_meeting_probs %>%
  filter(move %in% top3_moves)

# ------------------------------------------------------------------------------
# 11. DETERMINE CHART DATE RANGE
# ------------------------------------------------------------------------------

# Calculate date range (from 7 days before first data to 1 day after last data)
date_range <- top3_df %>%
  summarise(
    min_date = min(as.Date(scrape_time_melb)) - days(7),
    max_date = max(as.Date(scrape_time_melb)) + days(1)
  )

# Convert to datetime limits for plotting (in Melbourne timezone)
start_xlim <- ymd_hms(paste0(date_range$min_date, " 00:00:00"), 
                      tz = "Australia/Melbourne")
end_xlim <- ymd_hms(paste0(date_range$max_date, " 23:59:59"), 
                    tz = "Australia/Melbourne")

# ------------------------------------------------------------------------------
# 12. CREATE STATIC PROBABILITY CHART
# ------------------------------------------------------------------------------

line <- ggplot(top3_df, aes(x = scrape_time_melb, 
                             y = probability,
                             colour = move, 
                             group = move)) +
  geom_line(linewidth = 1.2) +
  scale_colour_manual(
    values = c(
      "-75 bp cut" = "#000080",
      "-50 bp cut" = "#004B8E",
      "-25 bp cut" = "#5FA4D4",
      "No change" = "#BFBFBF",
      "+25 bp hike" = "#E07C7C",
      "+50 bp hike" = "#B50000",
      "+75 bp hike" = "#800000"
    ),
    name = ""
  ) +
  scale_x_datetime(
    limits = c(start_xlim, end_xlim),
    date_breaks = "2 day",
    date_labels = "%d %b",
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, 1),
    labels = percent_format(accuracy = 1),
    expand = c(0, 0)
  ) +
  labs(
    title = glue("Cash-Rate Moves for the Next Meeting on {format(next_meeting, '%d %b %Y')}"),
    subtitle = glue("as of {format(as.Date(latest_scrape), '%d %b %Y')}"),
    x = "Forecast date",
    y = "Probability"
  ) +
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
    axis.text.y = element_text(size = 12),
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14),
    legend.position = "right",
    legend.title = element_blank()
  )

# Save static plot (two versions)
ggsave("docs/line.png", line, width = 10, height = 5, dpi = 300)
ggsave(
  glue("docs/line_{format(next_meeting, '%d %b %Y')}.png"), 
  line, 
  width = 10, 
  height = 5, 
  dpi = 300
)

print(top3_df, n = 50)

# ------------------------------------------------------------------------------
# 14. CREATE INTERACTIVE VERSION WITH PROPER VERTICAL LINES
# ------------------------------------------------------------------------------

# Define colors for ABS releases
abs_colors <- c(
  "CPI" = "#FF6B6B",
  "CPI Indicator" = "#4ECDC4",
  "WPI" = "#45B7D1",
  "National Accounts" = "#FFA726",
  "Labour Force" = "#AB47BC"
)

# Create base plot WITHOUT any vertical lines
line_int_base <- ggplot(top3_df, aes(x = scrape_time_melb, 
                                      y = probability,
                                      colour = move, 
                                      group = move)) +
  geom_line(linewidth = 1.2) +
  scale_colour_manual(
    values = c(
      "-75 bp cut" = "#000080",
      "-50 bp cut" = "#004B8E",
      "-25 bp cut" = "#5FA4D4",
      "No change" = "#BFBFBF",
      "+25 bp hike" = "#E07C7C",
      "+50 bp hike" = "#B50000",
      "+75 bp hike" = "#800000"
    ),
    name = ""
  ) +
  scale_x_datetime(
    limits = c(start_xlim, end_xlim),
    date_breaks = "2 day",
    date_labels = "%d %b",
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, 1),
    labels = percent_format(accuracy = 1),
    expand = c(0, 0)
  ) +
  labs(
    title = glue("Cash-Rate Moves for the Next Meeting on {format(next_meeting, '%d %b %Y')}"),
    subtitle = glue("as of {format(as.Date(latest_scrape), '%d %b %Y')}"),
    x = "Forecast date",
    y = "Probability"
  ) +
  aes(text = paste0(
    "Time: ", format(scrape_time_melb, "%d %b %H:%M"), "<br>",
    "Move: ", move, "<br>",
    "Probability: ", percent(probability, accuracy = 1)
  )) +
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
    axis.text.y = element_text(size = 12),
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14),
    legend.position = "right",
    legend.title = element_blank()
  )

# Filter releases to only show those within the chart's date range
relevant_releases <- abs_releases %>%
  filter(datetime >= start_xlim & datetime <= end_xlim)

# Prepare vertical line data in the SAME format as top3_df
# Create two points for each release (bottom and top of chart)
vlines_df <- relevant_releases %>%
  rowwise() %>%
  mutate(
    data = list(tibble(
      scrape_time_melb = datetime,  # Already in Melbourne time
      probability = c(0, 1),
      move = dataset,
      point_order = 1:2
    ))
  ) %>%
  ungroup() %>%
  select(data) %>%
  unnest(data)

# Combine with top3_df for plotting
plot_df <- bind_rows(
  top3_df %>% mutate(line_type = "probability"),
  vlines_df %>% mutate(line_type = "release")
)

# Create completely fresh ggplot with BOTH datasets
line_int_complete <- ggplot() +
  # Probability lines
  geom_line(
    data = plot_df %>% filter(line_type == "probability"),
    aes(x = scrape_time_melb, 
        y = probability,
        colour = move, 
        group = move,
        text = paste0(
          "Time: ", format(scrape_time_melb, "%d %b %H:%M"), "<br>",
          "Move: ", move, "<br>",
          "Probability: ", percent(probability, accuracy = 1)
        )),
    linewidth = 1.2
  ) +
  # Vertical lines for releases
  geom_line(
    data = plot_df %>% filter(line_type == "release"),
    aes(x = scrape_time_melb,
        y = probability,
        colour = move,
        group = interaction(move, scrape_time_melb),
        text = paste0(
          "<b>", move, "</b><br>",
          format(scrape_time_melb, "%d %b %Y<br>%H:%M %Z")
        )),
    linetype = "dashed",
    linewidth = 1
  ) +
  scale_colour_manual(
    values = c(
      "-75 bp cut" = "#000080",
      "-50 bp cut" = "#004B8E",
      "-25 bp cut" = "#5FA4D4",
      "No change" = "#BFBFBF",
      "+25 bp hike" = "#E07C7C",
      "+50 bp hike" = "#B50000",
      "+75 bp hike" = "#800000",
      "CPI" = "#FF6B6B",
      "CPI Indicator" = "#4ECDC4",
      "WPI" = "#45B7D1",
      "National Accounts" = "#FFA726",
      "Labour Force" = "#AB47BC"
    ),
    name = ""
  ) +
  scale_x_datetime(
    limits = c(start_xlim, end_xlim),
    date_breaks = "2 day",
    date_labels = "%d %b",
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, 1),
    labels = percent_format(accuracy = 1),
    expand = c(0, 0)
  ) +
  labs(
    title = glue("Cash-Rate Moves for the Next Meeting on {format(next_meeting, '%d %b %Y')}"),
    subtitle = glue("as of {format(as.Date(latest_scrape), '%d %b %Y')}"),
    x = "Forecast date",
    y = "Probability"
  ) +
  theme_bw() +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
    axis.text.y = element_text(size = 12),
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14),
    legend.position = "right",
    legend.title = element_blank()
  )

# Convert to Plotly
interactive_line <- ggplotly(line_int_complete, tooltip = "text") %>%
  layout(
    hovermode = "x unified",
    legend = list(x = 1.02, y = 0.5, xanchor = "left"),
    showlegend = TRUE
  )

# Final layout adjustments
interactive_line <- interactive_line %>%
  layout(
    xaxis = list(
      title = "Forecast date",
      tickangle = 45
    ),
    yaxis = list(
      title = "Probability",
      tickformat = ".0%"
    ),
    title = list(
      text = paste0(
        glue("Cash-Rate Moves for the Next Meeting on {format(next_meeting, '%d %b %Y')}"),
        "<br>",
        "<sub>", glue("as of {format(as.Date(latest_scrape), '%d %b %Y')}"), "</sub>"
      )
    )
  )

# Save interactive HTML
htmlwidgets::saveWidget(
  interactive_line,
  file = "docs/line_interactive.html",
  selfcontained = TRUE
)

cat("\nInteractive chart saved to: docs/line_interactive.html\n")
