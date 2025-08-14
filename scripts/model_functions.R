# This R script is mostly based on the epiworldRShiny 
# package's implementation of the measles model module. 
# The code was originally developed by George V. Vega Yon
# (with contributions by Andrew Pulsipher) and adapted
# for this project by Josh Kelley and George V. Vega Yon.

library(epiworldR)
library(ggplot2)

# Model builder
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

# List of active case states
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

# Helper to format final case counts
format_counts <- function(histories) {
  exposed <- c(active_cases_statuses, "Recovered")
  counts <- subset(histories, state %in% exposed & date == max(date))
  counts <- aggregate(counts ~ sim_num, data = counts, FUN = sum)
  colnames(counts) <- c("Simulation", "Total")
  return(counts)
}

# Tabulate outbreak sizes
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

# Get summary statistics
get_takehome_stats <- function(histories_no_quarantine, histories) {
  no_quarantine_counts <- format_counts(histories_no_quarantine)
  quarantine_counts <- format_counts(histories)
  
  list(
    no_quarantine_mean_cases = mean(no_quarantine_counts$Total),
    quarantine_mean_cases = mean(quarantine_counts$Total)
  )
}

# Analyze hospitalizations
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

# Main function
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
