
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

    #> # A tibble: 291 × 9
    #>    scrape_time         meeting_date implied_mean stdev bucket probability   diff
    #>    <dttm>              <date>              <dbl> <dbl>  <dbl>       <dbl>  <dbl>
    #>  1 2025-04-01 12:00:00 2025-05-20           3.90 0.206   3.85      0.443  -0.250
    #>  2 2025-04-01 12:00:00 2025-05-20           3.90 0.206   4.1       0.307   0    
    #>  3 2025-04-01 12:00:00 2025-05-20           3.90 0.206   3.6       0.174  -0.500
    #>  4 2025-04-02 12:00:00 2025-05-20           3.91 0.188   3.85      0.474  -0.250
    #>  5 2025-04-02 12:00:00 2025-05-20           3.91 0.188   4.1       0.317   0    
    #>  6 2025-04-02 12:00:00 2025-05-20           3.91 0.188   3.6       0.154  -0.500
    #>  7 2025-04-03 12:00:00 2025-05-20           3.87 0.175   3.85      0.524  -0.250
    #>  8 2025-04-03 12:00:00 2025-05-20           3.87 0.175   4.1       0.245   0    
    #>  9 2025-04-03 12:00:00 2025-05-20           3.87 0.175   3.6       0.198  -0.500
    #> 10 2025-04-04 12:00:00 2025-05-20           3.79 0.168   3.85      0.519  -0.250
    #> 11 2025-04-04 12:00:00 2025-05-20           3.79 0.168   3.6       0.319  -0.500
    #> 12 2025-04-04 12:00:00 2025-05-20           3.79 0.168   4.1       0.132   0    
    #> 13 2025-04-07 12:00:00 2025-05-20           3.71 0.156   3.6       0.479  -0.500
    #> 14 2025-04-07 12:00:00 2025-05-20           3.71 0.156   3.85      0.410  -0.250
    #> 15 2025-04-07 12:00:00 2025-05-20           3.71 0.156   3.35      0.0685 -0.750
    #> 16 2025-04-08 12:00:00 2025-05-20           3.75 0.154   3.85      0.487  -0.250
    #> 17 2025-04-08 12:00:00 2025-05-20           3.75 0.154   3.6       0.405  -0.500
    #> 18 2025-04-08 12:00:00 2025-05-20           3.75 0.154   4.1       0.0691  0    
    #> 19 2025-04-09 12:00:00 2025-05-20           3.63 0.146   3.6       0.604  -0.500
    #> 20 2025-04-09 12:00:00 2025-05-20           3.63 0.146   3.85      0.255  -0.250
    #>    diff_s move      
    #>     <dbl> <fct>     
    #>  1 -0.707 -25 bp cut
    #>  2  0     No change 
    #>  3 -0.841 -50 bp cut
    #>  4 -0.707 -25 bp cut
    #>  5  0     No change 
    #>  6 -0.841 -50 bp cut
    #>  7 -0.707 -25 bp cut
    #>  8  0     No change 
    #>  9 -0.841 -50 bp cut
    #> 10 -0.707 -25 bp cut
    #> 11 -0.841 -50 bp cut
    #> 12  0     No change 
    #> 13 -0.841 -50 bp cut
    #> 14 -0.707 -25 bp cut
    #> 15 -0.931 <NA>      
    #> 16 -0.707 -25 bp cut
    #> 17 -0.841 -50 bp cut
    #> 18  0     No change 
    #> 19 -0.841 -50 bp cut
    #> 20 -0.707 -25 bp cut
    #> # ℹ 271 more rows
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
