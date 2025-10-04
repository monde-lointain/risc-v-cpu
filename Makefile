.PHONY: test clean
test:
	$(MAKE) -C tb

clean:
	rm -rf modelsim.ini work transcript vsim*
