# Use this run.do file to run this example.
# Either bring up the Simulator and type the following at the "Simulator>" prompt:
#     do run.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do run.do -c
# (omit the "-c" to see the GUI while running from the shell)
# Remove the "quit -f" command from this file to view the results in the GUI.
#

onbreak {resume}

# Create the library.
if [file exists work] {
    vdel -all
}
vlib work
 
# Compile the source files.
vlog ./rtl/definitions_pkg.sv ./rtl/control.sv

# Optimize the design.
vopt -debugdb control -o top_opt

# Load simulator with optimized design.
vsim -debugdb top_opt

# run the simulation
run -all

view schematic
