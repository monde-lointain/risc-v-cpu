import cocotb
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.log import SimLog
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer, Combine

@cocotb.test()
async def run_test(dut):
    cocotb.start_soon(Clock(dut.clk, 50, units="ns").start())
    dut.rst_n.setimmediatevalue(1)

    log = SimLog("cocotb.tb")
    log.info("Hello testbench!")

    for i in range(50):
        log.info(f"Cycle {i}")
        await RisingEdge(dut.rst_n)
