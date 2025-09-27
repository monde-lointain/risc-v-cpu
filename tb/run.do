onbreak {resume}

# Create the library.
if [file exists work] {
    vdel -all
}
vlib work

# Compile sources
vlog if_tb.sv -f ../rtl_files.f

# Optimize
vopt -debugdb +acc if_stage_tb -o top_opt

# Load simulator with optimized design.
vsim -debugdb top_opt

# run the simulation
run -all
