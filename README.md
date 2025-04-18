
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
    #>  1 2025-04-01 1%              NA Apr 2025   
    #>  2 2025-04-01 2%              NA Apr 2025   
    #>  3 2025-04-01 3%              NA Apr 2025   
    #>  4 2025-04-01 4%              NA Apr 2025   
    #>  5 2025-04-01 5%              NA Apr 2025   
    #>  6 2025-04-01 6%              NA Apr 2025   
    #>  7 2025-04-01 7%              NA Apr 2025   
    #>  8 2025-04-01 8%              NA Apr 2025   
    #>  9 2025-04-01 9%              NA Apr 2025   
    #> 10 2025-04-01 10%             NA Apr 2025   
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
    #>  1 2025-04-03  0.10%    2.30e- 97
    #>  2 2025-04-03  0.35%    8.89e- 85
    #>  3 2025-04-03  0.60%    4.44e- 73
    #>  4 2025-04-03  0.85%    2.87e- 62
    #>  5 2025-04-03  1.10%    2.41e- 52
    #>  6 2025-04-03  1.35%    2.62e- 43
    #>  7 2025-04-03  1.60%    3.71e- 35
    #>  8 2025-04-03  1.85%    6.85e- 28
    #>  9 2025-04-03  2.10%    1.65e- 21
    #> 10 2025-04-03  2.35%    5.26e- 16
    #> 11 2025-04-03  2.60%    2.22e- 11
    #> 12 2025-04-03  2.85%    1.25e-  7
    #> 13 2025-04-03  3.10%    9.75e-  5
    #> 14 2025-04-03  3.35%    1.08e-  2
    #> 15 2025-04-03  3.60%    1.84e-  1
    #> 16 2025-04-03  3.85%    5.21e-  1
    #> 17 2025-04-03  4.10%    2.62e-  1
    #> 18 2025-04-03  4.35%    2.23e-  2
    #> 19 2025-04-03  4.60%    2.97e-  4
    #> 20 2025-04-03  4.85%    5.70e-  7
    #> 21 2025-04-03  5.10%    1.51e- 10
    #> 22 2025-04-04  0.10%    3.11e-101
    #> 23 2025-04-04  0.35%    7.13e- 88
    #> 24 2025-04-04  0.60%    1.78e- 75
    #> 25 2025-04-04  0.85%    4.84e- 64
    #> 26 2025-04-04  1.10%    1.44e- 53
    #> 27 2025-04-04  1.35%    4.65e- 44
    #> 28 2025-04-04  1.60%    1.65e- 35
    #> 29 2025-04-04  1.85%    6.42e- 28
    #> 30 2025-04-04  2.10%    2.75e- 21
    #> # ℹ 180 more rows
