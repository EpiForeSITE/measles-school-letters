# Measles School Simulation Template[^original]

[![Test Measles Simulation Scripts](https://github.com/EpiForeSITE/measles-school-letters/actions/workflows/test-simulation.yml/badge.svg)](https://github.com/EpiForeSITE/measles-school-letters/actions/workflows/test-simulation.yml)

[^original]: This template is based on the original joint work by the Utah Department of Health and the University of Utah with support from the CDC.

> [!CAUTION]
> The code and model are still under development. We would love to hear your feedback and suggestions. Please open an issue in the [GitHub repository](https://github.com/EpiForeSITE/measles-school-letters) if you have any questions or suggestions.

## Overview

This repository provides a template for conducting measles outbreak scenario modeling for schools. It helps public health officials and researchers simulate disease spread under different vaccination rates and intervention scenarios, generating customized reports for individual schools.

**What this tool does:**
- Simulates measles outbreaks in school settings based on vaccination data
- Compares scenarios with and without quarantine interventions
- Generates professional Word document reports for each school
- Provides probability estimates for different outbreak sizes
- Includes hospitalization projections and recommendations

**Who can use this:**
- Public health departments
- School administrators
- Epidemiologists and researchers
- Anyone needing measles outbreak risk assessments for schools

## Quick Start

### Testing the System (Recommended First Step)

Try the system with included synthetic data to understand how it works:

```bash
TEST_DATA=TRUE make sims
TEST_DATA=TRUE make reports
```

This will create example reports using 3 synthetic schools. Check the `reports/` folder for generated Word documents.

### Using Your Own Data

1. **Prepare your data**: Create `school_vax_data.csv` with your school vaccination data ([see format requirements](docs/details.md#required-input-data-format))
2. **Add your letterhead**: Replace `letter_head.docx` with your organization's template
3. **Run the analysis**:
   ```bash
   make sims
   make reports
   ```

Your custom reports will be saved in the `reports/` directory.

## How It Works

The system works in two main steps:

1. **Simulation**: Analyzes your school data and runs epidemiological models to simulate potential measles outbreaks
2. **Report Generation**: Creates professional Word documents with school-specific results and recommendations

Each report includes:
- Risk assessment based on current vaccination rates
- Comparison of outbreak scenarios with and without quarantine measures  
- Probability tables for different outbreak sizes
- Hospitalization estimates
- Actionable recommendations for school administrators

For technical details about the workflow, data formats, and implementation, see our [technical documentation](docs/details.md).

## Using the Makefile

This repository includes a Makefile to simplify common tasks. **Note**: GNU Make is not required - you can run the R scripts directly if preferred.

### With Make (Recommended)

```bash
# Generate simulation data
make sims

# Generate reports from simulation data  
make reports

# Clean up generated files
make clean_all

# See all available commands
make help
```

### Without Make (Alternative)

If you don't have Make installed or prefer to run scripts directly:

```bash
# Generate simulation data
R CMD BATCH 00-simulation_data.R 00-simulation_data.Rout

# Generate reports
R CMD BATCH 01-generate_reports.R 01-generate_reports.Rout
```

Both approaches produce identical results - choose whichever is more convenient for your setup.

## Repository Contents

### Main Files
- `00-simulation_data.R` - Runs outbreak simulations for each school
- `01-generate_reports.R` - Creates individual Word reports
- `02-split_simulated_LHD.R` - Splits results by health district (optional)
- `params.yaml` - Model configuration parameters
- `measles.qmd` - Report template
- `letter_head.docx` - Your organization's letterhead (replace for production)

### Data Files
- `school_vax_data.csv` - Your school vaccination data (you provide this)
- `test_school_vax_data.csv` - Synthetic test data (included)

### Generated Output
- `simulation_data.csv` - Simulation results
- `reports/` - Generated Word document reports

### Documentation
- [`docs/`](docs/) - Technical documentation and requirements
- [`reports/README.md`](reports/README.md) - Information about generated reports

For detailed descriptions of what each script does and technical implementation details, see [`docs/details.md`](docs/details.md).

## Requirements

- R 4.0 or later
- Required R packages (see [`docs/requirements.md`](docs/requirements.md) for complete list)
- Quarto for report generation
- Optional: GNU Make for build automation

For detailed technical requirements and installation instructions, see [`docs/requirements.md`](docs/requirements.md).

## Need Help Running Simulations?

**We're here to help!** If your public health department, school district, or organization needs measles outbreak risk assessments but lacks the technical resources or expertise to run this analysis, we can assist you.

We offer:
- Running simulations with your data
- Customizing reports for your specific needs  
- Training on using the tools
- Technical support and consultation

**Contact us** through this repository's issues or reach out to discuss how we can support your public health response efforts.

## Documentation

- **[`docs/requirements.md`](docs/requirements.md)** - Technical requirements and installation
- **[`docs/details.md`](docs/details.md)** - Technical implementation details and workflow
- **[`docs/README.md`](docs/README.md)** - Documentation overview

## Testing

The repository includes automated testing via GitHub Actions to ensure all components work correctly. The test suite validates both simulation and report generation using synthetic data.


## Acknowledgements

This was made possible by cooperative agreement CDC-RFA-FT-23-0069 from the CDC’s Center for Forecasting and Outbreak Analytics. Its contents are solely the responsibility of the authors and do not necessarily represent the official views of the Centers for Disease Control and Prevention.