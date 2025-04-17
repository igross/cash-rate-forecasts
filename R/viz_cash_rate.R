suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(lubridate)
  library(ggrepel)
  library(tidyr)
  library(scales)
  library(readabs)
  library(readrba)
          })

# Meeting schedule (expiry month first day, meeting dates)
meeting_schedule <- tibble::tibble(
  expiry       = as.Date(c(
    "2025-02-01", "2025-03-01", "2025-05-01",
    "2025-07-01", "2025-08-01", "2025-09-01",
    "2025-11-01", "2025-12-01"
  )),
  meeting_date = as.Date(c(
    "2025-02-18", "2025-04-01", "2025-05-20",
    "2025-07-08", "2025-08-12", "2025-09-30",
    "2025-11-04", "2025-12-09"
  ))
)

# Spread adjustment
spread_bp     <- 0.01  # in percentage points

# Hard-coded RMSE lookup by days to meeting (0..60)
rmse_lookup <- c(
  0.042179271, 0.042179271, 0.042179271, 0.042179271, 0.042179271,
  0.042776679, 0.046298074, 0.046298074, 0.046298074, 0.046298074,
  0.046298074, 0.046298074, 0.046298074, 0.046298074, 0.046298074,
  0.046298074, 0.046298074, 0.046298074, 0.046298074, 0.046298074,
  0.046298074, 0.046298074, 0.046298074, 0.049190132, 0.055747377,
  0.066188053, 0.076198602, 0.085952901, 0.095017305, 0.102963055,
  0.108868503, 0.114587407, 0.120812307, 0.124727182, 0.126527307,
  0.127130759, 0.130574217, 0.131907087, 0.131907087, 0.133101424,
  0.133604684, 0.133604684, 0.133604684, 0.134157915, 0.134279318,
  0.135105750, 0.135768693, 0.135768693, 0.135768693, 0.137844837,
  0.141733602, 0.144384669, 0.151849631, 0.160263120, 0.170752101,
  0.182983584, 0.187848605, 0.193679887, 0.201277676, 0.210711555,
  0.216858302
)
names(rmse_lookup) <- 0:(length(rmse_lookup)-1)

# Inject RMSE (manual)
rmse <- c(
  0.045551112, 0.102312111, 0.221970531, 0.327847512, 0.412946769,
  0.468724693, 0.500403217, 0.557833521, 0.649794316, 0.69814153,
  0.778152254, 0.860217121, 0.909074616, 0.997528424, 1.065491777,
  1.131569667, 1.211783477, 1.322739338, 1.359617226
)

rba_meeting_dates <- as.Date(c(
  "2025-04-01", "2025-05-20", "2025-07-08", "2025-08-12",
  "2025-09-30", "2025-11-04", "2025-12-09"
))

file.remove(list.files("docs", pattern = "\\.png$", full.names = TRUE))

cash_rate <- readRDS(file.path("combined_data", "all_data.Rds"))

current_rate <- read_rba(series_id = "FIRMMCRTD") %>%
    filter(date == max(date)) %>%
    pull(value)

if (!dir.exists("figures")) dir.create("figures")

viz_1 <- cash_rate |>
  ggplot(aes(x = date, y = cash_rate, col = scrape_date, group = scrape_date)) +
  geom_line() +
  geom_line(data = ~filter(., scrape_date == max(scrape_date)),
            colour = "red",
            linewidth = 1.5) +
  geom_text(data = ~filter(.,
                           scrape_date == max(scrape_date)) |>
              filter(date == max(date)),
            colour = "red",
            hjust = 0,
            lineheight = 0.8,
            aes(label = format(scrape_date, "%e %b\n%Y"))) +
  scale_colour_date(date_labels = "%b '%y") +
  scale_x_date(expand = expansion(c(0, 0.1)),
               date_labels = "%b\n%Y",
               breaks = seq(max(cash_rate$date),
                            min(cash_rate$date),
                            by = "-1 year")) +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  theme_bw() +
  labs(subtitle = "Expected future cash rate",
       colour = "Expected\nas at:",
       x = "Date") +
  theme(panel.grid.minor = element_blank(),
        axis.title = element_blank())

