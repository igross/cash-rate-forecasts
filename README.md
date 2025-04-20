
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
    #> Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
    #> ℹ Please use `linewidth` instead.
    #> This warning is displayed once every 8 hours.
    #> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
    #> generated.
    #> Warning: There was 1 warning in `mutate()`.
    #> ℹ In argument: `days_to_meeting = as.integer(next_meeting - scrape_time)`.
    #> Caused by warning:
    #> ! Incompatible methods ("-.Date", "-.POSIXt") for "-"
    #> # A tibble: 0 × 0
    #> # A tibble: 252 × 6
    #>    scrape_date            mu sigma r_curr probability bucket
    #>    <dttm>              <dbl> <dbl>  <dbl>       <dbl> <chr> 
    #>  1 2025-04-03 12:00:00  3.88    NA   4.08          NA 0.10% 
    #>  2 2025-04-03 12:00:00  3.88    NA   4.08          NA 0.35% 
    #>  3 2025-04-03 12:00:00  3.88    NA   4.08          NA 0.60% 
    #>  4 2025-04-03 12:00:00  3.88    NA   4.08          NA 0.85% 
    #>  5 2025-04-03 12:00:00  3.88    NA   4.08          NA 1.10% 
    #>  6 2025-04-03 12:00:00  3.88    NA   4.08          NA 1.35% 
    #>  7 2025-04-03 12:00:00  3.88    NA   4.08          NA 1.60% 
    #>  8 2025-04-03 12:00:00  3.88    NA   4.08          NA 1.85% 
    #>  9 2025-04-03 12:00:00  3.88    NA   4.08          NA 2.10% 
    #> 10 2025-04-03 12:00:00  3.88    NA   4.08          NA 2.35% 
    #> 11 2025-04-03 12:00:00  3.88    NA   4.08          NA 2.60% 
    #> 12 2025-04-03 12:00:00  3.88    NA   4.08          NA 2.85% 
    #> 13 2025-04-03 12:00:00  3.88    NA   4.08          NA 3.10% 
    #> 14 2025-04-03 12:00:00  3.88    NA   4.08          NA 3.35% 
    #> 15 2025-04-03 12:00:00  3.88    NA   4.08          NA 3.60% 
    #> # ℹ 237 more rows
    #> Warning: Removed 252 rows containing missing values or values outside the scale range
    #> (`geom_line()`).
    #> Warning: Removed 252 rows containing missing values or values outside the scale range
    #> (`geom_point()`).
