# TRI-ARGA: Authenticated, Replay-Resistant Ingress Boundary for Lightweight Serial Links

Category: IC Chip Design & FPGA Implementation

Focus Area: 04 - Secure Communication (secure framing & interface integrity) [1]

## 1. Executive Summary

**Problem:**

Lightweight serial and RF receivers parse an untrusted bitstream directly into registers and forward the integrity field to the host without checking it. On the Tiny Tapeout 07 Manchester baseline `tt07-bep-decode` [4], [5], [6], we measured that a corrupt payload and a corrupt integrity field are still forwarded with `full=1` (CWE-354) [14]. Without a key and a counter, such a receiver cannot distinguish a genuine frame from a forged one or a replayed one [12].

**Solution:**

A fail-closed ingress boundary with three layers of defense in one core:

1. L1 frame loader: shift in a 128-bit frame (counter + payload + tag) and a 64-bit key serially, with a write-once key that locks until reset (CWE-20) [14].
2. L2 authentication: keyed SIMON-32/64 [7] in fixed-length CBC-MAC mode [9], plus a strict counter freshness check (CWE-345, CWE-354, CWE-294) [14].
3. L3 atomic commit: data and `host_full` are released together in one cycle, only if authentication and freshness pass; on failure, `fault` fires and stays sticky until acknowledged (CWE-1264, CWE-1245) [14].

Beyond the core, an 8b/10b serial link (Tier B) is built [2] and tested with a single-clock loopback through the L2+L3 core. In that loopback, a clean frame is committed while forgery, replay, and line errors are rejected.

**Chip:**

A small pure-digital IP with a single clock, no block RAM, no DSP. The core is front-end-agnostic and can be placed behind the official Area 04 TT07 SerDes baseline [2], a Manchester/RF decoder, or a UART. Targets: sky130 ASIC (Tiny Tapeout) [11] and DE10-Nano FPGA [13].

**DE10-Nano implementation:**

The prototype maps to the Cyclone V fabric without the HPS. `CLOCK_50` (50 MHz) is used directly, one clock domain. The on-board demonstration uses an internal loopback: `link_tx` sends a frame to `link_rx` through the L2+L3 core, and a switch selects the clean, corrupt, or replay case. Status `host_full`, `fault`, `auth_ok`, `fresh_ok`, `done`, and `key_locked` are observed through LEDs and SignalTap. There is no external device and no second clock.

**Users:**

Secure-element and identity-device designers, IP integrators needing an ingress-hardening block, and firmware teams that need assurance that a frame read from the host is authenticated.

**Measured results:**

| Metric | Result | Source |
| --- | --- | --- |
| Single-bit flip on frame | 128/128 rejected | cocotb simulation |
| Forgery, wrong key, replay, stale counter | All rejected | cocotb simulation |
| False reject | 0 of 20 clean frames | cocotb simulation |
| End-to-end latency | 108 cycles (2.16 µs at 50 MHz) | Simulation |
| Serial link loopback (Tier B) | clean commit; forgery/replay/line error rejected | cocotb simulation |
| Fail-closed properties | 9 pass (5 core, 1 Tier B, 3 RF appendix) | SymbiYosys |
| sky130 hardening (core) | 2×2 tile, 0.0756 mm², 2511 cells, 0 DRC, 0 LVS, WNS 0.00, 2.10 mW | OpenLane |
| sky130 hardening (Tier B) | 2×2 tile, 3220 cells, 2 antenna violations, WNS 0.00, 3.61 mW | OpenLane |
| FPGA synthesis | 421 ALM, 1029 FF, 0 M10K, 0 DSP, Fmax 97.9 MHz | Quartus 25.1 |
| FPGA power | 426.2 mW total, 3.76 mW core dynamic | PowerPlay |

**Impact:**

A corrupt, forged, or replayed frame no longer appears valid to the host. The check happens in hardware, before data crosses the trust boundary, at a cost of under 0.08 mm² and 2.1 mW.

## 2. Background & Problem Statement

### 2.1 Background

