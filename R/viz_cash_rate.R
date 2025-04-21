suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(lubridate)
  library(ggrepel)
  library(tidyr)
  library(scales)
  library(readabs)
  library(readrba)
  library(plotly)
  library(purrr)
})
 

# 1.  Define only the meeting dates
meeting_schedule <- tibble::tibble(
  meeting_date = as.Date(c(
    "2025-02-18", "2025-04-01", "2025-05-20",
    "2025-07-08", "2025-08-12", "2025-09-30",
    "2025-11-04", "2025-12-09"
  ))
)

# 2.  Compute the expiry (first of month) automatically
meeting_schedule <- meeting_schedule %>%
  mutate(
    expiry = floor_date(meeting_date, unit = "month")
  ) %>%
  select(expiry, meeting_date)

# 3.  If you still need a vector of just the upcoming meeting dates:
rba_meeting_dates <- meeting_schedule$meeting_date

# Spread adjustment
spread     <- 0.01  # in percentage points

file.remove(list.files("docs", pattern = "\\.png$", full.names = TRUE))

cash_rate <- readRDS(file.path("combined_data", "all_data.Rds"))

load("combined_data/rmse_days.RData")

current_rate <- read_rba(series_id = "FIRMMCRTD") %>%
    filter(date == max(date)) %>%
    pull(value)

# ============================
# VIZ 6: BUCKETED RATE PROBABILITIES BY MEETING
# ============================

# Forecast path and RMSE
meetingforecasts_df <- cash_rate %>%
filter(scrape_date == max(scrape_date)) %>%
select(date, forecast_rate = cash_rate) %>%
filter(date >= Sys.Date() %m-% months(1))

# scrape_date <- max(cash_rate$scrape_date) 
scrape_latest <- max(cash_rate$scrape_date)


meetingforecasts_df <- meetingforecasts_df %>%
  left_join(meeting_schedule, by = c("date" = "expiry")) %>%
  distinct()

# Iterative cash rate logic
results <- list()
rt <- meetingforecasts_df$forecast_rate[1]

for (i in 1:nrow(meetingforecasts_df)) {
  row <- meetingforecasts_df[i, ]
  dim <- days_in_month(row$date)
  if (!is.na(row$meeting_date)) {
    nb <- (day(row$meeting_date) - 1) / dim
    na <- 1 - nb
    r_tp1 <- ( (row$forecast_rate+spread) - (rt+spread) * nb) / na
  } else {
    nb <- 1
    na <- 0
    r_tp1 <- row$forecast_rate
    rt <- row$forecast_rate
  }

  results[[i]] <- tibble(
    date = row$date,
    meeting_date = row$meeting_date,
    forecast_rate = row$forecast_rate,
    implied_r_tp1 = r_tp1
  )

  if (!is.na(row$meeting_date)) {
    rt <- r_tp1
  }
}

df_result <- bind_rows(results) %>% distinct()

df_result <- df_result %>%
  mutate(
    days_to_meeting = as.integer(meeting_date - scrape_latest)    # difference in calendar days
  ) %>%
  left_join(rmse_days, by = "days_to_meeting") %>%       # brings in the 'rmse' column
  rename(stdev = finalrmse) %>%                               # rename for clarity
  select(date, meeting_date, forecast_rate, implied_r_tp1, stdev)

# Bucket edges
bucket_centers <- seq(0.10, 5.1, by = 0.25)
bucket_edges <- c(bucket_centers - 0.125, tail(bucket_centers, 1) + 0.125)

# Probabilities
bucket_matrix <- sapply(1:(length(bucket_edges) - 1), function(i) {
  pnorm(bucket_edges[i + 1], mean = df_result$implied_r_tp1, sd = df_result$stdev) -
    pnorm(bucket_edges[i], mean = df_result$implied_r_tp1, sd = df_result$stdev)
})
bucket_matrix[bucket_matrix < 0.01] <- 0
bucket_matrix <- apply(bucket_matrix, 1, function(row) row / sum(row)) %>% t()

colnames(bucket_matrix) <- paste0("p_", bucket_centers)
df_probs <- cbind(df_result["date"], round(bucket_matrix * 100, 2))


# 1. compute the raw pnorm‐differences matrix
raw_pm <- sapply(1:(length(bucket_edges)-1), function(i) {
  pnorm(bucket_edges[i+1],
        mean = df_result$implied_r_tp1,
        sd   = df_result$stdev) -
  pnorm(bucket_edges[i],
        mean = df_result$implied_r_tp1,
        sd   = df_result$stdev)
})
# raw_pm is an N×M matrix (N = number of dates, M = number of buckets)

# 2. row‐wise normalise so each row sums exactly to 1
bucket_matrix <- prop.table(raw_pm, margin = 1)

# 3. (optional) drop *very* small probs and renormalise
bucket_matrix[bucket_matrix < 1e-3] <- 0
bucket_matrix <- prop.table(bucket_matrix, margin = 1)

# 4. turn into percentages
bucket_pct <- round(bucket_matrix * 100, 2)

df_probs <- data.frame(
  date = df_result$date,
  bucket_pct,
  check.names = FALSE    # preserve your p_… column names exactly
) %>%
  as_tibble()

