# Makefile for Vivado simulation and synthesis

# Project and top-level module names
PROJECT_NAME = packetizer_fsm_project
TOP_MODULE = packetizer_fsm_tb

# Source files
SRC = packetizer_fsm.v packetizer_fsm_tb.v

# TCL script for Vivado flow
TCL_SCRIPT = run_vivado.tcl

.PHONY: all synth sim clean

all: synth sim

synth:
	vivado -mode batch -source $(TCL_SCRIPT) -tclargs synth $(PROJECT_NAME) $(TOP_MODULE) "$(SRC)"

sim:
	vivado -mode batch -source $(TCL_SCRIPT) -tclargs sim $(PROJECT_NAME) $(TOP_MODULE) "$(SRC)"

clean:
	rm -rf $(PROJECT_NAME) .Xil vivado*.log vivado*.jou webtalk* simulation runs
