packages <- c(
  "broom",
  "conflicted",
  "dplyr",
  "ggpattern",
  "ggplot2",
  "ggtext",
  "glue",
  "here",
  "htmlwidgets",
  "jsonlite",
  "lubridate",
  "plotly",
  "purrr",
  "readr",
  "readrba",
  "scales",
  "stringr",
  "tibble",
  "tidyr",
  "tidyverse",
  "viridis",
  "zoo"
)

missing_packages <- packages[!packages %in% rownames(installed.packages())]

if (length(missing_packages) == 0) {
  message("All dependencies are already installed.")
} else {
  message("Installing missing dependencies: ", paste(missing_packages, collapse = ", "))
  install.packages(missing_packages)
}