# ensure it’s a tibble
df_probs <- as_tibble(df_probs)

df_long <- df_probs %>%
  as_tibble() %>%                  # ensure it’s a tibble
  pivot_longer(
    cols      = -date,             # everything but date
    names_to  = "bucket_idx", 
    values_to = "probability"
  ) %>%
  mutate(
    # bucket_idx comes in as "1","2",… so convert to integer
    bucket_idx   = as.integer(bucket_idx),
    
    # reconstruct the actual bucket centre
    bucket_centre = 0.10 + (bucket_idx - 1) * 0.25,
    
    # format for display
    bucket        = paste0(sprintf("%.2f", bucket_centre), "%"),
    month_label   = format(date, "%b %Y")
  ) %>%
  select(date, month_label, bucket, probability)
                       

# Filter only meeting months

meeting_months <- floor_date(rba_meeting_dates, "month")
meeting_months <- meeting_months[meeting_months >= floor_date(Sys.Date(), "month")]

df_long <- df_long %>%
  filter(date %in% meeting_months)

latest_scrape <- max(cash_rate$scrape_date)
                                          
for (m in unique(df_long$month_label)) {
  dfm <- df_long %>% 
    filter(month_label == m) %>%
    mutate(
      bucket_num = as.numeric(sub("%","",bucket)),
      diff       = bucket_num - current_rate   # deviation from today’s rate
    )

power_trans <- function(p) {
  trans_new(
    name      = paste0("signed-", p),
    transform = function(x) sign(x) * abs(x)^p,
    inverse   = function(x) sign(x) * abs(x)^(1/p)
  )
}
  
  # find the bucket *string* and its *position* in the factor levels
  current_bucket_num   <- dfm$bucket_num[which.min(abs(dfm$bucket_num - current_rate))]
  current_bucket_label <- sprintf("%.2f%%", current_bucket_num)
  xpos                 <- which(levels(dfm$bucket) == current_bucket_label)
  
  p <- ggplot(dfm, aes(x = bucket, y = probability, fill = diff)) +
    geom_col(show.legend = FALSE) +
    
    # draw a vertical line on the discrete x–position:
    geom_vline(xintercept = xpos, 
               colour = "black", 
               linetype = "dashed", 
               linewidth = 0.8) +
    
  scale_fill_gradient2(
    midpoint = 0,
    low      = "#0000FF",
    mid      = "grey80",
    high     = "#FF0000",
    limits   = range(dfm$diff),
    trans    = power_trans(0.25)  # fourth‐root transform
  ) +
    labs(
      title   = paste("Cash Rate Outcome Probabilities –", m),
      caption = paste("Based on futures‑implied rates as of", 
                      format(latest_scrape, "%d %B %Y")),
      x       = "Target Rate Bucket",
      y       = "Probability (%)"
    ) +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  ggsave(
    sprintf("docs/rate_probabilities_%s.png", gsub(" ","_",m)),
    plot   = p,
    width  = 6,
    height = 4,
    dpi    = 300
  )
}


# ────────────────────────────────────────────────────────────────────────────────
# 2.  Identify the last and next meetings ---------------------------------------
today <- Sys.Date()  
last_meeting     <- max(meeting_schedule$meeting_date[meeting_schedule$meeting_date <= today])
next_meeting_row <- meeting_schedule %>% filter(meeting_date >  today) %>% slice_min(meeting_date)

last_expiry      <- meeting_schedule$expiry [meeting_schedule$meeting_date == last_meeting]
next_expiry      <- next_meeting_row$expiry
current_expiry <- next_meeting_row$expiry %m-% months(1)   # exactly 1 month earlier
next_meeting     <- next_meeting_row$meeting_date      # scalar date

forecast_df <- cash_rate %>%
  filter(
    scrape_date  >  last_meeting+1,         # all scrapes since the last decision
    date         >= last_expiry,          # start at the month that covers it
    date         <= next_expiry           # stop at the month of the next meeting
  ) %>%
   arrange(scrape_date, date)  %>% 
  distinct()  %>%
  select(scrape_date, scrape_time, date, cash_rate)                 

print(forecast_df)
print(spread)
                       
# ── Build `results` with spread in one go ──────────────────────────────────────

results <- forecast_df %>%
  # only the two expiries per scrape_date
  filter(date %in% c(current_expiry, next_expiry)) %>%
  # widen so each scrape_date is one row
  pivot_wider(
    id_cols      = scrape_time,
    names_from   = date,
    values_from  = cash_rate,
    names_prefix = "r_",
    values_fn    = mean,        # collapse duplicates by taking the mean
    values_fill  = NA_real_
  ) %>%
  # rename into meaningful names
  rename(
    cash_rate_current = paste0("r_", current_expiry),
    cash_rate_next    = paste0("r_", next_expiry)
  ) %>%
  # now compute implied next‐meeting rate WITH spread
  mutate(
    nb = (day(next_meeting) - 1) / days_in_month(next_meeting),
    implied_r_tp1 = (
      (cash_rate_next    + spread) -
      (cash_rate_current + spread) * nb
    ) / (1 - nb),
    days_to_meeting = as.integer(next_meeting - as.Date(scrape_time))
  ) %>%
  left_join(rmse_days, by = "days_to_meeting") %>% 
  rename(RMSE = finalrmse) 
                        # %>%   select(cash_rate_current, implied_r_tp1, RMSE, scrape_time)