max_scrape_date <- max(cash_rate$scrape_date)
week_ago <- max_scrape_date - weeks(1)
year_ago <- max_scrape_date - years(1)
month_ago <- max_scrape_date - months(1)
yesterday <- max(cash_rate$scrape_date[cash_rate$scrape_date < max_scrape_date])

viz_2 <- cash_rate |>
  filter(scrape_date %in% c(max_scrape_date,
                            min(scrape_date[scrape_date >= week_ago]),
                            min(scrape_date[scrape_date >= month_ago]),
                            max(scrape_date[scrape_date != max(scrape_date)]))) |>
  distinct() |>
  ggplot(aes(x = date, y = cash_rate,
             col = factor(scrape_date),
             group = scrape_date)) +
  geom_line() +
  geom_text_repel(data = ~group_by(., scrape_date) |>
                    filter(date == max(date)),
                  hjust = 0,
                  nudge_x = 10,
                  min.segment.length = 10000,
                  aes(label = format(scrape_date, "%d %b %Y"))) +
  scale_x_date(expand = expansion(c(0.05, 0.15)),
               date_labels = "%b\n%Y",
               breaks = seq(max(cash_rate$date),
                            min(cash_rate$date),
                            by = "-6 months")) +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  theme_bw() +
  theme(legend.position = "none") +
  labs(subtitle = "Expected future cash rate",
       x = "Date") +
  theme(panel.grid.minor = element_blank(),
        axis.title = element_blank())

viz_3 <- cash_rate |>
  group_by(scrape_date) |>
  filter(cash_rate == max(cash_rate)) |>
  ggplot(aes(x = scrape_date, y = cash_rate)) +
  geom_line() +
  theme_bw() +
  scale_x_date(date_labels = "%b\n%Y",
               date_breaks = "3 months") +
  labs(x = "Expected as at",
       subtitle = "Expected peak cash rate") +
  scale_y_continuous(labels = \(x) paste0(x, "%"),
                     breaks = seq(0, 100, 0.25)) +
  theme(panel.grid.minor = element_blank(),
        axis.title = element_blank())


viz_4 <- cash_rate |>
  group_by(scrape_date) |>
  summarise(peak_date = min(date[cash_rate == max(cash_rate)])) |>
  ggplot(aes(x = scrape_date, y = peak_date)) +
  geom_point() +
  geom_smooth(method = "loess",
              formula = y ~ x,
              span = 0.1,
              se = FALSE) +
  theme_bw() +
  scale_x_date(date_labels = "%b\n%Y",
               date_breaks = "3 months") +
  scale_y_date(date_labels = "%b\n%Y",
               date_breaks = "3 months") +
  labs(x = "Expected as at",
       y = "Expected to peak in") +
  theme(panel.grid.minor = element_blank())

viz_5 <- cash_rate |>
  group_by(scrape_date) |>
  mutate(next_month = floor_date(scrape_date + months(1), "month"),
         current_rate = mean(cash_rate[date == next_month])) |>
  filter(date >= scrape_date) |>
  mutate(diff = cash_rate - current_rate) |>
  filter(diff <= -0.25) |>
  filter(date == min(date)) |>
  ggplot(aes(x = scrape_date,
             y = date)) +
  geom_point() +
  geom_line() +
  scale_x_date("Expected as at",
               limits = ymd("2024-01-01",
                            max(cash_rate$scrape_date)),
               breaks = seq(max(cash_rate$scrape_date),
                            min(cash_rate$scrape_date),
                            by = "-1 months"),
               date_labels = "%d %b\n%Y") +
  scale_y_date("Expected date of first cut",
               date_labels = "%b\n%Y",
               date_breaks = "3 months",
               limits = \(x) ymd("2024-01-01",
                                 x[2])) +
  theme_bw() +
  labs(subtitle = "Expected date of first rate cut",
       caption = "Refers to the first date at which futures pricing imply a 100% or greater chance of a 25bp cut relative to the then-current rate.")




# ============================
# VIZ 6: BUCKETED RATE PROBABILITIES BY MEETING
# ============================

