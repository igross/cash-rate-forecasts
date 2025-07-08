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
})

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

  override <- 3.85
  


spread <- 0.00
cash_rate$cash_rate <- cash_rate$cash_rate+spread

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



# =============================================
# 4) Identify last meeting, collect scrapes
# =============================================
last_meeting   <- max(meeting_schedule$meeting_date[
                        meeting_schedule$meeting_date <= Sys.Date()])

use_override   <- !is.null(override) &&
                  Sys.Date() - last_meeting <= 1

initial_rt     <- if (use_override) override else latest_rt

all_times <- sort(unique(cash_rate$scrape_time))
scrapes   <- all_times[all_times > last_meeting]   # every scrape after the last decision

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



all_estimates%>% tail(100) %>% print(n = Inf,  width = Inf)

# =============================================
# 6) Build bucketed probabilities for each row
# =============================================
bucket_centers <- seq(0.10, 6.10, by = 0.25)
half_width     <- 0.125

current_rate <- read_rba(series_id = "FIRMMCRTD") %>%
  filter(date == max(date)) %>%
  pull(value)

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
latest_scrape <- max(all_estimates_buckets$scrape_time)

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
      subtitle = paste("As of", format(as.Date(latest_scrape), "%d %B %Y")),
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
  paste0(today_melb, " 15:30"),
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
      levels = c("-50 bp cut","-25 bp cut","No change","+25 bp hike","+50 bp hike")
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


print(top3_df, width = Inf)

line <- ggplot(top3_df, aes(
    x     = scrape_time + hours(10),
    y     = probability,
    colour = move,
    group  = move
  )) +
  geom_line(linewidth = 1.2) +
  scale_colour_manual(
    values = c(
      "-75 bp cut"   = "#000080",
      "-50 bp cut"   = "#004B8E",
      "-25 bp cut"   = "#5FA4D4",
      "No change"    = "#BFBFBF",
      "+25 bp hike"  = "#E07C7C",
      "+50 bp hike"  = "#B50000",
      "+75 bp hike"  = "#800000"
    ),
    drop = FALSE,   # keep colours even if a series is all-zero today
    name = ""
  ) + 
scale_x_datetime(
  limits = function(x) c(
      min(x),
      as.POSIXct(next_meeting) + hours(17)          # end exactly at meeting
    ),   # axis extends 3 days
  breaks = function(x) {
    start <- lubridate::floor_date(min(x), "day") + lubridate::hours(10)
    end   <- floor_date(max(x), "day") + hours(10) + days(3)  # ticks cover buffer

    alldays <- seq(from = start, to = end, by = "1 day")
    alldays[!lubridate::wday(alldays) %in% c(1, 7)]   # Mon‑Fri 10 a.m.
  },
  date_labels = "%d %b",
  expand = c(0, 0)
) + 
  scale_y_continuous( limits = c(0, 1),
    expand = c(0, 0),
                     labels = scales::percent_format(accuracy = 1)) +
  labs(
    title    = paste("Cash Rate Moves for the Next Meeting on", format(as.Date(next_meeting), "%d %b %Y")),
    subtitle = paste("as of", format(as.Date(latest_scrape),   "%d %b %Y")),
    x        = "Forecast date",
    y        = "Probability"
  ) +
  theme_bw() +
  theme(
    axis.text.x  = element_text(angle = 45, hjust = 1, size = 12),
    axis.text.y  = element_text(size = 12),
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14),
    legend.position = c(1.02, 0.5)
  ) 

# overwrite the previous PNG
ggsave("docs/line.png", line, width = 8, height = 5, dpi = 300)


# =============================================
# Interactive widget
# =============================================
line_int <- line +
  aes(text = paste0(
    "", format(scrape_time + hours(10), "%H:%M"), "<br>",
    "Probability: ", scales::percent(probability, accuracy = 1)
  ))

interactive_line <- ggplotly(line_int, tooltip = "text") %>%
  layout(
    hovermode = "x unified",
    legend    = list(x = 1.02, y = 0.5, xanchor = "left")
  )

