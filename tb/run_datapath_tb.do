# Create the library.
if [file exists work] {
    vdel -all
}
vlib work

# Compile sources
vlog ../rtl/definitions_pkg.sv ../rtl/imm_gen.sv ../rtl/alu.sv ../rtl/register_file.sv ../rtl/datapath.sv ./datapath_tb.sv 

# Optimize
vopt +acc datapath_tb -o top_opt +cover=sbfec+datapath(rtl)

# Load simulator with optimized design.
vsim -coverage top_opt

set NoQuitOnFinish 1
onbreak {resume}
log */ -r
run -all
coverage save datapath.ucdb
vcover report datapath.ucdb
vcover report datapath.ucdb -cvg -details
quit
