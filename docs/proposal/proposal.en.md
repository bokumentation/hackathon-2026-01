# TRI-ARGA: Authenticated, Replay-Resistant Ingress Boundary for Lightweight Serial Links

Category: IC Chip Design & FPGA Implementation

Focus Area: 04 - Secure Communication (secure framing & interface integrity)

## 1. Executive Summary

TRI-ARGA is a hardware-enforced ingress boundary IP that ensures the host only ever sees authenticated, fresh frames. Frames that fail any check never reach the host.

Problem:

Lightweight serial and RF receivers parse an untrusted bitstream directly into registers and forward the integrity field to the host without checking it. On the Tiny Tapeout 07 Manchester baseline `tt07-bep-decode`, we measured that a corrupt payload and a corrupt integrity field are still forwarded with `full=1` (CWE-354). Without a key and a counter, such a receiver cannot distinguish a genuine frame from a forged one or a replayed one.

Solution:

A fail-closed ingress boundary with three layers of defense in one core:

1. **L1 Frame loader:** shift in a 128-bit frame (counter + payload + tag) and a 64-bit key serially, with a write-once key that locks until reset (CWE-20).
2. **L2 Authentication:** keyed SIMON-32/64 in fixed-length CBC-MAC mode, plus a strict counter freshness check (CWE-345, CWE-354, CWE-294).
3. **L3 Atomic commit:** data and `host_full` are released together in one cycle, only if authentication and freshness pass; on failure, `fault` fires and stays sticky until acknowledged (CWE-1264, CWE-1245).

Chip:

A small pure-digital IP with a single clock, no block RAM, no DSP. The core is front-end-agnostic and can be placed behind the official Area 04 TT07 SerDes baseline, a Manchester/RF decoder, or a UART. Targets: sky130 ASIC (Tiny Tapeout) and DE10-Nano FPGA.

Users:

Secure-element and identity-device designers, IP integrators needing an ingress-hardening block, and firmware teams that need assurance that a frame read from the host is authenticated.

Measured results:

| Metric | Result | Source |
| --- | --- | --- |
| Single-bit flip on frame | 128/128 rejected | cocotb simulation |
| Forgery, wrong key, replay, stale counter | All rejected | cocotb simulation |
| False reject | 0 of 20 clean frames | cocotb simulation |
| End-to-end latency | 108 cycles (2.16 µs at 50 MHz) | Simulation |
| Fail-closed properties | 5 pass (3 core, 2 RF appendix) + 6 L1 properties | SymbiYosys |
| sky130 hardening | 2×2 tile, 0.0756 mm², 2354 cells, 0 DRC, 0 LVS, WNS 0.00, 1.87 mW | OpenLane |
| FPGA synthesis | 242 ALM, 654 FF, 0 M10K, 0 DSP, Fmax 136 MHz | Quartus 25.1 |
| FPGA power | 425.4 mW total, 2.42 mW core dynamic | PowerPlay |

Impact:

A corrupt, forged, or replayed frame no longer appears valid to the host. The check happens in hardware, before data crosses the trust boundary, at a cost of under 0.08 mm² and 1.9 mW.

## 2. Background & Problem Statement

### 2.1 Background

Serial and RF links carry data between transceivers, terminals, secure elements, and hosts in identity and payment systems. In lightweight designs the physical line coding (Manchester, 8b/10b) is often treated as sufficient, so the receiver parses an untrusted bitstream and authenticates no frame at all.

Three failure classes follow:

1. **No integrity validation (CWE-354, CWE-345).** A keyless CRC or ECC detects random errors only. An active attacker can recompute the value for a forged frame. An unimplemented check provides nothing.
2. **Replay (CWE-294).** An old valid frame remains valid if there is no freshness marker. Replay and jamming-replay attacks on 433 MHz remotes (well-known example: RollJam, Kamkar 2015) show this attack class is practical on cheap RF links.
3. **Non-atomic commit (CWE-1264), fragile FSM (CWE-1245), and unvalidated input (CWE-20).** Data and control signals (`full`, latch enable) can de-synchronize, so the host can read data before the check is complete.