Serial and RF links carry data between transceivers, terminals, secure elements, and hosts in identity and payment systems. In lightweight designs the physical line coding (Manchester, 8b/10b) is often treated as sufficient, so the receiver parses an untrusted bitstream and authenticates no frame at all.

Three failure classes follow:

1. No integrity validation (CWE-354, CWE-345) [14]. A keyless CRC or ECC detects random errors only. An active attacker can recompute the value for a forged frame. An unimplemented check provides nothing.
2. Replay (CWE-294) [14]. An old valid frame remains valid if there is no freshness marker. Replay and jamming-replay attacks on 433 MHz remotes, demonstrated through the RollJam technique (Kamkar, 2015) [12], show this attack class is practical on cheap RF links.
3. Non-atomic commit (CWE-1264), fragile FSM (CWE-1245), and unvalidated input (CWE-20) [14]. Data and control signals (`full`, latch enable) can de-synchronize, so the host can read data before the check is complete.

Software verification does not close this gap because software runs after data has already crossed the trust boundary.

### 2.2 Evidence from a Real Link

We use `tt07-bep-decode` (433 MHz Manchester, Tiny Tapeout 07) [4], [5], [6] as a measured example, not as a flawed design for its original purpose. It was built to decode a thermostat protocol and makes no security claim. That is precisely why it represents the common pattern in lightweight receivers.

- The baseline receives a 24-bit integrity field (`tail_1..3`) and exposes it to the host without checking it.
- In simulation, the baseline latches a corrupted payload and a corrupted integrity field with `full=1` (CWE-354, measured; details in Appendix F).
- The field is an undocumented error-correcting code (confirmed by the baseline author) and the algorithm is unsolved. The RF case is therefore used as evidence of the vulnerability class, not as an integrity path we claim to have fixed.

The waveform is in Appendix F, Figure F.1.

### 2.3 Gap vs Available Solutions

No small-area block combines authentication, freshness, and atomic fail-closed commit at the ingress boundary.

| Approach | Handled | Not handled |
| --- | --- | --- |
| Parity or CRC | Random errors | Forgery, replay, framing |
| Full 8b/10b | DC balance, synchronization | No integrity at all |
| Standard decoders | Frame start validation | Frame content |
| Software verification | Flexible | Runs after trust boundary is crossed |
| MAC without freshness | Forgery | Replay |
| Full AEAD (e.g. Ascon) | Forgery and confidentiality | Freshness and commit gating still need design; larger area |
| TRI-ARGA | Forgery, replay, atomic fail-closed commit | Confidentiality (out of scope, see Appendix G) |

### 2.4 Problem Statement

1. How to authenticate a received frame against forgery at an area budget suitable for Tiny Tapeout (CWE-345) [14]?
2. How to reject replayed frames within one power session without non-volatile memory (CWE-294) [14]?
3. How to commit data and control atomically, fail-closed, so a frame that fails any check is never visible to the host (CWE-1264, CWE-1245) [14]?
4. How to make this a reusable core behind different front-ends, especially the official TT07 SerDes baseline [2], on both FPGA and ASIC?

## 3. Proposed Chip Design

TRI-ARGA is a single-clock digital core sitting between an untrusted front-end and the host: a frame arrives, is authenticated, its freshness is checked, then it is atomically released or rejected.

### 3.1 Proposed Chip Design

<figure class="proto"><img src="assets/block-diagram.svg" alt="Authenticated boundary architecture"><figcaption>Figure 1. TRI-ARGA architecture: trust boundary, three layers, separate key path. Everything from the link is untrusted; the key arrives from the host via a separate path, and only L3 may release data to the host.</figcaption></figure>

The frame format and CBC-MAC chain diagram is in Appendix I, Figure I.1.

**Frame format (128 bits + separate key):**

| Field | Width | Function |
| --- | --- | --- |
| Counter | 32 bits | Freshness marker, must be strictly greater than the last accepted counter |
| Payload | 64 bits | Application data |
| Tag | 32 bits | CBC-MAC over counter + payload |
| Key | 64 bits | Not in the frame; loaded by the host via a trusted port |

CBC-MAC chain over three 32-bit blocks (B1 = counter, B2–B3 = payload), IV = 0, 64-bit key:

