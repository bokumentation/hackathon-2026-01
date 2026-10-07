# Trade Study

Design alternatives considered and decisions made for the TRI-ARGA authenticated ingress boundary.
Each study presents a decision table followed by the chosen alternative and its rationale.

---

## TS-01: Cipher selection

The MAC core must fit in a 2x2 Tiny Tapeout tile (sky130, up to about 2000 synthesis cells in the link tree), run at 50 MHz, and be implementable from a public specification without a vendor-licensed core.

| Alternative | Area (LUT equiv.) | Latency (cycles/block) | Key size (bits) | Security level | Hardware simplicity | Tiny Tapeout 2x2 fit |
| --- | --- | --- | --- | --- | --- | --- |
| SIMON-32/64 (chosen) | ~360 ALUTs (Cyclone V proxy) | 33 (32 rounds + 1) | 64 | ~64-bit block, 2^-32 forgery at 32-bit tag | High - XOR/shift datapath, no S-box LUT | Yes - 2511 cells total, WNS 0.00 |
| AES-128 | ~800-1200 ALUTs | 11-44 depending on unrolling | 128 | 128-bit block, AES-proven | Low - 8-bit S-box requires LUT or ROM | Marginal - S-box alone approaches tile budget |
| PRESENT-80 | ~500-700 ALUTs | 32 | 80 | 80-bit block | Medium - 4-bit S-box, bit permutation | Tight - P-layer wiring overhead |
| Keyless CRC-32 | ~50 ALUTs (LFSR) | 72 (streaming, 72-bit) | None | None - linear, recomputable | Very high | Yes - measured 73 cycles, small area |

**Decision:** SIMON-32/64.

**Rationale:**
SIMON-32/64 is a 32-bit block cipher with a 64-bit key from a public NSA/NIST lightweight-cryptography specification.
Its round function is XOR, AND, and rotate - no S-box lookup table is needed, so the gate count is small.
The serialized implementation (one round per cycle) measures 33 cycles per block (32 rounds plus one pipeline cycle), confirmed by 49 block vectors including the published test vector (key `1918111009080100`, plaintext `65656877`, ciphertext `C69BE9BB`).
AES requires an 8-bit S-box whose area is comparable to the entire SIMON datapath and does not fit within the tile budget.
PRESENT has a 4-bit S-box and a wide bit-permutation layer that adds routing complexity.
A keyless CRC is forgeable by an active attacker who can recompute the checksum without a key; the measured baseline demonstrates this vulnerability (CWE-354).
The sky130 signoff for SIMON-based `tt_um_auth_boundary` on a 2x2 tile reports 2511 synthesis cells, Magic DRC 0, LVS 0, WNS 0.00 (worst setup slack +10.87 ns), and typical power 2.10 mW.

---

## TS-02: MAC mode

The MAC must authenticate counter plus payload (96 bits, three 32-bit blocks) and produce a tag that fits in the 128-bit frame.
It must not require a nonce separate from the freshness counter.

| Alternative | Replay resistance | Forgery resistance | Area overhead | Nonce requirement | Tag size | Deterministic latency |
| --- | --- | --- | --- | --- | --- | --- |
| CBC-MAC fixed-length (chosen) | Via counter (no MAC nonce) | Yes - keyed | One cipher instance, 3 block invocations | No - IV=0, counter in plaintext | 32 bits (one block) | Yes - 3 x 33 = 99 cycles + FSM |
| HMAC-SHA256 | Via counter | Yes - keyed | SHA-256 datapath (~1500+ gates) | No | 256 bits (trimmed) | Yes but SHA latency ~80+ cycles |
| GHASH/GCM | Built-in (nonce) | Yes - AEAD | GF(2^128) multiplier + AES-CTR | Yes - explicit nonce per frame | 128 bits | Yes but needs full GCM engine |
| Keyless CRC-32 | No | No - recomputable | ~50 ALUTs (LFSR) | No | 32 bits | Yes - 73 cycles |

**Decision:** CBC-MAC fixed-length over three 32-bit blocks (counter, payload-low, payload-high), IV = 0, 64-bit key, 32-bit tag (LSB of final ciphertext block).

**Rationale:**
CBC-MAC over a fixed-length input (three 32-bit blocks) requires exactly one SIMON instance and three sequential block invocations.
The measured end-to-end MAC and freshness latency is 107 cycles (three blocks at 33 cycles each plus FSM overhead), matching the estimate.
No nonce is needed because the 32-bit monotonic counter fills the first block and provides per-frame uniqueness; a replay produces the same counter value and is rejected by the freshness check, not by the MAC.
HMAC-SHA256 would add a SHA-256 datapath that far exceeds the remaining tile budget after the SIMON core is placed.
GCM requires a GF(2^128) multiplier and an AES-CTR stream, neither of which fits in the target tile.
Keyless CRC is rejected as in TS-01: it is forgeable, which is the primary threat (CWE-345).
The fixed-length restriction is honest: CBC-MAC is not secure over variable-length inputs without length encoding; the frame format is fixed (128 bits), so the restriction is met by construction.

---

## TS-03: Freshness mechanism

The design must reject replayed and stale frames without requiring a real-time clock, persistent storage, or a nonce injected from outside the frame.

