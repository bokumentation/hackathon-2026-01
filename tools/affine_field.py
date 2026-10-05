"""Affine GF(2) analysis of the 24-bit integrity field.

The field is affine: `tail = A*payload ^ c` over GF(2). This tool measures
whether A can be recovered from the available (payload, tail) pairs.

With 6 independent payload deltas against a reference pair, the delta span has
rank at most 6, so A is determined only on that span. Recovering the full map
needs enough pairs to make the delta rank reach the size of the payload.

Usage:
    python tools/affine_field.py
"""

PAIRS = [
    (0x03391F89, 0x00F6, 0x00B5, 0x00, 0x94AE16),
    (0x02391F89, 0x0116, 0x0104, 0x00, 0xB0860E),
    (0x02391F89, 0x0116, 0x0105, 0x00, 0x56844E),
    (0x03391F89, 0x0112, 0x00B4, 0x00, 0xDAFB46),
    (0x03391F89, 0x0112, 0x00B5, 0x00, 0x3CF906),
    (0x02391F89, 0x0114, 0x0000, 0x00, 0x4890BE),
    (0x02391F89, 0x0110, 0x0104, 0x00, 0xAE875A),
]

PAYLOAD_BITS = 72


def payload(p):
    return (p[0] << 40) | (p[1] << 24) | (p[2] << 8) | p[3]


def gf2_rank(vectors, nbits):
    basis = {}
    for v in vectors:
        while v:
            pivot = v.bit_length() - 1
            if pivot in basis:
                v ^= basis[pivot]
            else:
                basis[pivot] = v
                break
    return len(basis)


def main():
    msgs = [payload(p) for p in PAIRS]
    tails = [p[4] for p in PAIRS]
    deltas = [m ^ msgs[0] for m in msgs[1:]]
    dtail = [t ^ tails[0] for t in tails[1:]]

    rank = gf2_rank(deltas, PAYLOAD_BITS)
    varying = set()
    for d in deltas:
        for i in range(PAYLOAD_BITS):
            if (d >> i) & 1:
                varying.add(i)

    print(f"pairs: {len(PAIRS)}")
    print(f"payload bits: {PAYLOAD_BITS}")
    print(f"payload bit positions that vary: {len(varying)}")
    print(f"rank of payload deltas: {rank}")
    print(f"unconstrained payload dimensions: {PAYLOAD_BITS - rank}")

    # Verify consistency: the affine map is single valued on the delta span.
    # Check that equal payload deltas always give equal tail deltas.
    seen = {}
    consistent = True
    for d, dt in zip(deltas, dtail):
        if d in seen and seen[d] != dt:
            consistent = False
        seen[d] = dt
    print(f"map well defined on observed deltas: {consistent}")
    print()
    print("Conclusion: the affine map is determined only on the observed")
    print("delta subspace. Recovering the full 24-bit field requires many more")
    print("(payload, tail) pairs so the delta rank reaches the payload size.")


if __name__ == "__main__":
    main()