C1 = E_K(B1), C2 = E_K(C1 ⊕ B2), tag = C3 = E_K(C2 ⊕ B3)

A frame is accepted only if the computed tag matches the received tag and the counter is strictly greater than the last accepted counter.

**Module summary:**

| Module | Layer | Function |
| --- | --- | --- |
| `l1_serial_loader.v` | L1 | Shift in 64-bit key and 128-bit frame serially; write-once key, locked until reset |
| `simon32_64.v` | L2 | Serialized SIMON-32/64 block cipher, one round per cycle |
| `l2_auth.v` | L2 | CBC-MAC over counter + payload (three 32-bit blocks), tag compare, counter freshness |
| `l3_commit_gatekeeper.v` | L3 | Atomic commit only if auth and freshness pass; on failure holds `host_full` low and raises sticky `fault` |
| `link_enc_8b10b.v`, `link_dec_10b8b.v`, `l1_link_framing.v`, `link_tx.v`, `link_rx.v`, `link_top.v` | Tier B | 8b/10b serial link with running disparity, K-character framing, word lock, and loopback through L2+L3 |
| `boundary_top.v` | L2+L3 | L2 and L3 integration |
| `project.v` | Wrapper | Tiny Tapeout wrapper: instantiates L1 + L2+L3 |

**`boundary_top` interface:**

| Signal | Direction | Width | Notes |
| --- | --- | --- | --- |
| `key` | Input (host) | 64 | MAC key, loaded via trusted port |
| `counter`, `payload`, `tag` | Input (link) | 32, 64, 32 | Frame from front-end |
| `host_data` | Output | 96 | Authenticated counter + payload |
| `host_full` | Output | 1 | High only if `auth_ok` and `fresh_ok` |
| `auth_ok`, `fresh_ok`, `done` | Output | 1 | Per-frame status |
| `fault` | Output | 1 | Sticky until host acknowledges |

**Processing and memory:**

- One-way streaming data path; CBC-MAC runs as blocks arrive.
- No block RAM and no frame buffer. State is registers only: cipher state, last counter, status flags.

**Power:**

- Single-clock digital logic, no DSP, internal PLL, or large memory.
- The MAC is active only during a frame, so switching activity is minimal when idle. OpenLane result: 2.10 mW typical for the core.
- Quartus synthesis for the DE10-Nano (Cyclone V) gives a vector-less PowerPlay estimate for the Tier B loopback wrapper: 426.2 mW total with 3.76 mW core dynamic power. This estimate has low confidence and is dominated by device static power, so it is labeled an estimate, not a measurement.

**FPGA resource usage:**

Quartus Prime 25.1 post-fit synthesis result for the DE10-Nano (Cyclone V 5CSEBA6U23I7):

| Resource | Result | DE10-Nano capacity (5CSEBA6U23I7) |
| --- | --- | --- |
| Logic (ALM) | 421 | 41,910 ALM |
| Registers (FF) | 1029 | 166,036 |
| Block RAM (M10K) | 0 | 5,570 Kbit |
| DSP | 0 | 112 |
| PLL | 0 | 6 |
| Fmax | 97.9 MHz | 50 MHz target |

These are the Tier B loopback wrapper numbers (`link_demo_top`: `link_tx` + `link_rx` + `boundary_top`), which is the demonstrated design. The design maps with no block RAM, no DSP, and no PLL, and closes timing at 50 MHz with margin (WNS +9.785 ns).

**Tools:**

- Intel Quartus Prime (synthesis, fit, timing, SignalTap) for the DE10-Nano [13].
- OpenLane/OpenROAD and Yosys for the sky130 ASIC path.
- Verilator and Icarus Verilog for simulation and lint.
- cocotb and pytest for automated testbenches.
- SymbiYosys (formal proofs, smtbmc z3 engine).

ASIC target: Tiny Tapeout sky130 130 nm via OpenLane [11].

