import json
import os

import cocotb
from cocotb.triggers import RisingEdge

OUT = os.path.join(os.path.dirname(__file__), "..", "sim", "out")

POLY = 0x864CFB
INIT = 0xB704CE


def crc24(bits):
    crc = INIT
    for bit in bits:
        msb = (crc >> 23) & 1
        crc = (crc << 1) & 0xFFFFFF
        if msb ^ bit:
            crc ^= POLY
    return crc


async def reset(dut):
    dut.rst_n.value = 0
    dut.frame_start.value = 0
    dut.bit_valid.value = 0
    dut.bit_data.value = 0
    dut.frame_done.value = 0
    dut.expected_crc.value = 0
    for _ in range(4):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_crc_latency(dut):
    await reset(dut)

    bits = [i & 1 for i in range(72)]

    dut.frame_start.value = 1
    await RisingEdge(dut.clk)
    dut.frame_start.value = 0

    cycles = 0
    for bit in bits:
        dut.bit_valid.value = 1
        dut.bit_data.value = bit
        await RisingEdge(dut.clk)
        cycles += 1
    dut.bit_valid.value = 0
    await RisingEdge(dut.clk)

    expected = crc24(bits)
    dut.expected_crc.value = expected
    dut.frame_done.value = 1
    await RisingEdge(dut.clk)
    cycles += 1
    dut.frame_done.value = 0
    await RisingEdge(dut.clk)

    dut._log.info(
        "CRC latency = %d cycles; value=%06X expected=%06X crc_ok=%d",
        cycles,
        int(dut.crc_value.value),
        expected,
        int(dut.crc_ok.value),
    )
    assert int(dut.crc_ok.value) == 1, "crc mismatch"

    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "crc_latency.json"), "w") as handle:
        json.dump({"bits": 72, "latency_cycles": cycles}, handle)
