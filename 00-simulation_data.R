#!/bin/sh
#SBATCH --job-name=main-measles_schools
#SBATCH --output=simulation_data.Rout
#SBATCH --account=vegayon-np
#SBATCH --partition=vegayon-shared-np
#SBATCH --mem=5GB
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mail-user=george.vegayon@utah.edu
#SBATCH --mail-type=ALL

library(measles)
library(dplyr)
library(readr)
library(stringr)

# This R script runs the main component of the simulation model
# and stores the data under the `simulation_data/` directory.

if (require("slurmR", quietly = TRUE)) {
  lapply_call <- function(..., njobs = 100) {
    Slurm_lapply(
      ...,
      njobs = njobs,
      mc.cores = 1,
      job_name = "measles_schools",
      tmp_path = file.path(getwd(), "slurmr_tmp"),
      sbatch_opt = list(
        partition = "notchpeak-shared-freecycle",
        account = "vegayon",
        mem = "2G"
      )
    )
  }
} else {
  lapply_call <- function(..., njobs) {lapply(...)}
}

# Loading the school data (checking if test data is used)
test_data <- ifelse(
  Sys.getenv("TEST_DATA", "FALSE") == "TRUE",
  "./test_school_vax_data.csv",
  ""
  ) 

school_data <- if (file.exists(test_data)) {
  read_csv(test_data, comment = "#") 
} else {
  read_csv(
    "school_vax_data.csv",
    comment = "#"
    )
}

# Validate required columns
required_cols <- c("school_name", "school_id", "vax_rate", "pop_size")
missing_cols <- setdiff(required_cols, colnames(school_data))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}

# Prepare school data with required and optional columns
school_mmr_data <- school_data %>%
  mutate(
    name = school_name,
    id_new = school_id,
    `Population size` = pop_size,
    `Vaccination rate` = vax_rate
  )

# Add optional columns if they exist
if ("group" %in% colnames(school_data)) {
  school_mmr_data$group <- school_data$group
} else {
  school_mmr_data$group <- ""
}

if ("template_path" %in% colnames(school_data)) {
  school_mmr_data$template_path <- school_data$template_path
} else {
  school_mmr_data$template_path <- "letter_head.docx"
}

school_mmr_data <- school_mmr_data %>%
  select(id_new, name, `Population size`, `Vaccination rate`, group, template_path)

# Checking that the ids are unique. If not, then throw an error
if (any(duplicated(school_mmr_data$id_new))) {
  stop("Duplicate school IDs found. Please ensure each school has a unique ID.")
}

# Create simulation_data directory if it doesn't exist
if (!dir.exists("simulation_data")) {
  dir.create("simulation_data", recursive = TRUE)
}

# Identifying what simulations are ready
ready_sims <- list.files(
  "simulation_data",
  pattern = "\\.csv$"
)

ready_sims <- gsub("\\.csv$", "", ready_sims)

sims_to_do <- school_mmr_data$id_new |>
  gsub(pattern = "/", replacement = "-slash-")

sims_to_do <- which(!sims_to_do %in% ready_sims)

message("Number of simulations to do: ", length(sims_to_do))

# Now, we iterate through each school and run the model
if (length(sims_to_do) != 0) {
  res <- lapply_call(sims_to_do, function(i, sdata) {

    # Ensure the necessary functions are sourced
    source("scripts/model_functions.R")

    # Subset the school
    school <- sdata[i, ]
    school_id <- gsub("/", "-slash-", school$id_new)

    # Forming output and checking if it already exists
    output_file <- file.path(
      "simulation_data",
      paste0(school_id, ".csv")
    )

    if (file.exists(output_file))
      return(read.csv(output_file))

    # Creating a tempdir for copying the needed data
    tmp_dir <- tempfile(pattern = school_id)
    dir.create(tmp_dir, recursive = TRUE)

    # Creating a copy of the yaml parameters
    tmp_yaml <- file.path(tmp_dir, "params.yaml")
    file.copy("params.yaml", tmp_yaml)

    # Updating the parameters in the yaml file
    params <- yaml::read_yaml(tmp_yaml)
    params$`Population size` <- school$`Population size`
    params$`Vaccination rate` <- school$`Vaccination rate`
    params$school_name <- school$name
    yaml::write_yaml(params, tmp_yaml)

    # Ensuring it runs in a local environment
    tmp_env <- new.env()
    local({
      parameters <- yaml::read_yaml(tmp_yaml)
      results <- shiny_measles(parameters)
    }, envir = tmp_env)

    # Storing the results
    results <- with(tmp_env, list(
      id = school$id_new,
      name = school$name,
      group = school$group,
      template_path = school$template_path,
      vax_rate = parameters$`Vaccination rate`,
      pop_size = parameters$`Population size`,
      no_quarantine_mean_cases = results$takehome_stats$no_quarantine_mean_cases,
      no_quarantine_mean_hosp = results$hospitalizations$no_quarantine$mean,
      quarantine_mean_cases = results$takehome_stats$quarantine_mean_cases,
      quarantine_mean_hosp = results$hospitalizations$quarantine$mean
    )) |> as.data.frame()

    # Saving the results to a CSV file
    write_csv(results, output_file)

    return(results)

  }, sdata = school_mmr_data
  )
}

# Re-loading all the simulation results
res <- list.files(
  "simulation_data",
  pattern = "\\.csv$",
  full.names = TRUE
) |> lapply(read_csv) |> suppressWarnings()

# Save the results to a file
saveRDS(res, file = "simulation_data.rds")

# Combining the results into a single data frame
res <- do.call(rbind, res)
rownames(res) <- NULL

# Trying to create a CSV version of it
write_csv(res, "simulation_data.csv")
