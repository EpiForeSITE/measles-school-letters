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

1. **Prepare your data**: Create `school_vax_data.csv` with required columns: `school_name`, `school_id`, `vax_rate`, `pop_size` ([see format details](docs/details.md#required-input-data-format))
2. **Add your letterhead** (optional): Replace `letter_head.docx` with your organization's template
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

## Parameters & references

The model is `ModelMeaslesSchool()` from the [`measles`](https://github.com/UofUEpiBio/measles) R package. Its parameters are set in [`params.yaml`](params.yaml), which has a source comment for each value, and passed to the model by `model_builder()` in [`scripts/model_functions.R`](scripts/model_functions.R). Every parameter is passed explicitly, so none falls back silently to a package default. The table lists each one next to the package default. **Bold** values differ from the package default.

Canonical values and sources for all measles models: [`measles_parameters.csv`](https://github.com/UofUEpiBio/measles/blob/main/inst/extdata/measles_parameters.csv) and the [Parameters and literature references](https://github.com/UofUEpiBio/measles/blob/main/vignettes/parameters.qmd) vignette (also available in R as `measles::measles_parameters()`).

Status: ✅ verified against the cited source; 🗣️ team assumption or rationale, confirmed by the authors; ⚠️ pending.

| Parameter | Value used | Package default | Source | Status | Notes / why different |
|---|---|---|---|---|---|
| Population size (`n`) | Per school (`pop_size`); 190 in `params.yaml` is a placeholder | None | Scenario input: your school data | 🗣️ | Replaced for each school. |
| Vaccination rate (`prop_vaccinated`) | Per school (`vax_rate`); 0.42 in `params.yaml` is a placeholder | 1 − 1/15 ≈ 0.933 | Scenario input: your school MMR data | 🗣️ | Replaced for each school. The package default is the herd-immunity threshold for R0 = 15. |
| Prevalence (`prevalence`) | 1 | 1 | Scenario input | 🗣️ | One index case per simulation. |
| R0 (target) | 15 (not read by the model) | 15 | Guerra et al. 2017, *Lancet Infect Dis*, [doi:10.1016/S1473-3099(17)30307-9](https://doi.org/10.1016/S1473-3099(17)30307-9) | ✅ 🗣️ | The `R0` key in `params.yaml` is for reference only. R0 enters the model through the contact rate. With the values used here, the implied R0 is about 10.2 (see contact rate). |
| Transmission rate (`transmission_rate`) | 0.9 | 0.9 | Assumption: highly transmissible. [Utah DHHS Measles Disease Plan][udhhs]: "90% of susceptible contacts will develop disease" | 🗣️ ✅ | Same as the default. |
| Contact rate (`contact_rate`) | **3.79** | 15 / 0.9 / 4 ≈ 4.17 | Calibrated to R0 = 15 as 15 / 0.99 / 4, the default in the [epiworldRShiny](https://github.com/UofUEpiBio/epiworldRShiny) measles app | 🗣️ ⚠️ | **Differs.** Copied from the epiworldRShiny default, which assumes transmission 0.99 and a 4-day prodrome. In `ModelMeaslesSchool` only prodromal agents transmit, so R0 = transmission × contact rate × prodromal period. With this repo's transmission (0.9) and prodrome (3 days), that gives 0.9 × 3.79 × 3 ≈ 10.2, not 15. The value is kept so that letters already sent stay reproducible. ⚠️ Authors still need to confirm. |
| Incubation period (`incubation_period`) | 12 days | 12 | [Utah DHHS plan][udhhs]: exposure to prodrome averages 8–12 days | ✅ | Same as the default. |
| Prodromal period (`prodromal_period`) | **3 days** | 4 | [Utah DHHS plan][udhhs]: prodrome lasts 2–4 days (range 2–8) | ✅ ⚠️ | **Differs.** 3 days is within the Utah DHHS range. It has been in `params.yaml` since the first version of this template. The reason for 3 rather than 4 days is not recorded (⚠️ pending author confirmation). A shorter prodrome lowers R0 for a given contact rate. |
| Rash period (`rash_period`) | **4 days** | 3 | [Utah DHHS plan][udhhs]: contagious to 4 days after rash onset | ✅ ⚠️ | **Differs.** In this model, agents with rash do not transmit. The rash period sets how long a case can be detected or hospitalized. With 4 days, the share of cases hospitalized rises from about 37.5% to about 44% (see hospitalization). The reason for 4 rather than 3 days is not recorded (⚠️ pending author confirmation). |
| Days undetected (`days_undetected`) | 2 days | 2 | Assumption: about 2 days from active case to public health notification | 🗣️ | Same as the default. |
| Hospitalization rate (`hospitalization_rate`) | 0.2 per day | 0.2 | Started at 20% as a conservative value agreed with Utah DHHS. Recent analyses use 10%, following Jones et al. 2026, *NEJM Evid* ([doi:10.1056/EVIDpha2600141](https://doi.org/10.1056/EVIDpha2600141)), who report 8% overall and 9% among unvaccinated people in Utah | ✅ 🗣️ | Same value as the default, but note that it is a **daily rate, not a probability**. The probability of hospitalization is p = h / (h + 1/rash) = 0.2 / (0.2 + 1/4) ≈ **0.44** with this repo's 4-day rash period (≈ 0.375 with the package's 3 days). This is higher than the observed 8–9% in Utah, and the 18.5% in West Texas reported by Wang et al. 2026, *MMWR* ([doi:10.15585/mmwr.mm7520a1](https://doi.org/10.15585/mmwr.mm7520a1)). The hospitalization numbers in the letters are therefore conservative (high). |
| Hospitalization period (`hospitalization_period`) | 7 days | 7 | Assumption | 🗣️ | Same as the default. Observed stays are shorter: a mean of 2.1 nights in Utah (Jones et al. 2026). The letters count admissions, so this value does not change the reported numbers. |
| Quarantine period (`quarantine_period`) | 21 days (quarantine scenario); −1, meaning off (no-quarantine scenario) | 21 | [Utah DHHS plan][udhhs]: 21 days since last exposure | ✅ | Same as the default. Each school is simulated with and without quarantine. |
| Quarantine willingness (`quarantine_willingness`) | 1.0 | 1 | Assumption (field experience) | 🗣️ | Same as the default. Some analyses use 0.9. |
| Isolation period (`isolation_period`) | 4 days | 4 | [Utah DHHS plan][udhhs]: isolate until 4 days after rash onset | ✅ | Same as the default. |
| Vaccine efficacy (`vax_efficacy`) | 0.97 | 0.97 | [Utah DHHS plan][udhhs] ("~97%"); [CDC](https://www.cdc.gov/measles/about/questions.html) | ✅ | Same as the default, for 2 doses of MMR. |
| Vax improved recovery (`vax_improved_recovery`) | 0.5 (ignored) | Removed in measles 0.10.0 | Not active | ✅ | Still passed for backward compatibility. The package warns and ignores it. |
| `initial number of exposed` (`params.yaml` key) | 1.0 (not used) | — | — | — | Legacy key that is never passed to the model. The initial cases come from `Prevalence`. |
| Post-exposure prophylaxis (PEP) | Not used | — | — | — | This template does not model PEP (`InterventionMeaslesPEP`). |

[udhhs]: https://epi.utah.gov/wp-content/uploads/Measles-disease-plan.pdf

Simulation settings (not epidemiological parameters): `Seed` 2023, `N days` 100, `Replicates` 500 per scenario, `Threads` 2.

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
R CMD BATCH 00-simulation_data.R 00-simulation_data.Rout &

# Generate reports
R CMD BATCH 01-generate_reports.R 01-generate_reports.Rout &
```

Both approaches produce identical results - choose whichever is more convenient for your setup.

## Repository Contents

### Main Files
- `00-simulation_data.R` - Runs outbreak simulations for each school
- `01-generate_reports.R` - Creates individual Word reports
- `02-split_simulated_LHD.R` - Optional utility to split results by group/district
- `params.yaml` - Model configuration parameters (see [Parameters & references](#parameters--references))
- `measles.qmd` - Report template
- `letter_head.docx` - Your organization's letterhead (replace for production)

### Data Files
- `school_vax_data.csv` - Your school vaccination data with required columns: `school_name`, `school_id`, `vax_rate`, `pop_size`
- `test_school_vax_data.csv` - Synthetic test data (included)

### Generated Output
- `simulation_data.csv` - Simulation results
- `reports/` - Generated Word document reports

> **Note**: Looking for more advanced district-level grouping and analysis features? Check out the [v1.0 release](https://github.com/EpiForeSITE/measles-school-letters/releases/tag/v1.0) which includes additional functionality for combining and analyzing results by school district.

## Requirements

- R 4.0 or later
- Required R packages (see [`docs/requirements.md`](docs/requirements.md) for complete list)
- Quarto for report generation
- Optional: GNU Make for build automation

For detailed technical requirements and installation instructions, see [`docs/requirements.md`](docs/requirements.md).

**Alternative: Development Container**: This repository includes a `.devcontainer` setup that provides a pre-configured environment with all dependencies. You can use this with GitHub Codespaces or VS Code Dev Containers for a quick start without local installation.

## Need Help Running Simulations?

**We're here to help!** If your public health department, school district, or organization needs measles outbreak risk assessments but lacks the technical resources or expertise to run this analysis, we can assist you.

We offer:
- Running simulations with your data
- Customizing reports for your specific needs  
- Training on using the tools
- Technical support and consultation

**Contact us** through this repository's issues or reach out to discuss how we can support your public health response efforts at no cost.

## Documentation

- **[`docs/requirements.md`](docs/requirements.md)** - Technical requirements and installation
- **[`docs/details.md`](docs/details.md)** - Technical implementation details and workflow
- **[`docs/README.md`](docs/README.md)** - Documentation overview

## Testing

The repository includes automated testing via GitHub Actions to ensure all components work correctly. The test suite validates both simulation and report generation using synthetic data.


## Acknowledgements

This was made possible by cooperative agreement CDC-RFA-FT-23-0069 from the CDC’s Center for Forecasting and Outbreak Analytics. Its contents are solely the responsibility of the authors and do not necessarily represent the official views of the Centers for Disease Control and Prevention.