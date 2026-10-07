import os
import sys

import cocotb
from cocotb.triggers import RisingEdge

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import simon_ref as ref

KEY = 0x1918111009080100


def tag_of(counter, payload, key=KEY):
    words = [counter & 0xFFFFFFFF, payload & 0xFFFFFFFF, (payload >> 32) & 0xFFFFFFFF]
    return ref.cbcmac(words, key)


def _bit(value, width, pos):
    return (value >> (width - 1 - pos)) & 1


async def _reset(dut):
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.ena.value = 1
    for _ in range(4):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def _shift_bits(dut, value, width, key_mode):
    for i in range(width):
        bit = _bit(value, width, i)
        dut.ui_in.value = (key_mode << 3) | (1 << 1) | (bit & 1)
        await RisingEdge(dut.clk)
    dut.ui_in.value = (key_mode << 3)
    await RisingEdge(dut.clk)


async def _load_key(dut, key):
    await _shift_bits(dut, key, 64, key_mode=1)
    for _ in range(4):
        await RisingEdge(dut.clk)


async def _send_frame(dut, counter, payload, tag):
    frame = ((counter & 0xFFFFFFFF) << 96) | ((payload & 0xFFFFFFFFFFFFFFFF) << 32) | (tag & 0xFFFFFFFF)
    await _shift_bits(dut, frame, 128, key_mode=0)
    to_done = 0
    while not ((int(dut.uo_out.value) >> 7) & 1):
        await RisingEdge(dut.clk)
        to_done += 1
        if to_done > 512:
            raise AssertionError("wrapper did not signal done")
    await RisingEdge(dut.clk)
    uo = int(dut.uo_out.value)
    return {
        "done":      (uo >> 7) & 1,
        "host_full": (uo >> 6) & 1,
        "fault":     (uo >> 5) & 1,
        "auth_ok":   (uo >> 4) & 1,
        "fresh_ok":  (uo >> 3) & 1,
    }


@cocotb.test()
async def test_key_then_clean_frame(dut):
    await _reset(dut)
    await _load_key(dut, KEY)

    counter = 1
    payload = 0x1122334455667788
    res = await _send_frame(dut, counter, payload, tag_of(counter, payload))
    assert res["host_full"] == 1, "clean frame not committed"
    assert res["fault"] == 0, "fault raised on clean frame"
    dut._log.info("key_then_clean_frame: host_full=%d fault=%d", res["host_full"], res["fault"])


@cocotb.test()
async def test_wrong_tag_rejected(dut):
    await _reset(dut)
    await _load_key(dut, KEY)

    counter = 2
    payload = 0xAABBCCDDEEFF0011
    bad_tag = tag_of(counter, payload) ^ 0x1
    res = await _send_frame(dut, counter, payload, bad_tag)
    assert res["host_full"] == 0, "forged frame committed"
    assert res["fault"] == 1, "fault not raised on forgery"
    dut._log.info("wrong_tag_rejected: host_full=%d fault=%d", res["host_full"], res["fault"])


@cocotb.test()
async def test_replay_rejected(dut):
    await _reset(dut)
    await _load_key(dut, KEY)

    counter = 3
    payload = 0x0102030405060708
    tag = tag_of(counter, payload)

    res = await _send_frame(dut, counter, payload, tag)
    assert res["host_full"] == 1, "first frame not committed"

    dut.ui_in.value = (1 << 2)
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    res2 = await _send_frame(dut, counter, payload, tag)
    assert res2["host_full"] == 0, "replayed frame committed"
    assert res2["fault"] == 1, "fault not raised on replay"
    dut._log.info("replay_rejected: host_full=%d fault=%d", res2["host_full"], res2["fault"])


@cocotb.test()
async def test_second_key_load_ignored(dut):
    await _reset(dut)
    await _load_key(dut, KEY)

    attacker_key = 0xDEADBEEFCAFEBABE
    await _shift_bits(dut, attacker_key, 64, key_mode=1)
    for _ in range(4):
        await RisingEdge(dut.clk)

    counter = 4
    payload = 0xFEDCBA9876543210
    tag_real    = tag_of(counter, payload, KEY)
    tag_attacker = tag_of(counter, payload, attacker_key)

    res_attacker = await _send_frame(dut, counter, payload, tag_attacker)
    assert res_attacker["host_full"] == 0, "attacker-keyed frame committed after key_locked"
    assert res_attacker["fault"] == 1, "fault not raised on attacker frame"

    dut.ui_in.value = (1 << 2)
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    counter2 = 5
    payload2 = 0x0807060504030201
    res_real = await _send_frame(dut, counter2, payload2, tag_of(counter2, payload2, KEY))
    assert res_real["host_full"] == 1, "legitimate frame rejected after attacker attempt"
    dut._log.info("second_key_ignored: attacker full=%d real full=%d", res_attacker["host_full"], res_real["host_full"])


@cocotb.test()
async def test_truncated_frame_rejected(dut):
    await _reset(dut)
    await _load_key(dut, KEY)

    for i in range(10):
        dut.ui_in.value = (1 << 1) | (i & 1)
        await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    for _ in range(2):
        await RisingEdge(dut.clk)

    uo = int(dut.uo_out.value)
    fault = (uo >> 5) & 1
    host_full = (uo >> 6) & 1
    assert fault == 1, "truncated frame did not raise a framing fault"
    assert host_full == 0, "truncated frame committed"

    dut.ui_in.value = (1 << 2)
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)

    counter = 7
    payload = 0x0BADF00DCAFEBABE
    res = await _send_frame(dut, counter, payload, tag_of(counter, payload, KEY))
    assert res["host_full"] == 1, "clean frame rejected after a framing fault"
    dut._log.info("truncated_frame_rejected: recovered, host_full=%d", res["host_full"])


@cocotb.test()
async def test_frame_before_key_ignored(dut):
    await _reset(dut)

    counter = 6
    payload = 0x1234567890ABCDEF
    tag = tag_of(counter, payload)

    frame = ((counter & 0xFFFFFFFF) << 96) | ((payload & 0xFFFFFFFFFFFFFFFF) << 32) | (tag & 0xFFFFFFFF)
    await _shift_bits(dut, frame, 128, key_mode=0)

    for _ in range(200):
        await RisingEdge(dut.clk)

    uo = int(dut.uo_out.value)
    host_full = (uo >> 6) & 1
    fault     = (uo >> 5) & 1
    assert host_full == 0, "frame committed before key loaded"
    assert fault == 0, "fault raised unexpectedly before key loaded"
    dut._log.info("frame_before_key_ignored: host_full=%d fault=%d", host_full, fault)