Software verification does not close this gap because software runs after data has already crossed the trust boundary.

### 2.2 Evidence from a Real Link

We use `tt07-bep-decode` (433 MHz Manchester, Tiny Tapeout 07) as a **measured example**, not as a flawed design for its original purpose. It was built to decode a thermostat protocol and makes no security claim. That is precisely why it represents the common pattern in lightweight receivers.

- The baseline receives a 24-bit integrity field (`tail_1..3`) and exposes it to the host without checking it.
- In simulation, the baseline latches a corrupted payload and a corrupted integrity field with `full=1` (CWE-354, measured; details in Appendix F).
- The field is an undocumented error-correcting code (confirmed by the baseline author) and the algorithm is unsolved. The RF case is therefore used as **evidence of the vulnerability class**, not as an integrity path we claim to have fixed.

<figure class="proto"><img src="assets/sim-baseline-vulnerability.png" alt="Baseline vulnerability"><figcaption>Figure 1. Baseline tt07-bep-decode: full stays high for a clean frame, a corrupt payload, and a corrupt integrity field.</figcaption></figure>

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
| **TRI-ARGA** | **Forgery, replay, atomic fail-closed commit** | Confidentiality (out of scope, see Appendix G) |

### 2.4 Problem Statement

1. How to authenticate a received frame against forgery at an area budget suitable for Tiny Tapeout (CWE-345)?
2. How to reject replayed frames within one power session without non-volatile memory (CWE-294)?
3. How to commit data and control atomically, fail-closed, so a frame that fails any check is never visible to the host (CWE-1264, CWE-1245)?
4. How to make this a reusable core behind different front-ends, especially the official TT07 SerDes baseline, on both FPGA and ASIC?

## 3. Proposed Chip Design

TRI-ARGA is a single-clock digital core sitting between an untrusted front-end and the host: a frame arrives, is authenticated, its freshness is checked, then it is atomically released or rejected.

### 3.1 System Architecture

<figure class="proto"><img src="assets/block-diagram.svg" alt="Authenticated boundary architecture"><figcaption>Figure 2. TRI-ARGA architecture: trust boundary, three layers, separate key path. Everything from the link is untrusted; the key arrives from the host via a separate path, and only L3 may release data to the host.</figcaption></figure>

The frame format and CBC-MAC chain diagram is in Appendix I, Figure I.1.

Frame format (128 bits + separate key):

| Field | Width | Function |
| --- | --- | --- |
| Counter | 32 bits | Freshness marker, must be strictly greater than the last accepted counter |
| Payload | 64 bits | Application data |
| Tag | 32 bits | CBC-MAC over counter + payload |
| Key | 64 bits | **Not** in the frame; loaded by the host via a trusted port |

CBC-MAC chain over three 32-bit blocks (B1 = counter, B2-B3 = payload), IV = 0, 64-bit key:

**C₁ = E_K(B₁), C₂ = E_K(C₁ ⊕ B₂), tag = C₃ = E_K(C₂ ⊕ B₃)**

A frame is accepted only if the computed tag matches the received tag **and** the counter is strictly greater than the last accepted counter.

Module summary:

| Module | Layer | Function |
| --- | --- | --- |
| `l1_serial_loader.v` | L1 | Shift in 64-bit key and 128-bit frame serially; write-once key, locked until reset |
| `simon32_64.v` | L2 | Serialized SIMON-32/64 block cipher, one round per cycle |
| `l2_auth.v` | L2 | CBC-MAC over counter + payload (three 32-bit blocks), tag compare, counter freshness |
| `l3_commit_gatekeeper.v` | L3 | Atomic commit only if auth and freshness pass; on failure holds `host_full` low and raises sticky `fault` |
| `boundary_top.v` | L2+L3 | L2 and L3 integration |
| `project.v` | Wrapper | Tiny Tapeout wrapper: instantiates L1 + L2+L3 |

`boundary_top` interface:

