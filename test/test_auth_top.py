import json
import os
import sys

import cocotb
from cocotb.triggers import RisingEdge

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import simon_ref as ref

OUT = os.path.join(HERE, "..", "sim", "out")

KEY = 0x1918111009080100


def tag_of(counter, payload, key=KEY):
    words = [counter & 0xFFFFFFFF, payload & 0xFFFFFFFF, (payload >> 32) & 0xFFFFFFFF]
    return ref.cbcmac(words, key)


async def reset(dut):
    dut.rst_n.value = 0
    dut.key.value = 0
    dut.key_load.value = 0
    dut.counter.value = 0
    dut.payload.value = 0
    dut.tag_in.value = 0
    dut.start.value = 0
    dut.fault_ack.value = 0
    dut.p_frame_done.value = 0
    dut.p_framing_ok.value = 0
    dut.p_crc_ok.value = 0
    dut.p_frame_data.value = 0
    dut.p_fault_ack.value = 0
    for _ in range(4):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)


async def load_key(dut, key):
    dut.key.value = key
    dut.key_load.value = 1
    await RisingEdge(dut.clk)
    dut.key_load.value = 0
    await RisingEdge(dut.clk)


async def run_frame(dut, counter, payload, tag):
    dut.counter.value = counter
    dut.payload.value = payload
    dut.tag_in.value = tag
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    to_done = 0
    while int(dut.done.value) == 0:
        await RisingEdge(dut.clk)
        to_done += 1
        if to_done > 512:
            raise AssertionError("auth top did not finish")

    hf_before = int(dut.host_full.value)
    fault_before = int(dut.fault.value)
    to_full = to_done
    for _ in range(16):
        await RisingEdge(dut.clk)
        to_full += 1
        hf = int(dut.host_full.value)
        flt = int(dut.fault.value)
        if (hf == 1 and hf_before == 0) or (flt == 1 and fault_before == 0):
            break

    return {
        "auth": int(dut.auth_ok.value),
        "fresh": int(dut.fresh_ok.value),
        "host_full": int(dut.host_full.value),
        "fault": int(dut.fault.value),
        "data": int(dut.host_data_q.value),
        "to_done": to_done,
        "to_full": to_full,
    }


@cocotb.test()
async def test_clean_commit(dut):
    await reset(dut)
    await load_key(dut, KEY)
    counter = 1
    payload = 0x1122334455667788
    res = await run_frame(dut, counter, payload, tag_of(counter, payload))
    assert res["auth"] == 1 and res["fresh"] == 1
    assert res["host_full"] == 1 and res["fault"] == 0
    assert res["data"] == ((counter << 64) | payload), "committed data mismatch"
    dut._log.info("clean commit; to_done=%d to_full=%d", res["to_done"], res["to_full"])


@cocotb.test()
async def test_forgery_and_replay_rejected(dut):
    await reset(dut)
    await load_key(dut, KEY)
    payload = 0xAABBCCDDEEFF0011

    res = await run_frame(dut, 1, payload ^ 1, tag_of(1, payload))
    assert res["host_full"] == 0 and res["fault"] == 1, "forgery committed"

    res = await run_frame(dut, 2, payload, tag_of(2, payload))
    assert res["host_full"] == 1

    res = await run_frame(dut, 2, payload, tag_of(2, payload))
    assert res["auth"] == 1 and res["fresh"] == 0
    assert res["host_full"] == 0 and res["fault"] == 1, "replay committed"


@cocotb.test()
async def test_sticky_fault_and_ack(dut):
    await reset(dut)
    await load_key(dut, KEY)
    payload = 0x0F0F0F0F0F0F0F0F
    res = await run_frame(dut, 1, payload, 0xDEADBEEF)
    assert res["fault"] == 1
    for _ in range(10):
        await RisingEdge(dut.clk)
        assert int(dut.fault.value) == 1, "fault not sticky"
    dut.fault_ack.value = 1
    await RisingEdge(dut.clk)
    dut.fault_ack.value = 0
    await RisingEdge(dut.clk)
    assert int(dut.fault.value) == 0, "fault not acknowledged"


@cocotb.test()
async def test_commit_latency(dut):
    await reset(dut)
    await load_key(dut, KEY)
    counter = 1
    payload = 0x0102030405060708
    res = await run_frame(dut, counter, payload, tag_of(counter, payload))
    commit = res["to_full"] - res["to_done"]
    dut._log.info("commit latency = %d cycle(s)", commit)
    assert commit == 1
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "auth_latency.json"), "w") as handle:
        json.dump(
            {"to_done_cycles": res["to_done"], "to_full_cycles": res["to_full"], "commit_cycles": commit},
            handle,
        )


@cocotb.test()
async def test_inputs_changed_mid_frame_not_committed(dut):
    await reset(dut)
    await load_key(dut, KEY)

    counter_orig  = 1
    payload_orig  = 0x1122334455667788
    tag_orig      = tag_of(counter_orig, payload_orig)

    counter_other = 0xDEADBEEF
    payload_other = 0xCAFECAFECAFECAFE

    dut.counter.value = counter_orig
    dut.payload.value = payload_orig
    dut.tag_in.value  = tag_orig
    dut.start.value   = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0

    for _ in range(10):
        await RisingEdge(dut.clk)

    dut.counter.value = counter_other
    dut.payload.value = payload_other

    to_done = 0
    while int(dut.done.value) == 0:
        await RisingEdge(dut.clk)
        to_done += 1
        if to_done > 512:
            raise AssertionError("auth top did not finish")
    await RisingEdge(dut.clk)

    assert int(dut.host_full.value) == 1, "frame should be accepted (valid tag for original inputs)"
    expected = (counter_orig << 64) | payload_orig
    assert int(dut.host_data_q.value) == expected, \
        f"host_data_q={int(dut.host_data_q.value):#x} expected={expected:#x}; committed data not authenticated data (TOCTOU)"


@cocotb.test()
async def test_two_profiles(dut):
    await reset(dut)

    dut.p_frame_data.value = 0x0123456789ABCDEF01234567
    dut.p_framing_ok.value = 1
    dut.p_crc_ok.value = 1
    dut.p_frame_done.value = 1
    await RisingEdge(dut.clk)
    dut.p_frame_done.value = 0
    await RisingEdge(dut.clk)
    assert int(dut.p_host_full.value) == 1 and int(dut.p_fault.value) == 0

    dut.p_crc_ok.value = 0
    dut.p_frame_done.value = 1
    await RisingEdge(dut.clk)
    dut.p_frame_done.value = 0
    await RisingEdge(dut.clk)
    assert int(dut.p_host_full.value) == 0 and int(dut.p_fault.value) == 1

    dut.p_fault_ack.value = 1
    await RisingEdge(dut.clk)
    dut.p_fault_ack.value = 0
    await RisingEdge(dut.clk)

    await load_key(dut, KEY)
    counter = 1
    payload = 0xCAFEBABE12345678
    res = await run_frame(dut, counter, payload, tag_of(counter, payload))
    assert res["host_full"] == 1 and res["fault"] == 0
    dut._log.info("two profiles share the same commit core and both commit")
