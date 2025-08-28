# Technical Details

This document provides technical details about the Measles School Simulation Template workflow, data processing, and implementation.

## Data Format Specifications

### Required Input Data Format

Your production CSV file must be named `school_vax_data.csv` and contain these columns:
- `SchoolID`: Unique identifier for the school
- `Name`: School name
- `enrolled_students`: Total number of enrolled students
- `Students up to date with MMR`: Number of students with up-to-date MMR vaccination
- `Grade_level`: Grade level (Elementary, Middle, High, or School for mixed)
- `school_district`: Name of the school district
- `Health District`: Name of the health district
- `PUBLIC/PRIVATE`: School type
- `Chartered?`: Whether school is chartered (Yes/No)
- `inperson/online`: Learning mode ("In person or hybrid" for in-person schools)
- `Address`, `City`, `Zip Code`, `County`: Location information
- `r_school_code`: School code for reference

**Note**: The file can include comments (lines starting with `#`) which will be ignored when loaded into R.

### Simulation Output Data Format

The `simulation_data.csv` file contains all the data needed to generate reports. Each row represents one school with the following columns:

- `id`: School identifier (format: `{SchoolID}_{r_school_code}_{Grade_level}`)
- `name`: School name
- `health_district`: Health district name (used for report organization)
- `letter_head`: Letterhead template filename (currently not used - defaults to `letter_head.docx`)
- `vax_rate`: Vaccination rate (0-1 scale)
- `pop_size`: School population size
- `no_quarantine_mean_cases`: Average number of cases without quarantine intervention
- `no_quarantine_mean_hosp`: Average number of hospitalizations without quarantine
- `quarantine_mean_cases`: Average number of cases with quarantine intervention  
- `quarantine_mean_hosp`: Average number of hospitalizations with quarantine

## Details of the Workflow

### 1. Data Loading and Environment Detection

The system automatically detects whether to use test or production data:

- **Test mode**: When `TEST_DATA=TRUE`, uses `test_school_vax_data.csv` (3 synthetic schools)
- **Production mode**: When `TEST_DATA` is unset or `FALSE`, uses `school_vax_data.csv` (your real data)

### 2. Simulation Process

```mermaid
flowchart TD
    A[Load school data] --> B[Clean and aggregate by school]
    B --> C[Filter schools >10 students, >30% vax rate]
    C --> D[Run measles simulations for each school]
    D --> E[Save results to simulation_data.csv]
```

#### Simulation Details

The simulation runs multiple scenarios for each school:
- **Without quarantine**: Natural outbreak progression
- **With quarantine**: 21-day quarantine for unvaccinated exposed students

#### Model Parameters

Each simulation uses parameters from `params.yaml`:
- Population size and vaccination rates (school-specific)
- Transmission parameters (contact rate, transmission probability)
- Disease progression parameters (incubation, prodromal, rash periods)
- Intervention parameters (quarantine compliance, isolation periods)
- Hospitalization parameters (rate, duration)

#### Parallel Processing

The simulation supports parallel processing:
- Uses `slurmR` package when available (for HPC environments)
- Falls back to standard `lapply` for local execution
- Configurable number of threads via parameters

### 3. Report Generation Process

```mermaid
flowchart TD
    A[Read simulation_data.csv] --> B[For each school]
    B --> C[Create temporary working directory]
    C --> D[Copy required files:<br/>measles.qmd, letter_head.docx,<br/>simulation data, etc.]
    D --> E[Render Quarto report to Word]
    E --> F[Apply text formatting:<br/>highlight key numbers in red/bold]
    F --> G[Move report to final location<br/>in reports/ directory]
    G --> H[Organize by health district<br/>if specified]
```

#### Report Processing Details

1. **Template Processing**: Each school gets its own temporary directory with copied template files
2. **Parameter Substitution**: School-specific data is injected into the Quarto template
3. **Document Rendering**: Quarto renders the template to a Word document
4. **Post-processing**: Key statistics are highlighted in red and bold for emphasis
5. **Organization**: Reports are organized by health district (if specified) or placed in the root reports directory

### 4. Output Organization

Reports are saved in the `reports/` directory:
- **With health districts**: `reports/{health_district_name}/{school_id}.docx`
- **Without health districts**: `reports/{school_id}.docx`

### 5. Script Descriptions

#### Main Scripts

- **`00-simulation_data.R`** - Main simulation script that:
  - Loads and processes school vaccination data
  - Filters schools by minimum population and vaccination thresholds
  - Runs measles outbreak simulations for each qualifying school
  - Handles both test data (synthetic) and production data
  - Supports parallel processing for large datasets
  - Outputs results in both CSV and RDS formats

- **`01-generate_reports.R`** - Report generation script that:
  - Reads simulation results from CSV files
  - Creates individual Word document reports for each school
  - Uses Quarto templates with school-specific parameter injection
  - Applies formatting to highlight key statistics
  - Organizes reports by health district when specified
  - Handles both test and production data scenarios

- **`02-split_simulated_LHD.R`** - Optional utility script that:
  - Splits combined simulation data by health district
  - Creates separate CSV files for each health district
  - Useful for distributing results to different jurisdictions

#### Supporting Scripts

- **`scripts/model_functions.R`** - Core epidemiological modeling functions:
  - `model_builder()`: Configures epiworldR measles models
  - `shiny_measles()`: Orchestrates complete simulation workflow
  - Helper functions for data processing and analysis
  - Statistical analysis functions for outbreak probabilities

- **`scripts/docx_edit.R`** - Document post-processing functions:
  - Functions to modify Word documents after Quarto rendering
  - Text formatting to highlight key statistics in red and bold
  - Integration with the report generation workflow

### 6. Configuration Files

- **`params.yaml`** - Central configuration for model parameters
- **`measles.qmd`** - Quarto template for report generation
- **`letter_head.docx`** - Word template with organization letterhead
- **`Makefile`** - Build automation for common workflows

## Development and Testing

### Test Data
The repository includes `test_school_vax_data.csv` with synthetic data for 3 schools (~500 students each, 80% vaccination rate) to enable testing without real data.

### Continuous Integration
GitHub Actions CI automatically tests:
1. Simulation data generation with synthetic data
2. Report generation process
3. Output file validation
4. Complete workflow from input to final reports

### Error Handling
- Graceful fallbacks for missing optional dependencies
- Comprehensive logging for debugging
- Validation of input data formats
- Safe handling of temporary files and directories