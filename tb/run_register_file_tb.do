# Create the library.
if [file exists work] {
    vdel -all
}
vlib work

# Compile sources
vlog ../rtl/register_file.sv ./register_file_tb.sv 

# Optimize
vopt -debugdb +acc register_file_tb -o top_opt +cover=sbfec+register_file(rtl)

# Load simulator with optimized design.
vsim -debugdb -coverage top_opt

set NoQuitOnFinish 1
onbreak {resume}
log */ -r
run -all
coverage save register_file.ucdb
vcover report register_file.ucdb
vcover report register_file.ucdb -cvg -details
quit
