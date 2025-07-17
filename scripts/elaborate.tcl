# Define output directory
set outputDir ../buildresults
file mkdir $outputDir

# Create dummy project
create_project alu ./buildresults -part xc7a35tcpg236-1 -force

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

puts "Synthesizing design..."
synth_design -rtl -name alu -top alu -flatten_hierarchy full 

puts "Starting GUI..."
start_gui