| Signal | Direction | Width | Notes |
| --- | --- | --- | --- |
| `key` | Input (host) | 64 | MAC key, loaded via trusted port |
| `counter`, `payload`, `tag` | Input (link) | 32, 64, 32 | Frame from front-end |
| `host_data` | Output | 96 | Authenticated counter + payload |
| `host_full` | Output | 1 | High only if `auth_ok` and `fresh_ok` |
| `auth_ok`, `fresh_ok`, `done` | Output | 1 | Per-frame status |
| `fault` | Output | 1 | Sticky until host acknowledges |

Handshake: `host_full` as data-ready indicator; `fault` sticky until acknowledged.

Processing and memory:

- One-way streaming data path; CBC-MAC runs as blocks arrive.
- No block RAM and no frame buffer. State is registers only: cipher state, last counter, status flags.

Power:

- Single-clock digital logic, no DSP, internal PLL, or large memory.
- The MAC is active only during a frame, so switching activity is minimal when idle. OpenLane result: 1.87 mW typical.
- Quartus synthesis for the DE10-Nano (Cyclone V) gives a vector-less PowerPlay estimate of 425.4 mW total with 2.42 mW core dynamic power. This estimate has low confidence and is dominated by device static power, so it is labeled an estimate, not a measurement.

### 3.2 Security Design (Threat Model)

Security is the starting point of this design, not an added feature: every module exists because of one threat in the table below.

**Protected assets:** integrity and authenticity of frames that reach the host, frame freshness, and MAC key confidentiality.

**Trust boundary:**
- *Untrusted:* everything from the link (SerDes front-end, Manchester/RF, UART), including counter, payload, and tag.
- *Trusted:* the host and the key-loading port. The key never crosses the link.

**Attacker capability:** can eavesdrop, insert, modify, delete, and replay frames on the link; can introduce random bit errors. Does **not** have the key, cannot read internal registers, and cannot perform side-channel or physical glitch attacks (out of scope, Appendix G).

**Threats, mitigations, and evidence:**

| Threat | CWE | Hardware mitigation | Evidence |
| --- | --- | --- | --- |
| Forged frame | CWE-345 | SIMON-32/64 CBC-MAC, 32-bit tag | Forgery rejected (simulation) |
| Integrity not checked | CWE-354 | Tag always recomputed and compared before commit | 128/128 bit flips rejected |
| Frame replay | CWE-294 | Counter must increase strictly | Replay and stale counter rejected |
| Data/control de-sync | CWE-1264 | One-cycle commit: `host_data` and `host_full` released together from latched frame | Formal property |
| Stuck or illegal FSM | CWE-1245 | Fully enumerated FSM, timeout, sticky fault | Formal properties, timeout test |
| Invalid framing | CWE-20 | Wrong-length or wrong-structure frames rejected at the loader | Timeout test (RF appendix) |

**Cryptographic design decisions:**

- **Why SIMON-32/64.** Designed for very small hardware and serializable at one round per cycle, fitting in a 2×2 Tiny Tapeout tile. We are aware that SIMON/SPECK was rejected as an ISO standard in 2018 and that the current NIST lightweight cryptography standard is Ascon. The cipher is therefore wrapped in a modular block interface: it can be swapped for SIMON-64/128 or Ascon without changing L2 and L3, at a larger area cost.
- **CBC-MAC for fixed length only.** CBC-MAC is secure only if all messages have the same length. The frame format is fixed at three blocks; if variable-length frames are ever needed, the mode changes to CMAC.
- **32-bit block birthday bound.** With a 32-bit block, CBC-MAC security degrades after about 2¹⁶ blocks under the same key, roughly 2×10⁴ frames. Integration policy: the key must be rotated well below this limit (recommendation: every 2¹² frames).
- **Forgery probability per attempt:** about 2⁻³² due to the 32-bit tag.
- **Constant decision time.** The accept/reject decision exits at the same cycle for all frames. L2 always processes all three blocks without early exit.
- **Post-reset behavior.** The last counter resets to 0 after reset, so old frames can be accepted again after a power cycle. Integration recommendation: the host loads a fresh session key every boot, so frames from the old session fail authentication automatically. The key is also write-once: loaded once after reset via the key-loading mode, then locked until reset.

### 3.3 FPGA Resource Usage

Quartus Prime 25.1 post-fit synthesis result for the DE10-Nano (Cyclone V 5CSEBA6U23I7):

