
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
    #> [1] "2025-09-12 17:22:31 AEST"
    #> [1] "2025-09-12 14:30:00 AEST"
    #> Replacing 19 missing/invalid stdev(s) with max RMSE = 1.3813
    #> # A tibble: 100 × 6
    #>     scrape_time         meeting_date implied_mean days_to_meeting previous_rate
    #>     <dttm>              <date>              <dbl>           <int>         <dbl>
    #>   1 2025-09-12 04:36:43 2026-12-08           3.11             453          3.10
    #>   2 2025-09-12 04:48:02 2025-09-30           3.57              19          3.6 
    #>   3 2025-09-12 04:48:02 2025-11-04           3.38              54          3.57
    #>   4 2025-09-12 04:48:02 2025-12-09           3.31              89          3.38
    #>   5 2025-09-12 04:48:02 2026-02-03           3.20             145          3.31
    #>   6 2025-09-12 04:48:02 2026-03-17           3.15             187          3.20
    #>   7 2025-09-12 04:48:02 2026-05-05           2.96             236          3.15
    #>   8 2025-09-12 04:48:02 2026-06-16           3.09             278          2.96
    #>   9 2025-09-12 04:48:02 2026-08-11           3.10             334          3.09
    #>  10 2025-09-12 04:48:02 2026-09-29           3.10             383          3.10
    #>  11 2025-09-12 04:48:02 2026-11-03           3.10             418          3.10
    #>  12 2025-09-12 04:48:02 2026-12-08           3.11             453          3.10
    #>  13 2025-09-12 04:59:56 2025-09-30           3.57              19          3.6 
    #>  14 2025-09-12 04:59:56 2025-11-04           3.38              54          3.57
    #>  15 2025-09-12 04:59:56 2025-12-09           3.31              89          3.38
    #>  16 2025-09-12 04:59:56 2026-02-03           3.20             145          3.31
    #>  17 2025-09-12 04:59:56 2026-03-17           3.15             187          3.20
    #>  18 2025-09-12 04:59:56 2026-05-05           2.96             236          3.15
    #>  19 2025-09-12 04:59:56 2026-06-16           3.09             278          2.96
    #>  20 2025-09-12 04:59:56 2026-08-11           3.10             334          3.09
    #>  21 2025-09-12 04:59:56 2026-09-29           3.10             383          3.10
    #>  22 2025-09-12 04:59:56 2026-11-03           3.10             418          3.10
    #>  23 2025-09-12 04:59:56 2026-12-08           3.11             453          3.10
    #>  24 2025-09-12 05:26:25 2025-09-30           3.57              19          3.6 
    #>  25 2025-09-12 05:26:25 2025-11-04           3.38              54          3.57
    #>  26 2025-09-12 05:26:25 2025-12-09           3.31              89          3.38
    #>  27 2025-09-12 05:26:25 2026-02-03           3.20             145          3.31
    #>  28 2025-09-12 05:26:25 2026-03-17           3.15             187          3.20
    #>  29 2025-09-12 05:26:25 2026-05-05           2.96             236          3.15
    #>  30 2025-09-12 05:26:25 2026-06-16           3.09             278          2.96
    #>  31 2025-09-12 05:26:25 2026-08-11           3.10             334          3.09
    #>  32 2025-09-12 05:26:25 2026-09-29           3.10             383          3.10
    #>  33 2025-09-12 05:26:25 2026-11-03           3.10             418          3.10
    #>  34 2025-09-12 05:26:25 2026-12-08           3.11             453          3.10
    #>  35 2025-09-12 05:41:14 2025-09-30           3.57              19          3.6 
    #>  36 2025-09-12 05:41:14 2025-11-04           3.38              54          3.57
    #>  37 2025-09-12 05:41:14 2025-12-09           3.31              89          3.38
    #>  38 2025-09-12 05:41:14 2026-02-03           3.20             145          3.31
    #>  39 2025-09-12 05:41:14 2026-03-17           3.15             187          3.20
    #>  40 2025-09-12 05:41:14 2026-05-05           2.96             236          3.15
    #>  41 2025-09-12 05:41:14 2026-06-16           3.09             278          2.96
    #>  42 2025-09-12 05:41:14 2026-08-11           3.10             334          3.09
    #>  43 2025-09-12 05:41:14 2026-09-29           3.10             383          3.10
    #>  44 2025-09-12 05:41:14 2026-11-03           3.10             418          3.10
    #>  45 2025-09-12 05:41:14 2026-12-08           3.11             453          3.10
    #>  46 2025-09-12 05:52:10 2025-09-30           3.57              19          3.6 
    #>  47 2025-09-12 05:52:10 2025-11-04           3.38              54          3.57
    #>  48 2025-09-12 05:52:10 2025-12-09           3.31              89          3.38
    #>  49 2025-09-12 05:52:10 2026-02-03           3.20             145          3.31
    #>  50 2025-09-12 05:52:10 2026-03-17           3.15             187          3.20
    #>  51 2025-09-12 05:52:10 2026-05-05           2.96             236          3.15
    #>  52 2025-09-12 05:52:10 2026-06-16           3.09             278          2.96
    #>  53 2025-09-12 05:52:10 2026-08-11           3.10             334          3.09
    #>  54 2025-09-12 05:52:10 2026-09-29           3.10             383          3.10
    #>  55 2025-09-12 05:52:10 2026-11-03           3.10             418          3.10
    #>  56 2025-09-12 05:52:10 2026-12-08           3.11             453          3.10
    #>  57 2025-09-12 06:17:31 2025-09-30           3.57              19          3.6 
    #>  58 2025-09-12 06:17:31 2025-11-04           3.38              54          3.57
    #>  59 2025-09-12 06:17:31 2025-12-09           3.31              89          3.38
    #>  60 2025-09-12 06:17:31 2026-02-03           3.20             145          3.31
    #>  61 2025-09-12 06:17:31 2026-03-17           3.15             187          3.20
    #>  62 2025-09-12 06:17:31 2026-05-05           2.96             236          3.15
    #>  63 2025-09-12 06:17:31 2026-06-16           3.09             278          2.96
    #>  64 2025-09-12 06:17:31 2026-08-11           3.10             334          3.09
    #>  65 2025-09-12 06:17:31 2026-09-29           3.10             383          3.10
    #>  66 2025-09-12 06:17:31 2026-11-03           3.10             418          3.10
    #>  67 2025-09-12 06:17:31 2026-12-08           3.11             453          3.10
    #>  68 2025-09-12 06:44:55 2025-09-30           3.57              19          3.6 
    #>  69 2025-09-12 06:44:55 2025-11-04           3.38              54          3.57
    #>  70 2025-09-12 06:44:55 2025-12-09           3.31              89          3.38
    #>  71 2025-09-12 06:44:55 2026-02-03           3.20             145          3.31
    #>  72 2025-09-12 06:44:55 2026-03-17           3.15             187          3.20
    #>  73 2025-09-12 06:44:55 2026-05-05           2.96             236          3.15
    #>  74 2025-09-12 06:44:55 2026-06-16           3.09             278          2.96
    #>  75 2025-09-12 06:44:55 2026-08-11           3.13             334          3.09
    #>  76 2025-09-12 06:44:55 2026-09-29           3.12             383          3.13
    #>  77 2025-09-12 06:44:55 2026-11-03           3.13             418          3.12
    #>  78 2025-09-12 06:44:55 2026-12-08           3.14             453          3.13
    #>  79 2025-09-12 06:56:21 2025-09-30           3.57              19          3.6 
    #>  80 2025-09-12 06:56:21 2025-11-04           3.38              54          3.57
    #>  81 2025-09-12 06:56:21 2025-12-09           3.31              89          3.38
    #>  82 2025-09-12 06:56:21 2026-02-03           3.20             145          3.31
    #>  83 2025-09-12 06:56:21 2026-03-17           3.15             187          3.20
    #>  84 2025-09-12 06:56:21 2026-05-05           2.96             236          3.15
    #>  85 2025-09-12 06:56:21 2026-06-16           3.09             278          2.96
    #>  86 2025-09-12 06:56:21 2026-08-11           3.13             334          3.09
    #>  87 2025-09-12 06:56:21 2026-09-29           3.12             383          3.13
    #>  88 2025-09-12 06:56:21 2026-11-03           3.13             418          3.12
    #>  89 2025-09-12 06:56:21 2026-12-08           3.14             453          3.13
    #>  90 2025-09-12 07:21:22 2025-09-30           3.57              19          3.6 
    #>  91 2025-09-12 07:21:22 2025-11-04           3.38              54          3.57
    #>  92 2025-09-12 07:21:22 2025-12-09           3.31              89          3.38
    #>  93 2025-09-12 07:21:22 2026-02-03           3.20             145          3.31
    #>  94 2025-09-12 07:21:22 2026-03-17           3.15             187          3.20
    #>  95 2025-09-12 07:21:22 2026-05-05           2.96             236          3.15
    #>  96 2025-09-12 07:21:22 2026-06-16           3.09             278          2.96
    #>  97 2025-09-12 07:21:22 2026-08-11           3.13             334          3.09
    #>  98 2025-09-12 07:21:22 2026-09-29           3.12             383          3.13
    #>  99 2025-09-12 07:21:22 2026-11-03           3.13             418          3.12
    #> 100 2025-09-12 07:21:22 2026-12-08           3.14             453          3.13
    #>      stdev
    #>      <dbl>
    #>   1 1.26  
    #>   2 0.0671
    #>   3 0.238 
    #>   4 0.395 
    #>   5 0.584 
    #>   6 0.737 
    #>   7 0.868 
    #>   8 1.06  
    #>   9 1.06  
    #>  10 1.09  
    #>  11 1.20  
    #>  12 1.26  
    #>  13 0.0671
    #>  14 0.238 
    #>  15 0.395 
    #>  16 0.584 
    #>  17 0.737 
    #>  18 0.868 
    #>  19 1.06  
    #>  20 1.06  
    #>  21 1.09  
    #>  22 1.20  
    #>  23 1.26  
    #>  24 0.0671
    #>  25 0.238 
    #>  26 0.395 
    #>  27 0.584 
    #>  28 0.737 
    #>  29 0.868 
    #>  30 1.06  
    #>  31 1.06  
    #>  32 1.09  
    #>  33 1.20  
    #>  34 1.26  
    #>  35 0.0671
    #>  36 0.238 
    #>  37 0.395 
    #>  38 0.584 
    #>  39 0.737 
    #>  40 0.868 
    #>  41 1.06  
    #>  42 1.06  
    #>  43 1.09  
    #>  44 1.20  
    #>  45 1.26  
    #>  46 0.0671
    #>  47 0.238 
    #>  48 0.395 
    #>  49 0.584 
    #>  50 0.737 
    #>  51 0.868 
    #>  52 1.06  
    #>  53 1.06  
    #>  54 1.09  
    #>  55 1.20  
    #>  56 1.26  
    #>  57 0.0671
    #>  58 0.238 
    #>  59 0.395 
    #>  60 0.584 
    #>  61 0.737 
    #>  62 0.868 
    #>  63 1.06  
    #>  64 1.06  
    #>  65 1.09  
    #>  66 1.20  
    #>  67 1.26  
    #>  68 0.0671
    #>  69 0.238 
    #>  70 0.395 
    #>  71 0.584 
    #>  72 0.737 
    #>  73 0.868 
    #>  74 1.06  
    #>  75 1.06  
    #>  76 1.09  
    #>  77 1.20  
    #>  78 1.26  
    #>  79 0.0671
    #>  80 0.238 
    #>  81 0.395 
    #>  82 0.584 
    #>  83 0.737 
    #>  84 0.868 
    #>  85 1.06  
    #>  86 1.06  
    #>  87 1.09  
    #>  88 1.20  
    #>  89 1.26  
    #>  90 0.0671
    #>  91 0.238 
    #>  92 0.395 
    #>  93 0.584 
    #>  94 0.737 
    #>  95 0.868 
    #>  96 1.06  
    #>  97 1.06  
    #>  98 1.09  
    #>  99 1.20  
    #> 100 1.26
    #> Warning: All formats failed to parse. No formats found.
    #> Warning: All formats failed to parse. No formats found.
    #> # A tibble: 20 × 11
    #>    scrape_time         meeting_date implied_mean stdev days_to_meeting bucket
    #>    <dttm>              <date>              <dbl> <dbl>           <int>  <dbl>
    #>  1 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   1.35
    #>  2 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   1.6 
    #>  3 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   1.85
    #>  4 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   2.1 
    #>  5 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   2.35
    #>  6 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   2.6 
    #>  7 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   2.85
    #>  8 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   3.1 
    #>  9 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   3.35
    #> 10 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   3.6 
    #> 11 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   3.85
    #> 12 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   4.1 
    #> 13 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   4.35
    #> 14 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   4.6 
    #> 15 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   4.85
    #> 16 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   5.1 
    #> 17 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   5.35
    #> 18 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   5.6 
    #> 19 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   5.85
    #> 20 2025-09-12 07:21:22 2026-12-08           3.14  1.26             453   6.1 
    #>    probability_linear probability_prob probability   diff diff_s
    #>                 <dbl>            <dbl>       <dbl>  <dbl>  <dbl>
    #>  1              0               0.0301      0.0301 -2.25  -1.22 
    #>  2              0               0.0391      0.0391 -2     -1.19 
    #>  3              0               0.0488      0.0488 -1.75  -1.15 
    #>  4              0               0.0585      0.0585 -1.5   -1.11 
    #>  5              0               0.0675      0.0675 -1.25  -1.06 
    #>  6              0               0.0749      0.0749 -1     -1    
    #>  7              0               0.0799      0.0799 -0.75  -0.931
    #>  8              0.849           0.0820      0.0820 -0.5   -0.841
    #>  9              0.151           0.0809      0.0809 -0.25  -0.707
    #> 10              0               0.0767      0.0767  0      0    
    #> 11              0               0.0700      0.0700  0.25   0.707
    #> 12              0               0.0614      0.0614  0.500  0.841
    #> 13              0               0.0518      0.0518  0.750  0.931
    #> 14              0               0.0420      0.0420  1      1    
    #> 15              0               0.0327      0.0327  1.25   1.06 
    #> 16              0               0.0246      0.0246  1.5    1.11 
    #> 17              0               0.0177      0.0177  1.75   1.15 
    #> 18              0               0.0123      0.0123  2      1.19 
    #> 19              0               0           0       2.25   1.22 
    #> 20              0               0           0       2.5    1.26
    #> [1] "2025-09-30"
    #> Warning: Removed 66 rows containing missing values or values outside the scale range
    #> (`geom_vline()`).
    #> Warning: Removed 136 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Warning: Removed 66 rows containing missing values or values outside the scale range
    #> (`geom_vline()`).
    #> Removed 66 rows containing missing values or values outside the scale range
    #> (`geom_vline()`).
    #> Warning: Removed 136 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Removed 136 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Processing meeting: 20361 
    #> df_mt dimensions: 10800 x 3 
    #> Creating plot with 10800 data points
    #> Saving to: docs/meetings/area_all_moves_20250930.png
    #> Warning: Removed 181 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20361 
    #> Processing meeting: 20396 
    #> df_mt dimensions: 10800 x 3 
    #> Creating plot with 10800 data points
    #> Saving to: docs/meetings/area_all_moves_20251104.png
    #> Warning: Removed 1096 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20396 
    #> Processing meeting: 20431 
    #> df_mt dimensions: 10800 x 3 
    #> Creating plot with 10800 data points
    #> Saving to: docs/meetings/area_all_moves_20251209.png
    #> Warning: Removed 1359 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20431 
    #> Processing meeting: 20487 
    #> df_mt dimensions: 10800 x 3 
    #> Creating plot with 10800 data points
    #> Saving to: docs/meetings/area_all_moves_20260203.png
    #> Warning: Removed 730 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20487 
    #> Processing meeting: 20529 
    #> df_mt dimensions: 10800 x 3 
    #> Creating plot with 10800 data points
    #> Saving to: docs/meetings/area_all_moves_20260317.png
    #> Warning: Removed 735 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20529 
    #> Processing meeting: 20578 
    #> df_mt dimensions: 10800 x 3 
    #> Creating plot with 10800 data points
    #> Saving to: docs/meetings/area_all_moves_20260505.png
    #> Warning: Removed 947 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20578 
    #> Processing meeting: 20620 
    #> df_mt dimensions: 10800 x 3 
    #> Creating plot with 10800 data points
    #> Saving to: docs/meetings/area_all_moves_20260616.png
    #> Warning: Removed 613 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20620 
    #> Processing meeting: 20676 
    #> df_mt dimensions: 10800 x 3 
    #> Creating plot with 10800 data points
    #> Saving to: docs/meetings/area_all_moves_20260811.png
    #> Warning: Removed 297 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20676 
    #> Processing meeting: 20725 
    #> df_mt dimensions: 10800 x 3 
    #> Creating plot with 10800 data points
    #> Saving to: docs/meetings/area_all_moves_20260929.png
    #> Warning: Removed 953 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20725 
    #> Processing meeting: 20760 
    #> df_mt dimensions: 10800 x 3 
    #> Creating plot with 10800 data points
    #> Saving to: docs/meetings/area_all_moves_20261103.png
    #> Warning: Removed 439 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Successfully saved plot for 20760 
    #> Processing meeting: 20795 
    #> df_mt dimensions: 10800 x 3 
    #> Creating plot with 10800 data points
    #> Saving to: docs/meetings/area_all_moves_20261208.png
    #> Warning: Removed 150 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Error creating plot for meeting 20795 : Problem while converting geom to grob. 
    #> Data summary:
    #>   scrape_time                          move       probability         stack_id 
    #>  Min.   :2025-08-12 00:01:37   300 bp cut: 432   Min.   :0.00000   Min.   : 1  
    #>  1st Qu.:2025-08-20 05:44:15   275 bp cut: 432   1st Qu.:0.01479   1st Qu.: 7  
    #>  Median :2025-08-28 06:17:58   250 bp cut: 432   Median :0.03821   Median :13  
    #>  Mean   :2025-08-28 14:18:43   225 bp cut: 432   Mean   :0.04000   Mean   :13  
    #>  3rd Qu.:2025-09-05 05:25:37   200 bp cut: 432   3rd Qu.:0.06758   3rd Qu.:19  
    #>  Max.   :2025-09-12 07:21:22   175 bp cut: 432   Max.   :0.08273   Max.   :25  
    #>                                (Other)   :8208
