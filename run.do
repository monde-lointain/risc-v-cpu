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
<<<<<<< HEAD
vlog -lint -f list1.f
=======
vlog ./rtl/definitions_pkg.sv ./rtl/imm_gen.sv ./rtl/alu.sv ./rtl/register_file.sv ./rtl/datapath.sv
>>>>>>> 85667a3e90bb46e39a89fadce7c30939a85eb008

# Optimize the design.
vopt -debugdb +acc datapath -o top_opt

# Load simulator with optimized design.
vsim -debugdb top_opt

# run the simulation
run -all

view schematic
