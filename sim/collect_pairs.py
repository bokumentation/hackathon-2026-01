"""Collect unique (payload, tail) pairs by replaying every baseline capture.

This drives the real tt07-bep-decode Manchester waveform captures into the
baseline top and reads the decoded fields. Run with:

    make -f Makefile -f tb_baseline_top.mk ...   (or the collect target)
"""

import csv
import glob
import os
from fractions import Fraction

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

HERE = os.path.dirname(__file__)
DATA = os.path.join(HERE, "..", "baseline", "tt07-bep-decode", "test", "data")
READOUT = Timer(Fraction(1, 100_000), units="sec")

FIELDS = [
    (0, "id0"),
    (1, "id1"),
    (2, "id2"),
    (3, "id3"),
    (4, "room0"),
    (5, "room1"),
    (6, "set0"),
    (7, "set1"),
    (8, "state"),
    (9, "tail1"),
    (10, "tail2"),
    (11, "tail3"),
]


def load(path, channel=2):
    rows = []
    with open(path, newline="") as f:
        for row in csv.reader(f):
            if not row or row[0].startswith("#") or row[0] == "Time (s)":
                continue
            rows.append(int(row[channel]))
    return rows


def capture_files():
    files = [os.path.join(DATA, "transmission_digital_hs.csv")]
    files += sorted(glob.glob(os.path.join(DATA, "hs", "*.csv")))
    files += sorted(glob.glob(os.path.join(DATA, "hs_long", "*.csv")))
    files += sorted(glob.glob(os.path.join(DATA, "hs_repeating", "*.csv")))
    files += sorted(glob.glob(os.path.join(DATA, "hs_super_long", "*.csv")))
    return files


async def reset(dut):
    dut.rst_n.value = 0
    dut.digital_in.value = 0
    dut.halt.value = 0
    dut.address.value = 0
    for _ in range(10):
        await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)


async def read_fields(dut):
    dut.halt.value = 1
    values = {}
    for addr, name in FIELDS:
        dut.address.value = addr
        await READOUT
        values[name] = int(dut.parallel_out.value)
    dut.halt.value = 0
    return values


def pack(v):
    return (
        (v["id0"] << 24) | (v["id1"] << 16) | (v["id2"] << 8) | v["id3"],
        (v["room0"] << 8) | v["room1"],
        (v["set0"] << 8) | v["set1"],
        v["state"],
        (v["tail1"] << 16) | (v["tail2"] << 8) | v["tail3"],
    )


@cocotb.test()
async def collect(dut):
    cocotb.start_soon(Clock(dut.clk, 50, unit="us").start())
    seen = set()
    pairs = []
    for path in capture_files():
        await reset(dut)
        prev = 0
        for sample in load(path):
            await ClockCycles(dut.clk, 1, rising=False)
            dut.digital_in.value = sample
            await ClockCycles(dut.clk, 1, rising=True)
            cur = int(dut.full.value)
            if cur == 1 and prev == 0:
                p = pack(await read_fields(dut))
                if p not in seen:
                    seen.add(p)
                    pairs.append(p)
                    dut._log.info(
                        "pair id=%08X room=%04X set=%04X state=%02X tail=%02X%02X%02X  (%s)",
                        p[0], p[1], p[2], p[3], (p[4] >> 16) & 0xFF, (p[4] >> 8) & 0xFF,
                        p[4] & 0xFF, os.path.basename(path),
                    )
            prev = cur
    dut._log.info("unique pairs: %d", len(pairs))
    with open(os.path.join(HERE, "out", "pairs.txt"), "w") as f:
        for p in pairs:
            f.write(f"{p[0]:08X} {p[1]:04X} {p[2]:04X} {p[3]:02X} {p[4]:06X}\n")
