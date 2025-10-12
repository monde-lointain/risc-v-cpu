TEST ?= 

.PHONY: all test clean
all:
	vsim -gui -do run.do

test:
	$(MAKE) -C tb TEST=$(TEST)

clean:
	rm -rf modelsim.ini work transcript vsim*
