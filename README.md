
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

    #> # A tibble: 13,377 × 8
    #>    scrape_time         meeting_date implied_mean stdev bucket probability  diff
    #>    <dttm>              <date>              <dbl> <dbl>  <dbl>       <dbl> <dbl>
    #>  1 2025-04-01 12:00:00 2025-04-01           4.08    NA   0.1           NA -4   
    #>  2 2025-04-01 12:00:00 2025-04-01           4.08    NA   0.35          NA -3.75
    #>  3 2025-04-01 12:00:00 2025-04-01           4.08    NA   0.6           NA -3.5 
    #>  4 2025-04-01 12:00:00 2025-04-01           4.08    NA   0.85          NA -3.25
    #>  5 2025-04-01 12:00:00 2025-04-01           4.08    NA   1.1           NA -3   
    #>  6 2025-04-01 12:00:00 2025-04-01           4.08    NA   1.35          NA -2.75
    #>  7 2025-04-01 12:00:00 2025-04-01           4.08    NA   1.6           NA -2.5 
    #>  8 2025-04-01 12:00:00 2025-04-01           4.08    NA   1.85          NA -2.25
    #>  9 2025-04-01 12:00:00 2025-04-01           4.08    NA   2.1           NA -2   
    #> 10 2025-04-01 12:00:00 2025-04-01           4.08    NA   2.35          NA -1.75
    #> # ℹ 13,367 more rows
    #> # ℹ 1 more variable: diff_s <dbl>
    #> Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
    #> ℹ Please use `linewidth` instead.
    #> This warning is displayed once every 8 hours.
    #> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
    #> generated.
    #> Warning: A numeric `legend.position` argument in `theme()` was deprecated in ggplot2
    #> 3.5.0.
    #> ℹ Please use the `legend.position.inside` argument of `theme()` instead.
    #> This warning is displayed once every 8 hours.
    #> Call `lifecycle::last_lifecycle_warnings()` to see where this warning was
    #> generated.
