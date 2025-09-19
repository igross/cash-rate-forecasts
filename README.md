
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
    #> [1] "2025-09-19 13:26:26 AEST"
    #> [1] "2025-09-19 14:30:00 AEST"
    #> Replacing 19 missing/invalid stdev(s) with max RMSE = 1.3813
    #> # A tibble: 100 × 6
    #>     scrape_time         meeting_date implied_mean days_to_meeting previous_rate
    #>     <dttm>              <date>              <dbl>           <int>         <dbl>
    #>   1 2025-09-18 06:34:38 2026-12-08           3.13             447          3.12
    #>   2 2025-09-18 06:52:33 2025-09-30           3.58              13          3.6 
    #>   3 2025-09-18 06:52:33 2025-11-04           3.37              48          3.58
    #>   4 2025-09-18 06:52:33 2025-12-09           3.30              83          3.37
    #>   5 2025-09-18 06:52:33 2026-02-03           3.18             139          3.30
    #>   6 2025-09-18 06:52:33 2026-03-17           3.17             181          3.18
    #>   7 2025-09-18 06:52:33 2026-05-05           2.96             230          3.17
    #>   8 2025-09-18 06:52:33 2026-06-16           3.09             272          2.96
    #>   9 2025-09-18 06:52:33 2026-08-11           3.06             328          3.09
    #>  10 2025-09-18 06:52:33 2026-09-29           3.07             377          3.06
    #>  11 2025-09-18 06:52:33 2026-11-03           3.08             412          3.07
    #>  12 2025-09-18 06:52:33 2026-12-08           3.08             447          3.08
    #>  13 2025-09-18 07:12:54 2025-09-30           3.58              13          3.6 
    #>  14 2025-09-18 07:12:54 2025-11-04           3.37              48          3.58
    #>  15 2025-09-18 07:12:54 2025-12-09           3.30              83          3.37
    #>  16 2025-09-18 07:12:54 2026-02-03           3.18             139          3.30
    #>  17 2025-09-18 07:12:54 2026-03-17           3.17             181          3.18
    #>  18 2025-09-18 07:12:54 2026-05-05           2.96             230          3.17
    #>  19 2025-09-18 07:12:54 2026-06-16           3.09             272          2.96
    #>  20 2025-09-18 07:12:54 2026-08-11           3.06             328          3.09
    #>  21 2025-09-18 07:12:54 2026-09-29           3.07             377          3.06
    #>  22 2025-09-18 07:12:54 2026-11-03           3.08             412          3.07
    #>  23 2025-09-18 07:12:54 2026-12-08           3.08             447          3.08
    #>  24 2025-09-18 23:19:47 2025-09-30           3.58              12          3.6 
    #>  25 2025-09-18 23:19:47 2025-11-04           3.38              47          3.58
    #>  26 2025-09-18 23:19:47 2025-12-09           3.32              82          3.38
    #>  27 2025-09-18 23:19:47 2026-02-03           3.17             138          3.32
    #>  28 2025-09-18 23:19:47 2026-03-17           3.18             180          3.17
    #>  29 2025-09-18 23:19:47 2026-05-05           2.96             229          3.18
    #>  30 2025-09-18 23:19:47 2026-06-16           3.09             271          2.96
    #>  31 2025-09-18 23:19:47 2026-08-11           3.06             327          3.09
    #>  32 2025-09-18 23:19:47 2026-09-29           3.07             376          3.06
    #>  33 2025-09-18 23:19:47 2026-11-03           3.08             411          3.07
    #>  34 2025-09-18 23:19:47 2026-12-08           3.08             446          3.08
    #>  35 2025-09-18 23:31:29 2025-09-30           3.58              12          3.6 
    #>  36 2025-09-18 23:31:29 2025-11-04           3.38              47          3.58
    #>  37 2025-09-18 23:31:29 2025-12-09           3.32              82          3.38
    #>  38 2025-09-18 23:31:29 2026-02-03           3.17             138          3.32
    #>  39 2025-09-18 23:31:29 2026-03-17           3.18             180          3.17
    #>  40 2025-09-18 23:31:29 2026-05-05           2.96             229          3.18
    #>  41 2025-09-18 23:31:29 2026-06-16           3.09             271          2.96
    #>  42 2025-09-18 23:31:29 2026-08-11           3.06             327          3.09
    #>  43 2025-09-18 23:31:29 2026-09-29           3.07             376          3.06
    #>  44 2025-09-18 23:31:29 2026-11-03           3.08             411          3.07
    #>  45 2025-09-18 23:31:29 2026-12-08           3.08             446          3.08
    #>  46 2025-09-18 23:42:54 2025-09-30           3.58              12          3.6 
    #>  47 2025-09-18 23:42:54 2025-11-04           3.38              47          3.58
    #>  48 2025-09-18 23:42:54 2025-12-09           3.32              82          3.38
    #>  49 2025-09-18 23:42:54 2026-02-03           3.17             138          3.32
    #>  50 2025-09-18 23:42:54 2026-03-17           3.18             180          3.17
    #>  51 2025-09-18 23:42:54 2026-05-05           2.96             229          3.18
    #>  52 2025-09-18 23:42:54 2026-06-16           3.09             271          2.96
    #>  53 2025-09-18 23:42:54 2026-08-11           3.06             327          3.09
    #>  54 2025-09-18 23:42:54 2026-09-29           3.07             376          3.06
    #>  55 2025-09-18 23:42:54 2026-11-03           3.08             411          3.07
    #>  56 2025-09-18 23:42:54 2026-12-08           3.08             446          3.08
    #>  57 2025-09-18 23:54:48 2025-09-30           3.58              12          3.6 
    #>  58 2025-09-18 23:54:48 2025-11-04           3.38              47          3.58
    #>  59 2025-09-18 23:54:48 2025-12-09           3.32              82          3.38
    #>  60 2025-09-18 23:54:48 2026-02-03           3.17             138          3.32
    #>  61 2025-09-18 23:54:48 2026-03-17           3.18             180          3.17
    #>  62 2025-09-18 23:54:48 2026-05-05           2.96             229          3.18
    #>  63 2025-09-18 23:54:48 2026-06-16           3.09             271          2.96
    #>  64 2025-09-18 23:54:48 2026-08-11           3.06             327          3.09
    #>  65 2025-09-18 23:54:48 2026-09-29           3.07             376          3.06
    #>  66 2025-09-18 23:54:48 2026-11-03           3.08             411          3.07
    #>  67 2025-09-18 23:54:48 2026-12-08           3.08             446          3.08
    #>  68 2025-09-19 01:19:35 2025-09-30           3.58              12          3.6 
    #>  69 2025-09-19 01:19:35 2025-11-04           3.38              47          3.58
    #>  70 2025-09-19 01:19:35 2025-12-09           3.32              82          3.38
    #>  71 2025-09-19 01:19:35 2026-02-03           3.17             138          3.32
    #>  72 2025-09-19 01:19:35 2026-03-17           3.18             180          3.17
    #>  73 2025-09-19 01:19:35 2026-05-05           2.96             229          3.18
    #>  74 2025-09-19 01:19:35 2026-06-16           3.09             271          2.96
    #>  75 2025-09-19 01:19:35 2026-08-11           3.06             327          3.09
    #>  76 2025-09-19 01:19:35 2026-09-29           3.07             376          3.06
    #>  77 2025-09-19 01:19:35 2026-11-03           3.08             411          3.07
    #>  78 2025-09-19 01:19:35 2026-12-08           3.08             446          3.08
    #>  79 2025-09-19 02:42:12 2025-09-30           3.58              12          3.6 
    #>  80 2025-09-19 02:42:12 2025-11-04           3.38              47          3.58
    #>  81 2025-09-19 02:42:12 2025-12-09           3.32              82          3.38
    #>  82 2025-09-19 02:42:12 2026-02-03           3.17             138          3.32
    #>  83 2025-09-19 02:42:12 2026-03-17           3.18             180          3.17
    #>  84 2025-09-19 02:42:12 2026-05-05           2.96             229          3.18
    #>  85 2025-09-19 02:42:12 2026-06-16           3.09             271          2.96
    #>  86 2025-09-19 02:42:12 2026-08-11           3.06             327          3.09
    #>  87 2025-09-19 02:42:12 2026-09-29           3.07             376          3.06
    #>  88 2025-09-19 02:42:12 2026-11-03           3.08             411          3.07
    #>  89 2025-09-19 02:42:12 2026-12-08           3.08             446          3.08
    #>  90 2025-09-19 03:25:19 2025-09-30           3.58              12          3.6 
    #>  91 2025-09-19 03:25:19 2025-11-04           3.38              47          3.58
    #>  92 2025-09-19 03:25:19 2025-12-09           3.32              82          3.38
    #>  93 2025-09-19 03:25:19 2026-02-03           3.17             138          3.32
    #>  94 2025-09-19 03:25:19 2026-03-17           3.18             180          3.17
    #>  95 2025-09-19 03:25:19 2026-05-05           2.96             229          3.18
    #>  96 2025-09-19 03:25:19 2026-06-16           3.09             271          2.96
    #>  97 2025-09-19 03:25:19 2026-08-11           3.06             327          3.09
    #>  98 2025-09-19 03:25:19 2026-09-29           3.07             376          3.06
    #>  99 2025-09-19 03:25:19 2026-11-03           3.08             411          3.07
    #> 100 2025-09-19 03:25:19 2026-12-08           3.08             446          3.08
    #>      stdev
    #>      <dbl>
    #>   1 1.26  
    #>   2 0.0639
    #>   3 0.188 
    #>   4 0.385 
    #>   5 0.498 
    #>   6 0.727 
    #>   7 0.846 
    #>   8 1.05  
    #>   9 1.06  
    #>  10 1.06  
    #>  11 1.15  
    #>  12 1.26  
    #>  13 0.0639
    #>  14 0.188 
    #>  15 0.385 
    #>  16 0.498 
    #>  17 0.727 
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
    #>  91 0.175 
    #>  92 0.384 
    #>  93 0.489 
    #>  94 0.725 
    #>  95 0.846 
    #>  96 1.05  
    #>  97 1.06  
    #>  98 1.06  
    #>  99 1.15  
    #> 100 1.26
    #> Warning: All formats failed to parse. No formats found.
    #> Warning: All formats failed to parse. No formats found.
    #> # A tibble: 20 × 11
    #>    scrape_time         meeting_date implied_mean stdev days_to_meeting bucket
    #>    <dttm>              <date>              <dbl> <dbl>           <int>  <dbl>
    #>  1 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   1.35
    #>  2 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   1.6 
    #>  3 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   1.85
    #>  4 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   2.1 
    #>  5 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   2.35
    #>  6 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   2.6 
    #>  7 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   2.85
    #>  8 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   3.1 
    #>  9 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   3.35
    #> 10 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   3.6 
    #> 11 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   3.85
    #> 12 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   4.1 
    #> 13 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   4.35
    #> 14 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   4.6 
    #> 15 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   4.85
    #> 16 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   5.1 
    #> 17 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   5.35
    #> 18 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   5.6 
    #> 19 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   5.85
    #> 20 2025-09-19 03:25:19 2026-12-08           3.08  1.26             446   6.1 
    #>    probability_linear probability_prob probability   diff diff_s
    #>                 <dbl>            <dbl>       <dbl>  <dbl>  <dbl>
    #>  1             0                0.0320      0.0320 -2.25  -1.22 
    #>  2             0                0.0412      0.0412 -2     -1.19 
    #>  3             0                0.0510      0.0510 -1.75  -1.15 
    #>  4             0                0.0607      0.0607 -1.5   -1.11 
    #>  5             0                0.0694      0.0694 -1.25  -1.06 
    #>  6             0                0.0763      0.0763 -1     -1    
    #>  7             0.0746           0.0807      0.0807 -0.75  -0.931
    #>  8             0.925            0.0820      0.0820 -0.5   -0.841
    #>  9             0                0.0802      0.0802 -0.25  -0.707
    #> 10             0                0.0754      0.0754  0      0    
    #> 11             0                0.0682      0.0682  0.25   0.707
    #> 12             0                0.0593      0.0593  0.500  0.841
    #> 13             0                0.0495      0.0495  0.750  0.931
    #> 14             0                0.0398      0.0398  1      1    
    #> 15             0                0.0308      0.0308  1.25   1.06 
    #> 16             0                0.0229      0.0229  1.5    1.11 
    #> 17             0                0.0163      0.0163  1.75   1.15 
    #> 18             0                0.0112      0.0112  2      1.19 
    #> 19             0                0           0       2.25   1.22 
    #> 20             0                0           0       2.5    1.26
    #> [1] "2025-09-30"
    #> Warning: Removed 66 rows containing missing values or values outside the scale range
    #> (`geom_vline()`).
    #> Creating extended buckets for 5770 estimate rows
    #> Bucket range: 0.1 to 6.1 
    #> Extended buckets created: 144250 rows
    #> Unique moves: 23 
    #> ✓ all_estimates_buckets_ext created successfully
    #> Future meetings found: 11 
    #> Meetings: 2025-09-30, 2025-11-04, 2025-12-09, 2026-02-03, 2026-03-17, 2026-05-05, 2026-06-16, 2026-08-11, 2026-09-29, 2026-11-03, 2026-12-08 
    #> Processing meeting: 20361 
    #> df_mt dimensions: 13025 x 3 
    #> Creating plot with 13025 data points
    #> Error creating plot for meeting 20361 : object 'fill_map' not found 
    #> Data summary:
    #>   scrape_time                            move       probability    
    #>  Min.   :2025-08-12 00:01:37   +300 bp hike: 521   Min.   :0.0000  
    #>  1st Qu.:2025-08-21 23:46:59   +275 bp hike: 521   1st Qu.:0.0000  
    #>  Median :2025-09-02 04:25:29   +250 bp hike: 521   Median :0.0000  
    #>  Mean   :2025-08-31 21:22:52   +225 bp hike: 521   Mean   :0.0400  
    #>  3rd Qu.:2025-09-10 04:58:13   +200 bp hike: 521   3rd Qu.:0.0000  
    #>  Max.   :2025-09-19 03:25:19   +175 bp hike: 521   Max.   :0.9216  
    #>                                (Other)     :9899                   
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
    #> df_mt dimensions: 13025 x 3 
    #> Creating plot with 13025 data points
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
    #> df_mt dimensions: 13025 x 3 
    #> Creating plot with 13025 data points
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
    #> df_mt dimensions: 13025 x 3 
    #> Creating plot with 13025 data points
    #> Saving to: docs/meetings/area_all_moves_2026-02-03.png
    #> Warning: Removed 1959 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20487 
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
    #> df_mt dimensions: 13025 x 3 
    #> Creating plot with 13025 data points
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
    #> df_mt dimensions: 13025 x 3 
    #> Creating plot with 13025 data points
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
    #> df_mt dimensions: 13025 x 3 
    #> Creating plot with 13025 data points
    #> Saving to: docs/meetings/area_all_moves_2026-06-16.png
    #> Warning: Removed 1533 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Error creating plot for meeting 20620 : Problem while converting geom to grob. 
    #> Data summary:
    #>   scrape_time                            move       probability     
    #>  Min.   :2025-08-12 00:01:37   +300 bp hike: 521   Min.   :0.00000  
    #>  1st Qu.:2025-08-21 23:46:59   +275 bp hike: 521   1st Qu.:0.00000  
    #>  Median :2025-09-02 04:25:29   +250 bp hike: 521   Median :0.03451  
    #>  Mean   :2025-08-31 21:22:52   +225 bp hike: 521   Mean   :0.04000  
    #>  3rd Qu.:2025-09-10 04:58:13   +200 bp hike: 521   3rd Qu.:0.07495  
    #>  Max.   :2025-09-19 03:25:19   +175 bp hike: 521   Max.   :0.09922  
    #>                                (Other)     :9899                    
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
    #> df_mt dimensions: 13025 x 3 
    #> Creating plot with 13025 data points
    #> Saving to: docs/meetings/area_all_moves_2026-08-11.png
    #> Warning: Removed 1571 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Error creating plot for meeting 20676 : Problem while converting geom to grob. 
    #> Data summary:
    #>   scrape_time                            move       probability     
    #>  Min.   :2025-08-12 00:01:37   +300 bp hike: 521   Min.   :0.00000  
    #>  1st Qu.:2025-08-21 23:46:59   +275 bp hike: 521   1st Qu.:0.00000  
    #>  Median :2025-09-02 04:25:29   +250 bp hike: 521   Median :0.03301  
    #>  Mean   :2025-08-31 21:22:52   +225 bp hike: 521   Mean   :0.04000  
    #>  3rd Qu.:2025-09-10 04:58:13   +200 bp hike: 521   3rd Qu.:0.07426  
    #>  Max.   :2025-09-19 03:25:19   +175 bp hike: 521   Max.   :0.09710  
    #>                                (Other)     :9899                    
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
    #> df_mt dimensions: 13025 x 3 
    #> Creating plot with 13025 data points
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
    #> df_mt dimensions: 13025 x 3 
    #> Creating plot with 13025 data points
    #> Saving to: docs/meetings/area_all_moves_2026-11-03.png
    #> Warning: Removed 1551 rows containing missing values or values outside the scale range
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
    #> df_mt dimensions: 13025 x 3 
    #> Creating plot with 13025 data points
    #> Saving to: docs/meetings/area_all_moves_2026-12-08.png
    #> Warning: Removed 1541 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Error creating plot for meeting 20795 : Problem while converting geom to grob. 
    #> Data summary:
    #>   scrape_time                            move       probability     
    #>  Min.   :2025-08-12 00:01:37   +300 bp hike: 521   Min.   :0.00000  
    #>  1st Qu.:2025-08-21 23:46:59   +275 bp hike: 521   1st Qu.:0.01541  
    #>  Median :2025-09-02 04:25:29   +250 bp hike: 521   Median :0.03909  
    #>  Mean   :2025-08-31 21:22:52   +225 bp hike: 521   Mean   :0.04000  
    #>  3rd Qu.:2025-09-10 04:58:13   +200 bp hike: 521   3rd Qu.:0.06790  
    #>  Max.   :2025-09-19 03:25:19   +175 bp hike: 521   Max.   :0.08273  
    #>                                (Other)     :9899                    
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