- sky130 hardening of the core (real result): 2×2 tile, die 0.0756 mm², 2511 cells, 0 DRC, 0 LVS, 0 antenna, WNS 0.00, typical power 2.10 mW.
- sky130 hardening of the Tier B serial link (real result): 2×2 tile, 3220 cells, 2 antenna violations, WNS 0.00, typical power 3.61 mW. These are the `tt_um_link` numbers, not the L2+L3 core alone.
- The RF appendix has a separate real result: 1×2 tile, die 0.0363 mm², WNS 0.00, typical power 1.21 mW. These are not the TRI-ARGA core numbers (see Appendix F).

Throughput: 108 cycles per frame at 50 MHz = 2.16 µs, equivalent to about 29 Mbit/s payload throughput. This is well above the 433 MHz RF link rate, so authentication is not the bottleneck.

### 3.2 Technical Design

**RTL approach:**

- Verilog-2001 with `default_nettype none`, fully synthesizable, modular per layer.
- The cipher is wrapped in a block interface, so SIMON-32/64 can be swapped for SIMON-64/128 or Ascon without changing L2 and L3 [7], [10].
- The 8b/10b link uses the tables as a seed, adds running disparity (RD+/RD-), K-characters, and rewrites framing, alignment, and the serial datapath [2].

#### 3.2.1 Test Plan

**RTL simulation (S1, measured):**

- cocotb testbenches drive L1, L2, and commit with the success matrix: clean frames accepted, forgery, wrong key, replay, and stale counter rejected, and 128 of 128 single-bit flips rejected.
- A link testbench drives the Tier B loopback: a clean frame is committed, while forgery, replay, and line errors are rejected.
- Latency is measured per stage: 33 cycles per SIMON block, 107 cycles for MAC and freshness, 108 cycles end-to-end.

The measured authentication and commit waveform (first frame passes, second frame rejected) is in Appendix I, Figure I.2.

**Formal verification (SymbiYosys):**

Nine properties pass: five for the core (`auth_top`, `auth_data_integrity`, `l3_commit_core`, `simon32_64`, `l1_link`), one for the Tier B link (`link_framing`), and three for the RF appendix (`l1_framing`, `l2_integrity`, `l3_commit`). The per-job detail is in Appendix K.

**DE10-Nano board test (S2, planned):**

- Synthesis: Quartus project with board wrapper, SDC, and pin assignments.
- Bitstream implementation (.sof/.rbf) and real-time on-board testing.
- The on-board demonstration uses an internal loopback from `link_tx` to `link_rx` through the L2+L3 core. A switch selects the case: clean frame, corrupt frame (one payload/tag bit flipped), and replay (the same frame sent again).
- Internal signal monitoring with SignalTap on `auth_ok`, `fresh_ok`, `done`, `host_full`, and `fault`.
- There is no external device and no second clock; CDC is out of scope.

**Success metrics:**

| Metric | Target | Evidence |
| --- | --- | --- |
| Single-bit error detection | 128/128 observed; theoretical pass probability ~2^-32 | Simulation |
| False reject | 0% | Simulation (20 clean frames) |
| Forgery and replay | Rejected | Simulation, then on-board |
| End-to-end latency | 108 cycles | Simulation, then SignalTap |
| Fail-closed | 9 jobs pass | SymbiYosys |
| FPGA Fmax | 97.9 MHz measured (target at least 50 MHz) | Quartus Timing Analyzer |

### 3.3 Security Design (Threat Model)

Security is the starting point of this design, not an added feature: every module exists because of one threat in the table below.

**Protected assets:** integrity and authenticity of frames that reach the host, frame freshness, and MAC key confidentiality.

**Trust boundary:**

- Untrusted: everything from the link (SerDes front-end, Manchester/RF, UART), including counter, payload, and tag.
- Trusted: the host and the key-loading port. The key never crosses the link.

**Attacker capability:** can eavesdrop, insert, modify, delete, and replay frames on the link; can introduce random bit errors. Does not have the key, cannot read internal registers, and cannot perform side-channel or physical glitch attacks (out of scope, Appendix G).

**Threats, mitigations, and evidence:**

