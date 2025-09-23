
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
    #> [1] "2025-09-24 09:44:07 AEST"
    #> [1] "2025-09-23 14:30:00 AEST"
    #> Replacing 19 missing/invalid stdev(s) with max RMSE = 1.3813
    #> # A tibble: 100 × 6
    #>     scrape_time         meeting_date implied_mean days_to_meeting previous_rate
    #>     <dttm>              <date>              <dbl>           <int>         <dbl>
    #>   1 2025-09-23 05:19:59 2026-12-08           3.14             442          3.14
    #>   2 2025-09-23 05:37:39 2025-09-30           3.58               8          3.6 
    #>   3 2025-09-23 05:37:39 2025-11-04           3.41              43          3.58
    #>   4 2025-09-23 05:37:39 2025-12-09           3.34              78          3.41
    #>   5 2025-09-23 05:37:39 2026-02-03           3.17             134          3.34
    #>   6 2025-09-23 05:37:39 2026-03-17           3.18             176          3.17
    #>   7 2025-09-23 05:37:39 2026-05-05           2.96             225          3.18
    #>   8 2025-09-23 05:37:39 2026-06-16           3.09             267          2.96
    #>   9 2025-09-23 05:37:39 2026-08-11           3.14             323          3.09
    #>  10 2025-09-23 05:37:39 2026-09-29           3.13             372          3.14
    #>  11 2025-09-23 05:37:39 2026-11-03           3.14             407          3.13
    #>  12 2025-09-23 05:37:39 2026-12-08           3.14             442          3.14
    #>  13 2025-09-23 05:49:40 2025-09-30           3.58               8          3.6 
    #>  14 2025-09-23 05:49:40 2025-11-04           3.41              43          3.58
    #>  15 2025-09-23 05:49:40 2025-12-09           3.34              78          3.41
    #>  16 2025-09-23 05:49:40 2026-02-03           3.17             134          3.34
    #>  17 2025-09-23 05:49:40 2026-03-17           3.18             176          3.17
    #>  18 2025-09-23 05:49:40 2026-05-05           2.96             225          3.18
    #>  19 2025-09-23 05:49:40 2026-06-16           3.09             267          2.96
    #>  20 2025-09-23 05:49:40 2026-08-11           3.14             323          3.09
    #>  21 2025-09-23 05:49:40 2026-09-29           3.13             372          3.14
    #>  22 2025-09-23 05:49:40 2026-11-03           3.14             407          3.13
    #>  23 2025-09-23 05:49:40 2026-12-08           3.14             442          3.14
    #>  24 2025-09-23 06:00:13 2025-09-30           3.58               8          3.6 
    #>  25 2025-09-23 06:00:13 2025-11-04           3.41              43          3.58
    #>  26 2025-09-23 06:00:13 2025-12-09           3.34              78          3.41
    #>  27 2025-09-23 06:00:13 2026-02-03           3.17             134          3.34
    #>  28 2025-09-23 06:00:13 2026-03-17           3.18             176          3.17
    #>  29 2025-09-23 06:00:13 2026-05-05           2.96             225          3.18
    #>  30 2025-09-23 06:00:13 2026-06-16           3.09             267          2.96
    #>  31 2025-09-23 06:00:13 2026-08-11           3.14             323          3.09
    #>  32 2025-09-23 06:00:13 2026-09-29           3.13             372          3.14
    #>  33 2025-09-23 06:00:13 2026-11-03           3.14             407          3.13
    #>  34 2025-09-23 06:00:13 2026-12-08           3.14             442          3.14
    #>  35 2025-09-23 06:40:01 2025-09-30           3.58               8          3.6 
    #>  36 2025-09-23 06:40:01 2025-11-04           3.41              43          3.58
    #>  37 2025-09-23 06:40:01 2025-12-09           3.35              78          3.41
    #>  38 2025-09-23 06:40:01 2026-02-03           3.17             134          3.35
    #>  39 2025-09-23 06:40:01 2026-03-17           3.18             176          3.17
    #>  40 2025-09-23 06:40:01 2026-05-05           2.96             225          3.18
    #>  41 2025-09-23 06:40:01 2026-06-16           3.09             267          2.96
    #>  42 2025-09-23 06:40:01 2026-08-11           3.14             323          3.09
    #>  43 2025-09-23 06:40:01 2026-09-29           3.13             372          3.14
    #>  44 2025-09-23 06:40:01 2026-11-03           3.14             407          3.13
    #>  45 2025-09-23 06:40:01 2026-12-08           3.14             442          3.14
    #>  46 2025-09-23 06:55:21 2025-09-30           3.58               8          3.6 
    #>  47 2025-09-23 06:55:21 2025-11-04           3.41              43          3.58
    #>  48 2025-09-23 06:55:21 2025-12-09           3.35              78          3.41
    #>  49 2025-09-23 06:55:21 2026-02-03           3.17             134          3.35
    #>  50 2025-09-23 06:55:21 2026-03-17           3.18             176          3.17
    #>  51 2025-09-23 06:55:21 2026-05-05           2.96             225          3.18
    #>  52 2025-09-23 06:55:21 2026-06-16           3.09             267          2.96
    #>  53 2025-09-23 06:55:21 2026-08-11           3.14             323          3.09
    #>  54 2025-09-23 06:55:21 2026-09-29           3.13             372          3.14
    #>  55 2025-09-23 06:55:21 2026-11-03           3.14             407          3.13
    #>  56 2025-09-23 06:55:21 2026-12-08           3.15             442          3.14
    #>  57 2025-09-23 07:19:57 2025-09-30           3.58               8          3.6 
    #>  58 2025-09-23 07:19:57 2025-11-04           3.41              43          3.58
    #>  59 2025-09-23 07:19:57 2025-12-09           3.35              78          3.41
    #>  60 2025-09-23 07:19:57 2026-02-03           3.17             134          3.35
    #>  61 2025-09-23 07:19:57 2026-03-17           3.18             176          3.17
    #>  62 2025-09-23 07:19:57 2026-05-05           2.96             225          3.18
    #>  63 2025-09-23 07:19:57 2026-06-16           3.09             267          2.96
    #>  64 2025-09-23 07:19:57 2026-08-11           3.14             323          3.09
    #>  65 2025-09-23 07:19:57 2026-09-29           3.13             372          3.14
    #>  66 2025-09-23 07:19:57 2026-11-03           3.14             407          3.13
    #>  67 2025-09-23 07:19:57 2026-12-08           3.15             442          3.14
    #>  68 2025-09-23 23:19:48 2025-09-30           3.58               7          3.6 
    #>  69 2025-09-23 23:19:48 2025-11-04           3.41              42          3.58
    #>  70 2025-09-23 23:19:48 2025-12-09           3.35              77          3.41
    #>  71 2025-09-23 23:19:48 2026-02-03           3.17             133          3.35
    #>  72 2025-09-23 23:19:48 2026-03-17           3.18             175          3.17
    #>  73 2025-09-23 23:19:48 2026-05-05           2.96             224          3.18
    #>  74 2025-09-23 23:19:48 2026-06-16           3.09             266          2.96
    #>  75 2025-09-23 23:19:48 2026-08-11           3.14             322          3.09
    #>  76 2025-09-23 23:19:48 2026-09-29           3.13             371          3.14
    #>  77 2025-09-23 23:19:48 2026-11-03           3.14             406          3.13
    #>  78 2025-09-23 23:19:48 2026-12-08           3.15             441          3.14
    #>  79 2025-09-23 23:31:03 2025-09-30           3.58               7          3.6 
    #>  80 2025-09-23 23:31:03 2025-11-04           3.41              42          3.58
    #>  81 2025-09-23 23:31:03 2025-12-09           3.35              77          3.41
    #>  82 2025-09-23 23:31:03 2026-02-03           3.17             133          3.35
    #>  83 2025-09-23 23:31:03 2026-03-17           3.18             175          3.17
    #>  84 2025-09-23 23:31:03 2026-05-05           2.96             224          3.18
    #>  85 2025-09-23 23:31:03 2026-06-16           3.09             266          2.96
    #>  86 2025-09-23 23:31:03 2026-08-11           3.14             322          3.09
    #>  87 2025-09-23 23:31:03 2026-09-29           3.13             371          3.14
    #>  88 2025-09-23 23:31:03 2026-11-03           3.14             406          3.13
    #>  89 2025-09-23 23:31:03 2026-12-08           3.15             441          3.14
    #>  90 2025-09-23 23:42:47 2025-09-30           3.58               7          3.6 
    #>  91 2025-09-23 23:42:47 2025-11-04           3.41              42          3.58
    #>  92 2025-09-23 23:42:47 2025-12-09           3.35              77          3.41
    #>  93 2025-09-23 23:42:47 2026-02-03           3.17             133          3.35
    #>  94 2025-09-23 23:42:47 2026-03-17           3.18             175          3.17
    #>  95 2025-09-23 23:42:47 2026-05-05           2.96             224          3.18
    #>  96 2025-09-23 23:42:47 2026-06-16           3.09             266          2.96
    #>  97 2025-09-23 23:42:47 2026-08-11           3.14             322          3.09
    #>  98 2025-09-23 23:42:47 2026-09-29           3.13             371          3.14
    #>  99 2025-09-23 23:42:47 2026-11-03           3.14             406          3.13
    #> 100 2025-09-23 23:42:47 2026-12-08           3.15             441          3.14
    #>      stdev
    #>      <dbl>
    #>   1 1.25  
    #>   2 0.0639
    #>   3 0.156 
    #>   4 0.368 
    #>   5 0.468 
    #>   6 0.703 
    #>   7 0.846 
    #>   8 0.999 
    #>   9 1.06  
    #>  10 1.06  
    #>  11 1.13  
    #>  12 1.25  
    #>  13 0.0639
    #>  14 0.156 
    #>  15 0.368 
    #>  16 0.468 
    #>  17 0.703 
    #>  18 0.846 
    #>  19 0.999 
    #>  20 1.06  
    #>  21 1.06  
    #>  22 1.13  
    #>  23 1.25  
    #>  24 0.0639
    #>  25 0.156 
    #>  26 0.368 
    #>  27 0.468 
    #>  28 0.703 
    #>  29 0.846 
    #>  30 0.999 
    #>  31 1.06  
    #>  32 1.06  
    #>  33 1.13  
    #>  34 1.25  
    #>  35 0.0639
    #>  36 0.156 
    #>  37 0.368 
    #>  38 0.468 
    #>  39 0.703 
    #>  40 0.846 
    #>  41 0.999 
    #>  42 1.06  
    #>  43 1.06  
    #>  44 1.13  
    #>  45 1.25  
    #>  46 0.0639
    #>  47 0.156 
    #>  48 0.368 
    #>  49 0.468 
    #>  50 0.703 
    #>  51 0.846 
    #>  52 0.999 
    #>  53 1.06  
    #>  54 1.06  
    #>  55 1.13  
    #>  56 1.25  
    #>  57 0.0639
    #>  58 0.156 
    #>  59 0.368 
    #>  60 0.468 
    #>  61 0.703 
    #>  62 0.846 
    #>  63 0.999 
    #>  64 1.06  
    #>  65 1.06  
    #>  66 1.13  
    #>  67 1.25  
    #>  68 0.0639
    #>  69 0.154 
    #>  70 0.366 
    #>  71 0.462 
    #>  72 0.697 
    #>  73 0.846 
    #>  74 0.996 
    #>  75 1.06  
    #>  76 1.06  
    #>  77 1.13  
    #>  78 1.25  
    #>  79 0.0639
    #>  80 0.154 
    #>  81 0.366 
    #>  82 0.462 
    #>  83 0.697 
    #>  84 0.846 
    #>  85 0.996 
    #>  86 1.06  
    #>  87 1.06  
    #>  88 1.13  
    #>  89 1.25  
    #>  90 0.0639
    #>  91 0.154 
    #>  92 0.366 
    #>  93 0.462 
    #>  94 0.697 
    #>  95 0.846 
    #>  96 0.996 
    #>  97 1.06  
    #>  98 1.06  
    #>  99 1.13  
    #> 100 1.25
    #> Warning: All formats failed to parse. No formats found.
    #> Warning: All formats failed to parse. No formats found.
    #> # A tibble: 20 × 11
    #>    scrape_time         meeting_date implied_mean stdev days_to_meeting bucket
    #>    <dttm>              <date>              <dbl> <dbl>           <int>  <dbl>
    #>  1 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   1.35
    #>  2 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   1.6 
    #>  3 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   1.85
    #>  4 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   2.1 
    #>  5 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   2.35
    #>  6 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   2.6 
    #>  7 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   2.85
    #>  8 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   3.1 
    #>  9 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   3.35
    #> 10 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   3.6 
    #> 11 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   3.85
    #> 12 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   4.1 
    #> 13 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   4.35
    #> 14 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   4.6 
    #> 15 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   4.85
    #> 16 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   5.1 
    #> 17 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   5.35
    #> 18 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   5.6 
    #> 19 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   5.85
    #> 20 2025-09-23 23:42:47 2026-12-08           3.15  1.25             441   6.1 
    #>    probability_linear probability_prob probability   diff diff_s
    #>                 <dbl>            <dbl>       <dbl>  <dbl>  <dbl>
    #>  1              0               0.0297      0.0297 -2.25  -1.22 
    #>  2              0               0.0388      0.0388 -2     -1.19 
    #>  3              0               0.0488      0.0488 -1.75  -1.15 
    #>  4              0               0.0588      0.0588 -1.5   -1.11 
    #>  5              0               0.0682      0.0682 -1.25  -1.06 
    #>  6              0               0.0760      0.0760 -1     -1    
    #>  7              0               0.0813      0.0813 -0.75  -0.931
    #>  8              0.809           0.0836      0.0836 -0.5   -0.841
    #>  9              0.191           0.0825      0.0825 -0.25  -0.707
    #> 10              0               0.0783      0.0783  0      0    
    #> 11              0               0.0714      0.0714  0.25   0.707
    #> 12              0               0.0626      0.0626  0.500  0.841
    #> 13              0               0.0526      0.0526  0.750  0.931
    #> 14              0               0.0426      0.0426  1      1    
    #> 15              0               0.0331      0.0331  1.25   1.06 
    #> 16              0               0.0247      0.0247  1.5    1.11 
    #> 17              0               0.0177      0.0177  1.75   1.15 
    #> 18              0               0.0122      0.0122  2      1.19 
    #> 19              0               0           0       2.25   1.22 
    #> 20              0               0           0       2.5    1.26
    #> [1] "2025-09-30"
    #> Warning: Removed 66 rows containing missing values or values outside the scale range
    #> (`geom_vline()`).
    #> Creating extended buckets for 6364 estimate rows
    #> Bucket range: 0.1 to 6.1 
    #> Extended buckets created: 159100 rows
    #> Unique moves: 23 
    #> ✓ all_estimates_buckets_ext created successfully
    #> Future meetings found: 11 
    #> Meetings: 2025-09-30, 2025-11-04, 2025-12-09, 2026-02-03, 2026-03-17, 2026-05-05, 2026-06-16, 2026-08-11, 2026-09-29, 2026-11-03, 2026-12-08 
    #> 
    #> === Processing meeting: 2025-09-30 ===
    #> Initial df_mt dimensions: 14375 x 3 
    #> After cleaning dimensions: 14375 x 3 
    #> Final data dimensions: 14375 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-23 23:42:47 
    #> Probability range: 0 0.9408276 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2025-09-30.png
    #> Warning: Removed 1045 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2025-09-30 
    #> 
    #> === Processing meeting: 2025-11-04 ===
    #> Initial df_mt dimensions: 14375 x 3 
    #> After cleaning dimensions: 14375 x 3 
    #> Final data dimensions: 14375 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-23 23:42:47 
    #> Probability range: 0 0.5574795 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2025-11-04.png
    #> Warning: Removed 832 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2025-11-04 
    #> 
    #> === Processing meeting: 2025-12-09 ===
    #> Initial df_mt dimensions: 14375 x 3 
    #> After cleaning dimensions: 14375 x 3 
    #> Final data dimensions: 14375 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-23 23:42:47 
    #> Probability range: 0 0.2715836 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2025-12-09.png
    #> Warning: Removed 1420 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2025-12-09 
    #> 
    #> === Processing meeting: 2026-02-03 ===
    #> Initial df_mt dimensions: 14375 x 3 
    #> After cleaning dimensions: 14375 x 3 
    #> Final data dimensions: 14375 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-23 23:42:47 
    #> Probability range: 0 0.2142866 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-02-03.png
    #> Warning: Removed 2035 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-02-03 
    #> 
    #> === Processing meeting: 2026-03-17 ===
    #> Initial df_mt dimensions: 14375 x 3 
    #> After cleaning dimensions: 14375 x 3 
    #> Final data dimensions: 14375 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-23 23:42:47 
    #> Probability range: 0 0.1444453 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-03-17.png
    #> Warning: Removed 1978 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-03-17 
    #> 
    #> === Processing meeting: 2026-05-05 ===
    #> Initial df_mt dimensions: 14375 x 3 
    #> After cleaning dimensions: 14375 x 3 
    #> Final data dimensions: 14375 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-23 23:42:47 
    #> Probability range: 0 0.1198767 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-05-05.png
    #> Warning: Removed 1901 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-05-05 
    #> 
    #> === Processing meeting: 2026-06-16 ===
    #> Initial df_mt dimensions: 14375 x 3 
    #> After cleaning dimensions: 14375 x 3 
    #> Final data dimensions: 14375 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-23 23:42:47 
    #> Probability range: 0 0.1032427 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-06-16.png
    #> Warning: Removed 1792 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-06-16 
    #> 
    #> === Processing meeting: 2026-08-11 ===
    #> Initial df_mt dimensions: 14375 x 3 
    #> After cleaning dimensions: 14375 x 3 
    #> Final data dimensions: 14375 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-23 23:42:47 
    #> Probability range: 0 0.09710456 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-08-11.png
    #> Warning: Removed 1790 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-08-11 
    #> 
    #> === Processing meeting: 2026-09-29 ===
    #> Initial df_mt dimensions: 14375 x 3 
    #> After cleaning dimensions: 14375 x 3 
    #> Final data dimensions: 14375 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-23 23:42:47 
    #> Probability range: 0 0.09708598 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-09-29.png
    #> Warning: Removed 410 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-09-29 
    #> 
    #> === Processing meeting: 2026-11-03 ===
    #> Initial df_mt dimensions: 14375 x 3 
    #> After cleaning dimensions: 14375 x 3 
    #> Final data dimensions: 14375 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-23 23:42:47 
    #> Probability range: 0 0.09111703 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-11-03.png
    #> Warning: Removed 2007 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Strategy 1 failed: Problem while converting geom to grob. 
    #> Attempting simplified plot...
    #> ✓ Saved simplified plot for 2026-11-03 
    #> ❌ Failed to create plot for meeting 2026-11-03 
    #> 
    #> === Processing meeting: 2026-12-08 ===
    #> Initial df_mt dimensions: 14375 x 3 
    #> After cleaning dimensions: 14375 x 3 
    #> Final data dimensions: 14375 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-23 23:42:47 
    #> Probability range: 0 0.08357517 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-12-08.png
    #> Warning: Removed 1701 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-12-08 
    #> 
    #> === Plotting loop completed ===
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
    #> Analysis completed successfully!
