# Simulation TCL script
set project_name [lindex $argv 0]

open_project $project_name/$project_name.xpr

# Set simulation properties
set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

# Launch simulation
launch_simulation -simset sim_1 -mode behavioral
run all
close_sim