# Create the library.
if [file exists work] {
    vdel -all
}
vlib work

# Compile sources
vlog ../rtl/definitions_pkg.sv ../rtl/imm_gen.sv ./imm_gen_tb.sv 

# Optimize
vopt +acc imm_gen_tb -o top_opt +cover=sbfec+imm_gen(rtl)

# Load simulator with optimized design.
vsim -coverage top_opt

set NoQuitOnFinish 1
onbreak {resume}
log */ -r
run -all
coverage save imm_gen.ucdb
vcover report imm_gen.ucdb
vcover report imm_gen.ucdb -cvg -details
quit
