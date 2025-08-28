# Technical Requirements

This document outlines the technical requirements and dependencies for running the Measles School Simulation Template.

## System Requirements

### R Environment
- **R Version**: 4.0 or later (tested with R 4.5.1)
- **Operating System**: Linux, macOS, or Windows

### Required R Packages

#### Core Dependencies
- **epiworldR**: Version 0.9.0 or later
  - Epidemiological modeling framework
  - Install from: `UofUEpiBio/epiworldR` (GitHub repository)
  - Note: Currently requires the `patch-rename-measlesmodel` branch

#### Document Generation
- **quarto**: Quarto publishing system for report generation
- **flextable**: Table formatting for reports

#### Data Processing (from tidyverse)
- **dplyr**: Data manipulation
- **readr**: Reading CSV files  
- **stringr**: String processing
- **ggplot2**: Plotting (included with model functions)

#### Document Editing
- **yaml**: YAML file processing
- Standard R packages for Word document manipulation

### External Tools

#### Document Processing
- **Quarto CLI**: Required for rendering .qmd files to Word documents
- **Pandoc**: Included with Quarto for document conversion

#### Build Automation (Optional)
- **GNU Make**: For using the included Makefile (not required - manual execution possible)

## Installation Instructions

### Using the Provided Container
The repository includes a devcontainer configuration that provides all dependencies pre-installed.

### Manual Installation

1. **Install R 4.0+** from [CRAN](https://cran.r-project.org/)

2. **Install Quarto** from [quarto.org](https://quarto.org/docs/get-started/)

3. **Install R packages**:
   ```r
   # Install epiworldR (development version)
   if (!require("remotes")) install.packages("remotes")
   remotes::install_github("UofUEpiBio/epiworldR", ref = "patch-rename-measlesmodel")
   
   # Install other packages
   install.packages(c("quarto", "flextable", "dplyr", "readr", "stringr", "ggplot2", "yaml"))
   ```

4. **Optional: Install GNU Make** (for Windows users):
   - Download from [gnu.org](https://www.gnu.org/software/make/)
   - Or use alternatives like `nmake` on Windows

## Development Environment

### Recommended Setup
- Use the provided devcontainer for consistent environment
- Or use RStudio with the included `.Rproj` file

### Container Specifications
- Base image: `rocker/tidyverse:4.5.1`
- Includes R, RStudio Server, and tidyverse packages
- Pre-configured with all required dependencies

## Memory and Performance
- **Minimum RAM**: 4GB recommended
- **CPU**: Multi-core recommended for parallel simulations
- **Storage**: ~100MB for base installation, additional space for simulation outputs

## Compatibility Notes
- Tested on Ubuntu Linux (via GitHub Actions)
- Should work on all major platforms with R support
- Windows users may need to adjust path separators in some scripts
- Make targets work on Unix-like systems; Windows users can run R scripts directly