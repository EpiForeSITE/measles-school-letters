# This R script is mostly based on the epiworldRShiny 
# package's implementation of the measles model module. 
# The code was originally developed by George V. Vega Yon
# (with contributions by Andrew Pulsipher) and adapted
# for this project by Josh Kelley and George V. Vega Yon.

library(epiworldR)
library(ggplot2)

#' Build Measles School Model
#'
#' Creates a measles school model using the epiworldR package with specified parameters.
#' This function configures all model parameters including transmission rates, vaccination 
#' rates, and intervention measures like quarantine.
#'
#' @param input A list containing model parameters with specific named elements:
#'   - `Population size`: Integer, total number of students in the school
#'   - `Contact rate`: Numeric, daily contact rate between students
#'   - `Prevalence`: Integer, initial number of infected students
#'   - `Transmission rate`: Numeric, probability of transmission per contact
#'   - `Vax efficacy`: Numeric, vaccine efficacy (0-1)
#'   - `Vax improved recovery`: Numeric, vaccination effect on recovery
#'   - `Incubation period`: Numeric, days in incubation period
#'   - `Prodromal period`: Numeric, days in prodromal period
#'   - `Rash period`: Numeric, days with visible rash
#'   - `Days undetected`: Numeric, days infectious before detection
#'   - `Hospitalization rate`: Numeric, probability of hospitalization
#'   - `Hospitalization days`: Numeric, length of hospital stay
#'   - `Vaccination rate`: Numeric, proportion of students vaccinated (0-1)
#'   - `Quarantine days`: Integer, length of quarantine period
#'   - `Quarantine willingness`: Numeric, compliance rate for quarantine (0-1)
#'   - `Isolation days`: Integer, length of isolation period
#' @param quarantine Logical, whether to enable quarantine interventions (default: TRUE)
#'
#' @return An epiworldR model object configured for measles simulation in schools
#' @export
model_builder <- function(input, quarantine = TRUE) {
  epiworldR::ModelMeaslesSchool(
    n                      = as.integer(input$`Population size`),
    contact_rate           = input$`Contact rate`,
    prevalence             = as.integer(input$Prevalence),
    transmission_rate      = input$`Transmission rate`,
    vax_efficacy           = input$`Vax efficacy`,
    vax_improved_recovery  = input$`Vax improved recovery`,
    incubation_period      = input$`Incubation period`,
    prodromal_period       = input$`Prodromal period`,
    rash_period            = input$`Rash period`,
    days_undetected        = input$`Days undetected`,
    hospitalization_rate   = input$`Hospitalization rate`,
    hospitalization_period = input$`Hospitalization days`,
    prop_vaccinated        = input$`Vaccination rate`,
    quarantine_period      =  if (quarantine) {input$`Quarantine days`} else {-1L},
    quarantine_willingness = input$`Quarantine willingness`,
    isolation_period       = input$`Isolation days`
  )
}

#' Active Case Status Vector
#'
#' A character vector containing all epidemiological states that represent active 
#' (infectious or potentially infectious) cases in the measles model. Used for 
#' filtering simulation results to count only active cases.
#'
#' @details Includes the following states:
#'   - Exposed: Recently infected, not yet symptomatic
#'   - Prodromal: Early symptomatic phase
#'   - Rash: Characteristic measles rash phase
#'   - Isolated: Confirmed cases in isolation
#'   - Quarantined Exposed: Exposed individuals in quarantine
#'   - Quarantined Prodromal: Symptomatic individuals in quarantine
#'   - Quarantined Recovered: Recovered individuals completing quarantine
#'   - Hospitalized: Severe cases requiring hospitalization
#'
active_cases_statuses <- c(
  "Exposed",
  "Prodromal",
  "Rash",
  "Isolated",
  "Quarantined Exposed",
  "Quarantined Prodromal",
  "Quarantined Recovered",
  "Hospitalized"
)

#' Format Final Case Counts
#'
#' Processes simulation histories to extract final case counts for each simulation run.
#' Aggregates all exposed states (including recovered) at the final simulation day.
#'
#' @param histories A data.frame containing simulation history with columns:
#'   - state: epidemiological state name
#'   - date: simulation day
#'   - counts: number of individuals in each state
#'   - sim_num: simulation run identifier
#'
#' @return A data.frame with columns:
#'   - Simulation: simulation run number
#'   - Total: total number of cases (exposed + recovered) at simulation end
#'
#' @details Includes all active case states plus "Recovered" individuals.
#'   Only counts cases on the final simulation day.
format_counts <- function(histories) {
  exposed <- c(active_cases_statuses, "Recovered")
  counts <- subset(histories, state %in% exposed & date == max(date))
  counts <- aggregate(counts ~ sim_num, data = counts, FUN = sum)
  colnames(counts) <- c("Simulation", "Total")
  return(counts)
}