| Resource | Result | DE10-Nano capacity (5CSEBA6U23I7) |
| --- | --- | --- |
| Logic (ALM) | 242 | 41,910 ALM |
| Registers (FF) | 654 | 166,036 |
| Block RAM (M10K) | 0 | 5,570 Kbit |
| DSP | 0 | 112 |
| PLL | 0 | 6 |
| Fmax | 136.37 MHz | 50 MHz target |

The design maps with no block RAM, no DSP, and no PLL, and closes timing at 50 MHz with a large margin.
This replaces the earlier Yosys estimate (about 360 LUT equivalent and 500 FF for `boundary_top`), because it now covers the full board wrapper including the L1 serial loader.

ASIC target: Tiny Tapeout sky130 130nm via OpenLane.

sky130 hardening (real result): 2×2 tile, die 0.0756 mm², 2354 cells, 0 DRC, 0 LVS, WNS 0.00, typical power 1.87 mW.

The RF appendix has a separate real result: 1×2 tile, die 0.0363 mm², WNS 0.00, typical power 1.21 mW. These are **not** the TRI-ARGA core numbers (see Appendix F).

Tools:

- Intel Quartus Prime (synthesis, fit, timing, SignalTap) for the DE10-Nano.
- OpenLane/OpenROAD and Yosys for the sky130 ASIC path.
- Verilator and Icarus Verilog for simulation and lint.
- cocotb and pytest for automated testbenches.
- SymbiYosys (formal proofs, smtbmc z3 engine).

Throughput: 108 cycles per frame at 50 MHz = 2.16 µs, equivalent to about 29 Mbit/s payload throughput. This is well above the 433 MHz RF link rate, so authentication is not the bottleneck.

### 3.4 Test Plan

RTL simulation (S1, measured):

- cocotb testbenches drive L1, L2, and commit with the success matrix: clean frames accepted, forgery, wrong key, replay, and stale counter rejected, and 128 of 128 single-bit flips rejected.
- Latency measured per stage: 33 cycles per SIMON block, 107 cycles for MAC and freshness, 108 cycles end-to-end.

The measured authentication and commit waveform (first frame passes, second frame rejected) is in Appendix I, Figure I.2.



Formal verification (SymbiYosys):

| SymbiYosys job | Property | Scope |
| --- | --- | --- |
| `auth_top` | `host_full` high only if the last completed frame passed `auth_ok` and `fresh_ok` | Core |
| `l3_commit` | `host_full` high only if the last commit decision accepted the frame | RF appendix |
| `simon32_64` | `done` rises only after exactly 32 rounds | Core |
| `l1_link` | 6 properties: `key_load`/`start` mutual exclusion, `start` only after key locked, `key_load` only before lock, `key_locked` sticky, both are single-cycle pulses | L1 |
| `l1_framing` | `framing_ok` never high together with `timing_fault` or `timeout_fault` | RF appendix |
| `l2_integrity` | CRC register always starts from initial value when a frame begins | RF appendix |
| `auth_data_integrity` | Committed data equals the authenticated frame (BMC depth 20, abstracted cipher) | Core |

DE10-Nano board test (S2, planned):

- Synthesis: Quartus project with board wrapper, SDC, and pin assignments.
- Bitstream implementation (.sof/.rbf) and real-time on-board testing.
- Internal signal monitoring with SignalTap on `auth_ok`, `fresh_ok`, `done`, `host_full`, and `fault`.
- On-board test: clean frame accepted, corrupt frame rejected, replay not committed, frame attempting a second key load ignored.
- The organizer's FPGA/sandbox facility is used at the bootcamp for this stage.

Success metrics:

| Metric | Target | Evidence |
| --- | --- | --- |
| Single-bit error detection | 128/128 observed; theoretical pass probability ~2⁻³² | Simulation |
| False reject | 0% | Simulation (20 clean frames) |
| Forgery and replay | Rejected | Simulation, then on-board |
| End-to-end latency | 108 cycles | Simulation, then SignalTap |
| Fail-closed | 7 jobs pass (4 core/link, 3 RF appendix) | SymbiYosys |
| FPGA Fmax | 136.37 MHz measured (target at least 50 MHz) | Quartus Timing Analyzer |

