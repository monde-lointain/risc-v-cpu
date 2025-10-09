# Create the library.
if [file exists work] {
    vdel -all
}
vlib work

# Compile sources
vlog ../rtl/definitions_pkg.sv ../rtl/alu.sv ./alu_tb.sv 

# Optimize
vopt +acc alu_tb -o top_opt +cover=sbfec+alu(rtl)

# Load simulator with optimized design.
vsim -coverage top_opt

set NoQuitOnFinish 1
onbreak {resume}
log */ -r
run -all
coverage save alu.ucdb
vcover report alu.ucdb
vcover report alu.ucdb -cvg -details
quit
