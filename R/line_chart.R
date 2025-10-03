# =============================================
# 1) Setup & libraries
# =============================================
suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(purrr)
  library(tibble)
  library(ggplot2)
  library(tidyr)
  library(plotly)
  library(readrba)   # for read_rba()
  library(scales)
  library(glue)
})


# Get all matching files
files <- list.files("docs/meetings", pattern = "^area_all_moves_\\d{4}-\\d{2}-\\d{2}\\.png$", full.names = TRUE)

# Extract dates from filenames and filter
files_to_delete <- files[sapply(files, function(f) {
  date_str <- sub(".*area_all_moves_(\\d{4}-\\d{2}-\\d{2})\\.png$", "\\1", basename(f))
  file_date <- as.Date(date_str)
  file_date < as.Date("2025-07-14")
})]

# Delete the files
if (length(files_to_delete) > 0) {
  file.remove(files_to_delete)
  cat("Deleted", length(files_to_delete), "files\n")
} else {
  cat("No files to delete\n")
}

# =============================================
# 2) Load data & RMSE lookup
# =============================================
cash_rate <- readRDS("combined_data/all_data.Rds")    # columns: date, cash_rate, scrape_time
load("combined_data/rmse_days.RData")                 # object rmse_days: days_to_meeting ↦ finalrmse

blend_weight <- function(days_to_meeting) {
  # Linear blend from 0 to 1 over last 30 days
  pmax(0, pmin(1, 1 - days_to_meeting / 30))
}

  # 1. grab the most-recent published value only
latest_rt <- read_rba(series_id = "FIRMMCRTD") |>
             slice_max(date, n = 1, with_ties = FALSE) |>
             pull(value)

  override <- 3.60
  


spread <- 0.00
cash_rate$cash_rate <- cash_rate$cash_rate+spread


if (!dir.exists("docs/meetings")) dir.create("docs/meetings", recursive = TRUE)

# =============================================
# 3) Define RBA meeting schedule
# =============================================
meeting_schedule <- tibble(
  meeting_date = as.Date(c(
    # 2025 meetings
    "2025-02-18","2025-04-01","2025-05-20","2025-07-08",
    "2025-08-12","2025-09-30","2025-11-04","2025-12-09",
    # 2026 meetings (second day of each two-day meeting)
    "2026-02-03","2026-03-17","2026-05-05","2026-06-16",
    "2026-08-11" ,"2026-09-29","2026-11-03","2026-12-08"
  ))
) %>% 
  mutate(
    expiry = if_else(
      day(meeting_date) >= days_in_month(meeting_date) - 1,   # last 1‑2 days
      ceiling_date(meeting_date, "month"),                    # → next month
      floor_date(meeting_date,  "month")                      # otherwise same
    )
  ) %>% 
  select(expiry, meeting_date)