| Threat | CWE | Hardware mitigation | Evidence |
| --- | --- | --- | --- |
| Forged frame | CWE-345 [14] | SIMON-32/64 CBC-MAC, 32-bit tag | Forgery rejected (simulation) |
| Integrity not checked | CWE-354 [14] | Tag always recomputed and compared before commit | 128/128 bit flips rejected |
| Frame replay | CWE-294 [14] | Counter must increase strictly | Replay and stale counter rejected |
| Data/control de-sync | CWE-1264 [14] | One-cycle commit: `host_data` and `host_full` released together from latched frame | Formal property |
| Stuck or illegal FSM | CWE-1245 [14] | Fully enumerated FSM, timeout, sticky fault | Formal properties, timeout test |
| Invalid framing | CWE-20 [14] | Wrong-length or wrong-structure frames rejected at the loader | Timeout test (RF appendix) |

The cryptographic design decisions and their limits are in Appendix J. In brief: a 32-bit tag gives about a 2^-32 per-attempt forgery probability [8], [9]; CBC-MAC is secure only for fixed length [8]; a 32-bit block has a birthday bound so keys must rotate; and the accept/reject decision exits at the same cycle for all frames.

## 4. References

1. PERURI. "Buku Panduan Peserta PERURI Chip Hackathon 2026." 2026. https://summit.peruri.co.id/docs/Buku-Panduan-PERURI-Chip-Hackathon.pdf
2. Santeep G, M. and N. Shylashree. "TT_UM_SERDES, Tiny Tapeout 07." https://github.com/Santeep/TT_UM_SERDES
3. Pa1mantri. "tt07_cdc_fifo, Tiny Tapeout 07." https://github.com/Pa1mantri/tt07_cdc_fifo
4. DusterTheFirst. "tt07-bep-decode, Tiny Tapeout 07." https://github.com/DusterTheFirst/tt07-bep-decode
5. Z. Kohnen. "Decoding Manchester coded transmissions in a fully digital ASIC." BSc Thesis, 2024.
6. Z. Kohnen and A. Alvarado. "Manchester decoder of a home thermostat's wireless protocol." FSiC, 2025.
7. R. Beaulieu et al. "The SIMON and SPECK Families of Lightweight Block Ciphers." IACR ePrint 2013/404, 2013.
8. M. Bellare, J. Kilian, and P. Rogaway. "The Security of the Cipher Block Chaining Message Authentication Code." *Journal of Computer and System Sciences*, vol. 61, no. 3, 2000.
9. NIST. SP 800-38B, "Recommendation for Block Cipher Modes of Operation: The CMAC Mode for Authentication." 2016. https://csrc.nist.gov/
10. NIST. SP 800-232, "Ascon-Based Lightweight Cryptography Standards for Constrained Devices." 2024. https://csrc.nist.gov/
11. Tiny Tapeout. "Tiny Tapeout — Make Your Own Chip." 2024. https://tinytapeout.com/
12. S. Kamkar. "Drive It Like You Hacked It" (RollJam). DEF CON 23, 2015.
13. Terasic. "DE10-Nano — Cyclone V FPGA User Manual." 2019. https://www.terasic.com.tw/
14. MITRE. "Common Weakness Enumeration (CWE): CWE-20, CWE-294, CWE-345, CWE-354, CWE-1245, CWE-1264." 2024. https://cwe.mitre.org/

## 5. Appendix

### Appendix A. Team Identity and Roles

Team Tri Arga, Universitas Telkom.

| Member Name | Primary Expertise | Responsibility & Role |
| --- | --- | --- |
| Ibrahim Fauzi Rahman | Embedded Hardware/System, IoT, PCB Design, Isolated RS485/CAN Bus | RTL: L1–L3 design and integration |
| Idris Syaifulloh | DevOps, Machine Learning, Malware Researcher, CI/CD | Verification: cocotb, fault injection, metrics, CI, analysis |

Advisor: Dr. Setia Juli Irzal Ismail, S.T., M.T. — Universitas Telkom

### Appendix B. Outputs and Demo

- Verilog RTL, cocotb testbench scripts, and SymbiYosys formal properties.
- sky130 hardening results (GDS, DRC/LVS/timing/power reports).
- FPGA bitstream (.sof/.rbf), buildable from this repository.
- Source repository: https://github.com/bokumentation/hackathon-2026-01, and a short technical report.

### Appendix C. Bootcamp Plan (18–20 October 2026)

