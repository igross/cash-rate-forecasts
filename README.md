
<!-- README.md is generated from README.Rmd. Please edit that file -->

# cash-rate-scraper

The key script in this repo is `R/scrape_cash_rate.R`. This file parses
market expectations for the cash rate based on the [latest ASX cash rate
implied yield
curve](https://www.asx.com.au/markets/trade-our-derivatives-market/futures-market/rba-rate-tracker).

The data is saved as a CSV in `daily_data`. The file
`combined_data/all_data.Rds` contains a dataframe that is the
combination of all the daily data CSVs.

Note that there was a gap in the data collection between 1 July and 20
July, as the ASX changed its website.

I offer no assurance that this will continue to work, or that the data
extracted using this script will be free of errors.

The `.github/workflows/refresh_data.yaml` file contains the instructions
to GitHub Actions to tell it to run `scrape_cash_rate.R` each day and
commit the results in this repo.

Please fork/copy/modify as you see fit.

# Graphs!

The file `R/viz_cash_rate.R` produces visualisations of this data, which
are shown below:

    #> Warning: All formats failed to parse. No formats found.
    #> Warning: All formats failed to parse. No formats found.
    #> [1] "2025-08-12"
    #> [1] FALSE
    #> [1] 3.6
    #> [1] "2025-08-12"
    #> [1] "2025-09-21 09:19:36 AEST"
    #> [1] "2025-09-20 14:30:00 AEST"
    #> Replacing 19 missing/invalid stdev(s) with max RMSE = 1.3813
    #> # A tibble: 100 × 6
    #>     scrape_time         meeting_date implied_mean days_to_meeting previous_rate
    #>     <dttm>              <date>              <dbl>           <int>         <dbl>
    #>   1 2025-09-19 04:46:19 2026-12-08           3.08             446          3.08
    #>   2 2025-09-19 04:57:51 2025-09-30           3.58              12          3.6 
    #>   3 2025-09-19 04:57:51 2025-11-04           3.38              47          3.58
    #>   4 2025-09-19 04:57:51 2025-12-09           3.32              82          3.38
    #>   5 2025-09-19 04:57:51 2026-02-03           3.17             138          3.32
    #>   6 2025-09-19 04:57:51 2026-03-17           3.18             180          3.17
    #>   7 2025-09-19 04:57:51 2026-05-05           2.96             229          3.18
    #>   8 2025-09-19 04:57:51 2026-06-16           3.09             271          2.96
    #>   9 2025-09-19 04:57:51 2026-08-11           3.06             327          3.09
    #>  10 2025-09-19 04:57:51 2026-09-29           3.07             376          3.06
    #>  11 2025-09-19 04:57:51 2026-11-03           3.08             411          3.07
    #>  12 2025-09-19 04:57:51 2026-12-08           3.08             446          3.08
    #>  13 2025-09-19 05:23:55 2025-09-30           3.58              12          3.6 
    #>  14 2025-09-19 05:23:55 2025-11-04           3.38              47          3.58
    #>  15 2025-09-19 05:23:55 2025-12-09           3.32              82          3.38
    #>  16 2025-09-19 05:23:55 2026-02-03           3.17             138          3.32
    #>  17 2025-09-19 05:23:55 2026-03-17           3.18             180          3.17
    #>  18 2025-09-19 05:23:55 2026-05-05           2.96             229          3.18
    #>  19 2025-09-19 05:23:55 2026-06-16           3.09             271          2.96
    #>  20 2025-09-19 05:23:55 2026-08-11           3.06             327          3.09
    #>  21 2025-09-19 05:23:55 2026-09-29           3.07             376          3.06
    #>  22 2025-09-19 05:23:55 2026-11-03           3.08             411          3.07
    #>  23 2025-09-19 05:23:55 2026-12-08           3.08             446          3.08
    #>  24 2025-09-19 05:39:14 2025-09-30           3.58              12          3.6 
    #>  25 2025-09-19 05:39:14 2025-11-04           3.38              47          3.58
    #>  26 2025-09-19 05:39:14 2025-12-09           3.32              82          3.38
    #>  27 2025-09-19 05:39:14 2026-02-03           3.17             138          3.32
    #>  28 2025-09-19 05:39:14 2026-03-17           3.18             180          3.17
    #>  29 2025-09-19 05:39:14 2026-05-05           2.96             229          3.18
    #>  30 2025-09-19 05:39:14 2026-06-16           3.09             271          2.96
    #>  31 2025-09-19 05:39:14 2026-08-11           3.06             327          3.09
    #>  32 2025-09-19 05:39:14 2026-09-29           3.07             376          3.06
    #>  33 2025-09-19 05:39:14 2026-11-03           3.08             411          3.07
    #>  34 2025-09-19 05:39:14 2026-12-08           3.08             446          3.08
    #>  35 2025-09-19 05:50:21 2025-09-30           3.58              12          3.6 
    #>  36 2025-09-19 05:50:21 2025-11-04           3.38              47          3.58
    #>  37 2025-09-19 05:50:21 2025-12-09           3.32              82          3.38
    #>  38 2025-09-19 05:50:21 2026-02-03           3.17             138          3.32
    #>  39 2025-09-19 05:50:21 2026-03-17           3.18             180          3.17
    #>  40 2025-09-19 05:50:21 2026-05-05           2.96             229          3.18
    #>  41 2025-09-19 05:50:21 2026-06-16           3.09             271          2.96
    #>  42 2025-09-19 05:50:21 2026-08-11           3.06             327          3.09
    #>  43 2025-09-19 05:50:21 2026-09-29           3.07             376          3.06
    #>  44 2025-09-19 05:50:21 2026-11-03           3.08             411          3.07
    #>  45 2025-09-19 05:50:21 2026-12-08           3.08             446          3.08
    #>  46 2025-09-19 06:02:25 2025-09-30           3.58              12          3.6 
    #>  47 2025-09-19 06:02:25 2025-11-04           3.38              47          3.58
    #>  48 2025-09-19 06:02:25 2025-12-09           3.32              82          3.38
    #>  49 2025-09-19 06:02:25 2026-02-03           3.17             138          3.32
    #>  50 2025-09-19 06:02:25 2026-03-17           3.18             180          3.17
    #>  51 2025-09-19 06:02:25 2026-05-05           2.96             229          3.18
    #>  52 2025-09-19 06:02:25 2026-06-16           3.09             271          2.96
    #>  53 2025-09-19 06:02:25 2026-08-11           3.06             327          3.09
    #>  54 2025-09-19 06:02:25 2026-09-29           3.07             376          3.06
    #>  55 2025-09-19 06:02:25 2026-11-03           3.08             411          3.07
    #>  56 2025-09-19 06:02:25 2026-12-08           3.08             446          3.08
    #>  57 2025-09-19 06:39:53 2025-09-30           3.58              12          3.6 
    #>  58 2025-09-19 06:39:53 2025-11-04           3.39              47          3.58
    #>  59 2025-09-19 06:39:53 2025-12-09           3.31              82          3.39
    #>  60 2025-09-19 06:39:53 2026-02-03           3.18             138          3.31
    #>  61 2025-09-19 06:39:53 2026-03-17           3.17             180          3.18
    #>  62 2025-09-19 06:39:53 2026-05-05           2.96             229          3.17
    #>  63 2025-09-19 06:39:53 2026-06-16           3.09             271          2.96
    #>  64 2025-09-19 06:39:53 2026-08-11           3.06             327          3.09
    #>  65 2025-09-19 06:39:53 2026-09-29           3.07             376          3.06
    #>  66 2025-09-19 06:39:53 2026-11-03           3.08             411          3.07
    #>  67 2025-09-19 06:39:53 2026-12-08           3.08             446          3.08
    #>  68 2025-09-19 06:54:51 2025-09-30           3.58              12          3.6 
    #>  69 2025-09-19 06:54:51 2025-11-04           3.39              47          3.58
    #>  70 2025-09-19 06:54:51 2025-12-09           3.31              82          3.39
    #>  71 2025-09-19 06:54:51 2026-02-03           3.18             138          3.31
    #>  72 2025-09-19 06:54:51 2026-03-17           3.17             180          3.18
    #>  73 2025-09-19 06:54:51 2026-05-05           2.96             229          3.17
    #>  74 2025-09-19 06:54:51 2026-06-16           3.09             271          2.96
    #>  75 2025-09-19 06:54:51 2026-08-11           3.11             327          3.09
    #>  76 2025-09-19 06:54:51 2026-09-29           3.11             376          3.11
    #>  77 2025-09-19 06:54:51 2026-11-03           3.12             411          3.11
    #>  78 2025-09-19 06:54:51 2026-12-08           3.12             446          3.12
    #>  79 2025-09-19 07:18:00 2025-09-30           3.58              12          3.6 
    #>  80 2025-09-19 07:18:00 2025-11-04           3.39              47          3.58
    #>  81 2025-09-19 07:18:00 2025-12-09           3.31              82          3.39
    #>  82 2025-09-19 07:18:00 2026-02-03           3.18             138          3.31
    #>  83 2025-09-19 07:18:00 2026-03-17           3.17             180          3.18
    #>  84 2025-09-19 07:18:00 2026-05-05           2.96             229          3.17
    #>  85 2025-09-19 07:18:00 2026-06-16           3.09             271          2.96
    #>  86 2025-09-19 07:18:00 2026-08-11           3.11             327          3.09
    #>  87 2025-09-19 07:18:00 2026-09-29           3.11             376          3.11
    #>  88 2025-09-19 07:18:00 2026-11-03           3.12             411          3.11
    #>  89 2025-09-19 07:18:00 2026-12-08           3.12             446          3.12
    #>  90 2025-09-20 23:18:28 2025-09-30           3.58              10          3.6 
    #>  91 2025-09-20 23:18:28 2025-11-04           3.39              45          3.58
    #>  92 2025-09-20 23:18:28 2025-12-09           3.31              80          3.39
    #>  93 2025-09-20 23:18:28 2026-02-03           3.18             136          3.31
    #>  94 2025-09-20 23:18:28 2026-03-17           3.17             178          3.18
    #>  95 2025-09-20 23:18:28 2026-05-05           2.96             227          3.17
    #>  96 2025-09-20 23:18:28 2026-06-16           3.09             269          2.96
    #>  97 2025-09-20 23:18:28 2026-08-11           3.11             325          3.09
    #>  98 2025-09-20 23:18:28 2026-09-29           3.11             374          3.11
    #>  99 2025-09-20 23:18:28 2026-11-03           3.12             409          3.11
    #> 100 2025-09-20 23:18:28 2026-12-08           3.12             444          3.12
    #>      stdev
    #>      <dbl>
    #>   1 1.26  
    #>   2 0.0639
    #>   3 0.175 
    #>   4 0.384 
    #>   5 0.489 
    #>   6 0.725 
    #>   7 0.846 
    #>   8 1.05  
    #>   9 1.06  
    #>  10 1.06  
    #>  11 1.15  
    #>  12 1.26  
    #>  13 0.0639
    #>  14 0.175 
    #>  15 0.384 
    #>  16 0.489 
    #>  17 0.725 
    #>  18 0.846 
    #>  19 1.05  
    #>  20 1.06  
    #>  21 1.06  
    #>  22 1.15  
    #>  23 1.26  
    #>  24 0.0639
    #>  25 0.175 
    #>  26 0.384 
    #>  27 0.489 
    #>  28 0.725 
    #>  29 0.846 
    #>  30 1.05  
    #>  31 1.06  
    #>  32 1.06  
    #>  33 1.15  
    #>  34 1.26  
    #>  35 0.0639
    #>  36 0.175 
    #>  37 0.384 
    #>  38 0.489 
    #>  39 0.725 
    #>  40 0.846 
    #>  41 1.05  
    #>  42 1.06  
    #>  43 1.06  
    #>  44 1.15  
    #>  45 1.26  
    #>  46 0.0639
    #>  47 0.175 
    #>  48 0.384 
    #>  49 0.489 
    #>  50 0.725 
    #>  51 0.846 
    #>  52 1.05  
    #>  53 1.06  
    #>  54 1.06  
    #>  55 1.15  
    #>  56 1.26  
    #>  57 0.0639
    #>  58 0.175 
    #>  59 0.384 
    #>  60 0.489 
    #>  61 0.725 
    #>  62 0.846 
    #>  63 1.05  
    #>  64 1.06  
    #>  65 1.06  
    #>  66 1.15  
    #>  67 1.26  
    #>  68 0.0639
    #>  69 0.175 
    #>  70 0.384 
    #>  71 0.489 
    #>  72 0.725 
    #>  73 0.846 
    #>  74 1.05  
    #>  75 1.06  
    #>  76 1.06  
    #>  77 1.15  
    #>  78 1.26  
    #>  79 0.0639
    #>  80 0.175 
    #>  81 0.384 
    #>  82 0.489 
    #>  83 0.725 
    #>  84 0.846 
    #>  85 1.05  
    #>  86 1.06  
    #>  87 1.06  
    #>  88 1.15  
    #>  89 1.26  
    #>  90 0.0639
    #>  91 0.161 
    #>  92 0.374 
    #>  93 0.469 
    #>  94 0.710 
    #>  95 0.846 
    #>  96 1.01  
    #>  97 1.06  
    #>  98 1.06  
    #>  99 1.14  
    #> 100 1.26
    #> Warning: All formats failed to parse. No formats found.
    #> Warning: All formats failed to parse. No formats found.
    #> # A tibble: 20 × 11
    #>    scrape_time         meeting_date implied_mean stdev days_to_meeting bucket
    #>    <dttm>              <date>              <dbl> <dbl>           <int>  <dbl>
    #>  1 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   1.35
    #>  2 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   1.6 
    #>  3 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   1.85
    #>  4 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   2.1 
    #>  5 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   2.35
    #>  6 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   2.6 
    #>  7 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   2.85
    #>  8 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   3.1 
    #>  9 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   3.35
    #> 10 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   3.6 
    #> 11 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   3.85
    #> 12 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   4.1 
    #> 13 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   4.35
    #> 14 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   4.6 
    #> 15 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   4.85
    #> 16 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   5.1 
    #> 17 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   5.35
    #> 18 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   5.6 
    #> 19 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   5.85
    #> 20 2025-09-20 23:18:28 2026-12-08           3.12  1.26             444   6.1 
    #>    probability_linear probability_prob probability   diff diff_s
    #>                 <dbl>            <dbl>       <dbl>  <dbl>  <dbl>
    #>  1             0                0.0305      0.0305 -2.25  -1.22 
    #>  2             0                0.0396      0.0396 -2     -1.19 
    #>  3             0                0.0494      0.0494 -1.75  -1.15 
    #>  4             0                0.0592      0.0592 -1.5   -1.11 
    #>  5             0                0.0682      0.0682 -1.25  -1.06 
    #>  6             0                0.0755      0.0755 -1     -1    
    #>  7             0                0.0804      0.0804 -0.75  -0.931
    #>  8             0.915            0.0823      0.0823 -0.5   -0.841
    #>  9             0.0854           0.0810      0.0810 -0.25  -0.707
    #> 10             0                0.0766      0.0766  0      0    
    #> 11             0                0.0696      0.0696  0.25   0.707
    #> 12             0                0.0608      0.0608  0.500  0.841
    #> 13             0                0.0511      0.0511  0.750  0.931
    #> 14             0                0.0412      0.0412  1      1    
    #> 15             0                0.0320      0.0320  1.25   1.06 
    #> 16             0                0.0239      0.0239  1.5    1.11 
    #> 17             0                0.0171      0.0171  1.75   1.15 
    #> 18             0                0.0118      0.0118  2      1.19 
    #> 19             0                0           0       2.25   1.22 
    #> 20             0                0           0       2.5    1.26
    #> [1] "2025-09-30"
    #> Warning: Removed 66 rows containing missing values or values outside the scale range
    #> (`geom_vline()`).
    #> Creating extended buckets for 5913 estimate rows
    #> Bucket range: 0.1 to 6.1 
    #> Extended buckets created: 147825 rows
    #> Unique moves: 23 
    #> ✓ all_estimates_buckets_ext created successfully
    #> Future meetings found: 11 
    #> Meetings: 2025-09-30, 2025-11-04, 2025-12-09, 2026-02-03, 2026-03-17, 2026-05-05, 2026-06-16, 2026-08-11, 2026-09-29, 2026-11-03, 2026-12-08 
    #> Processing meeting: 20361 
    #> df_mt dimensions: 13350 x 3 
    #> Creating plot with 13350 data points
    #> Error creating plot for meeting 20361 : object 'fill_map' not found 
    #> Data summary:
    #>   scrape_time                            move        probability    
    #>  Min.   :2025-08-12 00:01:37   +300 bp hike:  534   Min.   :0.0000  
    #>  1st Qu.:2025-08-22 03:14:02   +275 bp hike:  534   1st Qu.:0.0000  
    #>  Median :2025-09-02 06:34:35   +250 bp hike:  534   Median :0.0000  
    #>  Mean   :2025-09-01 08:10:25   +225 bp hike:  534   Mean   :0.0400  
    #>  3rd Qu.:2025-09-10 23:54:08   +200 bp hike:  534   3rd Qu.:0.0000  
    #>  Max.   :2025-09-20 23:18:28   +175 bp hike:  534   Max.   :0.9216  
    #>                                (Other)     :10146                   
    #> CSV exported: docs/meetings/csv/area_data_2025-09-30.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-11-04.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-12-09.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-02-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-03-17.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-05-05.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-06-16.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-08-11.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-09-29.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-11-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-12-08.csv 
    #> Combined CSV exported: docs/meetings/csv/all_meetings_area_data.csv
    #> 
    #> Verification - Sample bucket_rate values:
    #> First 20 unique bucket rates: 0.1, 0.35, 0.6, 0.85, 1.1, 1.35, 1.6, 1.85, 2.1, 2.35, 2.6, 2.85, 3.1, 3.35, 3.6, 3.85, 4.1, 4.35, 4.6, 4.85 
    #> Decimal endings (should be 10, 35, 60, 85): 10, 35, 60, 85, 10, 9.99999999999994, 34.9999999999999, 59.9999999999999, 84.9999999999999 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20396 
    #> df_mt dimensions: 13350 x 3 
    #> Creating plot with 13350 data points
    #> Saving to: docs/meetings/area_all_moves_2025-11-04.png
    #> Warning: Removed 820 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20396 
    #> CSV exported: docs/meetings/csv/area_data_2025-09-30.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-11-04.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-12-09.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-02-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-03-17.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-05-05.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-06-16.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-08-11.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-09-29.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-11-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-12-08.csv 
    #> Combined CSV exported: docs/meetings/csv/all_meetings_area_data.csv
    #> 
    #> Verification - Sample bucket_rate values:
    #> First 20 unique bucket rates: 0.1, 0.35, 0.6, 0.85, 1.1, 1.35, 1.6, 1.85, 2.1, 2.35, 2.6, 2.85, 3.1, 3.35, 3.6, 3.85, 4.1, 4.35, 4.6, 4.85 
    #> Decimal endings (should be 10, 35, 60, 85): 10, 35, 60, 85, 10, 9.99999999999994, 34.9999999999999, 59.9999999999999, 84.9999999999999 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20431 
    #> df_mt dimensions: 13350 x 3 
    #> Creating plot with 13350 data points
    #> Saving to: docs/meetings/area_all_moves_2025-12-09.png
    #> Warning: Removed 1409 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20431 
    #> CSV exported: docs/meetings/csv/area_data_2025-09-30.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-11-04.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-12-09.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-02-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-03-17.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-05-05.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-06-16.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-08-11.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-09-29.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-11-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-12-08.csv 
    #> Combined CSV exported: docs/meetings/csv/all_meetings_area_data.csv
    #> 
    #> Verification - Sample bucket_rate values:
    #> First 20 unique bucket rates: 0.1, 0.35, 0.6, 0.85, 1.1, 1.35, 1.6, 1.85, 2.1, 2.35, 2.6, 2.85, 3.1, 3.35, 3.6, 3.85, 4.1, 4.35, 4.6, 4.85 
    #> Decimal endings (should be 10, 35, 60, 85): 10, 35, 60, 85, 10, 9.99999999999994, 34.9999999999999, 59.9999999999999, 84.9999999999999 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20487 
    #> df_mt dimensions: 13350 x 3 
    #> Creating plot with 13350 data points
    #> Saving to: docs/meetings/area_all_moves_2026-02-03.png
    #> Warning: Removed 1970 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Error creating plot for meeting 20487 : Problem while converting geom to grob. 
    #> Data summary:
    #>   scrape_time                            move        probability     
    #>  Min.   :2025-08-12 00:01:37   +300 bp hike:  534   Min.   :0.00000  
    #>  1st Qu.:2025-08-22 03:14:02   +275 bp hike:  534   1st Qu.:0.00000  
    #>  Median :2025-09-02 06:34:35   +250 bp hike:  534   Median :0.00000  
    #>  Mean   :2025-09-01 08:10:25   +225 bp hike:  534   Mean   :0.04000  
    #>  3rd Qu.:2025-09-10 23:54:08   +200 bp hike:  534   3rd Qu.:0.07649  
    #>  Max.   :2025-09-20 23:18:28   +175 bp hike:  534   Max.   :0.21135  
    #>                                (Other)     :10146                    
    #> CSV exported: docs/meetings/csv/area_data_2025-09-30.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-11-04.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-12-09.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-02-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-03-17.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-05-05.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-06-16.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-08-11.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-09-29.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-11-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-12-08.csv 
    #> Combined CSV exported: docs/meetings/csv/all_meetings_area_data.csv
    #> 
    #> Verification - Sample bucket_rate values:
    #> First 20 unique bucket rates: 0.1, 0.35, 0.6, 0.85, 1.1, 1.35, 1.6, 1.85, 2.1, 2.35, 2.6, 2.85, 3.1, 3.35, 3.6, 3.85, 4.1, 4.35, 4.6, 4.85 
    #> Decimal endings (should be 10, 35, 60, 85): 10, 35, 60, 85, 10, 9.99999999999994, 34.9999999999999, 59.9999999999999, 84.9999999999999 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20529 
    #> df_mt dimensions: 13350 x 3 
    #> Creating plot with 13350 data points
    #> Saving to: docs/meetings/area_all_moves_2026-03-17.png
    #> Warning: Removed 1951 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20529 
    #> CSV exported: docs/meetings/csv/area_data_2025-09-30.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-11-04.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-12-09.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-02-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-03-17.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-05-05.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-06-16.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-08-11.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-09-29.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-11-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-12-08.csv 
    #> Combined CSV exported: docs/meetings/csv/all_meetings_area_data.csv
    #> 
    #> Verification - Sample bucket_rate values:
    #> First 20 unique bucket rates: 0.1, 0.35, 0.6, 0.85, 1.1, 1.35, 1.6, 1.85, 2.1, 2.35, 2.6, 2.85, 3.1, 3.35, 3.6, 3.85, 4.1, 4.35, 4.6, 4.85 
    #> Decimal endings (should be 10, 35, 60, 85): 10, 35, 60, 85, 10, 9.99999999999994, 34.9999999999999, 59.9999999999999, 84.9999999999999 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20578 
    #> df_mt dimensions: 13350 x 3 
    #> Creating plot with 13350 data points
    #> Saving to: docs/meetings/area_all_moves_2026-05-05.png
    #> Warning: Removed 1829 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20578 
    #> CSV exported: docs/meetings/csv/area_data_2025-09-30.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-11-04.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-12-09.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-02-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-03-17.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-05-05.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-06-16.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-08-11.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-09-29.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-11-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-12-08.csv 
    #> Combined CSV exported: docs/meetings/csv/all_meetings_area_data.csv
    #> 
    #> Verification - Sample bucket_rate values:
    #> First 20 unique bucket rates: 0.1, 0.35, 0.6, 0.85, 1.1, 1.35, 1.6, 1.85, 2.1, 2.35, 2.6, 2.85, 3.1, 3.35, 3.6, 3.85, 4.1, 4.35, 4.6, 4.85 
    #> Decimal endings (should be 10, 35, 60, 85): 10, 35, 60, 85, 10, 9.99999999999994, 34.9999999999999, 59.9999999999999, 84.9999999999999 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20620 
    #> df_mt dimensions: 13350 x 3 
    #> Creating plot with 13350 data points
    #> Saving to: docs/meetings/area_all_moves_2026-06-16.png
    #> Warning: Removed 1736 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20620 
    #> CSV exported: docs/meetings/csv/area_data_2025-09-30.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-11-04.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-12-09.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-02-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-03-17.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-05-05.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-06-16.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-08-11.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-09-29.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-11-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-12-08.csv 
    #> Combined CSV exported: docs/meetings/csv/all_meetings_area_data.csv
    #> 
    #> Verification - Sample bucket_rate values:
    #> First 20 unique bucket rates: 0.1, 0.35, 0.6, 0.85, 1.1, 1.35, 1.6, 1.85, 2.1, 2.35, 2.6, 2.85, 3.1, 3.35, 3.6, 3.85, 4.1, 4.35, 4.6, 4.85 
    #> Decimal endings (should be 10, 35, 60, 85): 10, 35, 60, 85, 10, 9.99999999999994, 34.9999999999999, 59.9999999999999, 84.9999999999999 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20676 
    #> df_mt dimensions: 13350 x 3 
    #> Creating plot with 13350 data points
    #> Saving to: docs/meetings/area_all_moves_2026-08-11.png
    #> Warning: Removed 1760 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20676 
    #> CSV exported: docs/meetings/csv/area_data_2025-09-30.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-11-04.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-12-09.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-02-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-03-17.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-05-05.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-06-16.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-08-11.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-09-29.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-11-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-12-08.csv 
    #> Combined CSV exported: docs/meetings/csv/all_meetings_area_data.csv
    #> 
    #> Verification - Sample bucket_rate values:
    #> First 20 unique bucket rates: 0.1, 0.35, 0.6, 0.85, 1.1, 1.35, 1.6, 1.85, 2.1, 2.35, 2.6, 2.85, 3.1, 3.35, 3.6, 3.85, 4.1, 4.35, 4.6, 4.85 
    #> Decimal endings (should be 10, 35, 60, 85): 10, 35, 60, 85, 10, 9.99999999999994, 34.9999999999999, 59.9999999999999, 84.9999999999999 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20725 
    #> df_mt dimensions: 13350 x 3 
    #> Creating plot with 13350 data points
    #> Saving to: docs/meetings/area_all_moves_2026-09-29.png
    #> Warning: Removed 404 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20725 
    #> CSV exported: docs/meetings/csv/area_data_2025-09-30.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-11-04.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-12-09.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-02-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-03-17.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-05-05.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-06-16.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-08-11.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-09-29.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-11-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-12-08.csv 
    #> Combined CSV exported: docs/meetings/csv/all_meetings_area_data.csv
    #> 
    #> Verification - Sample bucket_rate values:
    #> First 20 unique bucket rates: 0.1, 0.35, 0.6, 0.85, 1.1, 1.35, 1.6, 1.85, 2.1, 2.35, 2.6, 2.85, 3.1, 3.35, 3.6, 3.85, 4.1, 4.35, 4.6, 4.85 
    #> Decimal endings (should be 10, 35, 60, 85): 10, 35, 60, 85, 10, 9.99999999999994, 34.9999999999999, 59.9999999999999, 84.9999999999999 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20760 
    #> df_mt dimensions: 13350 x 3 
    #> Creating plot with 13350 data points
    #> Saving to: docs/meetings/area_all_moves_2026-11-03.png
    #> Warning: Removed 1569 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20760 
    #> CSV exported: docs/meetings/csv/area_data_2025-09-30.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-11-04.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-12-09.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-02-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-03-17.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-05-05.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-06-16.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-08-11.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-09-29.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-11-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-12-08.csv 
    #> Combined CSV exported: docs/meetings/csv/all_meetings_area_data.csv
    #> 
    #> Verification - Sample bucket_rate values:
    #> First 20 unique bucket rates: 0.1, 0.35, 0.6, 0.85, 1.1, 1.35, 1.6, 1.85, 2.1, 2.35, 2.6, 2.85, 3.1, 3.35, 3.6, 3.85, 4.1, 4.35, 4.6, 4.85 
    #> Decimal endings (should be 10, 35, 60, 85): 10, 35, 60, 85, 10, 9.99999999999994, 34.9999999999999, 59.9999999999999, 84.9999999999999 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20795 
    #> df_mt dimensions: 13350 x 3 
    #> Creating plot with 13350 data points
    #> Saving to: docs/meetings/area_all_moves_2026-12-08.png
    #> Warning: Removed 1696 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20795 
    #> CSV exported: docs/meetings/csv/area_data_2025-09-30.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-11-04.csv 
    #> CSV exported: docs/meetings/csv/area_data_2025-12-09.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-02-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-03-17.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-05-05.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-06-16.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-08-11.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-09-29.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-11-03.csv 
    #> CSV exported: docs/meetings/csv/area_data_2026-12-08.csv 
    #> Combined CSV exported: docs/meetings/csv/all_meetings_area_data.csv
    #> 
    #> Verification - Sample bucket_rate values:
    #> First 20 unique bucket rates: 0.1, 0.35, 0.6, 0.85, 1.1, 1.35, 1.6, 1.85, 2.1, 2.35, 2.6, 2.85, 3.1, 3.35, 3.6, 3.85, 4.1, 4.35, 4.6, 4.85 
    #> Decimal endings (should be 10, 35, 60, 85): 10, 35, 60, 85, 10, 9.99999999999994, 34.9999999999999, 59.9999999999999, 84.9999999999999 
    #> CSV export completed with corrected bucket_rate values
