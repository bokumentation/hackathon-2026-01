import json
import os
import random
import sys

import cocotb
from cocotb.triggers import RisingEdge

HERE = os.path.dirname(__file__)
sys.path.insert(0, HERE)
import simon_ref as ref

OUT = os.path.join(HERE, "..", "sim", "out")

KEY = 0x1918111009080100
WRONG_KEY = 0x0102030405060708


def tag_of(counter, payload, key):
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
    cycles = 0
    while True:
        await RisingEdge(dut.clk)
        cycles += 1
        if int(dut.done.value) == 1:
            break
        if cycles > 512:
            raise AssertionError("l2_auth did not finish")
    return int(dut.auth_ok.value), int(dut.fresh_ok.value), int(dut.latency.value), cycles


@cocotb.test()
async def test_clean_and_false_reject(dut):
    await reset(dut)
    await load_key(dut, KEY)
    worst = 0
    for n in range(1, 21):
        payload = 0xA000000000000000 | n
        tag = tag_of(n, payload, KEY)
        auth, fresh, lat, cycles = await run_frame(dut, n, payload, tag)
        worst = max(worst, cycles)
        assert auth == 1 and fresh == 1, f"clean frame {n} rejected"
    dut._log.info("20 clean frames accepted; worst latency=%d cycles", worst)
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "l2_latency.json"), "w") as handle:
        json.dump({"frames": 20, "worst_latency_cycles": worst}, handle)


@cocotb.test()
async def test_forgery_and_wrong_key(dut):
    await reset(dut)
    await load_key(dut, KEY)
    payload = 0x1122334455667788
    tag = tag_of(1, payload, KEY)

    auth, _, _, _ = await run_frame(dut, 1, payload ^ 0x10, tag)
    assert auth == 0, "forged payload accepted"

    bad_tag = tag_of(1, payload, WRONG_KEY)
    auth, _, _, _ = await run_frame(dut, 2, payload, bad_tag)
    assert auth == 0, "wrong-key tag accepted"


@cocotb.test()
async def test_replay_and_stale(dut):
    await reset(dut)
    await load_key(dut, KEY)
    payload = 0xDEADBEEFCAFEBABE
    for n in (10, 11, 12):
        tag = tag_of(n, payload, KEY)
        auth, fresh, _, _ = await run_frame(dut, n, payload, tag)
        assert auth == 1 and fresh == 1

    replay_tag = tag_of(12, payload, KEY)
    auth, fresh, _, _ = await run_frame(dut, 12, payload, replay_tag)
    assert auth == 1 and fresh == 0, "replay not rejected"

    stale_tag = tag_of(11, payload, KEY)
    auth, fresh, _, _ = await run_frame(dut, 11, payload, stale_tag)
    assert auth == 1 and fresh == 0, "stale counter not rejected"

    fresh_tag = tag_of(13, payload, KEY)
    auth, fresh, _, _ = await run_frame(dut, 13, payload, fresh_tag)
    assert auth == 1 and fresh == 1, "fresh counter rejected"


@cocotb.test()
async def test_bit_flips(dut):
    await reset(dut)
    await load_key(dut, KEY)
    counter = 100
    payload = 0x0011223344556677
    tag = tag_of(counter, payload, KEY)
    rejected = 0
    total = 0
    for i in range(32):
        auth, _, _, _ = await run_frame(dut, counter ^ (1 << i), payload, tag)
        rejected += 1 - auth
        total += 1
    for i in range(64):
        auth, _, _, _ = await run_frame(dut, counter, payload ^ (1 << i), tag)
        rejected += 1 - auth
        total += 1
    for i in range(32):
        auth, _, _, _ = await run_frame(dut, counter, payload, tag ^ (1 << i))
        rejected += 1 - auth
        total += 1
    dut._log.info("bit flips rejected %d/%d", rejected, total)
    assert rejected == total, "a single-bit flip was not detected"
