
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

    #> # A tibble: 294 × 4
    #>    date       bucket probability month_label
    #>    <date>     <chr>        <dbl> <chr>      
    #>  1 2025-04-01 0.1%            NA Apr 2025   
    #>  2 2025-04-01 0.35%           NA Apr 2025   
    #>  3 2025-04-01 0.6%            NA Apr 2025   
    #>  4 2025-04-01 0.85%           NA Apr 2025   
    #>  5 2025-04-01 1.1%            NA Apr 2025   
    #>  6 2025-04-01 1.35%           NA Apr 2025   
    #>  7 2025-04-01 1.6%            NA Apr 2025   
    #>  8 2025-04-01 1.85%           NA Apr 2025   
    #>  9 2025-04-01 2.1%            NA Apr 2025   
    #> 10 2025-04-01 2.35%           NA Apr 2025   
    #> # ℹ 284 more rows
    #> Warning: Position guide is perpendicular to the intended axis.
    #> ℹ Did you mean to specify a different guide `position`?
    #> Warning: Removed 42 rows containing missing values or values outside the scale range
    #> (`geom_bar()`).
    #> [1] "Apr 2025"
    #> [1] "May 2025"
    #> [1] "Jul 2025"
    #> [1] "Aug 2025"
    #> [1] "Sep 2025"
    #> [1] "Nov 2025"
    #> [1] "Dec 2025"
    #> Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
    #> ℹ Please use `linewidth` instead.
    #> This warning is displayed once every 8 hours.
    #> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
    #> generated.
    #> # A tibble: 210 × 3
    #>    scrape_date bucket probability
    #>    <date>      <chr>        <dbl>
    #>  1 2025-04-03  0.10%    1.56e-159
    #>  2 2025-04-03  0.35%    9.73e-139
    #>  3 2025-04-03  0.60%    2.06e-119
    #>  4 2025-04-03  0.85%    1.48e-101
    #>  5 2025-04-03  1.10%    3.60e- 85
    #>  6 2025-04-03  1.35%    2.98e- 70
    #>  7 2025-04-03  1.60%    8.40e- 57
    #>  8 2025-04-03  1.85%    8.08e- 45
    #>  9 2025-04-03  2.10%    2.66e- 34
    #> 10 2025-04-03  2.35%    3.02e- 25
    #> 11 2025-04-03  2.60%    1.19e- 17
    #> 12 2025-04-03  2.85%    1.66e- 11
    #> 13 2025-04-03  3.10%    8.31e-  7
    #> 14 2025-04-03  3.35%    1.59e-  3
    #> 15 2025-04-03  3.60%    1.32e-  1
    #> 16 2025-04-03  3.85%    6.34e-  1
    #> 17 2025-04-03  4.10%    2.27e-  1
    #> 18 2025-04-03  4.35%    5.01e-  3
    #> 19 2025-04-03  4.60%    5.02e-  6
    #> 20 2025-04-03  4.85%    1.95e- 10
    #> 21 2025-04-03  5.10%    2.22e- 16
    #> 22 2025-04-04  0.10%    3.55e-153
    #> 23 2025-04-04  0.35%    8.08e-133
    #> 24 2025-04-04  0.60%    6.23e-114
    #> 25 2025-04-04  0.85%    1.63e- 96
    #> 26 2025-04-04  1.10%    1.45e- 80
    #> 27 2025-04-04  1.35%    4.37e- 66
    #> 28 2025-04-04  1.60%    4.49e- 53
    #> 29 2025-04-04  1.85%    1.58e- 41
    #> 30 2025-04-04  2.10%    1.90e- 31
    #> # ℹ 180 more rows
