onbreak {resume}

# Create the library.
if [file exists work] {
    vdel -all
}
vlib work

# Compile sources
vlog tb.sv ../rtl/pc.sv

# Optimize
vopt -debugdb +acc tb_pc_mux -o top_opt

# Load simulator with optimized design.
vsim -debugdb top_opt

# run the simulation
run -all
