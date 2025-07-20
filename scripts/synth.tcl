
# Define output directory
set outputDir ../buildresults
file mkdir $outputDir

# Create dummy project
create_project datapath ./buildresults -part xc7a35tcpg236-1 -force

# Compile all RTL files that will be synthesized 
if {[glob -nocomplain ./rtl/*.sv] != ""} {
    puts "Adding SV files..."
    add_files [glob ./rtl/*.sv]
}
if {[glob -nocomplain ./lib/*.sv] != ""} {
    add_files [glob ./lib/*.sv]
}
if {[glob -nocomplain ./rtl/*.v] != ""} {
    puts "Adding Verilog files..."
    add_files [glob ./rtl/*.v]
}
if {[glob -nocomplain ./rtl/*.vhd] != ""} {
    puts "Adding VHDL files..."
    add_files [glob ./rtl/*.vhd]
}

puts "Importing files to project folder..."
import_files -force -norecurse

puts "Updating compile order for source files..."
set_property top datapath [current_fileset]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Synthesizing design..."
launch_runs synth_1
wait_on_run synth_1

puts "Running place and route..."
launch_runs impl_1 -to_step route_design
wait_on_run impl_1

puts "Starting GUI..."
start_gui