# Forecast path and RMSE
forecast_df <- cash_rate %>%
  filter(scrape_date == max(scrape_date)) %>%
  select(date, forecast_rate = cash_rate) %>%
  filter(date >= as.Date("2025-04-01"),
         date <= as.Date("2026-09-01"))

)

forecast_df <- forecast_df %>%
  left_join(meeting_dates, by = c("date" = "expiry"))

# Iterative cash rate logic
results <- list()
rt <- forecast_df$forecast_rate[1]

for (i in 1:nrow(forecast_df)) {
  row <- forecast_df[i, ]
  dim <- days_in_month(row$date)
  if (!is.na(row$meeting_date)) {
    nb <- (day(row$meeting_date) - 1) / dim
    na <- 1 - nb
    r_tp1 <- (row$forecast_rate - rt * nb) / na
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

df_result <- bind_rows(results)


df_result$stdev <- rmse[1:nrow(df_result)]

# Bucket edges
bucket_centers <- seq(0.10, 4.60, by = 0.25)
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

# Reshape
df_long <- df_probs %>%
  rename_with(~ gsub("p_", "", .x), starts_with("p_")) %>%
  pivot_longer(cols = -date, names_to = "bucket", values_to = "probability") %>%
  mutate(bucket = paste0(bucket, "%"),
         month_label = format(date, "%b %Y"))

# Filter only meeting months

meeting_months <- floor_date(rba_meeting_dates, "month")

meeting_months <- meeting_months[meeting_months >= floor_date(Sys.Date(), "month")]

df_long <- df_long %>%
  filter(date %in% meeting_months)

latest_scrape <- max(cash_rate$scrape_date)
print(df_long)

                       
# Save each chart
for (m in unique(df_long$month_label)) {
  p <- ggplot(filter(df_long, month_label == m),
              aes(x = bucket, y = probability, fill = bucket)) +
    geom_bar(stat = "identity", show.legend = FALSE) +
     labs(
      title = paste("Cash Rate Outcome Probabilities -", m),
      caption = paste("Based on futures-implied rates as of", format(latest_scrape, "%d %B %Y")),
      x = "Target Rate Bucket", y = "Probability (%)"
    ) +
    theme_bw() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))


tryCatch({

  ggsave(
    filename = paste0("docs/rate_probabilities_", gsub(" ", "_", m), ".png"),
    plot = p,
    width = 6,
    height = 4,
    dpi = 300
  )
  print(m)
}, error = function(e) {
  message("❌ Failed to generate fan chart: ", e$message)
})
  

}

                       
                       # Select latest forecast path
fan_df <- cash_rate %>%
  filter(scrape_date == max(scrape_date)) %>%
  select(date, forecast_rate = cash_rate) %>%
  arrange(date)


n_rows <- min(nrow(fan_df), length(rmse))

fan_df <- fan_df[1:n_rows, ] %>%
  mutate(
    stdev = rmse[1:n_rows],
    lower_95 = forecast_rate - qnorm(0.975) * stdev,
    upper_95 = forecast_rate + qnorm(0.975) * stdev,
    lower_65 = forecast_rate - qnorm(0.825) * stdev,
    upper_65 = forecast_rate + qnorm(0.825) * stdev
  )

# Plot the fan chart
viz_fan <- ggplot(fan_df, aes(x = date)) +
  geom_ribbon(aes(ymin = lower_95, ymax = upper_95), fill = "#a6cee3", alpha = 0.5) +  # 95% band — light blue
  geom_ribbon(aes(ymin = lower_65, ymax = upper_65), fill = "#1f78b4", alpha = 0.6) +  # 65% band — stronger blue
  geom_line(aes(y = forecast_rate), color = "#e31a1c", size = 1.2) +  # Mean path — bold red
   scale_y_continuous(labels = label_percent(scale = 1), limits = c(0, NA)) +
  scale_x_date(date_labels = "%b\n%Y", date_breaks = "3 months") +
  theme_bw() +
  labs(
    title = "Mean Path of Cash Rate with Uncertainty Bands",
    caption = paste("Shaded areas represent 65% and 95% confidence interval using historical forecast errors. Futures-implied path as of", format(max(cash_rate$scrape_date), "%d %B %Y")),
    x = NULL, y = NULL
  ) +
  theme(panel.grid.minor = element_blank())

                       ggsave("docs/rate_fan_chart.png", plot = viz_fan, width = 8, height = 5, dpi = 300)