| Alternative | State required | Power-cycle persistence | Window size | Implementation complexity | CWE addressed |
| --- | --- | --- | --- | --- | --- |
| 32-bit monotonic counter (chosen) | 32-bit register | Session only (resets to 0) | 2^32 per session | Low - one comparator, one latch | CWE-294 |
| 64-bit monotonic counter | 64-bit register | Session only (or NVM) | 2^64 per session | Low - wider comparator | CWE-294 |
| Timestamp (RTC-based) | RTC peripheral | Yes - requires RTC | Clock accuracy | Medium - RTC interface, drift handling | CWE-294 |
| Nonce (random, sender-chosen) | None in receiver | N/A | Per-nonce uniqueness | Medium - nonce store or bloom filter | CWE-294 |
| None | None | N/A | None - replay always succeeds | Zero | Not addressed |

**Decision:** 32-bit monotonic counter, session-scoped (resets to 0 on power cycle), strictly increasing (`counter_rx > counter_last`).

**Rationale:**
The 32-bit counter requires a single 32-bit register and a one-cycle comparator.
Strict greater-than (`>`) rejects both replay (same counter) and stale frames (counter less than last accepted).
The session scope is an honest limitation documented in `PLAN.md`: the counter does not persist across power cycles, so a power-cycle replay attack is not prevented.
This limitation is within scope for the prototype - key provisioning and persistent counter storage are explicitly out of scope.
A 64-bit counter would double the register width with no benefit in the single-session model.
An RTC requires an additional peripheral not present on the Tiny Tapeout I/O budget.
A nonce requires either a cryptographically secure random number generator on the transmitter or a receiver-side nonce store, both of which are outside the committed scope.
The simulation evidence confirms: 20 clean frames with increasing counters accepted (false reject 0), replay rejected, stale counter rejected - measured in `make l2` and `make auth`.

---

## TS-04: Target platform tile size

The committed RTL must be hardened through the Tiny Tapeout GDS action on sky130.
The tile size affects die area, tile cost, placement density, and signoff complexity.

| Alternative | Die area | Synthesis cells (post-place) | Placement utilization | WNS (setup) | Magic DRC | GDS action outcome |
| --- | --- | --- | --- | --- | --- | --- |
| 1x1 tile | ~80.5 x 225.76 um | - | 105.57% (overflow) | - | - | FAIL - GPL-0301 placement overflow |
| 1x2 tile (RF appendix) | 161.0 x 225.76 um = 0.0363 mm^2 | 1671 placed | Measured fit | WNS +7.97 ns | 0 violations | PASS (RF appendix, 1x2) |
| 2x2 tile (chosen, link) | 334.88 x 225.76 um = 0.0756 mm^2 | 2511 synthesis (core), 3220 (link) | Fit with margin | WNS 0.00 | 0 violations (core), 2 antenna (link) | PASS - TRI-ARGA link boundary |
| FPGA-only (no ASIC) | N/A - Cyclone V | Tier B loopback 421 ALM, 1029 FF | ~1% of DE10-Nano | Timing met (97.9 MHz) | N/A | Not a GDS deliverable |

**Decision:** 2x2 tile for the committed core (`tt_um_auth_boundary`) and the secure serial link (`tt_um_link`).

**Rationale:**
The 1x1 tile is too small: OpenLane placement reports `GPL-0301 Utilization 105.57% exceeds 100%`.
The 1x2 tile was used as a fallback for the RF appendix (`tt_um_bokumentation_salaras_rx`) and passes with WNS +7.97 ns, but the authenticated core (SIMON-32/64 plus L2 plus L3) and the link are larger than the RF appendix.
The 2x2 tile provides a comfortable fit: the core hardening reports 2511 synthesis cells, Magic DRC 0, LVS 0, WNS 0.00 (worst setup slack +10.87 ns), and typical power 2.10 mW; the link hardening reports 3220 cells, 2 antenna violations, WNS 0.00, and 3.61 mW typical.
The die area 0.0756 mm^2 is within the Tiny Tapeout tile allocation for a 2x2 submission.
An FPGA-only approach would not produce the GDS deliverable required for the competition.
Quartus confirms the design maps cleanly to the DE10-Nano: the Tier B loopback wrapper fits in 421 ALM and 1029 registers, well within the 41,910 ALM capacity.

---

## TS-05: Transport

The boundary core is front-end-agnostic. The committed work adds a purpose-built secure link in front of it.

| Alternative | Framing | Integrity | Clock | Status |
| --- | --- | --- | --- | --- |
| Direct frame block (Tier A) | Host-driven block | Keyed MAC + freshness | Single | Committed |
| 8b/10b serial link (Tier B) | K28.5 comma, word lock | Keyed MAC + freshness, plus line coding | Single | Built (simulation loopback) |
| Async UART | Start/stop bits | Needs an added receiver and sampling | Single | Not built |
| CDC bridge (Tier C) | Via `cdc_fifo` | Keyed MAC + freshness | Two | Future |

**Decision:** Tier A core plus the Tier B 8b/10b link for the committed secure-communication claim.

**Rationale:**
Area 04 names TT07 SerDes and CDC FIFO. The Tier B link is the closest match: 8b/10b with running disparity, K28.5 comma framing, word lock, and invalid-code detection, feeding the authenticated core.
The link is verified in simulation by an internal loopback (clean commit; forgery, replay, and line error rejected); the on-board demonstration is a bootcamp step.
A second clock domain and the CDC crossing are deferred to Tier C and are not claimed.
