"""Reverse-engineer the 24-bit integrity field of tt07-bep-decode.

Golden (payload, tail) pairs come from the proposal appendix. The field is
affine over GF(2): flipping the set_temp LSB yields a constant tail delta, so a
CRC search over the polynomial is valid.

With init = 0 and xorout = 0 the CRC is linear over GF(2). The affine constant
cancels when comparing deltas against a reference pair, so only the polynomial,
coverage, and bit convention matter. Candidates are pruned one delta at a time.

Usage:
    python tools/crc_reveng.py
"""

from itertools import product

import numpy as np

PAIRS = [
    (0x03391F89, 0x00F6, 0x00B5, 0x00, 0x94AE16),
    (0x02391F89, 0x0116, 0x0104, 0x00, 0xB0860E),
    (0x02391F89, 0x0116, 0x0105, 0x00, 0x56844E),
    (0x03391F89, 0x0112, 0x00B4, 0x00, 0xDAFB46),
    (0x03391F89, 0x0112, 0x00B5, 0x00, 0x3CF906),
    (0x02391F89, 0x0114, 0x0000, 0x00, 0x4890BE),
    (0x02391F89, 0x0110, 0x0104, 0x00, 0xAE875A),
]

WIDTH = 24
MASK = (1 << WIDTH) - 1

HEADER = [0xAAAAAAAA, 0xD391, 0xD391, 0x0DFFFFFE]
HEADER_WIDTHS = [32, 16, 16, 32]
FIELDS = ["id", "room", "set", "state"]
FIELD_WIDTHS = {"id": 32, "room": 16, "set": 16, "state": 8}


def byteswap(value, width):
    nbytes = width // 8
    return int.from_bytes(value.to_bytes(nbytes, "big"), "little")


def bitrev(value, width):
    return int(f"{value:0{width}b}"[::-1], 2)


def message_bits(pair, prefix, order, endian, bit_order):
    vals = {"id": pair[0], "room": pair[1], "set": pair[2], "state": pair[3]}
    bits = []
    if prefix == "header":
        for v, w in zip(header_values(), HEADER_WIDTHS):
            bits += [int(c) for c in f"{v:0{w}b}"]
    for name in order:
        w = FIELD_WIDTHS[name]
        v = vals[name]
        if endian == "little":
            v = byteswap(v, w)
        s = f"{v:0{w}b}"
        if bit_order == "lsb":
            s = s[::-1]
        bits += [int(c) for c in s]
    return bits


def header_values():
    return HEADER


def crc_vector(bits, polys, refin, refout):
    crc = np.zeros_like(polys)
    for b in bits:
        if refin:
            crc ^= b
            lsb = crc & 1
            crc >>= 1
            crc ^= np.where(lsb != 0, polys, np.uint32(0))
        else:
            msb = (crc >> (WIDTH - 1)) & 1
            crc = (crc << 1) & MASK
            crc ^= np.where((msb ^ b) != 0, polys, np.uint32(0))
    if refout:
        r = np.zeros_like(crc)
        for i in range(WIDTH):
            r |= ((crc >> i) & 1) << (WIDTH - 1 - i)
        crc = r
    return crc


def search():
    polys = np.arange(1, 1 << WIDTH, 2, dtype=np.uint32)
    ref = PAIRS[0]
    orders = [
        ["id", "room", "set", "state"],
        ["id", "room", "set"],
        ["room", "set", "state"],
        ["id", "room", "set", "state"],
    ]
    for order in orders:
        for endian, bit_order in product(("big", "little"), ("msb", "lsb")):
            ref_bits = message_bits(ref, "none", order, endian, bit_order)
            dlist = []
            for p in PAIRS[1:]:
                pb = message_bits(p, "none", order, endian, bit_order)
                delta = [a ^ b for a, b in zip(ref_bits, pb)]
                dlist.append((delta, p[4] ^ ref[4]))
            for refin, refout in product((False, True), (False, True)):
                cand = polys
                for delta, dtail in dlist:
                    if len(cand) == 0:
                        break
                    crc = crc_vector(delta, cand, refin, refout)
                    cand = cand[crc == np.uint32(dtail)]
                if len(cand):
                    print(
                        f"MATCH order={order} endian={endian} bit_order={bit_order} "
                        f"refin={refin} refout={refout} poly={[hex(int(p)) for p in cand]}"
                    )
    print("search complete")


if __name__ == "__main__":
    search()
