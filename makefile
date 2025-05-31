# Makefile for UART Packetizer Project
PROJECT = uart_packetizer
PART = # Makefile for UART Packetizer Project
PROJECT = uart_packetizer
PART = XC7K325T-2FFG900C
VIVADO = vivado
JOBS = 4
REPORT_DIR = reports

# Default target
all: bitstream

# Create project and run full implementation flow
bitstream: clean
	$(VIVADO) -mode batch -source build.tcl -tclargs $(PROJECT) $(PART) $(JOBS)
	@echo "Bitstream generated in $(PROJECT)/$(PROJECT).runs/impl_1"

# Run simulation (behavioral)
sim:
	$(VIVADO) -mode batch -source sim.tcl -tclargs $(PROJECT)
	@echo "Simulation completed. Check waveform in $(PROJECT)"

# Generate and view reports
report:
	mkdir -p $(REPORT_DIR)
	cp $(PROJECT)/$(PROJECT).runs/synth_1/*_synth_*.rpt $(REPORT_DIR)/
	cp $(PROJECT)/$(PROJECT).runs/impl_1/*_impl_*.rpt $(REPORT_DIR)/
	@echo "----------------------------------------"
	@echo "Synthesis Timing Summary:"
	@grep -A 10 "Design Timing Summary" $(REPORT_DIR)/*synth_timing_summary.rpt
	@echo "----------------------------------------"
	@echo "Implementation Timing Summary:"
	@grep -A 10 "Design Timing Summary" $(REPORT_DIR)/*impl_timing_summary.rpt
	@echo "----------------------------------------"
	@echo "All reports saved to $(REPORT_DIR)/ directory"
	@echo "Use 'make open-reports' to view all reports"

# Open reports in default application
open-reports:
	xdg-open $(REPORT_DIR)/*.rpt >/dev/null 2>&1 || open $(REPORT_DIR)/*.rpt >/dev/null 2>&1

# Clean all generated files
clean:
	rm -rf $(PROJECT) $(REPORT_DIR) *.jou *.log

# Open project in Vivado GUI
gui:
	$(VIVADO) $(PROJECT)/$(PROJECT).xpr &

.PHONY: all bitstream sim report open-reports clean gui program
VIVADO = vivado
JOBS = 4
REPORT_DIR = reports

# Default target
all: bitstream

# Create project and run full implementation flow
bitstream: clean
	$(VIVADO) -mode batch -source build.tcl -tclargs $(PROJECT) $(PART) $(JOBS)
	@echo "Bitstream generated in $(PROJECT)/$(PROJECT).runs/impl_1"

# Run simulation (behavioral)
sim:
	$(VIVADO) -mode batch -source sim.tcl -tclargs $(PROJECT)
	@echo "Simulation completed. Check waveform in $(PROJECT)"

# Generate and view reports
report:
	mkdir -p $(REPORT_DIR)
	cp $(PROJECT)/$(PROJECT).runs/synth_1/*_synth_*.rpt $(REPORT_DIR)/
	cp $(PROJECT)/$(PROJECT).runs/impl_1/*_impl_*.rpt $(REPORT_DIR)/
	@echo "----------------------------------------"
	@echo "Synthesis Timing Summary:"
	@grep -A 10 "Design Timing Summary" $(REPORT_DIR)/*synth_timing_summary.rpt
	@echo "----------------------------------------"
	@echo "Implementation Timing Summary:"
	@grep -A 10 "Design Timing Summary" $(REPORT_DIR)/*impl_timing_summary.rpt
	@echo "----------------------------------------"
	@echo "All reports saved to $(REPORT_DIR)/ directory"
	@echo "Use 'make open-reports' to view all reports"

# Open reports in default application
open-reports:
	xdg-open $(REPORT_DIR)/*.rpt >/dev/null 2>&1 || open $(REPORT_DIR)/*.rpt >/dev/null 2>&1

# Clean all generated files
clean:
	rm -rf $(PROJECT) $(REPORT_DIR) *.jou *.log

# Open project in Vivado GUI
gui:
	$(VIVADO) $(PROJECT)/$(PROJECT).xpr &


.PHONY: all bitstream sim report open-reports clean gui program