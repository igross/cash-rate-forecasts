
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
    #> [1] "2025-09-26 16:17:06 AEST"
    #> [1] "2025-09-26 14:30:00 AEST"
    #> Replacing 19 missing/invalid stdev(s) with max RMSE = 1.3813
    #> # A tibble: 100 × 6
    #>     scrape_time         meeting_date implied_mean days_to_meeting previous_rate
    #>     <dttm>              <date>              <dbl>           <int>         <dbl>
    #>   1 2025-09-26 03:24:07 2026-12-08           3.27             439          3.26
    #>   2 2025-09-26 03:46:53 2025-09-30           3.59               5          3.6 
    #>   3 2025-09-26 03:46:53 2025-11-04           3.48              40          3.59
    #>   4 2025-09-26 03:46:53 2025-12-09           3.44              75          3.48
    #>   5 2025-09-26 03:46:53 2026-02-03           3.34             131          3.44
    #>   6 2025-09-26 03:46:53 2026-03-17           3.36             173          3.34
    #>   7 2025-09-26 03:46:53 2026-05-05           2.93             222          3.36
    #>   8 2025-09-26 03:46:53 2026-06-16           3.12             264          2.93
    #>   9 2025-09-26 03:46:53 2026-08-11           3.32             320          3.12
    #>  10 2025-09-26 03:46:53 2026-09-29           3.25             369          3.32
    #>  11 2025-09-26 03:46:53 2026-11-03           3.26             404          3.25
    #>  12 2025-09-26 03:46:53 2026-12-08           3.27             439          3.26
    #>  13 2025-09-26 03:58:28 2025-09-30           3.59               5          3.6 
    #>  14 2025-09-26 03:58:28 2025-11-04           3.48              40          3.59
    #>  15 2025-09-26 03:58:28 2025-12-09           3.44              75          3.48
    #>  16 2025-09-26 03:58:28 2026-02-03           3.34             131          3.44
    #>  17 2025-09-26 03:58:28 2026-03-17           3.36             173          3.34
    #>  18 2025-09-26 03:58:28 2026-05-05           2.93             222          3.36
    #>  19 2025-09-26 03:58:28 2026-06-16           3.12             264          2.93
    #>  20 2025-09-26 03:58:28 2026-08-11           3.32             320          3.12
    #>  21 2025-09-26 03:58:28 2026-09-29           3.25             369          3.32
    #>  22 2025-09-26 03:58:28 2026-11-03           3.26             404          3.25
    #>  23 2025-09-26 03:58:28 2026-12-08           3.27             439          3.26
    #>  24 2025-09-26 04:31:22 2025-09-30           3.59               5          3.6 
    #>  25 2025-09-26 04:31:22 2025-11-04           3.48              40          3.59
    #>  26 2025-09-26 04:31:22 2025-12-09           3.44              75          3.48
    #>  27 2025-09-26 04:31:22 2026-02-03           3.34             131          3.44
    #>  28 2025-09-26 04:31:22 2026-03-17           3.36             173          3.34
    #>  29 2025-09-26 04:31:22 2026-05-05           2.93             222          3.36
    #>  30 2025-09-26 04:31:22 2026-06-16           3.12             264          2.93
    #>  31 2025-09-26 04:31:22 2026-08-11           3.32             320          3.12
    #>  32 2025-09-26 04:31:22 2026-09-29           3.25             369          3.32
    #>  33 2025-09-26 04:31:22 2026-11-03           3.26             404          3.25
    #>  34 2025-09-26 04:31:22 2026-12-08           3.27             439          3.26
    #>  35 2025-09-26 04:47:46 2025-09-30           3.59               5          3.6 
    #>  36 2025-09-26 04:47:46 2025-11-04           3.48              40          3.59
    #>  37 2025-09-26 04:47:46 2025-12-09           3.44              75          3.48
    #>  38 2025-09-26 04:47:46 2026-02-03           3.34             131          3.44
    #>  39 2025-09-26 04:47:46 2026-03-17           3.36             173          3.34
    #>  40 2025-09-26 04:47:46 2026-05-05           2.93             222          3.36
    #>  41 2025-09-26 04:47:46 2026-06-16           3.12             264          2.93
    #>  42 2025-09-26 04:47:46 2026-08-11           3.32             320          3.12
    #>  43 2025-09-26 04:47:46 2026-09-29           3.25             369          3.32
    #>  44 2025-09-26 04:47:46 2026-11-03           3.26             404          3.25
    #>  45 2025-09-26 04:47:46 2026-12-08           3.27             439          3.26
    #>  46 2025-09-26 04:58:03 2025-09-30           3.59               5          3.6 
    #>  47 2025-09-26 04:58:03 2025-11-04           3.48              40          3.59
    #>  48 2025-09-26 04:58:03 2025-12-09           3.44              75          3.48
    #>  49 2025-09-26 04:58:03 2026-02-03           3.34             131          3.44
    #>  50 2025-09-26 04:58:03 2026-03-17           3.36             173          3.34
    #>  51 2025-09-26 04:58:03 2026-05-05           2.93             222          3.36
    #>  52 2025-09-26 04:58:03 2026-06-16           3.12             264          2.93
    #>  53 2025-09-26 04:58:03 2026-08-11           3.32             320          3.12
    #>  54 2025-09-26 04:58:03 2026-09-29           3.25             369          3.32
    #>  55 2025-09-26 04:58:03 2026-11-03           3.26             404          3.25
    #>  56 2025-09-26 04:58:03 2026-12-08           3.27             439          3.26
    #>  57 2025-09-26 05:23:44 2025-09-30           3.59               5          3.6 
    #>  58 2025-09-26 05:23:44 2025-11-04           3.48              40          3.59
    #>  59 2025-09-26 05:23:44 2025-12-09           3.44              75          3.48
    #>  60 2025-09-26 05:23:44 2026-02-03           3.34             131          3.44
    #>  61 2025-09-26 05:23:44 2026-03-17           3.36             173          3.34
    #>  62 2025-09-26 05:23:44 2026-05-05           2.93             222          3.36
    #>  63 2025-09-26 05:23:44 2026-06-16           3.12             264          2.93
    #>  64 2025-09-26 05:23:44 2026-08-11           3.32             320          3.12
    #>  65 2025-09-26 05:23:44 2026-09-29           3.25             369          3.32
    #>  66 2025-09-26 05:23:44 2026-11-03           3.26             404          3.25
    #>  67 2025-09-26 05:23:44 2026-12-08           3.27             439          3.26
    #>  68 2025-09-26 05:39:52 2025-09-30           3.59               5          3.6 
    #>  69 2025-09-26 05:39:52 2025-11-04           3.48              40          3.59
    #>  70 2025-09-26 05:39:52 2025-12-09           3.44              75          3.48
    #>  71 2025-09-26 05:39:52 2026-02-03           3.34             131          3.44
    #>  72 2025-09-26 05:39:52 2026-03-17           3.36             173          3.34
    #>  73 2025-09-26 05:39:52 2026-05-05           2.93             222          3.36
    #>  74 2025-09-26 05:39:52 2026-06-16           3.12             264          2.93
    #>  75 2025-09-26 05:39:52 2026-08-11           3.32             320          3.12
    #>  76 2025-09-26 05:39:52 2026-09-29           3.25             369          3.32
    #>  77 2025-09-26 05:39:52 2026-11-03           3.26             404          3.25
    #>  78 2025-09-26 05:39:52 2026-12-08           3.27             439          3.26
    #>  79 2025-09-26 05:51:08 2025-09-30           3.59               5          3.6 
    #>  80 2025-09-26 05:51:08 2025-11-04           3.48              40          3.59
    #>  81 2025-09-26 05:51:08 2025-12-09           3.44              75          3.48
    #>  82 2025-09-26 05:51:08 2026-02-03           3.34             131          3.44
    #>  83 2025-09-26 05:51:08 2026-03-17           3.36             173          3.34
    #>  84 2025-09-26 05:51:08 2026-05-05           2.93             222          3.36
    #>  85 2025-09-26 05:51:08 2026-06-16           3.12             264          2.93
    #>  86 2025-09-26 05:51:08 2026-08-11           3.32             320          3.12
    #>  87 2025-09-26 05:51:08 2026-09-29           3.25             369          3.32
    #>  88 2025-09-26 05:51:08 2026-11-03           3.26             404          3.25
    #>  89 2025-09-26 05:51:08 2026-12-08           3.27             439          3.26
    #>  90 2025-09-26 06:15:55 2025-09-30           3.59               5          3.6 
    #>  91 2025-09-26 06:15:55 2025-11-04           3.48              40          3.59
    #>  92 2025-09-26 06:15:55 2025-12-09           3.44              75          3.48
    #>  93 2025-09-26 06:15:55 2026-02-03           3.34             131          3.44
    #>  94 2025-09-26 06:15:55 2026-03-17           3.36             173          3.34
    #>  95 2025-09-26 06:15:55 2026-05-05           2.93             222          3.36
    #>  96 2025-09-26 06:15:55 2026-06-16           3.12             264          2.93
    #>  97 2025-09-26 06:15:55 2026-08-11           3.32             320          3.12
    #>  98 2025-09-26 06:15:55 2026-09-29           3.25             369          3.32
    #>  99 2025-09-26 06:15:55 2026-11-03           3.26             404          3.25
    #> 100 2025-09-26 06:15:55 2026-12-08           3.27             439          3.26
    #>      stdev
    #>      <dbl>
    #>   1 1.24  
    #>   2 0.0639
    #>   3 0.138 
    #>   4 0.353 
    #>   5 0.459 
    #>   6 0.696 
    #>   7 0.846 
    #>   8 0.988 
    #>   9 1.06  
    #>  10 1.06  
    #>  11 1.13  
    #>  12 1.24  
    #>  13 0.0639
    #>  14 0.138 
    #>  15 0.353 
    #>  16 0.459 
    #>  17 0.696 
    #>  18 0.846 
    #>  19 0.988 
    #>  20 1.06  
    #>  21 1.06  
    #>  22 1.13  
    #>  23 1.24  
    #>  24 0.0639
    #>  25 0.138 
    #>  26 0.353 
    #>  27 0.459 
    #>  28 0.696 
    #>  29 0.846 
    #>  30 0.988 
    #>  31 1.06  
    #>  32 1.06  
    #>  33 1.13  
    #>  34 1.24  
    #>  35 0.0639
    #>  36 0.138 
    #>  37 0.353 
    #>  38 0.459 
    #>  39 0.696 
    #>  40 0.846 
    #>  41 0.988 
    #>  42 1.06  
    #>  43 1.06  
    #>  44 1.13  
    #>  45 1.24  
    #>  46 0.0639
    #>  47 0.138 
    #>  48 0.353 
    #>  49 0.459 
    #>  50 0.696 
    #>  51 0.846 
    #>  52 0.988 
    #>  53 1.06  
    #>  54 1.06  
    #>  55 1.13  
    #>  56 1.24  
    #>  57 0.0639
    #>  58 0.138 
    #>  59 0.353 
    #>  60 0.459 
    #>  61 0.696 
    #>  62 0.846 
    #>  63 0.988 
    #>  64 1.06  
    #>  65 1.06  
    #>  66 1.13  
    #>  67 1.24  
    #>  68 0.0639
    #>  69 0.138 
    #>  70 0.353 
    #>  71 0.459 
    #>  72 0.696 
    #>  73 0.846 
    #>  74 0.988 
    #>  75 1.06  
    #>  76 1.06  
    #>  77 1.13  
    #>  78 1.24  
    #>  79 0.0639
    #>  80 0.138 
    #>  81 0.353 
    #>  82 0.459 
    #>  83 0.696 
    #>  84 0.846 
    #>  85 0.988 
    #>  86 1.06  
    #>  87 1.06  
    #>  88 1.13  
    #>  89 1.24  
    #>  90 0.0639
    #>  91 0.138 
    #>  92 0.353 
    #>  93 0.459 
    #>  94 0.696 
    #>  95 0.846 
    #>  96 0.988 
    #>  97 1.06  
    #>  98 1.06  
    #>  99 1.13  
    #> 100 1.24
    #> Warning: All formats failed to parse. No formats found.
    #> Warning: All formats failed to parse. No formats found.
    #> # A tibble: 20 × 11
    #>    scrape_time         meeting_date implied_mean stdev days_to_meeting bucket
    #>    <dttm>              <date>              <dbl> <dbl>           <int>  <dbl>
    #>  1 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   1.35
    #>  2 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   1.6 
    #>  3 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   1.85
    #>  4 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   2.1 
    #>  5 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   2.35
    #>  6 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   2.6 
    #>  7 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   2.85
    #>  8 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   3.1 
    #>  9 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   3.35
    #> 10 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   3.6 
    #> 11 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   3.85
    #> 12 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   4.1 
    #> 13 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   4.35
    #> 14 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   4.6 
    #> 15 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   4.85
    #> 16 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   5.1 
    #> 17 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   5.35
    #> 18 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   5.6 
    #> 19 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   5.85
    #> 20 2025-09-26 06:15:55 2026-12-08           3.27  1.24             439   6.1 
    #>    probability_linear probability_prob probability   diff diff_s
    #>                 <dbl>            <dbl>       <dbl>  <dbl>  <dbl>
    #>  1              0               0.0254      0.0254 -2.25  -1.22 
    #>  2              0               0.0340      0.0340 -2     -1.19 
    #>  3              0               0.0436      0.0436 -1.75  -1.15 
    #>  4              0               0.0538      0.0538 -1.5   -1.11 
    #>  5              0               0.0637      0.0637 -1.25  -1.06 
    #>  6              0               0.0724      0.0724 -1     -1    
    #>  7              0               0.0791      0.0791 -0.75  -0.931
    #>  8              0.309           0.0830      0.0830 -0.5   -0.841
    #>  9              0.691           0.0837      0.0837 -0.25  -0.707
    #> 10              0               0.0810      0.0810  0      0    
    #> 11              0               0.0753      0.0753  0.25   0.707
    #> 12              0               0.0672      0.0672  0.500  0.841
    #> 13              0               0.0577      0.0577  0.750  0.931
    #> 14              0               0.0475      0.0475  1      1    
    #> 15              0               0.0376      0.0376  1.25   1.06 
    #> 16              0               0.0286      0.0286  1.5    1.11 
    #> 17              0               0.0209      0.0209  1.75   1.15 
    #> 18              0               0.0146      0.0146  2      1.19 
    #> 19              0               0           0       2.25   1.22 
    #> 20              0               0           0       2.5    1.26
    #> [1] "2025-09-30"
    #> Warning: Removed 66 rows containing missing values or values outside the scale range
    #> (`geom_vline()`).
    #> Creating extended buckets for 6991 estimate rows
    #> Bucket range: 0.1 to 6.1 
    #> Extended buckets created: 174775 rows
    #> Unique moves: 23 
    #> ✓ all_estimates_buckets_ext created successfully
    #> Future meetings found: 11 
    #> Meetings: 2025-09-30, 2025-11-04, 2025-12-09, 2026-02-03, 2026-03-17, 2026-05-05, 2026-06-16, 2026-08-11, 2026-09-29, 2026-11-03, 2026-12-08 
    #> 
    #> === Processing meeting: 2025-09-30 ===
    #> Initial df_mt dimensions: 15800 x 3 
    #> After cleaning dimensions: 15800 x 3 
    #> Final data dimensions: 15800 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-26 06:15:55 
    #> Probability range: 0 0.972713 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2025-09-30.png
    #> Warning: Removed 1045 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2025-09-30 
    #> 
    #> === Processing meeting: 2025-11-04 ===
    #> Initial df_mt dimensions: 15800 x 3 
    #> After cleaning dimensions: 15800 x 3 
    #> Final data dimensions: 15800 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-26 06:15:55 
    #> Probability range: 0 0.5574795 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2025-11-04.png
    #> Warning: Removed 832 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2025-11-04 
    #> 
    #> === Processing meeting: 2025-12-09 ===
    #> Initial df_mt dimensions: 15800 x 3 
    #> After cleaning dimensions: 15800 x 3 
    #> Final data dimensions: 15800 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-26 06:15:55 
    #> Probability range: 0 0.2715836 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2025-12-09.png
    #> Warning: Removed 1472 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2025-12-09 
    #> 
    #> === Processing meeting: 2026-02-03 ===
    #> Initial df_mt dimensions: 15800 x 3 
    #> After cleaning dimensions: 15800 x 3 
    #> Final data dimensions: 15800 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-26 06:15:55 
    #> Probability range: 0 0.2178698 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-02-03.png
    #> Warning: Removed 2137 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-02-03 
    #> 
    #> === Processing meeting: 2026-03-17 ===
    #> Initial df_mt dimensions: 15800 x 3 
    #> After cleaning dimensions: 15800 x 3 
    #> Final data dimensions: 15800 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-26 06:15:55 
    #> Probability range: 0 0.145322 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-03-17.png
    #> Warning: Removed 2052 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-03-17 
    #> 
    #> === Processing meeting: 2026-05-05 ===
    #> Initial df_mt dimensions: 15800 x 3 
    #> After cleaning dimensions: 15800 x 3 
    #> Final data dimensions: 15800 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-26 06:15:55 
    #> Probability range: 0 0.12027 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-05-05.png
    #> Warning: Removed 2224 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Strategy 1 failed: Problem while converting geom to grob. 
    #> Attempting simplified plot...
    #> ✓ Saved simplified plot for 2026-05-05 
    #> ❌ Failed to create plot for meeting 2026-05-05 
    #> 
    #> === Processing meeting: 2026-06-16 ===
    #> Initial df_mt dimensions: 15800 x 3 
    #> After cleaning dimensions: 15800 x 3 
    #> Final data dimensions: 15800 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-26 06:15:55 
    #> Probability range: 0 0.1039371 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-06-16.png
    #> Warning: Removed 1932 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-06-16 
    #> 
    #> === Processing meeting: 2026-08-11 ===
    #> Initial df_mt dimensions: 15800 x 3 
    #> After cleaning dimensions: 15800 x 3 
    #> Final data dimensions: 15800 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-26 06:15:55 
    #> Probability range: 0 0.09710456 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-08-11.png
    #> Warning: Removed 1850 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-08-11 
    #> 
    #> === Processing meeting: 2026-09-29 ===
    #> Initial df_mt dimensions: 15800 x 3 
    #> After cleaning dimensions: 15800 x 3 
    #> Final data dimensions: 15800 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-26 06:15:55 
    #> Probability range: 0 0.09708598 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-09-29.png
    #> Warning: Removed 794 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-09-29 
    #> 
    #> === Processing meeting: 2026-11-03 ===
    #> Initial df_mt dimensions: 15800 x 3 
    #> After cleaning dimensions: 15800 x 3 
    #> Final data dimensions: 15800 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-26 06:15:55 
    #> Probability range: 0 0.09111703 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-11-03.png
    #> Warning: Removed 2324 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-11-03 
    #> 
    #> === Processing meeting: 2026-12-08 ===
    #> Initial df_mt dimensions: 15800 x 3 
    #> After cleaning dimensions: 15800 x 3 
    #> Final data dimensions: 15800 x 3 
    #> Unique moves: 25 
    #> Time range: 2025-08-12 00:01:37 2025-09-26 06:15:55 
    #> Probability range: 0 0.0836618 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-12-08.png
    #> Warning: Removed 1966 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> Strategy 1 failed: Problem while converting geom to grob. 
    #> Attempting simplified plot...
    #> ✓ Saved simplified plot for 2026-12-08 
    #> ❌ Failed to create plot for meeting 2026-12-08 
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