meeting_dates <- tibble(
  expiry = as.Date(c(
    "2025-02-01", "2025-03-01", "2025-05-01", "2025-07-01",
    "2025-08-01", "2025-09-01", "2025-11-01", "2025-12-01")),
  meeting_date = as.Date(c(
    "2025-02-18", "2025-04-01", "2025-05-20", "2025-07-08",
    "2025-08-12", "2025-09-30", "2025-11-04", "2025-12-09"))
)

spread <- 0.01

# ────────────────────────────────────────────────────────────────────────────────
# 2.  Identify the last and next meetings ---------------------------------------
today <- Sys.Date()  
last_meeting     <- max(meeting_dates$meeting_date[meeting_dates$meeting_date <= today])
next_meeting_row <- meeting_dates            %>% filter(meeting_date >  today) %>% slice_min(meeting_date)

last_expiry      <- meeting_dates$expiry [meeting_dates$meeting_date == last_meeting]
next_expiry      <- next_meeting_row$expiry
current_expiry <- next_meeting_row$expiry %m-% months(1)   # exactly 1 month earlier
next_meeting     <- next_meeting_row$meeting_date      # scalar date

# ────────────────────────────────────────────────────────────────────────────────
# 3.  Bring in every scrape since the last meeting, but only the months           #
#     we need (from the month *after* the last meeting up to the next expiry).    #
forecast_df <- cash_rate %>%
  filter(
    scrape_date  >  last_meeting+1,         # all scrapes since the last decision
    date         >= last_expiry,          # start at the month that covers it
    date         <= next_expiry           # stop at the month of the next meeting
  ) %>%
   arrange(scrape_date, date)  %>% 
  distinct()                  

unique_scrapes <- sort(unique(forecast_df$scrape_date))
results        <- vector("list", length(unique_scrapes))

results <- tibble(
  scrape_date       = as.Date(character()),
  current_expiry    = as.Date(character()),
  next_expiry       = as.Date(character()),
  cash_rate_current = numeric(),
  cash_rate_next    = numeric(),
  implied_r_tp1     = numeric()
)

for (j in seq_along(unique_scrapes)) {
  df_scr <- filter(forecast_df, scrape_date == unique_scrapes[j])
  
  row_next    <- filter(df_scr, date == next_expiry)
  row_current <- filter(df_scr, date == current_expiry)
  if (nrow(row_next) == 0 || nrow(row_current) == 0) next  # skip incomplete scrape
  
  dim <- days_in_month(next_meeting)
  nb  <- (day(next_meeting) - 1) / dim
  na  <- 1 - nb
  
  r_tp1 <- ((row_next$cash_rate + spread) -
              (row_current$cash_rate + spread) * nb) / na
  
  results <- add_row(
    results,
    scrape_date       = unique_scrapes[j],
    current_expiry    = current_expiry,
    next_expiry       = next_expiry,
    cash_rate_current = row_current$cash_rate,
    cash_rate_next    = row_next$cash_rate,
    implied_r_tp1     = r_tp1
  )
}

RMSE_day <- c(
  0.042179271, 0.042179271, 0.042179271, 0.042179271, 0.042179271,
  0.042776679, 0.046298074, 0.046298074, 0.046298074, 0.046298074,
  0.046298074, 0.046298074, 0.046298074, 0.046298074, 0.046298074,
  0.046298074, 0.046298074, 0.046298074, 0.046298074, 0.046298074,
  0.046298074, 0.046298074, 0.046298074, 0.049190132, 0.055747377,
  0.066188053, 0.076198602, 0.085952901, 0.095017305, 0.102963055,
  0.108868503, 0.114587407, 0.120812307, 0.124727182, 0.126527307,
  0.127130759, 0.130574217, 0.131907087, 0.131907087, 0.133101424,
  0.133604684, 0.133604684, 0.133604684, 0.134157915, 0.134279318,
  0.135105750, 0.135768693, 0.135768693, 0.135768693, 0.137844837,
  0.141733602, 0.144384669, 0.151849631, 0.160263120, 0.170752101,
  0.182983584, 0.187848605, 0.193679887, 0.201277676, 0.210711555,
  0.216858302
)
names(RMSE_day) <- 0:60                   # label each element by its day index