abs_releases <- tribble(
  ~dataset,           ~datetime,
  
  # CPI (quarterly)
  "CPI",  ymd_hm("2025-01-29 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2025-04-30 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2025-07-30 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2025-10-29 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2026-01-28 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2026-04-29 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2026-07-29 11:30", tz = "Australia/Melbourne"),
  "CPI",  ymd_hm("2026-10-28 11:30", tz = "Australia/Melbourne"),
  
  # CPI Indicator (monthly)
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
  
  # WPI (quarterly)
  "WPI",  ymd_hm("2025-02-19 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2025-05-14 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2025-08-13 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2025-11-12 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2026-02-18 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2026-05-13 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2026-08-12 11:30", tz = "Australia/Melbourne"),
  "WPI",  ymd_hm("2026-11-11 11:30", tz = "Australia/Melbourne"),
  
  # National Accounts (quarterly)
  "National Accounts", ymd_hm("2025-03-05 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2025-06-04 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2025-09-03 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2025-12-03 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2026-03-04 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2026-06-03 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2026-09-02 11:30", tz = "Australia/Melbourne"),
  "National Accounts", ymd_hm("2026-12-02 11:30", tz = "Australia/Melbourne"),
  
  # Labour Force (monthly)
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

# =============================================
# 4) Identify last meeting, collect scrapes
# =============================================
last_meeting   <- max(meeting_schedule$meeting_date[
                        meeting_schedule$meeting_date <= Sys.Date()])

print(last_meeting)

use_override   <- !is.null(override) &&
                  Sys.Date() - last_meeting <= 1

print(use_override)

initial_rt     <- if (use_override) override else latest_rt

  print(initial_rt)


all_times <- sort(unique(cash_rate$scrape_time))

# New logic for filtering scrapes based on 2:30 PM AEST cutoff
now_melb <- lubridate::now(tzone = "Australia/Melbourne")
cutoff_time <- lubridate::ymd_hm(paste0(Sys.Date(), " 14:30"), tz = "Australia/Melbourne")

# If it's before 2:30 PM AEST, include yesterday's data
if (now_melb < cutoff_time) {
  # Include data from yesterday onwards
  cutoff_date <- Sys.Date() - 1
} else {
  # After 2:30 PM, only include today's data
  cutoff_date <- Sys.Date()
}

print(last_meeting)
print(now_melb)
print(cutoff_time)


scrapes <- all_times[all_times >= cutoff_date | all_times > last_meeting]

tail(scrapes)

# =============================================
# 5) Build implied‐mean panel for each scrape × meeting
# =============================================
all_list <- map(scrapes, function(scr) {

  scr_date <- as.Date(scr)

  # 1) grab the last‐known price for each expiry up to this scrape
df_rates <- cash_rate %>% 
  filter(scrape_time == scr) %>%          # keep rows from *this* scrape only
  select(
    expiry        = date,                 # contract month
    forecast_rate = cash_rate,            # implied rate
    scrape_time                         # (all identical → scr)
  )


  # 2) join onto your schedule
  df <- meeting_schedule %>%
    distinct(expiry, meeting_date) %>%
    mutate(scrape_time = scr) %>%
    left_join(df_rates, by = "expiry") %>%
    arrange(expiry)

  # 3) lose exactly those expiries with no price yet
  df <- df %>% filter(!is.na(forecast_rate))
  if (nrow(df) == 0) return(NULL)



  prev_implied <- NA_real_          # will store r_tp1 from prior row
  out <- vector("list", nrow(df))

  for (i in seq_len(nrow(df))) {
    row   <- df[i, ]

    rt_in <- if (is.na(prev_implied)) initial_rt else prev_implied

    r_tp1 <- if (row$meeting_date < row$expiry) {
                row$forecast_rate
             } else {
                nb <- (day(row$meeting_date)-1) / days_in_month(row$expiry)
                na <- 1 - nb
                (row$forecast_rate - rt_in * nb) / na
             }

    out[[i]] <- tibble(
      scrape_time     = scr,
      meeting_date    = row$meeting_date,
      implied_mean    = r_tp1,
      days_to_meeting = as.integer(row$meeting_date - scr_date),
      previous_rate   = rt_in           # = rate actually used
    )

    prev_implied <- r_tp1               # roll forward
  }

  bind_rows(out)
})

all_estimates <- all_list %>%
  compact() %>%                    # drop the NULLs
  bind_rows() %>%
  filter(days_to_meeting >= 0) %>% # only future meetings
  left_join(rmse_days, by = "days_to_meeting") %>%
  rename(stdev = finalrmse)


max_rmse <- suppressWarnings(max(rmse_days$finalrmse, na.rm = TRUE))
if (!is.finite(max_rmse)) {
  stop("No finite RMSE values found in rmse_days$finalrmse")
}

bad_sd <- !is.finite(all_estimates$stdev) | is.na(all_estimates$stdev) | all_estimates$stdev <= 0
n_bad  <- sum(bad_sd, na.rm = TRUE)

if (n_bad > 0) {
  message(sprintf("Replacing %d missing/invalid stdev(s) with max RMSE = %.4f", n_bad, max_rmse))
  all_estimates$stdev[bad_sd] <- max_rmse
}


all_estimates%>% tail(100) %>% print(n = Inf,  width = Inf)

# =============================================
# 6) Build bucketed probabilities for each row
# =============================================
bucket_centers <- seq(0.10, 6.10, by = 0.25)
half_width     <- 0.125

current_rate <- read_rba(series_id = "FIRMMCRTD") %>%
  filter(date == max(date)) %>%
  pull(value)

 current_rate <- if (use_override) override else current_rate

current_center <- bucket_centers[ which.min( abs(bucket_centers - current_rate) ) ]

bucket_list <- vector("list", nrow(all_estimates))
for (i in seq_len(nrow(all_estimates))) {
  mu_i    <- all_estimates$implied_mean[i]
  sigma_i <- all_estimates$stdev[i]
  d_i     <- all_estimates$days_to_meeting[i]
  rc      <- current_rate  

  # Probabilistic method
  p_vec <- sapply(bucket_centers, function(b) {
    lower <- b - half_width
    upper <- b + half_width
    pnorm(upper, mean = mu_i, sd = sigma_i) - pnorm(lower, mean = mu_i, sd = sigma_i)
  })
  p_vec[p_vec < 0]    <- 0
  p_vec[p_vec < 0.01] <- 0
  p_vec <- p_vec / sum(p_vec)

  # Linear method
  nearest <- order(abs(bucket_centers - mu_i))[1:2]
  b1 <- min(bucket_centers[nearest])
  b2 <- max(bucket_centers[nearest])
  w2 <- (mu_i - b1) / (b2 - b1)
  l_vec <- numeric(length(bucket_centers))
  l_vec[bucket_centers == b1] <- 1 - w2
  l_vec[bucket_centers == b2] <- w2

  # Blending
  blend <- blend_weight(d_i)
  v <- blend * l_vec + (1 - blend) * p_vec

  bucket_list[[i]] <- tibble(
    scrape_time   = all_estimates$scrape_time[i],
    meeting_date  = all_estimates$meeting_date[i],
    implied_mean  = mu_i,
    stdev         = sigma_i,
    days_to_meeting = d_i,
    bucket        = bucket_centers,
    probability_linear = l_vec,
    probability_prob   = p_vec,
    probability        = v,
    diff           = bucket_centers - current_rate,
    diff_s         = sign(bucket_centers - current_rate) * abs(bucket_centers - current_rate)^(1/4)
  )
}

all_estimates_buckets <- bind_rows(bucket_list)

all_estimates_buckets %>% 
  tail(20) %>% 
  print(n = Inf, width = Inf)

# =============================================
# 7 Bar charts for every future meeting (latest scrape)
# =============================================

# 1) Identify all future RBA meetings
future_meetings <- meeting_schedule$meeting_date
future_meetings <- future_meetings[future_meetings > Sys.Date()]

# 2) Grab the most recent scrape_time
latest_scrape <- max(all_estimates_buckets$scrape_time)+hours(10)

# 3) Loop through each meeting, filter & plot
for (mt in future_meetings) {
  # a) extract the slice for this meeting
  bar_df <- all_estimates_buckets %>%
    filter(
      scrape_time  == latest_scrape,
      meeting_date == mt
    )


  

  # d) create the bar chart
p <- ggplot(bar_df, aes(x = factor(bucket), y = probability, fill = diff_s)) +
  geom_col(show.legend = FALSE) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_fill_gradient2(
    midpoint = 0,
    low      = "#0022FF",    # vivid blue for cuts
    mid      = "#B3B3B3",    # white at no change
    high     = "#FF2200",    # vivid red for hikes
    limits   = range(bar_df$diff_s, na.rm = TRUE)
  ) +
    labs(
      title    = paste("Cash Rate Outcome Probabilities —", format(as.Date(mt), "%d %B %Y")),
      subtitle =paste(
  "As of", 
  format(with_tz(as.POSIXct(latest_scrape) + hours(10), tzone = "Australia/Sydney"), "%d %B %Y, %I:%M %p AEST")
),
      x        = "Target Rate (%)",
      y        = "Probability (%)"
    ) +
   theme_bw()  +
   theme(axis.text.x = element_text(angle = 45, hjust = 1))

                     
  ggsave(
      filename = paste0("docs/rate_probabilities_", gsub(" ", "_", mt), ".png"),
    plot     = p,
    width    = 6,
    height   = 4,
    dpi      = 300,
    device   = "png"
  )
}


# =============================================
# Define next_meeting
#  • If today is a meeting day, keep it until 15:30 AEST/AEDT
#    then switch to the following meeting
# =============================================
now_melb  <- lubridate::now(tzone = "Australia/Melbourne")
today_melb <- as.Date(now_melb)

cutoff <- lubridate::ymd_hm(
  paste0(today_melb, " 15:00"),
  tz = "Australia/Melbourne"
)



next_meeting <- if (today_melb %in% meeting_schedule$meeting_date &&
                    now_melb < cutoff) {
  today_melb                       # keep showing today’s meeting
} else {
  meeting_schedule %>%             # otherwise roll forward
    filter(meeting_date > today_melb) %>%
    slice_min(meeting_date) %>%
    pull(meeting_date)
}

print(next_meeting)
# —————————————————————————————————————————————————————————————————————
# build top3_df and turn the numeric bucket centers into descriptive moves
# —————————————————————————————————————————————————————————————————————
# 1) compute the true “no‐change” bucket centre once:
current_center <- bucket_centers[which.min(abs(bucket_centers - current_rate))]

top3_buckets <- all_estimates_buckets %>% 
  filter(meeting_date == next_meeting) %>%          # keep the target meeting
  group_by(bucket) %>%                              # pool all scrapes
  summarise(probability = mean(probability, na.rm = TRUE),
            .groups = "drop") %>%                   # average across scrapes
  slice_max(order_by = probability, n = 4, with_ties = FALSE) %>% 
  pull(bucket)


# B) now build top3_df by filtering all dates to those same 3 buckets
top3_df <- all_estimates_buckets %>%
  filter(
    meeting_date == next_meeting,
    bucket %in% top3_buckets
  ) %>%
  # compute diff & move exactly as before
  mutate(
    diff_center = bucket - current_center,
    move = case_when(
      near(diff_center, -0.75) ~ "-75 bp cut",
      near(diff_center, -0.50) ~ "-50 bp cut",
      near(diff_center, -0.25) ~ "-25 bp cut",
      near(diff_center,  0.00) ~ "No change",
      near(diff_center,  0.25) ~ "+25 bp hike",
      near(diff_center,  0.50) ~ "+50 bp hike",
      near(diff_center,  0.75) ~ "+75 bp hike",
      TRUE                      ~ sprintf("%+.0f bp", diff_center*100)
    ),
    move = factor(
      move,
      levels = c("-75 bp cut","-50 bp cut","-25 bp cut","No change","+25 bp hike","+50 bp hike","+75 bp hike")
    )
  ) %>%
  select(-diff_center)

top3_df <- top3_df %>% 
  mutate(
    move = factor(
      move,
      levels = c(
        "-75 bp cut",      # add
        "-50 bp cut",
        "-25 bp cut",
        "No change",
        "+25 bp hike",
        "+50 bp hike",
        "+75 bp hike"      # add
      )
    )
  )


start_xlim <- min(top3_df$scrape_time) + hours(10)
end_xlim   <- as.POSIXct(next_meeting, tz = "Australia/Melbourne") + hours(17)



# Your existing line plot
line <- ggplot(top3_df, aes(x = scrape_time + hours(10), y = probability,
                            colour = move, group = move)) +
  geom_line(linewidth = 1.2) +
  scale_colour_manual(
    values = c("-75 bp cut" = "#000080", "-50 bp cut" = "#004B8E",
               "-25 bp cut" = "#5FA4D4", "No change" = "#BFBFBF",
               "+25 bp hike" = "#E07C7C", "+50 bp hike" = "#B50000",
               "+75 bp hike" = "#800000",
              "CPI" = "#FF6B6B",
"CPI Indicator" = "#4ECDC4", 
"WPI" = "#45B7D1",
"National Accounts" = "#FFA726",
"Labour Force" = "#AB47BC"),
    name = ""   
  ) +
  scale_x_datetime(
    limits      = c(start_xlim, end_xlim),
    date_breaks = "2 day",
    date_labels = "%d %b",
    expand      = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, 1), labels = scales::percent_format(accuracy = 1),
    expand = c(0, 0)
  ) +
  labs(
    title    = glue::glue("Cash-Rate Moves for the Next Meeting on {format(next_meeting, '%d %b %Y')}"),
    subtitle = glue::glue("as of {format(as.Date(latest_scrape+hours(10)), '%d %b %Y')}"),
    x = "Forecast date", y = "Probability"
  ) +
  geom_vline(data = abs_releases,
             aes(xintercept = datetime, colour = dataset),
             linetype = "dashed", alpha = 0.8) +
  theme_bw() +
  theme(axis.text.x  = element_text(angle = 45, hjust = 1, size = 9),
        axis.text.y  = element_text(size = 12),
        axis.title.x = element_text(size = 14),
        axis.title.y = element_text(size = 14),
        legend.position = "right",
        legend.title = element_blank())

# Save the static plot
ggsave("docs/line.png", line, width = 10, height = 5, dpi = 300)

ggsave(
  glue("docs/line_{format(next_meeting, '%d %b %Y')}.png"), 
  line, 
  width = 10, 
  height = 5, 
  dpi = 300
)

# NOW create line_int for interactive plot
line_int <- line +
  aes(text = paste0(
    "Time: ", format(scrape_time + hours(10), "%d %b %H:%M"), "<br>",
    "Move: ", move, "<br>",
    "Probability: ", scales::percent(probability, accuracy = 1)
  ))

# Convert to plotly
interactive_line <- ggplotly(line_int, tooltip = "text") %>%
  layout(
    hovermode = "x unified",
    legend = list(x = 1.02, y = 0.5, xanchor = "left"),
    showlegend = TRUE
  )


htmlwidgets::saveWidget(
  interactive_line,
  file          = "docs/line_interactive.html",
  selfcontained = TRUE
)
