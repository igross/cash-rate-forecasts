
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

    #> Warning: Position guide is perpendicular to the intended axis.
    #> ℹ Did you mean to specify a different guide `position`?
    #> Warning: Removed 21 rows containing missing values or values outside the scale range
    #> (`geom_bar()`).
    #> [1] "Apr 2025"
    #> [1] "May 2025"
    #> [1] "Jul 2025"
    #> [1] "Aug 2025"
    #> [1] "Sep 2025"
    #> [1] "Nov 2025"
    #> [1] "Dec 2025"
    #> # A tibble: 24 × 4
    #>    scrape_date scrape_time         date       cash_rate
    #>    <date>      <dttm>              <date>         <dbl>
    #>  1 2025-04-03  2025-04-03 12:00:00 2025-04-01      4.08
    #>  2 2025-04-03  2025-04-03 12:00:00 2025-05-01      4   
    #>  3 2025-04-04  2025-04-04 12:00:00 2025-04-01      4.08
    #>  4 2025-04-04  2025-04-04 12:00:00 2025-05-01      3.97
    #>  5 2025-04-07  2025-04-07 12:00:00 2025-04-01      4.05
    #>  6 2025-04-07  2025-04-07 12:00:00 2025-05-01      3.92
    #>  7 2025-04-08  2025-04-08 12:00:00 2025-04-01      4.07
    #>  8 2025-04-08  2025-04-08 12:00:00 2025-05-01      3.94
    #>  9 2025-04-09  2025-04-09 12:00:00 2025-04-01      4.05
    #> 10 2025-04-09  2025-04-09 12:00:00 2025-05-01      3.88
    #> # ℹ 14 more rows
    #> [1] 0.01
    #> # A tibble: 730 × 2
    #>    days_to_meeting finalrmse
    #>              <int>     <dbl>
    #>  1               1    0.0639
    #>  2               2    0.0639
    #>  3               3    0.0639
    #>  4               4    0.0639
    #>  5               5    0.0639
    #>  6               6    0.0639
    #>  7               7    0.0639
    #>  8               8    0.0639
    #>  9               9    0.0639
    #> 10              10    0.0639
    #> # ℹ 720 more rows
    #> # A tibble: 12 × 7
    #>    scrape_time         cash_rate_current cash_rate_next    nb implied_r_tp1
    #>    <dttm>                          <dbl>          <dbl> <dbl>         <dbl>
    #>  1 2025-04-03 12:00:00              4.08           4    0.613          3.88
    #>  2 2025-04-04 12:00:00              4.08           3.97 0.613          3.80
    #>  3 2025-04-07 12:00:00              4.05           3.92 0.613          3.72
    #>  4 2025-04-08 12:00:00              4.07           3.94 0.613          3.76
    #>  5 2025-04-09 12:00:00              4.05           3.88 0.613          3.64
    #>  6 2025-04-10 12:00:00              4.08           3.96 0.613          3.79
    #>  7 2025-04-11 12:00:00              4.08           3.95 0.613          3.76
    #>  8 2025-04-14 12:00:00              4.08           3.95 0.613          3.75
    #>  9 2025-04-16 12:00:00              4.08           3.97 0.613          3.79
    #> 10 2025-04-17 12:00:00              4.08           3.98 0.613          3.82
    #> 11 2025-04-19 14:00:34              4.08           3.98 0.613          3.82
    #> 12 2025-04-20 14:09:26              4.08           3.98 0.613          3.82
    #>    days_to_meeting  RMSE
    #>              <int> <dbl>
    #>  1              47 0.175
    #>  2              46 0.168
    #>  3              43 0.156
    #>  4              42 0.154
    #>  5              41 0.146
    #>  6              40 0.138
    #>  7              39 0.135
    #>  8              36 0.126
    #>  9              34 0.121
    #> 10              33 0.116
    #> 11              31 0.111
    #> 12              30 0.109
    #> # A tibble: 252 × 3
    #>    scrape_time         bucket probability
    #>    <dttm>              <chr>        <dbl>
    #>  1 2025-04-03 12:00:00 0.10%    2.30e- 97
    #>  2 2025-04-03 12:00:00 0.35%    8.89e- 85
    #>  3 2025-04-03 12:00:00 0.60%    4.44e- 73
    #>  4 2025-04-03 12:00:00 0.85%    2.87e- 62
    #>  5 2025-04-03 12:00:00 1.10%    2.41e- 52
    #>  6 2025-04-03 12:00:00 1.35%    2.62e- 43
    #>  7 2025-04-03 12:00:00 1.60%    3.71e- 35
    #>  8 2025-04-03 12:00:00 1.85%    6.85e- 28
    #>  9 2025-04-03 12:00:00 2.10%    1.65e- 21
    #> 10 2025-04-03 12:00:00 2.35%    5.26e- 16
    #> 11 2025-04-03 12:00:00 2.60%    2.22e- 11
    #> 12 2025-04-03 12:00:00 2.85%    1.25e-  7
    #> 13 2025-04-03 12:00:00 3.10%    9.75e-  5
    #> 14 2025-04-03 12:00:00 3.35%    1.08e-  2
    #> 15 2025-04-03 12:00:00 3.60%    1.84e-  1
    #> 16 2025-04-03 12:00:00 3.85%    5.21e-  1
    #> 17 2025-04-03 12:00:00 4.10%    2.62e-  1
    #> 18 2025-04-03 12:00:00 4.35%    2.23e-  2
    #> 19 2025-04-03 12:00:00 4.60%    2.97e-  4
    #> 20 2025-04-03 12:00:00 4.85%    5.70e-  7
    #> 21 2025-04-03 12:00:00 5.10%    1.51e- 10
    #> 22 2025-04-04 12:00:00 0.10%    3.11e-101
    #> 23 2025-04-04 12:00:00 0.35%    7.13e- 88
    #> 24 2025-04-04 12:00:00 0.60%    1.78e- 75
    #> 25 2025-04-04 12:00:00 0.85%    4.84e- 64
    #> 26 2025-04-04 12:00:00 1.10%    1.44e- 53
    #> 27 2025-04-04 12:00:00 1.35%    4.65e- 44
    #> 28 2025-04-04 12:00:00 1.60%    1.65e- 35
    #> 29 2025-04-04 12:00:00 1.85%    6.42e- 28
    #> 30 2025-04-04 12:00:00 2.10%    2.75e- 21
    #> # ℹ 222 more rows
