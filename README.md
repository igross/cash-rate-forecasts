
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

    #> # A tibble: 19,110 × 8
    #>    scrape_time         meeting_date implied_mean stdev bucket probability   diff
    #>    <dttm>              <date>              <dbl> <dbl>  <dbl>       <dbl>  <dbl>
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
    #> 11 2025-04-01 12:00:00 2025-04-01           4.08    NA   2.6           NA -1.5  
    #> 12 2025-04-01 12:00:00 2025-04-01           4.08    NA   2.85          NA -1.25 
    #> 13 2025-04-01 12:00:00 2025-04-01           4.08    NA   3.1           NA -1    
    #> 14 2025-04-01 12:00:00 2025-04-01           4.08    NA   3.35          NA -0.750
    #> 15 2025-04-01 12:00:00 2025-04-01           4.08    NA   3.6           NA -0.500
    #> 16 2025-04-01 12:00:00 2025-04-01           4.08    NA   3.85          NA -0.250
    #> 17 2025-04-01 12:00:00 2025-04-01           4.08    NA   4.1           NA  0    
    #> 18 2025-04-01 12:00:00 2025-04-01           4.08    NA   4.35          NA  0.25 
    #> 19 2025-04-01 12:00:00 2025-04-01           4.08    NA   4.6           NA  0.5  
    #> 20 2025-04-01 12:00:00 2025-04-01           4.08    NA   4.85          NA  0.75 
    #>    diff_s
    #>     <dbl>
    #>  1 -1.41 
    #>  2 -1.39 
    #>  3 -1.37 
    #>  4 -1.34 
    #>  5 -1.32 
    #>  6 -1.29 
    #>  7 -1.26 
    #>  8 -1.22 
    #>  9 -1.19 
    #> 10 -1.15 
    #> 11 -1.11 
    #> 12 -1.06 
    #> 13 -1    
    #> 14 -0.931
    #> 15 -0.841
    #> 16 -0.707
    #> 17  0    
    #> 18  0.707
    #> 19  0.841
    #> 20  0.931
    #> # ℹ 19,090 more rows
