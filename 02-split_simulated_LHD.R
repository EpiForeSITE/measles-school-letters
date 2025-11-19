# Optional utility script to split simulation data by group/district
# This can be useful for organizing results by health district or other grouping
# 
# Note: For more advanced district-level analysis and grouping features,
# see the v1.0 release: https://github.com/EpiForeSITE/measles-school-letters/releases/tag/v1.0

simulation_data <- read.csv("simulation_data.csv")

# Split by the 'group' column (if it exists and has meaningful values)
if ("group" %in% colnames(simulation_data)) {
  split_data <- split(simulation_data, simulation_data$group)
  
  for (group_name in names(split_data)) {
    # Skip empty groups
    if (group_name == "" || is.na(group_name)) next
    
    safe_name <- gsub("[^A-Za-z0-9_]", "_", group_name)
    file_name <- paste0("simulation_data_", safe_name, ".csv")
    write.csv(split_data[[group_name]], file = file_name, row.names = FALSE)
  }
} else {
  message("No 'group' column found in simulation_data.csv. Skipping split operation.")
}
