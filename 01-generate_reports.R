#remotes::install_github("UofUEpiBio/epiworldR")

library(readr)
library(dplyr)
library(stringr)
library(quarto)

source("scripts/docx_edit.R")

# Read in school data
school_results <- read_csv("simulation_data.csv")

# Default template
letter_head <- "letter_head.docx"

# Loading the school data (checking if test data is used)
test_data <- ifelse(
  Sys.getenv("TEST_DATA", "FALSE") == "TRUE",
  "./test_school_vax_data.csv",
  ""
  ) 

K_12_2ndMMR_data_set_for_2024_25 <- if (file.exists(test_data)) {
  read_csv(test_data, comment = "#") 
} else {
  read_csv(
    "school_vax_data.csv",
    comment = "#"
    )
}

# What column from `school_results` to use 
# for organizing the reports. If none, the reports
# will be placed in the root of the `reports` folder.
folder_group <- "health_district"

# What to make red and bold
# - The name of the entry is the pattern to find
# - The value is the replacement text
# 
red_and_bold <- c(
  "([0-9.%]+) of the ([0-9]+) students" = "\\1 of the \\2 students",
  "on average ([0-9]+) children could become infected" = "on average \\1 children could become infected,",
  "([0-9]+) of whom could be hospitalized" = "\\1 of whom could be hospitalized",
  "([0-9]+) infections and" = "\\1 infections and",
  "([0-9]+) hospitalizations" = "\\1 hospitalizations"
)


# this is testing with synthetic data - adjust filter as needed for your use case
test_school <- school_results %>% 
  filter(!health_district %in% c("Reserved District 1", "Reserved District 2"))
  # Example of limiting to specific schools for testing:
  # filter(name %in% c("Test Elementary School", "Demo Middle School", "Sample High School"))

# Checking if the dataset has the `letter_head` column
has_letter_head <- "letter_head" %in% colnames(school_results)

# Storing the old working directory
olddir <- getwd()

# Making room for the errors
errors <- NULL
for (i in seq_len(nrow(test_school))) {
  
  ans <- tryCatch({
    # Extracting the corresponding school
    school <- test_school[i, ]
    
    # Creating a directory for the report
    id <- gsub("/", "-slash-", school$id)
    file_word <- paste0(id, ".docx")
    
    # Checking if the report already exists
    if (folder_group == "") {
      folder_group_i <- ""
    } else {
      folder_group_i <- school[[folder_group]]
    }
    
    if (file.exists(file.path("reports", folder_group_i, file_word))) {
      message("Report for school '", id, "' already exists. Skipping.")
      next
    }

    # Making sure that the folder group exists
    report_dir <- file.path("reports", folder_group_i)
    if (!dir.exists(report_dir)) {
      dir.create(report_dir, recursive = TRUE)
    }
    
    # Use the single qmd file
    qmd_file <- "measles.qmd"
    
    # Use the default letterhead
    selected_letter_head <- letter_head
    
    # Checking if we need to create the dir
    if (!dir.exists(report_dir))
      dir.create(report_dir, recursive = TRUE)
    
    # Copy the appropriate data file based on environment
    data_file <- ifelse(
      file.exists(test_data),
      test_data,
      "school_vax_data.csv"
    )
    
    # Copying the necesary files
    file.copy(qmd_file, file.path(report_dir, "measles.qmd"), overwrite = TRUE)
    file.copy("scripts/model_functions.R", file.path(report_dir, "model_functions.R"))
    file.copy(data_file, file.path(report_dir, basename(data_file)))
    file.copy("simulation_data.csv", file.path(report_dir, "simulation_data.csv"))
    file.copy(selected_letter_head, file.path(report_dir, selected_letter_head))
    
    # Update the template and params
    file_path_quarto <- file.path(report_dir, "measles.qmd") |>
      normalizePath()
      
    quarto_file <- readLines(file_path_quarto)
    quarto_file <- gsub("reference-doc:\\s*.+",
                        paste0('reference-doc: "', selected_letter_head, '"'),
                        quarto_file)
    quarto_file <- gsub("school_id:\\s*.+",
                        paste0('school_id: "', school$id, '"'),
                        quarto_file)
    writeLines(quarto_file, file_path_quarto)
    
    # Quarto is funny about how it handles working directories
    # so we change it before running all
    setwd(report_dir)

    quarto::quarto_render(
      input = file_path_quarto,
      output_file = file_word,
      execute_params = list(
        school_id = school$id
      ),
      quiet = FALSE
    )

    message("Quarto report generated for school '", id, "'")

    # Trying to make bold text
    suppressMessages({
      docx_edit_bold_red(
        input_path = file_word,
        find_pattern = names(red_and_bold),
        replacement = unname(red_and_bold),
        output_path = file_word
      )
    })

    message("Bold text applied to report for school '", id, "'")

    message("Moving report for school '", id, "' to final location:")
    message("\t", file.path(olddir, "reports", folder_group_i))

    file.rename(
      from = file_word,
      to = file.path(olddir, "reports", folder_group_i, file_word)
    )
    
  }, error = function(e) e)

  # Ensuring we are still in the old wd
  setwd(olddir)
  
  # Checking if it failed
  if (inherits(ans, "error")) {
    
    message("Error processing school '", id, "'.")
    errors <- c(errors, list(list(school = id, error = ans)))
    next
    
  }
  
  # It worked!
  message("Report for school '", id, "' completed.")
  
}

saveRDS(errors, file = "01-generate_reports_errors.rds")

if (any(sapply(errors, length) > 0))
  stop(
    "There were errors processing some schools.",
    "See '01-generate_reports_errors.rds' for details."
    )