## 4. References

1. PERURI. "Buku Panduan Peserta PERURI Chip Hackathon 2026." https://summit.peruri.co.id/docs/Buku-Panduan-PERURI-Chip-Hackathon.pdf
2. PERURI. "Peruri Chip Design Datasheet" and Area 04 reference baselines (TT07 SerDes, CDC FIFO).
3. Kohnen, Z. "Decoding Manchester coded transmissions in a fully digital ASIC." BSc Thesis, 2024.
4. Kohnen, Z. and Alvarado, A. "Manchester decoder of a home thermostat's wireless protocol." FSiC, 2025.
5. Beaulieu, R. et al. "The SIMON and SPECK Families of Lightweight Block Ciphers." IACR ePrint 2013/404.
6. Bellare, M., Kilian, J., and Rogaway, P. "The Security of the Cipher Block Chaining Message Authentication Code." Journal of Computer and System Sciences 61(3), 2000.
7. NIST. SP 800-38B, "Recommendation for Block Cipher Modes of Operation: The CMAC Mode for Authentication." https://csrc.nist.gov/
8. NIST. SP 800-232, "Ascon-Based Lightweight Cryptography Standards for Constrained Devices." https://csrc.nist.gov/
9. Kamkar, S. "Drive It Like You Hacked It" (RollJam), DEF CON 23, 2015.
10. Tiny Tapeout. "Tiny Tapeout - Make Your Own Chip." https://tinytapeout.com/, 2024.
11. MITRE. "Common Weakness Enumeration (CWE): CWE-20, CWE-294, CWE-345, CWE-354, CWE-1245, CWE-1264." https://cwe.mitre.org/, 2024.
12. Terasic. "DE10-Nano - Cyclone V FPGA User Manual."
13. Intel. "Cyclone V Device Overview."

## 5. Appendix

### Appendix A. Team Identity and Roles

Team **Tri Arga**, Universitas Telkom.

| Member Name | Primary Expertise | Responsibility & Role |
| --- | --- | --- |
| Ibrahim Fauzi Rahman | Embedded Hardware/System, IoT, Isolated PCB Design RS485/CAN Bus | RTL: L1-L3 design and integration |
| Idris Syaifulloh | DevOps, Malware Researcher, CI/CD | Verification: cocotb, fault injection, metrics |

### Appendix B. Outputs and Demo

- Verilog RTL, cocotb testbench scripts, and SymbiYosys formal properties.
- sky130 hardening results (GDS, DRC/LVS/timing/power reports).
- FPGA bitstream (.sof/.rbf) and on-board demo (bootcamp).
- Source repository and a short technical report.

### Appendix C. Bootcamp Plan (18-20 October 2026)

| Day | Focus | Deliverable |
| --- | --- | --- |
| 1 (18 Oct) | Integrate core with TT07 SerDes baseline; test random multi-bit corruption and post-reset replay | Integrated RTL passing simulation |
| 2 (19 Oct) | Quartus synthesis, SignalTap, on-board forgery and replay tests | Bitstream, resource and timing report |
| 3 (20 Oct) | Final measurements, hardening polish, demo, Top 3 selection presentation | Demo and presentation material |

### Appendix D. Latency Budget (measured)

| Stage | Cycles |
| --- | --- |
| One SIMON-32/64 block (32 rounds + 1) | 33 |
| Three CBC-MAC blocks | 99 |
| FSM overhead: 2 cycles start/done handshake per block (×3), 1 cycle input latch, 1 cycle decision | 8 |
| MAC and freshness | 107 |
| Commit | 1 |
| **End to end** | **108** |

### Appendix E. Integrity Comparison (measured)

| Property | Keyless CRC | Keyed MAC | MAC + counter (TRI-ARGA) |
| --- | --- | --- | --- |
| Latency | 73 cycles (CRC serial 72 bit) | 107 cycles | 108 cycles |
| Random error detection | Yes | Yes | Yes |
| Forgery resistance | No | Yes | Yes |
| Replay resistance | No | No | Yes |

