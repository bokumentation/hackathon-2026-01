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


async def reset(dut):
    dut.rst_n.value = 0
    dut.key.value = 0
    dut.key_load.value = 0
    dut.block_in.value = 0
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


async def run_block(dut, plaintext):
    dut.block_in.value = plaintext
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    cycles = 0
    while True:
        await RisingEdge(dut.clk)
        cycles += 1
        if int(dut.done.value) == 1:
            break
        if cycles > 128:
            raise AssertionError("simon did not finish")
    return int(dut.block_out.value), cycles


@cocotb.test()
async def test_block_vectors(dut):
    await reset(dut)
    await load_key(dut, KEY)

    vectors = [(0x65656877, 0xC69BE9BB)]
    random.seed(1234)
    for _ in range(48):
        pt = random.getrandbits(32)
        vectors.append((pt, ref.encrypt_block(pt, KEY)))

    worst = 0
    for pt, expected in vectors:
        got, cycles = await run_block(dut, pt)
        worst = max(worst, cycles)
        assert got == expected, f"pt={pt:08X} got={got:08X} exp={expected:08X}"

    dut._log.info("block vectors pass (%d); worst latency=%d cycles", len(vectors), worst)
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "simon_latency.json"), "w") as handle:
        json.dump({"block_latency_cycles": worst, "vectors": len(vectors)}, handle)


@cocotb.test()
async def test_cbcmac(dut):
    await reset(dut)
    await load_key(dut, KEY)

    words = [0x11223344, 0x55667788, 0x99AABBCC]
    expected = ref.cbcmac(words, KEY)
    state = 0
    for word in words:
        state, _ = await run_block(dut, state ^ word)
    assert state == expected, f"cbcmac got={state:08X} exp={expected:08X}"
    dut._log.info("cbcmac matches reference: %08X", state)