htmlwidgets::saveWidget(
  interactive_line,
  file          = "docs/line_interactive.html",
  selfcontained = TRUE
)

top3_df <- top3_df %>%
  complete(scrape_time, move, fill = list(probability = 0)) %>%
  mutate(
    scrape_time = as.POSIXct(unlist(scrape_time), tz = "Australia/Melbourne"),
    scrape_time_adj = scrape_time + hours(10),
    move = factor(move, levels = c(
      "-75 bp cut", "-50 bp cut", "-25 bp cut", "No change",
      "+25 bp hike", "+50 bp hike", "+75 bp hike"
    ))
  )

# pick out only the colours you actually need, in exactly the order of your factor‐levels
my_fill_cols <- c(
  "-75 bp cut" = "#000080",  # navy blue
  "-50 bp cut"         = "#004B8E",
  "-25 bp cut"         = "#5FA4D4",
  "No change"          = "#BFBFBF",
  "+25 bp hike"        = "#E07C7C",
  "+50 bp hike"        = "#B50000",
  "+75 bp hike"= "#800000"   # dark red
)[ levels(top3_df$move) ]

# now your area plot will see exactly those 5 fills, in that locked‐in order:
area <- ggplot(top3_df, aes(
  x = scrape_time_adj,
  y = probability,
  fill = move,
  group = move
)) +
  geom_area(position = "stack", colour = NA, alpha = 0.9) +
  scale_fill_manual(
    values = my_fill_cols,
    breaks = levels(top3_df$move),
    drop = FALSE,
    name = "",
    na.value = "grey80"
  ) +
  scale_x_datetime(
    limits = function(x) c(
      min(x),
      as.POSIXct(next_meeting) + hours(17)          # end exactly at meeting
    ),
    breaks = function(x) {
      start <- lubridate::floor_date(min(x), "day") + hours(10)
      end   <- as.POSIXct(next_meeting) + hours(10)
      alldays <- seq(from = start, to = end, by = "1 day")
      alldays[!lubridate::wday(alldays) %in% c(1, 7)]   # Mon-Fri 10 a.m.
    },
    date_labels = "%d %b",
    expand = c(0, 0)
  ) +
  scale_y_continuous(
    limits = c(0, 1),
    expand = c(0, 0),
    labels = scales::percent_format(accuracy = 1)
  ) +
  labs(
    title    = paste(
      "Cash-Rate Scenarios up to the Meeting on",
      format(as.Date(next_meeting), "%d %b %Y")
    ),
    subtitle = paste(
      "as of", format(as.Date(latest_scrape), "%d %b %Y")
    ),
    x = "Forecast date",
    y = "Probability (stacked)"
  ) +
  theme_bw() +
  theme(
    axis.text.x  = element_text(angle = 45, hjust = 1, size = 12),
    axis.text.y  = element_text(size = 12),
    axis.title.x = element_text(size = 14),
    axis.title.y = element_text(size = 14),
    legend.position = c(1.02, 0.5)
  )

ggsave("docs/area.png", area, width = 8, height = 5, dpi = 300)  # overwrites if rerun

# -------------------------------------------------
# 2) Interactive version
# -------------------------------------------------
area_int <- area +
  aes(text = paste0(
    "", format(scrape_time, "%H:%M"), "<br>",
    "Probability: ", scales::percent(probability, accuracy = 1)
  ))

interactive_area <- ggplotly(area_int, tooltip = "text") %>%
  layout(
    hovermode = "x unified",
    legend    = list(x = 1.02, y = 0.5, xanchor = "left")
  )

htmlwidgets::saveWidget(
  interactive_area,
  file          = "docs/area_interactive.html",
  selfcontained = TRUE
)

# Save the `cars` data frame in R’s native “.rds” format:
saveRDS(Filter(is.data.frame, mget(ls(), .GlobalEnv)), "all_dataframes.rds")
