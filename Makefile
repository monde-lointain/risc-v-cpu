TEST ?= 

.PHONY: test clean
test:
	$(MAKE) -C tb TEST=$(TEST)

clean:
	rm -rf modelsim.ini work transcript vsim*
