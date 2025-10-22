TEST ?= 
TOP ?= cpu

.PHONY: all start_gui test elaborate clean
all:
	vsim -gui -do run.do

start_gui:
	vivado buildresults/$(TOP).xpr

test:
	$(MAKE) -C tb TEST=$(TEST)

elaborate:
	@echo "Elaborating..."
	vivado -mode batch -source scripts/elaborate.tcl
	rm -rf clockInfo.txt *.jou *.log

clean:
	rm -rf modelsim.ini work transcript vsim* dfx_runtime.txt buildresults clockInfo.txt *.jou *.log .Xil *.str
