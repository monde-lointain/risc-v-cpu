TOPLEVEL_LANG := verilog

SIM ?= icarus
WAVES ?= 1

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

RTL_DIR = ../rtl

DUT := cpu
TOPLEVEL := $(DUT)
MODULE := test_$(DUT)
VERILOG_SOURCES := \
	$(RTL_DIR)/control_defs.sv \
	$(RTL_DIR)/$(DUT).sv \
	$(RTL_DIR)/alu.sv \
	$(RTL_DIR)/alu_control.sv \
	$(RTL_DIR)/controller.sv \
	$(RTL_DIR)/datapath.sv \
	$(RTL_DIR)/dmem.sv \
	$(RTL_DIR)/imem.sv \
	$(RTL_DIR)/imm_gen.sv \
	$(RTL_DIR)/other_control.sv \
	$(RTL_DIR)/register_file.sv

COCOTB_REDUCED_LOG_FMT = True

ifeq ($(WAVES), 1)
	ifeq ($(SIM), verilator)
		EXTRA_ARGS += --trace --trace-fst --trace-structs
	endif
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

.PHONY: cleanall
cleanall: clean
	rm -rf __pycache__
	rm -rf results.xml
