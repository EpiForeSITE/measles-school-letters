## Overview

- This is a template repository for generating automatic reports of measles for schools.
- The reports are use data on vaccination rate and school sizes. We use the `epiworldR` package suit to run the simulations and generate the reports.
- The reports are generated using quarto; the `measles.qmd` file contains the template for the report.
- Since this should be a simple template, oriented for public health practitioners, we do not include advanced customization options, just the basics. Thus adding anything that would inflate the complexity of the template is discouraged.
- We use GitHub Actions to check whether the pipeline is working properly.
- We prefer using `data.table` for data manipulation instead of `dplyr`. Nonetheless, for visualization, we use `ggplot2`.