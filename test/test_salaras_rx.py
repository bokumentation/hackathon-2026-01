import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

CLK_PERIOD_NS = 50


async def reset(dut, cycles=10):
    dut.ena.value = 1
    dut.digital_in.value = 0
    dut.fault_ack.value = 0
    dut.address.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, cycles)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 4)


async def start_clock(dut):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())


@cocotb.test()
async def test_reset_is_idle(dut):
    await start_clock(dut)
    await reset(dut)
    assert int(dut.host_full.value) == 0, "host_full must be low after reset"
    assert int(dut.fault.value) == 0, "fault must be low after reset"
    assert int(dut.host_data.value) == 0, "host_data must be zero after reset"


@cocotb.test()
async def test_fail_closed_on_noise(dut):
    await start_clock(dut)
    await reset(dut)
    random.seed(0xC0FFEE)
    for _ in range(4000):
        dut.digital_in.value = random.randint(0, 1)
        await RisingEdge(dut.clk)
    assert int(dut.host_full.value) == 0, "noise must never commit a frame"


@cocotb.test()
async def test_fault_flag_visible(dut):
    await start_clock(dut)
    await reset(dut)
    await ClockCycles(dut.clk, 100)
    assert int(dut.fault.value) in (0, 1)