One additional cycle for freshness and commit adds replay resistance; 34 additional cycles over CRC adds forgery resistance.

### Appendix F. Problem Evidence (RF)

The baseline `tt07-bep-decode` latches a corrupt payload and integrity field with `full=1` (CWE-354, measured). Details in `sim/RESULTS.md`; the L1 timeout waveform is in `appendix/rf/figures/sim-boundary-timeout.png`.

sky130 hardening result for the RF appendix design (baseline front-end plus L1 framing, parameterized CRC L2 integrity, and the same L3 gate as the core): 1×2 tile, die 0.0363 mm², WNS 0.00, typical power 1.21 mW. These are **not** the TRI-ARGA core numbers (see 3.3).

### Appendix G. Limits

| Limit | Impact | Mitigation or plan |
| --- | --- | --- |
| No payload confidentiality | Payload readable by eavesdropper | Out of scope; can be added with AEAD (e.g. Ascon) |
| 32-bit tag | Forgery probability ~2⁻³² per attempt | Sufficient for lightweight links; longer tag with 64-bit cipher |
| 32-bit block birthday bound | Security degrades after ~2¹⁶ blocks per key | Mandatory key rotation, recommended every 2¹² frames |
| CBC-MAC fixed length only | Unsafe for variable-length frames | Frame format fixed at three blocks; switch to CMAC if variable |
| Counter resets to 0 after reset | Old frames can be accepted again after power cycle | Fresh session key every boot |
| Key provisioning | Core does not specify key source | Host or secure-element responsibility |
| Side-channel and glitch | Not analyzed | Formal properties prove logic only, not physical resilience |
| Front-end and CDC | Core is currently single clock domain | TT07 SerDes integration at bootcamp |
| FPGA power | Resource and timing measured in Quartus; power still a vector-less estimate | Measure on-board power at bootcamp |

### Appendix H. DE10-Nano FPGA Hardware Test

- **Board:** Terasic DE10-Nano, Cyclone V SoC (5CSEBA6U23I7), Quartus Prime.
- **Clock:** `CLOCK_50` (50 MHz) directly, one clock domain.
- **Procedure:** synthesis (`quartus_sh --flow compile`), bitstream upload (.sof/.rbf), real-time on-board test.
- **Key loading:** once after reset, with `SW[0]` high, shift the 64-bit key MSB-first over GPIO. Key locks until reset (`LEDR[5]` goes high); frames are ignored until the key is loaded. On Tiny Tapeout, key mode uses pin `ui_in[3]`.
- **Frame loading:** with `SW[0]` low, shift the 128-bit frame (counter 32, payload 64, tag 32) over GPIO; the core starts the MAC.
- **SignalTap (prepared, awaiting board):** taps `host_full`, `fault`, `auth_ok`, `fresh_ok`, `done`, `key_locked`; sample clock `CLOCK_50`, depth 2048, pre-trigger; trigger on `host_full` rising edge for the accept case and `fault` for the reject case. The `.stp` is created in the Quartus GUI, then `quartus_stp ... --enable` adds the SLD wiring and the design is recompiled; the acquisition script and procedure are in the repository.
- **Test scenarios:** clean frame accepted (`host_full` high); corrupt frame rejected (`host_full` low, `fault` high); replay not committed; frame attempting a second key load ignored.
- **Reports:** Fitter 242 ALM / 654 FF, Timing Analyzer Fmax 136.37 MHz (WNS +12.667 ns), PowerPlay 425.4 mW vector-less.
- **Facility:** organizer's FPGA/sandbox at bootcamp.

### Appendix I. Supporting Figures

<figure class="proto"><img src="assets/frame-link.svg" alt="Frame format and CBC-MAC chain"><figcaption>Figure I.1. 128-bit frame format (counter + payload + tag) and the SIMON-32/64 CBC-MAC chain.</figcaption></figure>

<figure class="proto"><img src="assets/sim-auth-commit.png" alt="Authentication and commit"><figcaption>Figure I.2. TRI-ARGA core: first frame passes (auth_ok, fresh_ok, host_full high); second frame rejected (host_full stays low, fault high).</figcaption></figure>
