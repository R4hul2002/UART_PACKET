# UART Packetizer Full Flow TCL Script with Testbench Support
# This script will:
# 1. Create the project
# 2. Add source files
# 3. Add testbench files (simulation only)
# 4. Run synthesis
# 5. Run implementation
# 6. Generate bitstream

# Set project and device parameters
set project_name "uart_packetizer"
set part_number "XC7K325T-2FFG900C"  # Change this to your target device

# Create project in current directory
create_project $project_name ./$project_name -part $part_number
set_property target_language Verilog [current_project]

# Add design source files
add_files -norecurse {
    ./src/async_fifo.v
    ./src/fsm.v
    ./src/top.v
}

# Add testbench files and mark them as simulation-only
if {[file exists "./tb/"]} {
    add_files -fileset sim_1 -norecurse {
        ./tb/atb.v
        ./tb/ftb.v
        ./tb/tb.v
    }
    # Uncomment if you have a top-level testbench
    # set_property top tb_top [get_filesets sim_1]
    # set_property top_lib xil_defaultlib [get_filesets sim_1]
} else {
    puts "Warning: Testbench directory not found at ./tb/"
}

# Set top module for synthesis
set_property top uart_packetizer_top [current_fileset]

# Update compile order for both design and simulation files
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Create basic constraints file (minimum clock constraint)
set constraints_file [open "./$project_name/$project_name.srcs/constrs_1/constraints.xdc" w]
puts $constraints_file "create_clock -name clk -period 10.000 [get_ports clk]"
close $constraints_file
add_files -fileset constrs_1 -norecurse ./$project_name/$project_name.srcs/constrs_1/constraints.xdc

# Run synthesis
puts "Running synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check for synthesis errors
if {[get_property STATUS [get_runs synth_1]] != "synth_design Complete!"} {
    error "Synthesis failed"
}

# Run implementation
puts "Running implementation..."
launch_runs impl_1 -to_step route_design -jobs 4
wait_on_run impl_1

# Check for implementation errors
if {[get_property STATUS [get_runs impl_1]] != "route_design Complete!"} {
    error "Implementation failed"
}

# Generate bitstream
puts "Generating bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Check for bitstream generation
if {[get_property STATUS [get_runs impl_1]] != "write_bitstream Complete!"} {
    error "Bitstream generation failed"
}

puts "Design flow completed successfully!"
puts "Bitstream generated in: ./$project_name/$project_name.runs/impl_1"
puts "Testbench files added to simulation fileset (sim_1)"