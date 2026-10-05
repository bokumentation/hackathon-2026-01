import os
import sys

import cocotb
from cocotb.triggers import RisingEdge

sys.path.insert(0, os.path.dirname(__file__))
from frame_gen import build_frame, flip

CLEAN = dict(
    thermostat_id=0x03391F89,
    room_temp=0x00F6,
    set_temp=0x00B5,
    state=0x00,
    tail=0x94AE16,
)

HEADER_BITS = 96
PAYLOAD_BITS = 72
TAIL_MSB_INDEX = HEADER_BITS + PAYLOAD_BITS


async def reset(dut, cycles=4):
    dut.rst_n.value = 0
    dut.sclk.value = 0
    dut.sdata.value = 0
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def drive_bits(dut, bits):
    for bit in bits:
        dut.sdata.value = int(bit)
        dut.sclk.value = 1
        await RisingEdge(dut.clk)
        dut.sclk.value = 0
        await RisingEdge(dut.clk)


def fields(dut):
    return dict(
        thermostat_id=int(dut.thermostat_id.value),
        room_temp=int(dut.room_temp.value),
        set_temp=int(dut.set_temp.value),
        state=int(dut.state.value),
        tail=(int(dut.tail_1.value) << 16)
        | (int(dut.tail_2.value) << 8)
        | int(dut.tail_3.value),
    )


async def replay(dut, frame):
    await reset(dut)
    await drive_bits(dut, frame)
    for _ in range(4):
        await RisingEdge(dut.clk)


@cocotb.test()
async def test_clean_frame(dut):
    frame = build_frame(
        CLEAN["thermostat_id"],
        CLEAN["room_temp"],
        CLEAN["set_temp"],
        CLEAN["state"],
        CLEAN["tail"],
    )
    await replay(dut, frame)
    got = fields(dut)
    dut._log.info("clean: full=%d %s", int(dut.full.value), got)
    assert int(dut.full.value) == 1
    assert got["thermostat_id"] == CLEAN["thermostat_id"]
    assert got["tail"] == CLEAN["tail"]


@cocotb.test()
async def test_corrupt_payload_is_accepted(dut):
    frame = build_frame(
        CLEAN["thermostat_id"],
        CLEAN["room_temp"],
        CLEAN["set_temp"],
        CLEAN["state"],
        CLEAN["tail"],
    )
    frame = flip(frame, HEADER_BITS + 5)
    await replay(dut, frame)
    got = fields(dut)
    dut._log.info("payload flip: full=%d %s", int(dut.full.value), got)
    assert int(dut.full.value) == 1, "baseline accepts a corrupted payload"
    assert got["thermostat_id"] != CLEAN["thermostat_id"]


@cocotb.test()
async def test_corrupt_integrity_field_is_accepted(dut):
    frame = build_frame(
        CLEAN["thermostat_id"],
        CLEAN["room_temp"],
        CLEAN["set_temp"],
        CLEAN["state"],
        CLEAN["tail"],
    )
    frame = flip(frame, TAIL_MSB_INDEX)
    await replay(dut, frame)
    got = fields(dut)
    dut._log.info("tail flip: full=%d %s", int(dut.full.value), got)
    assert int(dut.full.value) == 1, "baseline accepts a corrupted integrity field"
    assert got["tail"] != CLEAN["tail"]
