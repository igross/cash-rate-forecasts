
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
    #> Warning: There was 1 warning in `mutate()`.
    #> ℹ In argument: `days_to_meeting = as.integer(next_meeting - scrape_time)`.
    #> Caused by warning:
    #> ! Incompatible methods ("-.Date", "-.POSIXt") for "-"
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
    #> 12 2025-04-20 13:05:58              4.08           3.98 0.613          3.82
    #> # ℹ 2 more variables: days_to_meeting <int>, RMSE <dbl>
    #> # A tibble: 0 × 0
    #> # A tibble: 36 × 6
    #>    scrape_date            mu sigma r_curr probability bucket    
    #>    <dttm>              <dbl> <dbl>  <dbl>       <dbl> <fct>     
    #>  1 2025-04-03 12:00:00  3.88    NA   4.08          NA -50 bp cut
    #>  2 2025-04-03 12:00:00  3.88    NA   4.08          NA -25 bp cut
    #>  3 2025-04-03 12:00:00  3.88    NA   4.08          NA No change 
    #>  4 2025-04-04 12:00:00  3.80    NA   4.08          NA -50 bp cut
    #>  5 2025-04-04 12:00:00  3.80    NA   4.08          NA -25 bp cut
    #>  6 2025-04-04 12:00:00  3.80    NA   4.08          NA No change 
    #>  7 2025-04-07 12:00:00  3.72    NA   4.05          NA -50 bp cut
    #>  8 2025-04-07 12:00:00  3.72    NA   4.05          NA -25 bp cut
    #>  9 2025-04-07 12:00:00  3.72    NA   4.05          NA No change 
    #> 10 2025-04-08 12:00:00  3.76    NA   4.07          NA -50 bp cut
    #> 11 2025-04-08 12:00:00  3.76    NA   4.07          NA -25 bp cut
    #> 12 2025-04-08 12:00:00  3.76    NA   4.07          NA No change 
    #> 13 2025-04-09 12:00:00  3.64    NA   4.05          NA -50 bp cut
    #> 14 2025-04-09 12:00:00  3.64    NA   4.05          NA -25 bp cut
    #> 15 2025-04-09 12:00:00  3.64    NA   4.05          NA No change 
    #> # ℹ 21 more rows
    #> Warning: Removed 36 rows containing missing values or values outside the scale range
    #> (`geom_line()`).
    #> Warning: Removed 36 rows containing missing values or values outside the scale range
    #> (`geom_point()`).
