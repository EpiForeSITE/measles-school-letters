simulation_data <- read.csv("simulation_data.csv")

split_data <- split(simulation_data, simulation_data$health_district)

for (district_name in names(split_data)) {
  safe_name <- gsub("[^A-Za-z0-9_]", "_", district_name)
  
  file_name <- paste0("simulation_data_", safe_name, ".csv")
  
  write.csv(split_data[[district_name]], file = file_name, row.names = FALSE)
}
