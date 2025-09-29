
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
    #> [1] "2025-09-29 22:30:01 AEST"
    #> [1] "2025-09-29 14:30:00 AEST"
    #> Replacing 19 missing/invalid stdev(s) with max RMSE = 1.3813
    #> # A tibble: 100 × 6
    #>     scrape_time         meeting_date implied_mean days_to_meeting previous_rate
    #>     <dttm>              <date>              <dbl>           <int>         <dbl>
    #>   1 2025-09-29 04:40:59 2026-12-08           3.31             436          3.30
    #>   2 2025-09-29 04:52:52 2025-09-30           3.59               2          3.6 
    #>   3 2025-09-29 04:52:52 2025-11-04           3.47              37          3.59
    #>   4 2025-09-29 04:52:52 2025-12-09           3.41              72          3.47
    #>   5 2025-09-29 04:52:52 2026-02-03           3.34             128          3.41
    #>   6 2025-09-29 04:52:52 2026-03-17           3.36             170          3.34
    #>   7 2025-09-29 04:52:52 2026-05-05           2.93             219          3.36
    #>   8 2025-09-29 04:52:52 2026-06-16           3.12             261          2.93
    #>   9 2025-09-29 04:52:52 2026-08-11           3.36             317          3.12
    #>  10 2025-09-29 04:52:52 2026-09-29           3.29             366          3.36
    #>  11 2025-09-29 04:52:52 2026-11-03           3.30             401          3.29
    #>  12 2025-09-29 04:52:52 2026-12-08           3.31             436          3.30
    #>  13 2025-09-29 05:15:13 2025-09-30           3.59               2          3.6 
    #>  14 2025-09-29 05:15:13 2025-11-04           3.47              37          3.59
    #>  15 2025-09-29 05:15:13 2025-12-09           3.41              72          3.47
    #>  16 2025-09-29 05:15:13 2026-02-03           3.34             128          3.41
    #>  17 2025-09-29 05:15:13 2026-03-17           3.36             170          3.34
    #>  18 2025-09-29 05:15:13 2026-05-05           2.93             219          3.36
    #>  19 2025-09-29 05:15:13 2026-06-16           3.12             261          2.93
    #>  20 2025-09-29 05:15:13 2026-08-11           3.36             317          3.12
    #>  21 2025-09-29 05:15:13 2026-09-29           3.29             366          3.36
    #>  22 2025-09-29 05:15:13 2026-11-03           3.30             401          3.29
    #>  23 2025-09-29 05:15:13 2026-12-08           3.31             436          3.30
    #>  24 2025-09-29 05:35:35 2025-09-30           3.59               2          3.6 
    #>  25 2025-09-29 05:35:35 2025-11-04           3.46              37          3.59
    #>  26 2025-09-29 05:35:35 2025-12-09           3.41              72          3.46
    #>  27 2025-09-29 05:35:35 2026-02-03           3.34             128          3.41
    #>  28 2025-09-29 05:35:35 2026-03-17           3.36             170          3.34
    #>  29 2025-09-29 05:35:35 2026-05-05           2.93             219          3.36
    #>  30 2025-09-29 05:35:35 2026-06-16           3.12             261          2.93
    #>  31 2025-09-29 05:35:35 2026-08-11           3.36             317          3.12
    #>  32 2025-09-29 05:35:35 2026-09-29           3.29             366          3.36
    #>  33 2025-09-29 05:35:35 2026-11-03           3.30             401          3.29
    #>  34 2025-09-29 05:35:35 2026-12-08           3.31             436          3.30
    #>  35 2025-09-29 05:47:12 2025-09-30           3.59               2          3.6 
    #>  36 2025-09-29 05:47:12 2025-11-04           3.46              37          3.59
    #>  37 2025-09-29 05:47:12 2025-12-09           3.41              72          3.46
    #>  38 2025-09-29 05:47:12 2026-02-03           3.34             128          3.41
    #>  39 2025-09-29 05:47:12 2026-03-17           3.36             170          3.34
    #>  40 2025-09-29 05:47:12 2026-05-05           2.93             219          3.36
    #>  41 2025-09-29 05:47:12 2026-06-16           3.12             261          2.93
    #>  42 2025-09-29 05:47:12 2026-08-11           3.36             317          3.12
    #>  43 2025-09-29 05:47:12 2026-09-29           3.29             366          3.36
    #>  44 2025-09-29 05:47:12 2026-11-03           3.30             401          3.29
    #>  45 2025-09-29 05:47:12 2026-12-08           3.31             436          3.30
    #>  46 2025-09-29 05:58:38 2025-09-30           3.59               2          3.6 
    #>  47 2025-09-29 05:58:38 2025-11-04           3.46              37          3.59
    #>  48 2025-09-29 05:58:38 2025-12-09           3.41              72          3.46
    #>  49 2025-09-29 05:58:38 2026-02-03           3.34             128          3.41
    #>  50 2025-09-29 05:58:38 2026-03-17           3.36             170          3.34
    #>  51 2025-09-29 05:58:38 2026-05-05           2.93             219          3.36
    #>  52 2025-09-29 05:58:38 2026-06-16           3.12             261          2.93
    #>  53 2025-09-29 05:58:38 2026-08-11           3.36             317          3.12
    #>  54 2025-09-29 05:58:38 2026-09-29           3.29             366          3.36
    #>  55 2025-09-29 05:58:38 2026-11-03           3.30             401          3.29
    #>  56 2025-09-29 05:58:38 2026-12-08           3.31             436          3.30
    #>  57 2025-09-29 06:41:13 2025-09-30           3.59               2          3.6 
    #>  58 2025-09-29 06:41:13 2025-11-04           3.46              37          3.59
    #>  59 2025-09-29 06:41:13 2025-12-09           3.41              72          3.46
    #>  60 2025-09-29 06:41:13 2026-02-03           3.34             128          3.41
    #>  61 2025-09-29 06:41:13 2026-03-17           3.36             170          3.34
    #>  62 2025-09-29 06:41:13 2026-05-05           2.93             219          3.36
    #>  63 2025-09-29 06:41:13 2026-06-16           3.12             261          2.93
    #>  64 2025-09-29 06:41:13 2026-08-11           3.36             317          3.12
    #>  65 2025-09-29 06:41:13 2026-09-29           3.29             366          3.36
    #>  66 2025-09-29 06:41:13 2026-11-03           3.30             401          3.29
    #>  67 2025-09-29 06:41:13 2026-12-08           3.31             436          3.30
    #>  68 2025-09-29 06:57:35 2025-09-30           3.59               2          3.6 
    #>  69 2025-09-29 06:57:35 2025-11-04           3.46              37          3.59
    #>  70 2025-09-29 06:57:35 2025-12-09           3.41              72          3.46
    #>  71 2025-09-29 06:57:35 2026-02-03           3.34             128          3.41
    #>  72 2025-09-29 06:57:35 2026-03-17           3.36             170          3.34
    #>  73 2025-09-29 06:57:35 2026-05-05           2.93             219          3.36
    #>  74 2025-09-29 06:57:35 2026-06-16           3.12             261          2.93
    #>  75 2025-09-29 06:57:35 2026-08-11           3.31             317          3.12
    #>  76 2025-09-29 06:57:35 2026-09-29           3.26             366          3.31
    #>  77 2025-09-29 06:57:35 2026-11-03           3.27             401          3.26
    #>  78 2025-09-29 06:57:35 2026-12-08           3.28             436          3.27
    #>  79 2025-09-29 12:19:06 2025-09-30           3.59               1          3.6 
    #>  80 2025-09-29 12:19:06 2025-11-04           3.46              36          3.59
    #>  81 2025-09-29 12:19:06 2025-12-09           3.41              71          3.46
    #>  82 2025-09-29 12:19:06 2026-02-03           3.34             127          3.41
    #>  83 2025-09-29 12:19:06 2026-03-17           3.36             169          3.34
    #>  84 2025-09-29 12:19:06 2026-05-05           2.93             218          3.36
    #>  85 2025-09-29 12:19:06 2026-06-16           3.12             260          2.93
    #>  86 2025-09-29 12:19:06 2026-08-11           3.31             316          3.12
    #>  87 2025-09-29 12:19:06 2026-09-29           3.26             365          3.31
    #>  88 2025-09-29 12:19:06 2026-11-03           3.27             400          3.26
    #>  89 2025-09-29 12:19:06 2026-12-08           3.28             435          3.27
    #>  90 2025-09-29 12:28:34 2025-09-30           3.59               1          3.6 
    #>  91 2025-09-29 12:28:34 2025-11-04           3.46              36          3.59
    #>  92 2025-09-29 12:28:34 2025-12-09           3.41              71          3.46
    #>  93 2025-09-29 12:28:34 2026-02-03           3.34             127          3.41
    #>  94 2025-09-29 12:28:34 2026-03-17           3.36             169          3.34
    #>  95 2025-09-29 12:28:34 2026-05-05           2.93             218          3.36
    #>  96 2025-09-29 12:28:34 2026-06-16           3.12             260          2.93
    #>  97 2025-09-29 12:28:34 2026-08-11           3.31             316          3.12
    #>  98 2025-09-29 12:28:34 2026-09-29           3.26             365          3.31
    #>  99 2025-09-29 12:28:34 2026-11-03           3.27             400          3.26
    #> 100 2025-09-29 12:28:34 2026-12-08           3.28             435          3.27
    #>      stdev
    #>      <dbl>
    #>   1 1.23  
    #>   2 0.0639
    #>   3 0.129 
    #>   4 0.340 
    #>   5 0.448 
    #>   6 0.678 
    #>   7 0.846 
    #>   8 0.943 
    #>   9 1.06  
    #>  10 1.06  
    #>  11 1.11  
    #>  12 1.23  
    #>  13 0.0639
    #>  14 0.129 
    #>  15 0.340 
    #>  16 0.448 
    #>  17 0.678 
    #>  18 0.846 
    #>  19 0.943 
    #>  20 1.06  
    #>  21 1.06  
    #>  22 1.11  
    #>  23 1.23  
    #>  24 0.0639
    #>  25 0.129 
    #>  26 0.340 
    #>  27 0.448 
    #>  28 0.678 
    #>  29 0.846 
    #>  30 0.943 
    #>  31 1.06  
    #>  32 1.06  
    #>  33 1.11  
    #>  34 1.23  
    #>  35 0.0639
    #>  36 0.129 
    #>  37 0.340 
    #>  38 0.448 
    #>  39 0.678 
    #>  40 0.846 
    #>  41 0.943 
    #>  42 1.06  
    #>  43 1.06  
    #>  44 1.11  
    #>  45 1.23  
    #>  46 0.0639
    #>  47 0.129 
    #>  48 0.340 
    #>  49 0.448 
    #>  50 0.678 
    #>  51 0.846 
    #>  52 0.943 
    #>  53 1.06  
    #>  54 1.06  
    #>  55 1.11  
    #>  56 1.23  
    #>  57 0.0639
    #>  58 0.129 
    #>  59 0.340 
    #>  60 0.448 
    #>  61 0.678 
    #>  62 0.846 
    #>  63 0.943 
    #>  64 1.06  
    #>  65 1.06  
    #>  66 1.11  
    #>  67 1.23  
    #>  68 0.0639
    #>  69 0.129 
    #>  70 0.340 
    #>  71 0.448 
    #>  72 0.678 
    #>  73 0.846 
    #>  74 0.943 
    #>  75 1.06  
    #>  76 1.06  
    #>  77 1.11  
    #>  78 1.23  
    #>  79 0.0639
    #>  80 0.126 
    #>  81 0.339 
    #>  82 0.448 
    #>  83 0.678 
    #>  84 0.846 
    #>  85 0.941 
    #>  86 1.06  
    #>  87 1.06  
    #>  88 1.10  
    #>  89 1.23  
    #>  90 0.0639
    #>  91 0.126 
    #>  92 0.339 
    #>  93 0.448 
    #>  94 0.678 
    #>  95 0.846 
    #>  96 0.941 
    #>  97 1.06  
    #>  98 1.06  
    #>  99 1.10  
    #> 100 1.23
    #> Warning: All formats failed to parse. No formats found.
    #> Warning: All formats failed to parse. No formats found.
    #> # A tibble: 20 × 11
    #>    scrape_time         meeting_date implied_mean stdev days_to_meeting bucket
    #>    <dttm>              <date>              <dbl> <dbl>           <int>  <dbl>
    #>  1 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   1.35
    #>  2 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   1.6 
    #>  3 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   1.85
    #>  4 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   2.1 
    #>  5 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   2.35
    #>  6 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   2.6 
    #>  7 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   2.85
    #>  8 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   3.1 
    #>  9 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   3.35
    #> 10 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   3.6 
    #> 11 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   3.85
    #> 12 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   4.1 
    #> 13 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   4.35
    #> 14 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   4.6 
    #> 15 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   4.85
    #> 16 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   5.1 
    #> 17 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   5.35
    #> 18 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   5.6 
    #> 19 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   5.85
    #> 20 2025-09-29 12:28:34 2026-12-08           3.28  1.23             435   6.1 
    #>    probability_linear probability_prob probability   diff diff_s
    #>                 <dbl>            <dbl>       <dbl>  <dbl>  <dbl>
    #>  1              0               0.0247      0.0247 -2.25  -1.22 
    #>  2              0               0.0333      0.0333 -2     -1.19 
    #>  3              0               0.0431      0.0431 -1.75  -1.15 
    #>  4              0               0.0535      0.0535 -1.5   -1.11 
    #>  5              0               0.0637      0.0637 -1.25  -1.06 
    #>  6              0               0.0728      0.0728 -1     -1    
    #>  7              0               0.0798      0.0798 -0.75  -0.931
    #>  8              0.289           0.0839      0.0839 -0.5   -0.841
    #>  9              0.711           0.0846      0.0846 -0.25  -0.707
    #> 10              0               0.0819      0.0819  0      0    
    #> 11              0               0.0760      0.0760  0.25   0.707
    #> 12              0               0.0677      0.0677  0.500  0.841
    #> 13              0               0.0579      0.0579  0.750  0.931
    #> 14              0               0.0475      0.0475  1      1    
    #> 15              0               0.0373      0.0373  1.25   1.06 
    #> 16              0               0.0282      0.0282  1.5    1.11 
    #> 17              0               0.0204      0.0204  1.75   1.15 
    #> 18              0               0.0142      0.0142  2      1.19 
    #> 19              0               0           0       2.25   1.22 
    #> 20              0               0           0       2.5    1.26
    #> [1] "2025-09-30"
    #> Warning: Removed 66 rows containing missing values or values outside the scale range
    #> (`geom_vline()`).
    #> Creating extended buckets for 7222 estimate rows
    #> Bucket range: 0.1 to 6.1 
    #> Extended buckets created: 180550 rows
    #> Unique moves: 23 
    #> ✓ all_estimates_buckets_ext created successfully
    #> Future meetings found: 11 
    #> Meetings: 2025-09-30, 2025-11-04, 2025-12-09, 2026-02-03, 2026-03-17, 2026-05-05, 2026-06-16, 2026-08-11, 2026-09-29, 2026-11-03, 2026-12-08 
    #> 
    #> === Processing meeting: 2025-09-30 ===
    #> Initial df_mt dimensions: 16325 x 3 
    #> Pre-cleaning data summary:
    #>   - NA scrape_time: 0 
    #>   - NA probability: 0 
    #>   - NA move: 0 
    #>   - Negative probability: 0 
    #>   - Infinite probability: 0 
    #> After cleaning dimensions: 16325 x 3 
    #> Unique times: 653 
    #> Unique moves: 25 
    #> Raw time range: 2025-08-12 00:01:37 2025-09-29 12:28:34 
    #> Plot time limits: 2025-08-12 10:01:37 to 2025-09-30 17:00:00 
    #> Time span (days): 0.0005704924 
    #> Available moves ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Valid move levels ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Final data dimensions: 16325 x 3 
    #> Probability statistics:
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #>  0.0000  0.0000  0.0000  0.0400  0.0000  0.9779 
    #> Probability sums by time (should be around 1.0):
    #>   Min: 1 
    #>   Max: 1 
    #>   Mean: 1 
    #> Fill map subset length: 23 
    #> Missing colors for moves: +275 bp hike +300 bp hike 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2025-09-30.png 
    #> Creating ggplot object...
    #> Adding geom_area...
    #> Adding fill scale...
    #> Adding x-axis scale...
    #> Adding y-axis scale...
    #> Adding labels...
    #> Scale for fill is already present.
    #> Adding another scale for fill, which will replace the existing scale.
    #> Adding theme...
    #> Saving plot...
    #> Warning: Removed 1057 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2025-09-30 
    #> --- End meeting processing ---
    #> 
    #> === Processing meeting: 2025-11-04 ===
    #> Initial df_mt dimensions: 16325 x 3 
    #> Pre-cleaning data summary:
    #>   - NA scrape_time: 0 
    #>   - NA probability: 0 
    #>   - NA move: 0 
    #>   - Negative probability: 0 
    #>   - Infinite probability: 0 
    #> After cleaning dimensions: 16325 x 3 
    #> Unique times: 653 
    #> Unique moves: 25 
    #> Raw time range: 2025-08-12 00:01:37 2025-09-29 12:28:34 
    #> Plot time limits: 2025-08-12 10:01:37 to 2025-11-04 17:00:00 
    #> Time span (days): 0.0009751027 
    #> Available moves ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Valid move levels ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Final data dimensions: 16325 x 3 
    #> Probability statistics:
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #>  0.0000  0.0000  0.0000  0.0400  0.0000  0.5575 
    #> Probability sums by time (should be around 1.0):
    #>   Min: 1 
    #>   Max: 1 
    #>   Mean: 1 
    #> Fill map subset length: 23 
    #> Missing colors for moves: +275 bp hike +300 bp hike 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2025-11-04.png 
    #> Creating ggplot object...
    #> Adding geom_area...
    #> Adding fill scale...
    #> Adding x-axis scale...
    #> Adding y-axis scale...
    #> Adding labels...
    #> Scale for fill is already present.
    #> Adding another scale for fill, which will replace the existing scale.
    #> Adding theme...
    #> Saving plot...
    #> Warning: Removed 892 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> DETAILED ERROR INFORMATION:
    #> Error class: rlang_error error condition 
    #> Error message: Problem while converting geom to grob. 
    #> Error call: ggplot2::geom_area(position = "stack", alpha = 0.95, colour = NA) 
    #> DIAGNOSIS: geom_area rendering issue detected
    #> Possible causes:
    #>   1. Too many factor levels causing memory issues
    #>   2. Invalid datetime values in x-axis
    #>   3. Extreme probability values causing rendering problems
    #>   4. Color mapping issues
    #> 
    #> Factor level count: 25 
    #> Color mapping completeness: FALSE 
    #> X-axis value range: 1754956897 1759148914 
    #> X-axis contains infinite values: FALSE 
    #> Attempting minimal diagnostic plot...
    #> Reduced to 16325 rows with 25 moves
    #> ✓ Saved minimal plot to: docs/meetings/minimal_2025-11-04.png 
    #> ❌ Failed to create main plot for meeting 2025-11-04 
    #> --- End meeting processing ---
    #> 
    #> === Processing meeting: 2025-12-09 ===
    #> Initial df_mt dimensions: 16325 x 3 
    #> Pre-cleaning data summary:
    #>   - NA scrape_time: 0 
    #>   - NA probability: 0 
    #>   - NA move: 0 
    #>   - Negative probability: 0 
    #>   - Infinite probability: 0 
    #> After cleaning dimensions: 16325 x 3 
    #> Unique times: 653 
    #> Unique moves: 25 
    #> Raw time range: 2025-08-12 00:01:37 2025-09-29 12:28:34 
    #> Plot time limits: 2025-08-12 10:01:37 to 2025-12-09 17:00:00 
    #> Time span (days): 0.001380195 
    #> Available moves ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Valid move levels ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Final data dimensions: 16325 x 3 
    #> Probability statistics:
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #> 0.00000 0.00000 0.00000 0.04000 0.03612 0.28583 
    #> Probability sums by time (should be around 1.0):
    #>   Min: 1 
    #>   Max: 1 
    #>   Mean: 1 
    #> Fill map subset length: 23 
    #> Missing colors for moves: +275 bp hike +300 bp hike 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2025-12-09.png 
    #> Creating ggplot object...
    #> Adding geom_area...
    #> Adding fill scale...
    #> Adding x-axis scale...
    #> Adding y-axis scale...
    #> Adding labels...
    #> Scale for fill is already present.
    #> Adding another scale for fill, which will replace the existing scale.
    #> Adding theme...
    #> Saving plot...
    #> Warning: Removed 1483 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2025-12-09 
    #> --- End meeting processing ---
    #> 
    #> === Processing meeting: 2026-02-03 ===
    #> Initial df_mt dimensions: 16325 x 3 
    #> Pre-cleaning data summary:
    #>   - NA scrape_time: 0 
    #>   - NA probability: 0 
    #>   - NA move: 0 
    #>   - Negative probability: 0 
    #>   - Infinite probability: 0 
    #> After cleaning dimensions: 16325 x 3 
    #> Unique times: 653 
    #> Unique moves: 25 
    #> Raw time range: 2025-08-12 00:01:37 2025-09-29 12:28:34 
    #> Plot time limits: 2025-08-12 10:01:37 to 2026-02-03 17:00:00 
    #> Time span (days): 0.002028343 
    #> Available moves ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Valid move levels ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Final data dimensions: 16325 x 3 
    #> Probability statistics:
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #> 0.00000 0.00000 0.00000 0.04000 0.07081 0.22254 
    #> Probability sums by time (should be around 1.0):
    #>   Min: 1 
    #>   Max: 1 
    #>   Mean: 1 
    #> Fill map subset length: 23 
    #> Missing colors for moves: +275 bp hike +300 bp hike 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-02-03.png 
    #> Creating ggplot object...
    #> Adding geom_area...
    #> Adding fill scale...
    #> Adding x-axis scale...
    #> Adding y-axis scale...
    #> Adding labels...
    #> Scale for fill is already present.
    #> Adding another scale for fill, which will replace the existing scale.
    #> Adding theme...
    #> Saving plot...
    #> Warning: Removed 2137 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-02-03 
    #> --- End meeting processing ---
    #> 
    #> === Processing meeting: 2026-03-17 ===
    #> Initial df_mt dimensions: 16325 x 3 
    #> Pre-cleaning data summary:
    #>   - NA scrape_time: 0 
    #>   - NA probability: 0 
    #>   - NA move: 0 
    #>   - Negative probability: 0 
    #>   - Infinite probability: 0 
    #> After cleaning dimensions: 16325 x 3 
    #> Unique times: 653 
    #> Unique moves: 25 
    #> Raw time range: 2025-08-12 00:01:37 2025-09-29 12:28:34 
    #> Plot time limits: 2025-08-12 10:01:37 to 2026-03-17 17:00:00 
    #> Time span (days): 0.002514455 
    #> Available moves ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Valid move levels ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Final data dimensions: 16325 x 3 
    #> Probability statistics:
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #> 0.00000 0.00000 0.01547 0.04000 0.07565 0.14872 
    #> Probability sums by time (should be around 1.0):
    #>   Min: 1 
    #>   Max: 1 
    #>   Mean: 1 
    #> Fill map subset length: 23 
    #> Missing colors for moves: +275 bp hike +300 bp hike 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-03-17.png 
    #> Creating ggplot object...
    #> Adding geom_area...
    #> Adding fill scale...
    #> Adding x-axis scale...
    #> Adding y-axis scale...
    #> Adding labels...
    #> Scale for fill is already present.
    #> Adding another scale for fill, which will replace the existing scale.
    #> Adding theme...
    #> Saving plot...
    #> Warning: Removed 2204 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-03-17 
    #> --- End meeting processing ---
    #> 
    #> === Processing meeting: 2026-05-05 ===
    #> Initial df_mt dimensions: 16325 x 3 
    #> Pre-cleaning data summary:
    #>   - NA scrape_time: 0 
    #>   - NA probability: 0 
    #>   - NA move: 0 
    #>   - Negative probability: 0 
    #>   - Infinite probability: 0 
    #> After cleaning dimensions: 16325 x 3 
    #> Unique times: 653 
    #> Unique moves: 25 
    #> Raw time range: 2025-08-12 00:01:37 2025-09-29 12:28:34 
    #> Plot time limits: 2025-08-12 10:01:37 to 2026-05-05 17:00:00 
    #> Time span (days): 0.003082066 
    #> Available moves ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Valid move levels ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Final data dimensions: 16325 x 3 
    #> Probability statistics:
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #> 0.00000 0.00000 0.02279 0.04000 0.07262 0.12027 
    #> Probability sums by time (should be around 1.0):
    #>   Min: 1 
    #>   Max: 1 
    #>   Mean: 1 
    #> Fill map subset length: 23 
    #> Missing colors for moves: +275 bp hike +300 bp hike 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-05-05.png 
    #> Creating ggplot object...
    #> Adding geom_area...
    #> Adding fill scale...
    #> Adding x-axis scale...
    #> Adding y-axis scale...
    #> Adding labels...
    #> Scale for fill is already present.
    #> Adding another scale for fill, which will replace the existing scale.
    #> Adding theme...
    #> Saving plot...
    #> Warning: Removed 2359 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-05-05 
    #> --- End meeting processing ---
    #> 
    #> === Processing meeting: 2026-06-16 ===
    #> Initial df_mt dimensions: 16325 x 3 
    #> Pre-cleaning data summary:
    #>   - NA scrape_time: 0 
    #>   - NA probability: 0 
    #>   - NA move: 0 
    #>   - Negative probability: 0 
    #>   - Infinite probability: 0 
    #> After cleaning dimensions: 16325 x 3 
    #> Unique times: 653 
    #> Unique moves: 25 
    #> Raw time range: 2025-08-12 00:01:37 2025-09-29 12:28:34 
    #> Plot time limits: 2025-08-12 10:01:37 to 2026-06-16 17:00:00 
    #> Time span (days): 0.003568178 
    #> Available moves ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Valid move levels ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Final data dimensions: 16325 x 3 
    #> Probability statistics:
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #> 0.00000 0.00000 0.03411 0.04000 0.07509 0.10826 
    #> Probability sums by time (should be around 1.0):
    #>   Min: 1 
    #>   Max: 1 
    #>   Mean: 1 
    #> Fill map subset length: 23 
    #> Missing colors for moves: +275 bp hike +300 bp hike 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-06-16.png 
    #> Creating ggplot object...
    #> Adding geom_area...
    #> Adding fill scale...
    #> Adding x-axis scale...
    #> Adding y-axis scale...
    #> Adding labels...
    #> Scale for fill is already present.
    #> Adding another scale for fill, which will replace the existing scale.
    #> Adding theme...
    #> Saving plot...
    #> Warning: Removed 1981 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-06-16 
    #> --- End meeting processing ---
    #> 
    #> === Processing meeting: 2026-08-11 ===
    #> Initial df_mt dimensions: 16325 x 3 
    #> Pre-cleaning data summary:
    #>   - NA scrape_time: 0 
    #>   - NA probability: 0 
    #>   - NA move: 0 
    #>   - Negative probability: 0 
    #>   - Infinite probability: 0 
    #> After cleaning dimensions: 16325 x 3 
    #> Unique times: 653 
    #> Unique moves: 25 
    #> Raw time range: 2025-08-12 00:01:37 2025-09-29 12:28:34 
    #> Plot time limits: 2025-08-12 10:01:37 to 2026-08-11 17:00:00 
    #> Time span (days): 0.004216326 
    #> Available moves ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Valid move levels ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Final data dimensions: 16325 x 3 
    #> Probability statistics:
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #> 0.00000 0.00000 0.03322 0.04000 0.07451 0.09710 
    #> Probability sums by time (should be around 1.0):
    #>   Min: 1 
    #>   Max: 1 
    #>   Mean: 1 
    #> Fill map subset length: 23 
    #> Missing colors for moves: +275 bp hike +300 bp hike 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-08-11.png 
    #> Creating ggplot object...
    #> Adding geom_area...
    #> Adding fill scale...
    #> Adding x-axis scale...
    #> Adding y-axis scale...
    #> Adding labels...
    #> Scale for fill is already present.
    #> Adding another scale for fill, which will replace the existing scale.
    #> Adding theme...
    #> Saving plot...
    #> Warning: Removed 1866 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-08-11 
    #> --- End meeting processing ---
    #> 
    #> === Processing meeting: 2026-09-29 ===
    #> Initial df_mt dimensions: 16325 x 3 
    #> Pre-cleaning data summary:
    #>   - NA scrape_time: 0 
    #>   - NA probability: 0 
    #>   - NA move: 0 
    #>   - Negative probability: 0 
    #>   - Infinite probability: 0 
    #> After cleaning dimensions: 16325 x 3 
    #> Unique times: 653 
    #> Unique moves: 25 
    #> Raw time range: 2025-08-12 00:01:37 2025-09-29 12:28:34 
    #> Plot time limits: 2025-08-12 10:01:37 to 2026-09-29 17:00:00 
    #> Time span (days): 0.004783455 
    #> Available moves ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Valid move levels ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Final data dimensions: 16325 x 3 
    #> Probability statistics:
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #> 0.00000 0.00000 0.03475 0.04000 0.07374 0.09709 
    #> Probability sums by time (should be around 1.0):
    #>   Min: 1 
    #>   Max: 1 
    #>   Mean: 1 
    #> Fill map subset length: 23 
    #> Missing colors for moves: +275 bp hike +300 bp hike 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-09-29.png 
    #> Creating ggplot object...
    #> Adding geom_area...
    #> Adding fill scale...
    #> Adding x-axis scale...
    #> Adding y-axis scale...
    #> Adding labels...
    #> Scale for fill is already present.
    #> Adding another scale for fill, which will replace the existing scale.
    #> Adding theme...
    #> Saving plot...
    #> Warning: Removed 800 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-09-29 
    #> --- End meeting processing ---
    #> 
    #> === Processing meeting: 2026-11-03 ===
    #> Initial df_mt dimensions: 16325 x 3 
    #> Pre-cleaning data summary:
    #>   - NA scrape_time: 0 
    #>   - NA probability: 0 
    #>   - NA move: 0 
    #>   - Negative probability: 0 
    #>   - Infinite probability: 0 
    #> After cleaning dimensions: 16325 x 3 
    #> Unique times: 653 
    #> Unique moves: 25 
    #> Raw time range: 2025-08-12 00:01:37 2025-09-29 12:28:34 
    #> Plot time limits: 2025-08-12 10:01:37 to 2026-11-03 17:00:00 
    #> Time span (days): 0.005188066 
    #> Available moves ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Valid move levels ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Final data dimensions: 16325 x 3 
    #> Probability statistics:
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #> 0.00000 0.01318 0.03768 0.04000 0.07114 0.09380 
    #> Probability sums by time (should be around 1.0):
    #>   Min: 1 
    #>   Max: 1 
    #>   Mean: 1 
    #> Fill map subset length: 23 
    #> Missing colors for moves: +275 bp hike +300 bp hike 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-11-03.png 
    #> Creating ggplot object...
    #> Adding geom_area...
    #> Adding fill scale...
    #> Adding x-axis scale...
    #> Adding y-axis scale...
    #> Adding labels...
    #> Scale for fill is already present.
    #> Adding another scale for fill, which will replace the existing scale.
    #> Adding theme...
    #> Saving plot...
    #> Warning: Removed 2353 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> DETAILED ERROR INFORMATION:
    #> Error class: rlang_error error condition 
    #> Error message: Problem while converting geom to grob. 
    #> Error call: ggplot2::geom_area(position = "stack", alpha = 0.95, colour = NA) 
    #> DIAGNOSIS: geom_area rendering issue detected
    #> Possible causes:
    #>   1. Too many factor levels causing memory issues
    #>   2. Invalid datetime values in x-axis
    #>   3. Extreme probability values causing rendering problems
    #>   4. Color mapping issues
    #> 
    #> Factor level count: 25 
    #> Color mapping completeness: FALSE 
    #> X-axis value range: 1754956897 1759148914 
    #> X-axis contains infinite values: FALSE 
    #> Attempting minimal diagnostic plot...
    #> Reduced to 6530 rows with 10 moves
    #> ✓ Saved minimal plot to: docs/meetings/minimal_2026-11-03.png 
    #> ❌ Failed to create main plot for meeting 2026-11-03 
    #> --- End meeting processing ---
    #> 
    #> === Processing meeting: 2026-12-08 ===
    #> Initial df_mt dimensions: 16325 x 3 
    #> Pre-cleaning data summary:
    #>   - NA scrape_time: 0 
    #>   - NA probability: 0 
    #>   - NA move: 0 
    #>   - Negative probability: 0 
    #>   - Infinite probability: 0 
    #> After cleaning dimensions: 16325 x 3 
    #> Unique times: 653 
    #> Unique moves: 25 
    #> Raw time range: 2025-08-12 00:01:37 2025-09-29 12:28:34 
    #> Plot time limits: 2025-08-12 10:01:37 to 2026-12-08 17:00:00 
    #> Time span (days): 0.005593158 
    #> Available moves ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Valid move levels ( 25 ): 300 bp cut, 275 bp cut, 250 bp cut, 225 bp cut, 200 bp cut, 175 bp cut, 150 bp cut, 125 bp cut, 100 bp cut, 75 bp cut 
    #> Final data dimensions: 16325 x 3 
    #> Probability statistics:
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #> 0.00000 0.01528 0.03882 0.04000 0.06817 0.08472 
    #> Probability sums by time (should be around 1.0):
    #>   Min: 1 
    #>   Max: 1 
    #>   Mean: 1 
    #> Fill map subset length: 23 
    #> Missing colors for moves: +275 bp hike +300 bp hike 
    #> Attempting to create plot and save to: docs/meetings/area_all_moves_2026-12-08.png 
    #> Creating ggplot object...
    #> Adding geom_area...
    #> Adding fill scale...
    #> Adding x-axis scale...
    #> Adding y-axis scale...
    #> Adding labels...
    #> Scale for fill is already present.
    #> Adding another scale for fill, which will replace the existing scale.
    #> Adding theme...
    #> Saving plot...
    #> Warning: Removed 1971 rows containing missing values or values outside the scale range
    #> (`geom_area()`).
    #> ✓ Successfully saved plot for 2026-12-08 
    #> --- End meeting processing ---
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