print(as_tibble(rmse_days))
# Inspect
print(results, n = 50, width = Inf)
                  
                       
## ── 1.  Bucket definition ------------------------------------------------------
bucket_centers <- seq(0.10, 5.1, by = 0.25)
bucket_edges   <- c(bucket_centers - 0.125,
                    tail(bucket_centers, 1) + 0.125)
nbuckets <- length(bucket_centers)

## ── 2.  Outer loop over each row in `results` ----------------------------------
bucket_list <- vector("list", nrow(results))   # pre‑allocate

for (j in seq_len(nrow(results))) {
  mu    <- results$implied_r_tp1[j]
  sigma <- results$RMSE[j]
  
  # Skip if either is NA or sigma == 0
  if (is.na(mu) || is.na(sigma) || sigma == 0) next
  
  probs <- numeric(nbuckets)
  
  for (k in seq_len(nbuckets)) {
    lower <- bucket_edges[k]
    upper <- bucket_edges[k + 1]
    probs[k] <- pnorm(upper, mean = mu, sd = sigma) -
      pnorm(lower, mean = mu, sd = sigma)
  }
  
  # Normalise just in case of tiny numerical drift
  probs <- probs / sum(probs)
  
  bucket_list[[j]] <- tibble(
    scrape_time = results$scrape_time[j],
    bucket      = sprintf("%.2f%%", bucket_centers),
    probability = probs
  )
}

## ── 3.  Bind into one tidy frame ----------------------------------------------
bucket_probs <- bind_rows(bucket_list)

print(bucket_probs, n = 30)        # show first 30 rows

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
  library(ggplot2)
})

# your bucket definitions
bucket_def  <- c(-0.50, -0.25, 0.00, 0.25, 0.50)
bucket_lbls <- c("-50 bp cut","-25 bp cut","No change","+25 bp hike","+50 bp hike")
half_width  <- 0.125

move_probs <- results %>%
  transmute(
    scrape_date = scrape_time,
    mu          = implied_r_tp1,
    sigma       = RMSE,
    r_curr      = cash_rate_current
  ) %>%
  mutate(
    # pmap over the three scalars so you get one vector-of-5-per-row
    probs = pmap(
      list(mu, sigma, r_curr),
      function(mu_i, sigma_i, rc) {
        lowers <- rc + bucket_def - half_width
        uppers <- rc + bucket_def + half_width

        v <- pnorm(uppers, mean = mu_i, sd = sigma_i) -
             pnorm(lowers, mean = mu_i, sd = sigma_i)
        v[v < 0] <- 0
        v / sum(v)
      }
    ),
    bucket = list(bucket_lbls)
  ) %>%
  unnest(c(bucket, probs)) %>%
  rename(probability = probs)

# now slice out top‑3
top3_moves <- move_probs %>%
  group_by(scrape_date) %>%
  slice_max(probability, n = 3, with_ties = FALSE) %>%
  mutate(probability = probability / sum(probability)) %>%
  ungroup()

# build a named vector of colours keyed off your actual factor levels
my_cols <- setNames(
  c("#004B8E", "#5FA4D4", "#BFBFBF", "#E07C7C", "#B50000"),
  levels(top3_moves$bucket)
)

line <- ggplot(top3_moves, aes(scrape_date, probability, color = bucket, group = bucket)) +
  geom_line(linewidth = 1) +
  scale_y_continuous(labels = label_percent(1)) +
   scale_color_manual(
    values = c(
      "-50 bp cut"  = "#004B8E",   # darkest blue
      "-25 bp cut"  = "#5FA4D4",   # lighter blue
      "No change"   = "#BFBFBF",   # grey
      "+25 bp hike" = "#E07C7C",   # lighter red
      "+50 bp hike" = "#B50000"    # darkest red
    ) )+
  labs(
    title  = "Cash Rate probabilities for the next RBA meeting",
    x      = "Forecast date",
    y      = "Probability",
    colour = "Meeting‑day move"
  ) +
  theme_bw() +
    theme(
    axis.text.x        = element_text(angle = 45, hjust = 1),
    legend.position    = c(1.02, 0.5),               # right & centered
    legend.justification = c("left", "center"),
    legend.background  = element_blank()
  )

ggsave("docs/line.png", plot = line, width = 8, height = 5, dpi = 300)



# instead of `line + aes(...)` do:
 
line_int <- line +
  aes(text = paste0(
    format(scrape_date, "%m-%d"),
    "<br>", scales::percent(probability, accuracy = 1)
  ))

interactive_line <- ggplotly(line_int, tooltip = "text") %>%
  layout(
    hovermode = "x unified",
    legend    = list(x = 1.02, y = 1)
  )

htmlwidgets::saveWidget(
  interactive_line,
  "docs/line_interactive.html",
  selfcontained = TRUE
)