#' Create Outbreak Size Probability Table
#'
#' Generates a formatted table showing the probability of different outbreak sizes
#' under scenarios with and without quarantine interventions.
#'
#' @param no_quarantine_histories Data.frame of simulation histories without quarantine
#' @param quarantine_histories Data.frame of simulation histories with quarantine
#'
#' @return A data.frame with formatted outbreak probability table containing:
#'   - Outbreak Size: threshold descriptions (e.g., "≥ 2 cases")
#'   - Probability WITHOUT Quarantine: formatted percentages or "< 1%"
#'   - Probability WITH Quarantine: formatted percentages or "< 1%"
#'
#' @details Calculates probabilities for outbreak sizes of ≥2, ≥10, ≥25, ≥50, and ≥80 cases.
#'   Probabilities ≤1% are displayed as "< 1%" for readability.
tabulator <- function(no_quarantine_histories, quarantine_histories) {
  no_quarantine_counts <- format_counts(no_quarantine_histories)
  quarantine_counts <- format_counts(quarantine_histories)
  
  sizes <- c(2, 10, 25, 50, 80)
  
  outbreak_table <- data.frame(
    "Outbreak Size" = sprintf("≥ %1.0f cases", sizes),
    "Probability WITHOUT Quarantine" = sapply(sizes, function(x) {
      prob <- sum(no_quarantine_counts$Total >= x)/nrow(no_quarantine_counts)
      ifelse(prob <= 0.01, "< 1%", sprintf("%1.0f%%", prob * 100))
    }),
    "Probability WITH Quarantine" = sapply(sizes, function(x) {
      prob <- sum(quarantine_counts$Total >= x)/nrow(quarantine_counts)
      ifelse(prob <= 0.01, "< 1%", sprintf("%1.0f%%", prob * 100))
    }),
    check.names = FALSE
  )
  
  outbreak_table
}

#' Calculate Summary Statistics
#'
#' Computes mean case counts for scenarios with and without quarantine interventions.
#' Used to generate key statistics for report summaries.
#'
#' @param histories_no_quarantine Data.frame of simulation histories without quarantine
#' @param histories Data.frame of simulation histories with quarantine
#'
#' @return A list containing:
#'   - no_quarantine_mean_cases: mean number of cases without quarantine
#'   - quarantine_mean_cases: mean number of cases with quarantine
get_takehome_stats <- function(histories_no_quarantine, histories) {
  no_quarantine_counts <- format_counts(histories_no_quarantine)
  quarantine_counts <- format_counts(histories)
  
  list(
    no_quarantine_mean_cases = mean(no_quarantine_counts$Total),
    quarantine_mean_cases = mean(quarantine_counts$Total)
  )
}

#' Analyze Hospitalization Data
#'
#' Processes transition data to calculate hospitalization statistics across all
#' simulation runs, including mean and confidence intervals.
#'
#' @param transitions A data.frame containing state transition data with columns:
#'   - from: origin state
#'   - to: destination state  
#'   - counts: number of transitions
#'   - sim_num: simulation run identifier
#'
#' @return A list containing hospitalization statistics:
#'   - mean: average number of hospitalizations per simulation
#'   - lb: lower bound of 95% confidence interval (2.5th percentile)
#'   - ub: upper bound of 95% confidence interval (97.5th percentile)
#'
#' @details Filters for transitions TO "Hospitalized" state and aggregates by simulation.
analyze_hospitalizations <- function(transitions) {
  transitions <- subset(
    transitions,
    counts > 0 & from != "Hospitalized" & to == "Hospitalized"
  )
  transitions <- aggregate(counts ~ sim_num, data = transitions, FUN = sum)
  
  list(
    mean = mean(transitions$counts),
    lb   = quantile(transitions$counts, .025),
    ub   = quantile(transitions$counts, .975)
  )
}

