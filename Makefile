TOP ?= alu

start_gui:
	vivado buildresults/$(TOP).xpr

elaborate:
	@echo "Elaborating..."
	vivado -mode batch -source scripts/elaborate.tcl
	rm -rf clockInfo.txt *.jou *.log

synth:
	@echo "Running synthesis..."
	vivado -mode batch -source scripts/synth.tcl
	rm -rf clockInfo.txt *.jou *.log

clean:
	rm -rf buildresults clockInfo.txt *.jou *.log .Xil *.str

.PHONY: elaborate synth clean start_gui
