import json
import os
import sys

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import simon_ref as ref

OUT = os.path.join(HERE, "..", "sim", "out")

KEY = 0x1918111009080100


def tag_of(counter, payload, key=KEY):
    words = [counter & 0xFFFFFFFF, payload & 0xFFFFFFFF, (payload >> 32) & 0xFFFFFFFF]
    return ref.cbcmac(words, key)


def frame_of(counter, payload, tag):
    return ((counter & 0xFFFFFFFF) << 96) | ((payload & 0xFFFFFFFFFFFFFFFF) << 32) | (tag & 0xFFFFFFFF)


async def setup(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.rst_n.value = 0
    dut.tx_send.value = 0
    dut.corrupt.value = 0
    dut.fault_ack.value = 0
    dut.key.value = 0
    dut.key_load.value = 0
    dut.tx_frame.value = 0
    for _ in range(4):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    dut.key.value = KEY
    dut.key_load.value = 1
    await RisingEdge(dut.clk)
    dut.key_load.value = 0

    for _ in range(400):
        await RisingEdge(dut.clk)
        if int(dut.word_lock.value) == 1:
            return
    raise AssertionError("link did not acquire word lock")


async def ack(dut):
    if int(dut.fault.value) == 1:
        dut.fault_ack.value = 1
        await RisingEdge(dut.clk)
        dut.fault_ack.value = 0
        await RisingEdge(dut.clk)


async def send_frame(dut, frame, corrupt_cycle=None):
    dut.tx_frame.value = frame
    dut.tx_send.value = 1
    await RisingEdge(dut.clk)
    dut.tx_send.value = 0

    cycles = 0
    while True:
        await RisingEdge(dut.clk)
        cycles += 1
        if corrupt_cycle is not None and cycles == corrupt_cycle:
            dut.corrupt.value = 1
            await RisingEdge(dut.clk)
            dut.corrupt.value = 0
        if int(dut.done.value) == 1 or int(dut.fault.value) == 1:
            break
        if cycles > 8000:
            raise AssertionError("link did not finish")
    await RisingEdge(dut.clk)
    return {
        "host_full": int(dut.host_full.value),
        "fault": int(dut.fault.value),
        "auth_ok": int(dut.auth_ok.value),
        "fresh_ok": int(dut.fresh_ok.value),
        "data": int(dut.host_data_q.value),
        "cycles": cycles,
    }


@cocotb.test()
async def test_clean_frame_committed(dut):
    await setup(dut)
    counter, payload = 1, 0x1122334455667788
    res = await send_frame(dut, frame_of(counter, payload, tag_of(counter, payload)))
    assert res["host_full"] == 1 and res["fault"] == 0, "clean frame rejected"
    assert res["data"] == ((counter << 64) | payload), "committed data mismatch"
    dut._log.info("clean frame committed over the serial link; latency=%d cycles", res["cycles"])
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "link_latency.json"), "w") as handle:
        json.dump({"end_to_end_cycles": res["cycles"]}, handle)


@cocotb.test()
async def test_forgery_rejected(dut):
    await setup(dut)
    counter, payload = 2, 0xAABBCCDDEEFF0011
    bad_tag = tag_of(counter, payload) ^ 0x1
    res = await send_frame(dut, frame_of(counter, payload, bad_tag))
    assert res["host_full"] == 0 and res["fault"] == 1, "forged frame committed"
    dut._log.info("forged frame rejected over the serial link")


@cocotb.test()
async def test_replay_rejected(dut):
    await setup(dut)
    counter, payload = 3, 0x0102030405060708
    tag = tag_of(counter, payload)
    res1 = await send_frame(dut, frame_of(counter, payload, tag))
    assert res1["host_full"] == 1, "first frame not committed"
    await ack(dut)
    res2 = await send_frame(dut, frame_of(counter, payload, tag))
    assert res2["host_full"] == 0 and res2["fault"] == 1, "replayed frame committed"
    dut._log.info("replayed frame rejected over the serial link")


@cocotb.test()
async def test_line_error_rejected(dut):
    await setup(dut)
    counter, payload = 4, 0x0F0F0F0F0F0F0F0F
    res = await send_frame(dut, frame_of(counter, payload, tag_of(counter, payload)), corrupt_cycle=60)
    assert res["host_full"] == 0 and res["fault"] == 1, "corrupt line did not fail closed"
    dut._log.info("line error failed closed over the serial link")


@cocotb.test()
async def test_bit_flip_rejected(dut):
    await setup(dut)
    counter, payload = 5, 0x0F1E2D3C4B5A6978
    base = frame_of(counter, payload, tag_of(counter, payload))
    rejected = 0
    for i in range(128):
        await ack(dut)
        res = await send_frame(dut, base ^ (1 << i))
        if res["host_full"] == 0 and res["fault"] == 1:
            rejected += 1
    dut._log.info("link single-bit flips rejected %d/128", rejected)
    assert rejected == 128, "a single-bit flip was not rejected over the serial link"