#' Run Complete Measles Simulation Analysis
#'
#' Main function that orchestrates the complete measles simulation workflow.
#' Runs simulations both with and without quarantine interventions, then
#' analyzes results to generate comprehensive outbreak statistics.
#'
#' @param input A list containing all model parameters (see model_builder for details)
#'   Must include simulation-specific parameters:
#'   - `N days`: number of simulation days
#'   - `Replicates`: number of simulation runs
#'   - `Seed`: random seed for reproducibility
#'   - `Threads`: number of parallel threads
#'
#' @return A list containing complete analysis results:
#'   - summary_table: formatted probability table for different outbreak sizes
#'   - hospitalizations: list with quarantine/no_quarantine hospitalization stats
#'   - takehome_stats: mean case counts for both scenarios
#'   - model_no_quarantine: the configured model without quarantine
#'   - model_quarantine: the configured model with quarantine
#'
#' @details This function:
#'   1. Creates two model variants (with/without quarantine)
#'   2. Runs multiple simulations for each model
#'   3. Extracts and analyzes results
#'   4. Generates summary statistics and tables
#'   5. Returns comprehensive results for report generation
shiny_measles <- function(input) {
  
  model_measles <- model_builder(input, quarantine = TRUE)
  model_measles_no_quarantine <- model_builder(input, quarantine = FALSE)
  
  epiworldR::verbose_off(model_measles)
  epiworldR::verbose_off(model_measles_no_quarantine)
  
  invisible(capture.output(
    epiworldR::run_multiple(
    m = model_measles,
    ndays = input$`N days`,
    nsims = input$Replicates,
    seed = input$Seed,
    saver = make_saver("total_hist", "transition"),
    nthreads = input$Threads
  )
  ))
  
  invisible(capture.output(
    epiworldR::run_multiple(
    m = model_measles_no_quarantine,
    ndays = input$`N days`,
    nsims = input$Replicates,
    seed = input$Seed,
    saver = make_saver("total_hist", "transition"),
    nthreads = input$Threads
  )
  ))

  res_quarantine <- run_multiple_get_results(
    model_measles, nthreads = input$Threads
    )

  res_no_quarantine <- run_multiple_get_results(
    model_measles_no_quarantine, nthreads = input$Threads
    )

  histories <- res_quarantine$total_hist
  histories_no_quarantine <- res_no_quarantine$total_hist
  
  #plot_measles if output is a pdf using ggplot
  plot_measles <- function() {
    dat <- subset(histories, state %in% active_cases_statuses)
    dat <- aggregate(counts ~ sim_num + date, data = dat, FUN = sum)
    dat <- aggregate(counts ~ date, data = dat, FUN = function(x) {
      c(p50 = quantile(x, .5), lower = quantile(x, .025), upper = quantile(x, .975))
    })
    dat <- cbind(data.frame(dat[[1]]), data.frame(dat[[2]]))
    colnames(dat) <- c("date", "p50", "lower", "upper")
    
    dat_no_quarantine <- subset(histories_no_quarantine, state %in% active_cases_statuses)
    dat_no_quarantine <- aggregate(counts ~ sim_num + date, data = dat_no_quarantine, FUN = sum)
    dat_no_quarantine <- aggregate(
      counts ~ date, 
      data = dat_no_quarantine, 
      FUN = function(x) {
        c(p50 = quantile(x, .5), lower = quantile(x, .025), upper = quantile(x, .975))
    })
    dat_no_quarantine <- cbind(data.frame(dat_no_quarantine[[1]]), data.frame(dat_no_quarantine[[2]]))
    colnames(dat_no_quarantine) <- c("date", "p50", "lower", "upper")
    
    ggplot() +
      geom_ribbon(data = dat, aes(x = date, ymin = lower, ymax = upper), fill = "blue", alpha = 0.2) +
      geom_line(data = dat, aes(x = date, y = p50), color = "blue") +
      geom_ribbon(data = dat_no_quarantine, aes(x = date, ymin = lower, ymax = upper), fill = "red", alpha = 0.2) +
      geom_line(data = dat_no_quarantine, aes(x = date, y = p50), color = "red") +
      labs(x = "Date", y = "Active cases")
  }
  
  
  list(
    # epicurves_plot   = plot_measles(),
    summary_table    = tabulator(histories_no_quarantine, histories),
    hospitalizations = list(
      quarantine = analyze_hospitalizations(res_quarantine$transition),
      no_quarantine = analyze_hospitalizations(res_no_quarantine$transition)
    ),
    takehome_stats   = get_takehome_stats(histories_no_quarantine, histories),
    model_no_quarantine = model_measles_no_quarantine,
    model_quarantine = model_measles
  )
}