results <- results %>%
  mutate(
    days_to_meeting = as.integer(next_meeting - scrape_date),
    RMSE            = RMSE_day[as.character(days_to_meeting)]
  ) %>%
  select(-days_to_meeting)                # drop helper column if not needed

## ── 1.  Bucket definition ------------------------------------------------------
bucket_centers <- seq(0.10, 6.60, by = 0.25)
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
    scrape_date = results$scrape_date[j],
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

## ── 1. Bucket definition relative to the current rate -------------------------
bucket_def <- tibble(
  label = factor(c("-50 bp cut", "-25 bp cut", "No change",
                   "+25 bp hike", "+50 bp hike"),
                 levels = c("-50 bp cut", "-25 bp cut", "No change",
                            "+25 bp hike", "+50 bp hike")),
  shift = c(-0.50, -0.25, 0.00, +0.25, +0.50)   # shift in % pts (== 50/25 bp)
)
half_width <- 0.125                             # ±12.5 bp around each centre


## ── 2. Compute bucket probabilities for every scrape (plain loops) ------------
prob_rows <- vector("list", nrow(results))

for (j in seq_len(nrow(results))) {
  mu     <- results$implied_r_tp1[j]
  sigma  <- results$RMSE[j]
  r_curr <- results$cash_rate_current[j]
  
  # skip if NA or sigma == 0
  if (is.na(mu) || is.na(sigma) || sigma == 0) next
  
  probs <- numeric(nrow(bucket_def))
  
  for (k in seq_len(nrow(bucket_def))) {
    lower <- r_curr + bucket_def$shift[k] - half_width
    upper <- r_curr + bucket_def$shift[k] + half_width
    probs[k] <- pnorm(upper, mean = mu, sd = sigma) -
      pnorm(lower, mean = mu, sd = sigma)
  }
  
  prob_rows[[j]] <- tibble(
    scrape_date = results$scrape_date[j],
    bucket      = bucket_def$label,
    probability = probs / sum(probs)          # renormalise, tiny numerical drift
  )
}

bucket_probs <- bind_rows(prob_rows)


## ── 3. Keep the *top‑4* buckets per scrape ------------------------------------
top4 <- bucket_probs %>%
  group_by(scrape_date) %>%
  slice_max(order_by = probability, n = 4, with_ties = FALSE) %>%
  ungroup()


## ── 4. Stacked‑bar plot -------------------------------------------------------
stacked<-ggplot(top4, aes(x = scrape_date, y = probability, fill = bucket)) +
  geom_col(width = 0.9) +
  scale_y_continuous(labels = scales::percent) +
  labs(title = "Top‑4 policy‑move buckets per scrape date",
       x = "Scrape date",
       y = "Probability (stacked to 100 %)",
       fill = "Meeting‑day move") +
  theme_bw() +
  theme(legend.position = "right")


                           ggsave("docs/stacked.png", plot = stacked, width = 8, height = 5, dpi = 300)

line<-ggplot(top4,
       aes(x = scrape_date,
           y = probability,
           colour = bucket,
           group  = bucket)) +
  geom_line(size = 1) +
  geom_point(size = 2) +
  scale_colour_manual(
    values = c(
      "-50 bp cut" = "#004B8E",  # deepest blue  (largest cut)
      "-25 bp cut" = "#5FA4D4",  # lighter blue  (half‑size cut)
      "No change"  = "#BFBFBF",  # neutral grey
      "+25 bp hike"= "#E07C7C",  # lighter red   (half‑size hike)
      "+50 bp hike"= "#B50000"   # deepest red   (largest hike)
    )
  ) +
  scale_y_continuous(labels = scales::percent) +
  labs(  title  = paste0("Top‑4 policy‑move probabilities for next RBA meeting on {meeting_label}"),
       x      = "Forecast date",
       y      = "Probability",
       colour = "Meeting‑day move") +
  theme_bw() +
  theme(legend.position = "right")
  
    ggsave("docs/line.png", plot = line, width = 8, height = 5, dpi = 300)

