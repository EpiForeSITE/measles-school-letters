ifndef END
  END := &
endif

help:
	@echo "Available targets:"
	@echo "  simulation_data.csv: Generate simulation data"
	@echo "  reports            : Generate reports"
	@echo "  clean_reports      : Remove generated reports"
	@echo "  clean_sims         : Remove simulation data"
	@echo "  clean_all          : Removes reports and sims."

simulation_data.csv: 00-simulation_data.R
	R CMD BATCH 00-simulation_data.R 00-simulation_data.Rout $(END)

sims: simulation_data.csv

reports: 01-generate_reports.R measles.qmd params.yaml
	R CMD BATCH 01-generate_reports.R 01-generate_reports.Rout $(END)

clean_reports:
	rm -f reports/*.docx reports/*/*.docx

clean_sims:
	rm -f simulation_data.csv simulation_data/*.csv

clean_all: clean_reports clean_sims

.PHONY: sims reports clean_reports clean_sims clean_all
