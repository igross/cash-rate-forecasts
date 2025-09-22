
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
    #> [1] "2025-09-22 13:34:02 AEST"
    #> [1] "2025-09-22 14:30:00 AEST"
    #> Replacing 19 missing/invalid stdev(s) with max RMSE = 1.3813
    #> # A tibble: 100 × 6
    #>     scrape_time         meeting_date implied_mean days_to_meeting previous_rate
    #>     <dttm>              <date>              <dbl>           <int>         <dbl>
    #>   1 2025-09-19 06:39:53 2026-12-08           3.08             446          3.08
    #>   2 2025-09-19 06:54:51 2025-09-30           3.58              12          3.6 
    #>   3 2025-09-19 06:54:51 2025-11-04           3.39              47          3.58
    #>   4 2025-09-19 06:54:51 2025-12-09           3.31              82          3.39
    #>   5 2025-09-19 06:54:51 2026-02-03           3.18             138          3.31
    #>   6 2025-09-19 06:54:51 2026-03-17           3.17             180          3.18
    #>   7 2025-09-19 06:54:51 2026-05-05           2.96             229          3.17
    #>   8 2025-09-19 06:54:51 2026-06-16           3.09             271          2.96
    #>   9 2025-09-19 06:54:51 2026-08-11           3.11             327          3.09
    #>  10 2025-09-19 06:54:51 2026-09-29           3.11             376          3.11
    #>  11 2025-09-19 06:54:51 2026-11-03           3.12             411          3.11
    #>  12 2025-09-19 06:54:51 2026-12-08           3.12             446          3.12
    #>  13 2025-09-19 07:18:00 2025-09-30           3.58              12          3.6 
    #>  14 2025-09-19 07:18:00 2025-11-04           3.39              47          3.58
    #>  15 2025-09-19 07:18:00 2025-12-09           3.31              82          3.39
    #>  16 2025-09-19 07:18:00 2026-02-03           3.18             138          3.31
    #>  17 2025-09-19 07:18:00 2026-03-17           3.17             180          3.18
    #>  18 2025-09-19 07:18:00 2026-05-05           2.96             229          3.17
    #>  19 2025-09-19 07:18:00 2026-06-16           3.09             271          2.96
    #>  20 2025-09-19 07:18:00 2026-08-11           3.11             327          3.09
    #>  21 2025-09-19 07:18:00 2026-09-29           3.11             376          3.11
    #>  22 2025-09-19 07:18:00 2026-11-03           3.12             411          3.11
    #>  23 2025-09-19 07:18:00 2026-12-08           3.12             446          3.12
    #>  24 2025-09-21 23:19:18 2025-09-30           3.58               9          3.6 
    #>  25 2025-09-21 23:19:18 2025-11-04           3.39              44          3.58
    #>  26 2025-09-21 23:19:18 2025-12-09           3.31              79          3.39
    #>  27 2025-09-21 23:19:18 2026-02-03           3.18             135          3.31
    #>  28 2025-09-21 23:19:18 2026-03-17           3.17             177          3.18
    #>  29 2025-09-21 23:19:18 2026-05-05           2.96             226          3.17
    #>  30 2025-09-21 23:19:18 2026-06-16           3.09             268          2.96
    #>  31 2025-09-21 23:19:18 2026-08-11           3.11             324          3.09
    #>  32 2025-09-21 23:19:18 2026-09-29           3.11             373          3.11
    #>  33 2025-09-21 23:19:18 2026-11-03           3.12             408          3.11
    #>  34 2025-09-21 23:19:18 2026-12-08           3.12             443          3.12
    #>  35 2025-09-21 23:31:00 2025-09-30           3.58               9          3.6 
    #>  36 2025-09-21 23:31:00 2025-11-04           3.39              44          3.58
    #>  37 2025-09-21 23:31:00 2025-12-09           3.31              79          3.39
    #>  38 2025-09-21 23:31:00 2026-02-03           3.18             135          3.31
    #>  39 2025-09-21 23:31:00 2026-03-17           3.17             177          3.18
    #>  40 2025-09-21 23:31:00 2026-05-05           2.96             226          3.17
    #>  41 2025-09-21 23:31:00 2026-06-16           3.09             268          2.96
    #>  42 2025-09-21 23:31:00 2026-08-11           3.11             324          3.09
    #>  43 2025-09-21 23:31:00 2026-09-29           3.11             373          3.11
    #>  44 2025-09-21 23:31:00 2026-11-03           3.12             408          3.11
    #>  45 2025-09-21 23:31:00 2026-12-08           3.12             443          3.12
    #>  46 2025-09-21 23:42:44 2025-09-30           3.58               9          3.6 
    #>  47 2025-09-21 23:42:44 2025-11-04           3.39              44          3.58
    #>  48 2025-09-21 23:42:44 2025-12-09           3.31              79          3.39
    #>  49 2025-09-21 23:42:44 2026-02-03           3.18             135          3.31
    #>  50 2025-09-21 23:42:44 2026-03-17           3.17             177          3.18
    #>  51 2025-09-21 23:42:44 2026-05-05           2.96             226          3.17
    #>  52 2025-09-21 23:42:44 2026-06-16           3.09             268          2.96
    #>  53 2025-09-21 23:42:44 2026-08-11           3.11             324          3.09
    #>  54 2025-09-21 23:42:44 2026-09-29           3.11             373          3.11
    #>  55 2025-09-21 23:42:44 2026-11-03           3.12             408          3.11
    #>  56 2025-09-21 23:42:44 2026-12-08           3.12             443          3.12
    #>  57 2025-09-21 23:53:56 2025-09-30           3.58               9          3.6 
    #>  58 2025-09-21 23:53:56 2025-11-04           3.39              44          3.58
    #>  59 2025-09-21 23:53:56 2025-12-09           3.31              79          3.39
    #>  60 2025-09-21 23:53:56 2026-02-03           3.18             135          3.31
    #>  61 2025-09-21 23:53:56 2026-03-17           3.17             177          3.18
    #>  62 2025-09-21 23:53:56 2026-05-05           2.96             226          3.17
    #>  63 2025-09-21 23:53:56 2026-06-16           3.09             268          2.96
    #>  64 2025-09-21 23:53:56 2026-08-11           3.11             324          3.09
    #>  65 2025-09-21 23:53:56 2026-09-29           3.11             373          3.11
    #>  66 2025-09-21 23:53:56 2026-11-03           3.12             408          3.11
    #>  67 2025-09-21 23:53:56 2026-12-08           3.12             443          3.12
    #>  68 2025-09-22 01:16:41 2025-09-30           3.58               9          3.6 
    #>  69 2025-09-22 01:16:41 2025-11-04           3.39              44          3.58
    #>  70 2025-09-22 01:16:41 2025-12-09           3.31              79          3.39
    #>  71 2025-09-22 01:16:41 2026-02-03           3.18             135          3.31
    #>  72 2025-09-22 01:16:41 2026-03-17           3.17             177          3.18
    #>  73 2025-09-22 01:16:41 2026-05-05           2.96             226          3.17
    #>  74 2025-09-22 01:16:41 2026-06-16           3.09             268          2.96
    #>  75 2025-09-22 01:16:41 2026-08-11           3.11             324          3.09
    #>  76 2025-09-22 01:16:41 2026-09-29           3.11             373          3.11
    #>  77 2025-09-22 01:16:41 2026-11-03           3.12             408          3.11
    #>  78 2025-09-22 01:16:41 2026-12-08           3.12             443          3.12
    #>  79 2025-09-22 02:48:54 2025-09-30           3.58               9          3.6 
    #>  80 2025-09-22 02:48:54 2025-11-04           3.39              44          3.58
    #>  81 2025-09-22 02:48:54 2025-12-09           3.32              79          3.39
    #>  82 2025-09-22 02:48:54 2026-02-03           3.17             135          3.32
    #>  83 2025-09-22 02:48:54 2026-03-17           3.18             177          3.17
    #>  84 2025-09-22 02:48:54 2026-05-05           2.96             226          3.18
    #>  85 2025-09-22 02:48:54 2026-06-16           3.09             268          2.96
    #>  86 2025-09-22 02:48:54 2026-08-11           3.11             324          3.09
    #>  87 2025-09-22 02:48:54 2026-09-29           3.11             373          3.11
    #>  88 2025-09-22 02:48:54 2026-11-03           3.12             408          3.11
    #>  89 2025-09-22 02:48:54 2026-12-08           3.12             443          3.12
    #>  90 2025-09-22 03:32:36 2025-09-30           3.58               9          3.6 
    #>  91 2025-09-22 03:32:36 2025-11-04           3.39              44          3.58
    #>  92 2025-09-22 03:32:36 2025-12-09           3.32              79          3.39
    #>  93 2025-09-22 03:32:36 2026-02-03           3.17             135          3.32
    #>  94 2025-09-22 03:32:36 2026-03-17           3.18             177          3.17
    #>  95 2025-09-22 03:32:36 2026-05-05           2.96             226          3.18
    #>  96 2025-09-22 03:32:36 2026-06-16           3.09             268          2.96
    #>  97 2025-09-22 03:32:36 2026-08-11           3.11             324          3.09
    #>  98 2025-09-22 03:32:36 2026-09-29           3.11             373          3.11
    #>  99 2025-09-22 03:32:36 2026-11-03           3.12             408          3.11
    #> 100 2025-09-22 03:32:36 2026-12-08           3.12             443          3.12
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
    #>  25 0.158 
    #>  26 0.374 
    #>  27 0.468 
    #>  28 0.703 
    #>  29 0.846 
    #>  30 1.00  
    #>  31 1.06  
    #>  32 1.06  
    #>  33 1.13  
    #>  34 1.25  
    #>  35 0.0639
    #>  36 0.158 
    #>  37 0.374 
    #>  38 0.468 
    #>  39 0.703 
    #>  40 0.846 
    #>  41 1.00  
    #>  42 1.06  
    #>  43 1.06  
    #>  44 1.13  
    #>  45 1.25  
    #>  46 0.0639
    #>  47 0.158 
    #>  48 0.374 
    #>  49 0.468 
    #>  50 0.703 
    #>  51 0.846 
    #>  52 1.00  
    #>  53 1.06  
    #>  54 1.06  
    #>  55 1.13  
    #>  56 1.25  
    #>  57 0.0639
    #>  58 0.158 
    #>  59 0.374 
    #>  60 0.468 
    #>  61 0.703 
    #>  62 0.846 
    #>  63 1.00  
    #>  64 1.06  
    #>  65 1.06  
    #>  66 1.13  
    #>  67 1.25  
    #>  68 0.0639
    #>  69 0.158 
    #>  70 0.374 
    #>  71 0.468 
    #>  72 0.703 
    #>  73 0.846 
    #>  74 1.00  
    #>  75 1.06  
    #>  76 1.06  
    #>  77 1.13  
    #>  78 1.25  
    #>  79 0.0639
    #>  80 0.158 
    #>  81 0.374 
    #>  82 0.468 
    #>  83 0.703 
    #>  84 0.846 
    #>  85 1.00  
    #>  86 1.06  
    #>  87 1.06  
    #>  88 1.13  
    #>  89 1.25  
    #>  90 0.0639
    #>  91 0.158 
    #>  92 0.374 
    #>  93 0.468 
    #>  94 0.703 
    #>  95 0.846 
    #>  96 1.00  
    #>  97 1.06  
    #>  98 1.06  
    #>  99 1.13  
    #> 100 1.25
    #> Warning: All formats failed to parse. No formats found.
    #> Warning: All formats failed to parse. No formats found.
    #> # A tibble: 20 × 11
    #>    scrape_time         meeting_date implied_mean stdev days_to_meeting bucket
    #>    <dttm>              <date>              <dbl> <dbl>           <int>  <dbl>
    #>  1 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   1.35
    #>  2 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   1.6 
    #>  3 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   1.85
    #>  4 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   2.1 
    #>  5 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   2.35
    #>  6 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   2.6 
    #>  7 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   2.85
    #>  8 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   3.1 
    #>  9 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   3.35
    #> 10 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   3.6 
    #> 11 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   3.85
    #> 12 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   4.1 
    #> 13 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   4.35
    #> 14 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   4.6 
    #> 15 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   4.85
    #> 16 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   5.1 
    #> 17 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   5.35
    #> 18 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   5.6 
    #> 19 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   5.85
    #> 20 2025-09-22 03:32:36 2026-12-08           3.12  1.25             443   6.1 
    #>    probability_linear probability_prob probability   diff diff_s
    #>                 <dbl>            <dbl>       <dbl>  <dbl>  <dbl>
    #>  1             0                0.0304      0.0304 -2.25  -1.22 
    #>  2             0                0.0395      0.0395 -2     -1.19 
    #>  3             0                0.0493      0.0493 -1.75  -1.15 
    #>  4             0                0.0592      0.0592 -1.5   -1.11 
    #>  5             0                0.0683      0.0683 -1.25  -1.06 
    #>  6             0                0.0758      0.0758 -1     -1    
    #>  7             0                0.0807      0.0807 -0.75  -0.931
    #>  8             0.915            0.0826      0.0826 -0.5   -0.841
    #>  9             0.0854           0.0813      0.0813 -0.25  -0.707
    #> 10             0                0.0768      0.0768  0      0    
    #> 11             0                0.0697      0.0697  0.25   0.707
    #> 12             0                0.0609      0.0609  0.500  0.841
    #> 13             0                0.0510      0.0510  0.750  0.931
    #> 14             0                0.0411      0.0411  1      1    
    #> 15             0                0.0318      0.0318  1.25   1.06 
    #> 16             0                0.0237      0.0237  1.5    1.11 
    #> 17             0                0.0169      0.0169  1.75   1.15 
    #> 18             0                0.0116      0.0116  2      1.19 
    #> 19             0                0           0       2.25   1.22 
    #> 20             0                0           0       2.5    1.26
    #> [1] "2025-09-30"
    #> Warning: Removed 66 rows containing missing values or values outside the scale range
    #> (`geom_vline()`).
    #> Creating extended buckets for 5979 estimate rows
    #> Bucket range: 0.1 to 6.1 
    #> Extended buckets created: 149475 rows
    #> Unique moves: 23 
    #> ✓ all_estimates_buckets_ext created successfully
    #> Future meetings found: 11 
    #> Meetings: 2025-09-30, 2025-11-04, 2025-12-09, 2026-02-03, 2026-03-17, 2026-05-05, 2026-06-16, 2026-08-11, 2026-09-29, 2026-11-03, 2026-12-08 
    #> Processing meeting: 20361 
    #> df_mt dimensions: 13500 x 3 
    #> Creating plot with 13500 data points
    #> Error creating plot for meeting 20361 : object 'fill_map' not found 
    #> Data summary:
    #>   scrape_time                            move        probability    
    #>  Min.   :2025-08-12 00:01:37   +300 bp hike:  540   Min.   :0.0000  
    #>  1st Qu.:2025-08-22 03:59:10   +275 bp hike:  540   1st Qu.:0.0000  
    #>  Median :2025-09-02 23:25:14   +250 bp hike:  540   Median :0.0000  
    #>  Mean   :2025-09-01 13:44:23   +225 bp hike:  540   Mean   :0.0400  
    #>  3rd Qu.:2025-09-11 02:51:50   +200 bp hike:  540   3rd Qu.:0.0000  
    #>  Max.   :2025-09-22 03:32:36   +175 bp hike:  540   Max.   :0.9254  
    #>                                (Other)     :10260                   
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
    #> df_mt dimensions: 13500 x 3 
    #> Creating plot with 13500 data points
    #> Saving to: docs/meetings/area_all_moves_2025-11-04.png
    #> Warning: Removed 832 rows containing missing values or values outside the scale range
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
    #> df_mt dimensions: 13500 x 3 
    #> Creating plot with 13500 data points
    #> Saving to: docs/meetings/area_all_moves_2025-12-09.png
    #> Warning: Removed 1420 rows containing missing values or values outside the scale range
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
    #> df_mt dimensions: 13500 x 3 
    #> Creating plot with 13500 data points
    #> Saving to: docs/meetings/area_all_moves_2026-02-03.png
    #> Warning: Removed 2013 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Error creating plot for meeting 20487 : Problem while converting geom to grob. 
    #> Data summary:
    #>   scrape_time                            move        probability     
    #>  Min.   :2025-08-12 00:01:37   +300 bp hike:  540   Min.   :0.00000  
    #>  1st Qu.:2025-08-22 03:59:10   +275 bp hike:  540   1st Qu.:0.00000  
    #>  Median :2025-09-02 23:25:14   +250 bp hike:  540   Median :0.00000  
    #>  Mean   :2025-09-01 13:44:23   +225 bp hike:  540   Mean   :0.04000  
    #>  3rd Qu.:2025-09-11 02:51:50   +200 bp hike:  540   3rd Qu.:0.07649  
    #>  Max.   :2025-09-22 03:32:36   +175 bp hike:  540   Max.   :0.21160  
    #>                                (Other)     :10260                    
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
    #> df_mt dimensions: 13500 x 3 
    #> Creating plot with 13500 data points
    #> Saving to: docs/meetings/area_all_moves_2026-03-17.png
    #> Warning: Removed 1960 rows containing missing values or values outside the scale range
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
    #> df_mt dimensions: 13500 x 3 
    #> Creating plot with 13500 data points
    #> Saving to: docs/meetings/area_all_moves_2026-05-05.png
    #> Warning: Removed 1838 rows containing missing values or values outside the scale range
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
    #> df_mt dimensions: 13500 x 3 
    #> Creating plot with 13500 data points
    #> Saving to: docs/meetings/area_all_moves_2026-06-16.png
    #> Warning: Removed 1729 rows containing missing values or values outside the scale range
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
    #> df_mt dimensions: 13500 x 3 
    #> Creating plot with 13500 data points
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
    #> df_mt dimensions: 13500 x 3 
    #> Creating plot with 13500 data points
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
    #> df_mt dimensions: 13500 x 3 
    #> Creating plot with 13500 data points
    #> Saving to: docs/meetings/area_all_moves_2026-11-03.png
    #> Warning: Removed 1557 rows containing missing values or values outside the scale range
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
    #> df_mt dimensions: 13500 x 3 
    #> Creating plot with 13500 data points
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