| Day | Focus | Deliverable |
| --- | --- | --- |
| 1 (18 Oct) | Integrate the Tier B link with the L2+L3 core; test random multi-bit corruption and replay | Integrated RTL passing simulation |
| 2 (19 Oct) | Quartus synthesis of the loopback wrapper, SignalTap, on-board forgery and replay tests | Bitstream, resource and timing report |
| 3 (20 Oct) | Final measurements, hardening polish, demo, Top 3 selection presentation | Demo and presentation material |

### Appendix D. Latency Budget (measured)

| Stage | Cycles |
| --- | --- |
| One SIMON-32/64 block (32 rounds + 1) | 33 |
| Three CBC-MAC blocks | 99 |
| FSM overhead: 2 cycles start/done handshake per block (×3), 1 cycle input latch, 1 cycle decision | 8 |
| MAC and freshness | 107 |
| Commit | 1 |
| End to end | 108 |

### Appendix E. Integrity Comparison (measured)

| Property | Keyless CRC | Keyed MAC | MAC + counter (TRI-ARGA) |
| --- | --- | --- | --- |
| Latency | 73 cycles (CRC serial 72 bit) | 107 cycles | 108 cycles |
| Random error detection | Yes | Yes | Yes |
| Forgery resistance | No | Yes | Yes |
| Replay resistance | No | No | Yes |

One additional cycle for freshness and commit adds replay resistance; 34 additional cycles over CRC adds forgery resistance.

### Appendix F. Problem Evidence (RF)

The baseline `tt07-bep-decode` latches a corrupt payload and integrity field with `full=1` (CWE-354, measured) [4], [5]. Details in `sim/RESULTS.md`; the L1 timeout waveform is in `appendix/rf/figures/sim-boundary-timeout.png`.

<figure class="proto"><img src="assets/sim-baseline-vulnerability.png" alt="Baseline vulnerability"><figcaption>Figure F.1. Baseline tt07-bep-decode: full stays high for a clean frame, a corrupt payload, and a corrupt integrity field.</figcaption></figure>

sky130 hardening result for the RF appendix design (baseline front-end plus L1 framing, parameterized CRC L2 integrity, and the same L3 gate as the core): 1×2 tile, die 0.0363 mm², 1233 cells, WNS 0.00, typical power 1.21 mW. These are not the TRI-ARGA core numbers (see 3.1).

### Appendix G. Limits

| Limit | Impact | Mitigation or plan |
| --- | --- | --- |
| No payload confidentiality | Payload readable by eavesdropper | Out of scope; can be added with AEAD (e.g. Ascon) [10] |
| 32-bit tag | Forgery probability ~2^-32 per attempt | Sufficient for lightweight links; longer tag with 64-bit cipher |
| 32-bit block birthday bound | Security degrades after ~2^16 blocks per key | Mandatory key rotation, recommended every 2^12 frames |
| CBC-MAC fixed length only | Unsafe for variable-length frames | Frame format fixed at three blocks; switch to CMAC if variable [9] |
| Counter resets to 0 after reset | Old frames can be accepted again after power cycle | Fresh session key every boot |
| Key provisioning | Core does not specify key source | Host or secure-element responsibility |
| Side-channel and glitch | Not analyzed | Formal properties prove logic only, not physical resilience |
| CDC | Core is currently single clock domain | Out of scope; a second clock only via the CDC FIFO in Tier C [3] |
| FPGA power | Resource and timing measured in Quartus; power still a vector-less estimate | Measure on-board power at bootcamp |

### Appendix H. DE10-Nano FPGA Hardware Test

