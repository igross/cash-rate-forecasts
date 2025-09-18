
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
    #> [1] "2025-09-18 13:01:04 AEST"
    #> [1] "2025-09-18 14:30:00 AEST"
    #> Replacing 19 missing/invalid stdev(s) with max RMSE = 1.3813
    #> # A tibble: 100 × 6
    #>     scrape_time         meeting_date implied_mean days_to_meeting previous_rate
    #>     <dttm>              <date>              <dbl>           <int>         <dbl>
    #>   1 2025-09-17 06:47:04 2026-12-08           3.13             448          3.12
    #>   2 2025-09-17 06:58:44 2025-09-30           3.57              14          3.6 
    #>   3 2025-09-17 06:58:44 2025-11-04           3.39              49          3.57
    #>   4 2025-09-17 06:58:44 2025-12-09           3.32              84          3.39
    #>   5 2025-09-17 06:58:44 2026-02-03           3.20             140          3.32
    #>   6 2025-09-17 06:58:44 2026-03-17           3.15             182          3.20
    #>   7 2025-09-17 06:58:44 2026-05-05           2.96             231          3.15
    #>   8 2025-09-17 06:58:44 2026-06-16           3.09             273          2.96
    #>   9 2025-09-17 06:58:44 2026-08-11           3.12             329          3.09
    #>  10 2025-09-17 06:58:44 2026-09-29           3.11             378          3.12
    #>  11 2025-09-17 06:58:44 2026-11-03           3.12             413          3.11
    #>  12 2025-09-17 06:58:44 2026-12-08           3.13             448          3.12
    #>  13 2025-09-17 23:19:17 2025-09-30           3.56              13          3.6 
    #>  14 2025-09-17 23:19:17 2025-11-04           3.39              48          3.56
    #>  15 2025-09-17 23:19:17 2025-12-09           3.31              83          3.39
    #>  16 2025-09-17 23:19:17 2026-02-03           3.20             139          3.31
    #>  17 2025-09-17 23:19:17 2026-03-17           3.15             181          3.20
    #>  18 2025-09-17 23:19:17 2026-05-05           2.96             230          3.15
    #>  19 2025-09-17 23:19:17 2026-06-16           3.09             272          2.96
    #>  20 2025-09-17 23:19:17 2026-08-11           3.12             328          3.09
    #>  21 2025-09-17 23:19:17 2026-09-29           3.11             377          3.12
    #>  22 2025-09-17 23:19:17 2026-11-03           3.12             412          3.11
    #>  23 2025-09-17 23:19:17 2026-12-08           3.13             447          3.12
    #>  24 2025-09-17 23:31:00 2025-09-30           3.56              13          3.6 
    #>  25 2025-09-17 23:31:00 2025-11-04           3.39              48          3.56
    #>  26 2025-09-17 23:31:00 2025-12-09           3.31              83          3.39
    #>  27 2025-09-17 23:31:00 2026-02-03           3.20             139          3.31
    #>  28 2025-09-17 23:31:00 2026-03-17           3.15             181          3.20
    #>  29 2025-09-17 23:31:00 2026-05-05           2.96             230          3.15
    #>  30 2025-09-17 23:31:00 2026-06-16           3.09             272          2.96
    #>  31 2025-09-17 23:31:00 2026-08-11           3.12             328          3.09
    #>  32 2025-09-17 23:31:00 2026-09-29           3.11             377          3.12
    #>  33 2025-09-17 23:31:00 2026-11-03           3.12             412          3.11
    #>  34 2025-09-17 23:31:00 2026-12-08           3.13             447          3.12
    #>  35 2025-09-17 23:42:03 2025-09-30           3.56              13          3.6 
    #>  36 2025-09-17 23:42:03 2025-11-04           3.39              48          3.56
    #>  37 2025-09-17 23:42:03 2025-12-09           3.31              83          3.39
    #>  38 2025-09-17 23:42:03 2026-02-03           3.20             139          3.31
    #>  39 2025-09-17 23:42:03 2026-03-17           3.15             181          3.20
    #>  40 2025-09-17 23:42:03 2026-05-05           2.96             230          3.15
    #>  41 2025-09-17 23:42:03 2026-06-16           3.09             272          2.96
    #>  42 2025-09-17 23:42:03 2026-08-11           3.12             328          3.09
    #>  43 2025-09-17 23:42:03 2026-09-29           3.11             377          3.12
    #>  44 2025-09-17 23:42:03 2026-11-03           3.12             412          3.11
    #>  45 2025-09-17 23:42:03 2026-12-08           3.13             447          3.12
    #>  46 2025-09-17 23:53:38 2025-09-30           3.56              13          3.6 
    #>  47 2025-09-17 23:53:38 2025-11-04           3.39              48          3.56
    #>  48 2025-09-17 23:53:38 2025-12-09           3.31              83          3.39
    #>  49 2025-09-17 23:53:38 2026-02-03           3.20             139          3.31
    #>  50 2025-09-17 23:53:38 2026-03-17           3.15             181          3.20
    #>  51 2025-09-17 23:53:38 2026-05-05           2.96             230          3.15
    #>  52 2025-09-17 23:53:38 2026-06-16           3.09             272          2.96
    #>  53 2025-09-17 23:53:38 2026-08-11           3.12             328          3.09
    #>  54 2025-09-17 23:53:38 2026-09-29           3.11             377          3.12
    #>  55 2025-09-17 23:53:38 2026-11-03           3.12             412          3.11
    #>  56 2025-09-17 23:53:38 2026-12-08           3.13             447          3.12
    #>  57 2025-09-18 01:05:11 2025-09-30           3.56              13          3.6 
    #>  58 2025-09-18 01:05:11 2025-11-04           3.38              48          3.56
    #>  59 2025-09-18 01:05:11 2025-12-09           3.31              83          3.38
    #>  60 2025-09-18 01:05:11 2026-02-03           3.20             139          3.31
    #>  61 2025-09-18 01:05:11 2026-03-17           3.15             181          3.20
    #>  62 2025-09-18 01:05:11 2026-05-05           2.96             230          3.15
    #>  63 2025-09-18 01:05:11 2026-06-16           3.09             272          2.96
    #>  64 2025-09-18 01:05:11 2026-08-11           3.12             328          3.09
    #>  65 2025-09-18 01:05:11 2026-09-29           3.11             377          3.12
    #>  66 2025-09-18 01:05:11 2026-11-03           3.12             412          3.11
    #>  67 2025-09-18 01:05:11 2026-12-08           3.13             447          3.12
    #>  68 2025-09-18 02:10:12 2025-09-30           3.58              13          3.6 
    #>  69 2025-09-18 02:10:12 2025-11-04           3.36              48          3.58
    #>  70 2025-09-18 02:10:12 2025-12-09           3.32              83          3.36
    #>  71 2025-09-18 02:10:12 2026-02-03           3.20             139          3.32
    #>  72 2025-09-18 02:10:12 2026-03-17           3.15             181          3.20
    #>  73 2025-09-18 02:10:12 2026-05-05           2.96             230          3.15
    #>  74 2025-09-18 02:10:12 2026-06-16           3.09             272          2.96
    #>  75 2025-09-18 02:10:12 2026-08-11           3.12             328          3.09
    #>  76 2025-09-18 02:10:12 2026-09-29           3.11             377          3.12
    #>  77 2025-09-18 02:10:12 2026-11-03           3.12             412          3.11
    #>  78 2025-09-18 02:10:12 2026-12-08           3.13             447          3.12
    #>  79 2025-09-18 02:36:20 2025-09-30           3.58              13          3.6 
    #>  80 2025-09-18 02:36:20 2025-11-04           3.36              48          3.58
    #>  81 2025-09-18 02:36:20 2025-12-09           3.32              83          3.36
    #>  82 2025-09-18 02:36:20 2026-02-03           3.17             139          3.32
    #>  83 2025-09-18 02:36:20 2026-03-17           3.18             181          3.17
    #>  84 2025-09-18 02:36:20 2026-05-05           2.96             230          3.18
    #>  85 2025-09-18 02:36:20 2026-06-16           3.09             272          2.96
    #>  86 2025-09-18 02:36:20 2026-08-11           3.12             328          3.09
    #>  87 2025-09-18 02:36:20 2026-09-29           3.11             377          3.12
    #>  88 2025-09-18 02:36:20 2026-11-03           3.12             412          3.11
    #>  89 2025-09-18 02:36:20 2026-12-08           3.13             447          3.12
    #>  90 2025-09-18 03:00:04 2025-09-30           3.58              13          3.6 
    #>  91 2025-09-18 03:00:04 2025-11-04           3.36              48          3.58
    #>  92 2025-09-18 03:00:04 2025-12-09           3.32              83          3.36
    #>  93 2025-09-18 03:00:04 2026-02-03           3.17             139          3.32
    #>  94 2025-09-18 03:00:04 2026-03-17           3.18             181          3.17
    #>  95 2025-09-18 03:00:04 2026-05-05           2.96             230          3.18
    #>  96 2025-09-18 03:00:04 2026-06-16           3.09             272          2.96
    #>  97 2025-09-18 03:00:04 2026-08-11           3.12             328          3.09
    #>  98 2025-09-18 03:00:04 2026-09-29           3.11             377          3.12
    #>  99 2025-09-18 03:00:04 2026-11-03           3.12             412          3.11
    #> 100 2025-09-18 03:00:04 2026-12-08           3.13             447          3.12
    #>      stdev
    #>      <dbl>
    #>   1 1.26  
    #>   2 0.0639
    #>   3 0.206 
    #>   4 0.387 
    #>   5 0.507 
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
    #>  25 0.188 
    #>  26 0.385 
    #>  27 0.498 
    #>  28 0.727 
    #>  29 0.846 
    #>  30 1.05  
    #>  31 1.06  
    #>  32 1.06  
    #>  33 1.15  
    #>  34 1.26  
    #>  35 0.0639
    #>  36 0.188 
    #>  37 0.385 
    #>  38 0.498 
    #>  39 0.727 
    #>  40 0.846 
    #>  41 1.05  
    #>  42 1.06  
    #>  43 1.06  
    #>  44 1.15  
    #>  45 1.26  
    #>  46 0.0639
    #>  47 0.188 
    #>  48 0.385 
    #>  49 0.498 
    #>  50 0.727 
    #>  51 0.846 
    #>  52 1.05  
    #>  53 1.06  
    #>  54 1.06  
    #>  55 1.15  
    #>  56 1.26  
    #>  57 0.0639
    #>  58 0.188 
    #>  59 0.385 
    #>  60 0.498 
    #>  61 0.727 
    #>  62 0.846 
    #>  63 1.05  
    #>  64 1.06  
    #>  65 1.06  
    #>  66 1.15  
    #>  67 1.26  
    #>  68 0.0639
    #>  69 0.188 
    #>  70 0.385 
    #>  71 0.498 
    #>  72 0.727 
    #>  73 0.846 
    #>  74 1.05  
    #>  75 1.06  
    #>  76 1.06  
    #>  77 1.15  
    #>  78 1.26  
    #>  79 0.0639
    #>  80 0.188 
    #>  81 0.385 
    #>  82 0.498 
    #>  83 0.727 
    #>  84 0.846 
    #>  85 1.05  
    #>  86 1.06  
    #>  87 1.06  
    #>  88 1.15  
    #>  89 1.26  
    #>  90 0.0639
    #>  91 0.188 
    #>  92 0.385 
    #>  93 0.498 
    #>  94 0.727 
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
    #>  1 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   1.35
    #>  2 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   1.6 
    #>  3 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   1.85
    #>  4 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   2.1 
    #>  5 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   2.35
    #>  6 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   2.6 
    #>  7 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   2.85
    #>  8 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   3.1 
    #>  9 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   3.35
    #> 10 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   3.6 
    #> 11 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   3.85
    #> 12 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   4.1 
    #> 13 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   4.35
    #> 14 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   4.6 
    #> 15 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   4.85
    #> 16 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   5.1 
    #> 17 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   5.35
    #> 18 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   5.6 
    #> 19 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   5.85
    #> 20 2025-09-18 03:00:04 2026-12-08           3.13  1.26             447   6.1 
    #>    probability_linear probability_prob probability   diff diff_s
    #>                 <dbl>            <dbl>       <dbl>  <dbl>  <dbl>
    #>  1              0               0.0305      0.0305 -2.25  -1.22 
    #>  2              0               0.0395      0.0395 -2     -1.19 
    #>  3              0               0.0492      0.0492 -1.75  -1.15 
    #>  4              0               0.0589      0.0589 -1.5   -1.11 
    #>  5              0               0.0679      0.0679 -1.25  -1.06 
    #>  6              0               0.0752      0.0752 -1     -1    
    #>  7              0               0.0801      0.0801 -0.75  -0.931
    #>  8              0.889           0.0820      0.0820 -0.5   -0.841
    #>  9              0.111           0.0808      0.0808 -0.25  -0.707
    #> 10              0               0.0765      0.0765  0      0    
    #> 11              0               0.0697      0.0697  0.25   0.707
    #> 12              0               0.0610      0.0610  0.500  0.841
    #> 13              0               0.0514      0.0514  0.750  0.931
    #> 14              0               0.0416      0.0416  1      1    
    #> 15              0               0.0324      0.0324  1.25   1.06 
    #> 16              0               0.0242      0.0242  1.5    1.11 
    #> 17              0               0.0174      0.0174  1.75   1.15 
    #> 18              0               0.0121      0.0121  2      1.19 
    #> 19              0               0           0       2.25   1.22 
    #> 20              0               0           0       2.5    1.26
    #> [1] "2025-09-30"
    #> Warning: Removed 66 rows containing missing values or values outside the scale range
    #> (`geom_vline()`).
    #> Creating extended buckets for 5506 estimate rows
    #> Bucket range: 0.5 to 6.5 
    #> Extended buckets created: 137650 rows
    #> Unique moves: 25 
    #> ✓ all_estimates_buckets_ext created successfully
    #> Future meetings found: 11 
    #> Meetings: 2025-09-30, 2025-11-04, 2025-12-09, 2026-02-03, 2026-03-17, 2026-05-05, 2026-06-16, 2026-08-11, 2026-09-29, 2026-11-03, 2026-12-08 
    #> Processing meeting: 20361 
    #> df_mt dimensions: 12425 x 3 
    #> Creating plot with 12425 data points
    #> Error creating plot for meeting 20361 : object 'fill_map' not found 
    #> Data summary:
    #>   scrape_time                            move       probability    
    #>  Min.   :2025-08-12 00:01:37   +300 bp hike: 497   Min.   :0.0000  
    #>  1st Qu.:2025-08-21 05:46:12   +275 bp hike: 497   1st Qu.:0.0000  
    #>  Median :2025-09-01 05:50:03   +250 bp hike: 497   Median :0.0000  
    #>  Mean   :2025-08-31 01:01:30   +225 bp hike: 497   Mean   :0.0400  
    #>  3rd Qu.:2025-09-09 10:50:46   +200 bp hike: 497   3rd Qu.:0.0000  
    #>  Max.   :2025-09-18 03:00:04   +175 bp hike: 497   Max.   :0.8036  
    #>                                (Other)     :9443                   
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
    #> First 20 unique bucket rates: 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.25, 4.5, 4.75, 5, 5.25 
    #> Decimal endings (should be 10, 35, 60, 85): 50, 75, 0, 25 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20396 
    #> df_mt dimensions: 12425 x 3 
    #> Creating plot with 12425 data points
    #> Saving to: docs/meetings/area_all_moves_2025-11-04.png
    #> Warning: Removed 1311 rows containing missing values or values outside the scale range
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
    #> First 20 unique bucket rates: 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.25, 4.5, 4.75, 5, 5.25 
    #> Decimal endings (should be 10, 35, 60, 85): 50, 75, 0, 25 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20431 
    #> df_mt dimensions: 12425 x 3 
    #> Creating plot with 12425 data points
    #> Saving to: docs/meetings/area_all_moves_2025-12-09.png
    #> Warning: Removed 1566 rows containing missing values or values outside the scale range
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
    #> First 20 unique bucket rates: 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.25, 4.5, 4.75, 5, 5.25 
    #> Decimal endings (should be 10, 35, 60, 85): 50, 75, 0, 25 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20487 
    #> df_mt dimensions: 12425 x 3 
    #> Creating plot with 12425 data points
    #> Saving to: docs/meetings/area_all_moves_2026-02-03.png
    #> Warning: Removed 2096 rows containing missing values or values outside the scale range
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
    #> First 20 unique bucket rates: 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.25, 4.5, 4.75, 5, 5.25 
    #> Decimal endings (should be 10, 35, 60, 85): 50, 75, 0, 25 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20529 
    #> df_mt dimensions: 12425 x 3 
    #> Creating plot with 12425 data points
    #> Saving to: docs/meetings/area_all_moves_2026-03-17.png
    #> Warning: Removed 1738 rows containing missing values or values outside the scale range
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
    #> First 20 unique bucket rates: 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.25, 4.5, 4.75, 5, 5.25 
    #> Decimal endings (should be 10, 35, 60, 85): 50, 75, 0, 25 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20578 
    #> df_mt dimensions: 12425 x 3 
    #> Creating plot with 12425 data points
    #> Saving to: docs/meetings/area_all_moves_2026-05-05.png
    #> Warning: Removed 1712 rows containing missing values or values outside the scale range
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
    #> First 20 unique bucket rates: 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.25, 4.5, 4.75, 5, 5.25 
    #> Decimal endings (should be 10, 35, 60, 85): 50, 75, 0, 25 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20620 
    #> df_mt dimensions: 12425 x 3 
    #> Creating plot with 12425 data points
    #> Saving to: docs/meetings/area_all_moves_2026-06-16.png
    #> Warning: Removed 1831 rows containing missing values or values outside the scale range
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
    #> First 20 unique bucket rates: 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.25, 4.5, 4.75, 5, 5.25 
    #> Decimal endings (should be 10, 35, 60, 85): 50, 75, 0, 25 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20676 
    #> df_mt dimensions: 12425 x 3 
    #> Creating plot with 12425 data points
    #> Saving to: docs/meetings/area_all_moves_2026-08-11.png
    #> Warning: Removed 1995 rows containing missing values or values outside the scale range
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
    #> First 20 unique bucket rates: 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.25, 4.5, 4.75, 5, 5.25 
    #> Decimal endings (should be 10, 35, 60, 85): 50, 75, 0, 25 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20725 
    #> df_mt dimensions: 12425 x 3 
    #> Creating plot with 12425 data points
    #> Saving to: docs/meetings/area_all_moves_2026-09-29.png
    #> Warning: Removed 697 rows containing missing values or values outside the scale range
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
    #> First 20 unique bucket rates: 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.25, 4.5, 4.75, 5, 5.25 
    #> Decimal endings (should be 10, 35, 60, 85): 50, 75, 0, 25 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20760 
    #> df_mt dimensions: 12425 x 3 
    #> Creating plot with 12425 data points
    #> Saving to: docs/meetings/area_all_moves_2026-11-03.png
    #> Warning: Removed 1565 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Error creating plot for meeting 20760 : Problem while converting geom to grob. 
    #> Data summary:
    #>   scrape_time                            move       probability     
    #>  Min.   :2025-08-12 00:01:37   +300 bp hike: 497   Min.   :0.00000  
    #>  1st Qu.:2025-08-21 05:46:12   +275 bp hike: 497   1st Qu.:0.01272  
    #>  Median :2025-09-01 05:50:03   +250 bp hike: 497   Median :0.03777  
    #>  Mean   :2025-08-31 01:01:30   +225 bp hike: 497   Mean   :0.04000  
    #>  3rd Qu.:2025-09-09 10:50:46   +200 bp hike: 497   3rd Qu.:0.06847  
    #>  Max.   :2025-09-18 03:00:04   +175 bp hike: 497   Max.   :0.08856  
    #>                                (Other)     :9443                    
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
    #> First 20 unique bucket rates: 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.25, 4.5, 4.75, 5, 5.25 
    #> Decimal endings (should be 10, 35, 60, 85): 50, 75, 0, 25 
    #> CSV export completed with corrected bucket_rate values
    #> Processing meeting: 20795 
    #> df_mt dimensions: 12425 x 3 
    #> Creating plot with 12425 data points
    #> Saving to: docs/meetings/area_all_moves_2026-12-08.png
    #> Warning: Removed 1125 rows containing missing values or values outside the scale range
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
    #> First 20 unique bucket rates: 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3, 3.25, 3.5, 3.75, 4, 4.25, 4.5, 4.75, 5, 5.25 
    #> Decimal endings (should be 10, 35, 60, 85): 50, 75, 0, 25 
    #> CSV export completed with corrected bucket_rate values