- Board: Terasic DE10-Nano, Cyclone V SoC (5CSEBA6U23I7), Quartus Prime [13].
- Clock: `CLOCK_50` (50 MHz) directly, one clock domain.
- Procedure: synthesis (`quartus_sh --flow compile`), bitstream upload (.sof/.rbf), real-time on-board test.
- Demonstration: the loopback wrapper instantiates `link_tx` and `link_top` (`link_rx` + `boundary_top`). A switch selects the clean, corrupt, or replay case; `fault_ack` clears the sticky fault.
- SignalTap (prepared, awaiting board): taps `host_full`, `fault`, `auth_ok`, `fresh_ok`, `done`, `key_locked`; sample clock `CLOCK_50`, depth 2048, pre-trigger; trigger on `host_full` rising edge for the accept case and `fault` for the reject case. The `.stp` is created in the Quartus GUI, then `quartus_stp ... --enable` adds the SLD wiring and the design is recompiled; the acquisition script and procedure are in the repository.
- Test scenarios: clean frame committed (`host_full` high); corrupt frame rejected (`host_full` low, `fault` high); replay not committed; fault sticky until acknowledged.
- Reports for the Tier B loopback wrapper (`link_demo_top`): Fitter 421 ALM / 1029 FF, Timing Analyzer Fmax 97.9 MHz (WNS +9.785 ns), PowerPlay 426.2 mW vector-less (3.76 mW core dynamic).
- For reference, the Tier A wrapper (`de10nano_top`, L1 serial loader) was previously measured at 242 ALM / 654 FF, Fmax 136.37 MHz.
- Facility: organizer's FPGA/sandbox at bootcamp.

### Appendix I. Supporting Figures

<figure class="proto"><img src="assets/frame-link.svg" alt="Frame format and CBC-MAC chain"><figcaption>Figure I.1. 128-bit frame format (counter + payload + tag) and the SIMON-32/64 CBC-MAC chain.</figcaption></figure>

<figure class="proto"><img src="assets/sim-auth-commit.png" alt="Authentication and commit"><figcaption>Figure I.2. TRI-ARGA core: first frame passes (auth_ok, fresh_ok, host_full high); second frame rejected (host_full stays low, fault high).</figcaption></figure>

### Appendix J. Cryptography Notes

- **Why SIMON-32/64.** This cipher is designed for very small hardware and serializable at one round per cycle, fitting in a 2×2 Tiny Tapeout tile [7]. We are aware that SIMON/SPECK was rejected as an ISO standard in 2018 and that the current NIST lightweight cryptography standard is Ascon [10]. The cipher is therefore wrapped in a modular block interface: it can be swapped for SIMON-64/128 or Ascon without changing L2 and L3, at a larger area cost.
- **CBC-MAC for fixed length only.** CBC-MAC is secure only if all messages have the same length [8]. The frame format is fixed at three blocks; if variable-length frames are ever needed, the mode changes to CMAC [9].
- **32-bit block birthday bound.** With a 32-bit block, CBC-MAC security degrades after about 2^16 blocks under the same key, roughly 2×10^4 frames. Integration policy: the key must be rotated well below this limit (recommendation: every 2^12 frames).
- **Forgery probability per attempt** is about 2^-32 due to the 32-bit tag [8], [9].
- **Constant decision time.** The accept/reject decision exits at the same cycle for all frames. L2 always processes all three blocks without early exit.
- **Post-reset behavior.** The last counter resets to 0 after reset. Integration recommendation: the host loads a fresh session key every boot. The key is also write-once: loaded once after reset via the key-loading mode, then locked until reset.

### Appendix K. Formal Verification Detail

| SymbiYosys job | Property | Scope |
| --- | --- | --- |
| `auth_top` | `host_full` high only if the last completed frame passed `auth_ok` and `fresh_ok` | Core |
| `auth_data_integrity` | Committed data equals the authenticated frame (BMC depth 20, abstracted cipher) | Core |
| `l3_commit_core` | `host_full` high only if the last commit decision accepted the frame | Core |
| `simon32_64` | `done` rises only after exactly 32 rounds | Core |
| `l1_link` | 8 properties: key_load/start mutual exclusion, start only after key locked, key_load only before lock, key_locked sticky, single-cycle pulses, and framing fault | L1 |
| `link_framing` | 8b/10b framing and word lock never rise together with a fault | Tier B |
| `l1_framing` | `framing_ok` never high together with `timing_fault` or `timeout_fault` | RF appendix |
| `l2_integrity` | CRC register always starts from initial value when a frame begins | RF appendix |
| `l3_commit` | `host_full` high only if the last commit decision accepted the frame | RF appendix |
