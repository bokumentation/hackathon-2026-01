# A Reusable, Fail-Closed Authenticated Ingress Boundary for Serial/RF Links

Category: IC Chip Design & FPGA Implementation

Focus Area: 04 - Secure Communication (secure framing & interface integrity)

## 1. Executive Summary

Problem:

Lightweight serial/RF receivers parse an untrusted bitstream into a shift register and expose an integrity field to the host without validating it.

This gap is measured on the Tiny Tapeout 07 Manchester baseline `tt07-bep-decode`: the 24-bit integrity field (`tail_1..3`) is received but never checked, so a corrupt payload or a fault-injected frame still appears valid to the host (CWE-354).

Solution:

A fail-closed, reusable ingress boundary: a keyed MAC (SIMON-32/64, fixed-length CBC-MAC) plus a freshness counter and an atomic commit.

It closes forgery (CWE-345), replay (CWE-294), control/data de-synchronization (CWE-1264), invalid framing (CWE-20), and a hung FSM (CWE-1245).

Chip:

A small pure-digital IP with a single clock in the committed scope, targeting sky130 ASIC and the DE10-Nano FPGA.

Users:

Secure-element and contactless smart-card designers, IP integrators needing an ingress-hardening block, and firmware teams that need assurance that a frame read from the host is authenticated.

Measured results:

- 128 of 128 single-bit flips rejected.
- Forgery, wrong key, replay, and stale counter rejected; 20 clean frames accepted (false reject 0).
- End-to-end latency 108 cycles (107 for MAC and freshness, 1 for commit).
- Five formal properties pass, proving the fail-closed structure.
- RF appendix: real sky130 hardening on a 1x2 tile, die 0.0363 mm^2, WNS 0.00, typical power 1.21 mW.

Impact:

A corrupt, forged, or replayed frame no longer appears valid to the host, with measurable and traceable assurance.

## 2. Background & Problem Statement

Background:

Serial and RF links carry data between transceivers, terminals, and hosts in identity and payment systems.

In lightweight designs the physical line coding (Manchester, 8b/10b) is treated as sufficient, so the receiver parses an untrusted bitstream and no frame is authenticated.

Two failure classes follow.

First, no validation of the received integrity value (CWE-354): a keyless CRC or ECC detects random errors but is forgeable by an active attacker, and an unimplemented check provides nothing.

Second, non-atomic commit (CWE-1264): data and control can de-synchronize under glitches or jitter.

A fragile FSM (CWE-1245) and unvalidated input (CWE-20) compound it.

Evidence from a real link:

The baseline `tt07-bep-decode` (433 MHz Manchester, Tiny Tapeout 07) receives a 24-bit integrity field and exposes it to the host without checking it.

We reproduced the consequence in simulation: the baseline latches a corrupted payload and a corrupted integrity field with `full=1` (CWE-354, measured).

The field is not a standard CRC but an undocumented error-correcting code; this is confirmed by the baseline author, and the algorithm is unsolved.

The RF case is therefore evidence of the vulnerability class, not our solved integrity path.

<figure class="proto"><img src="assets/sim-baseline-vulnerability.png" alt="Baseline vulnerability"><figcaption>Figure: `full` stays high for a clean frame, a corrupt payload, and a corrupt integrity field (baseline `tt07-bep-decode`).</figcaption></figure>

Gap vs available solutions:

| Approach | Limit |
| --- | --- |
| Parity or CRC byte | Detects random errors; no framing; forgeable |
| Full 8b/10b | DC balance only; no integrity |
| Software verification | Runs after data crosses the trust boundary |
| Standard decoders | Validate only the start of the frame |
| MAC without freshness | Forge-resistant but replayable |

None combine authentication, freshness, and atomic fail-closed commit at the boundary in a small area.

Problem statement:

1. How to authenticate a received frame against forgery (CWE-345)?
2. How to reject replayed frames without persistent state (CWE-294)?
3. How to commit data and control atomically, fail-closed, so a failed check never reaches the host (CWE-1264, CWE-1245)?
4. How to make this a reusable core that fits different front-ends (Manchester/RF, SerDes, UART) and both FPGA and ASIC?

## 3. Proposed Chip Design

### 3.1 System Architecture

<figure class="proto"><img src="assets/block-diagram-link.svg" alt="Authenticated boundary architecture"><figcaption>Figure: authenticated boundary architecture (Tier A, single clock).</figcaption></figure>

<figure class="proto"><img src="assets/frame-link.svg" alt="Link frame format"><figcaption>Figure: link frame format and the CBC-MAC chain.</figcaption></figure>

Modules:

- `simon32_64.v`: serialized SIMON-32/64 block cipher, one round per cycle.
- `l2_auth.v`: CBC-MAC over counter plus payload (three 32-bit blocks), tag compare, and counter freshness.
- `l3_commit_gatekeeper.v`: atomic commit only when authentication and freshness pass; on failure it holds `host_full` low and raises a sticky `fault`.
- `salaras_auth_top.v`: L2 and L3 integration.
- `project.v`: Tiny Tapeout wrapper with a serial frame loader.

Interface:

- Inputs: 64-bit key, 32-bit counter, 64-bit payload, 32-bit tag.
- Outputs: `host_full`, `host_data`, `fault`, `auth_ok`, `fresh_ok`, `done`.
- `full` handshake and `fault` notification; `fault` is sticky until acknowledged.

Processing and memory:

- Streaming data path; CBC-MAC runs as blocks arrive.
- No block RAM; state is registers only (MAC, counter, flags).

Power:

- Single-clock digital logic, no DSP, internal PLL, or large memory.
- The MAC is active only during a frame, so switching activity is minimal when idle.

### 3.2 Resource Estimate

FPGA estimate (Yosys, before Quartus synthesis):

| Resource | Estimate | DE10-Nano capacity |
| --- | --- | --- |
| Logic elements / LUT | about 360 LUT equivalent | 41,910 ALM |
| Registers / flip-flops | 500 | 415,000 |
| Block RAM (M10K) | 0 | 5,570 Kbit |
| DSP | 0 | 112 |

ASIC target: Tiny Tapeout sky130 130nm via OpenLane.

The RF appendix has a real result: 1x2 tile, die 0.0363 mm^2, WNS 0.00, typical power 1.21 mW.

Sky130 hardening for the new link: 2x2 tile, die 0.0756 mm^2, 2354 cells, 0 DRC, 0 LVS, WNS 0.00, typical power 1.87 mW.

Tools:

- Intel Quartus Prime (synthesis, fit, timing, SignalTap) for the DE10-Nano.
- OpenLane and Yosys for the sky130 ASIC path.
- Verilator and Icarus Verilog for simulation and lint.
- cocotb and pytest for automated testbenches.
- SymbiYosys for formal proofs.

### 3.3 Test Plan

RTL simulation (S1, measured):

- cocotb drives the MAC, L2, and commit with the success matrix: clean frames accepted, forgery, wrong key, replay, and stale counter rejected, and 128 of 128 single-bit flips rejected.
- Latency measured per stage: 33 cycles per SIMON block, 107 cycles for MAC and freshness, 108 cycles end to end.

<figure class="proto"><img src="assets/sim-auth-commit.png" alt="Authentication and commit"><figcaption>Figure: a clean frame accepted and a corrupted frame rejected at the authenticated boundary.</figcaption></figure>

<figure class="proto"><img src="assets/sim-boundary-timeout.png" alt="Boundary timeout"><figcaption>Figure: a timeout fault on the boundary path (RF appendix evidence).</figcaption></figure>

DE10-Nano board test (S2, planned):

- Synthesis procedure: a Quartus project with a board wrapper, SDC, and pin assignments.
- Bitstream implementation (.sof/.rbf) and real-time on-board testing.
- Internal signal verification with SignalTap on `auth_ok`, `fresh_ok`, `done`, `host_full`, and `fault`.
- On-board test shows a clean frame accepted and a corrupt frame rejected.
- The organizer's FPGA/sandbox facility is used at the bootcamp to run this stage.

Success metrics:

| Metric | Target | Evidence |
| --- | --- | --- |
| Single-bit error detection | 100 percent | Simulation (128/128) |
| False reject | 0 percent | Simulation (20 clean frames) |
| Forgery and replay | rejected | Simulation |
| End-to-end latency | measured 108 cycles | Simulation |
| Fail-closed | formally proven | SymbiYosys |

## 4. References

- PERURI. "Buku Panduan Peserta PERURI Chip Hackathon 2026." https://summit.peruri.co.id/docs/Buku-Panduan-PERURI-Chip-Hackathon.pdf
- Kohnen, Z. "Decoding Manchester coded transmissions in a fully digital ASIC." BSc Thesis, 2024.
- Kohnen, Z. and Alvarado, A. "Manchester decoder of a home thermostat's wireless protocol." FSiC, 2025.
- Beaulieu, R. et al. "The SIMON and SPECK Families of Lightweight Block Ciphers." IACR ePrint 2013/404.
- Tiny Tapeout. https://tinytapeout.com/
- MITRE. CWE-354, CWE-345, CWE-294, CWE-1264, CWE-1245, CWE-20.
- Terasic. "DE10-Nano - Cyclone V FPGA Guide."

## 5. Appendix

### Appendix A. Team & Roles

| Name | Expertise | Role |
| --- | --- | --- |
| Ibrahim Fauzi Rahman | RTL / Verilog | RTL designer, integration, synthesis |
| Idris Syaifulloh | Verification / Python | cocotb, fault injection, metrics |
| Dr. Setia Jul Ismail, S.T., M.T. | Architecture / Methodology | Advisor, claim validation |

### Appendix B. Outputs & Demo

- Verilog RTL, cocotb testbench scripts, and formal properties.
- FPGA bitstream (.sof/.rbf) and on-board demo (bootcamp plan).
- Source repository and a short technical report.

### Appendix C. Bootcamp Plan (18-20 October 2026)

| Day | Focus | Deliverable |
| --- | --- | --- |
| Day 1 | Finalize link RTL, SerDes integration, start advanced crypto analysis | Simulatable RTL |
| Day 2 | Quartus synthesis, SignalTap, on-board fault-injection and replay tests | Bitstream and resource/timing report |
| Day 3 | Final measurements, hardening polish, demo, Top 5 to Top 3 presentation | Demo and presentation material |

### Appendix D. Latency Budget (measured)

| Stage | Value |
| --- | --- |
| SIMON block | 33 cycles |
| MAC and freshness | 107 cycles |
| Commit | 1 cycle |
| End to end | 108 cycles |

### Appendix E. Integrity Comparison (measured)

| Property | Keyless CRC | Keyed MAC | MAC + counter |
| --- | --- | --- | --- |
| Latency | 73 cycles | 107 cycles | 108 cycles |
| Random error detection | yes | yes | yes |
| Forgery resistance | no | yes | yes |
| Replay resistance | no | no | yes |

### Appendix F. Problem Evidence (RF)

The baseline `tt07-bep-decode` latches a corrupt payload and integrity field with `full=1` (CWE-354, measured). Details in `sim/RESULTS.md`.

### Appendix G. Limits

- No key provisioning, cross-power replay resistance, or side-channel resistance.
- No full cryptographic proof; a 32-bit tag gives about 2^-32 forgery probability.
- The serial link and CDC are the next stage; FPGA numbers await Quartus synthesis.

### Appendix H. DE10-Nano Board Test

- Board: Terasic DE10-Nano, Cyclone V SoC (5CSEBA6U23I7), with Quartus Prime.
- Clock: `CLOCK_50` at 50 MHz directly, one clock domain.
- Procedure: synthesis (`quartus_sh --flow compile`), bitstream upload (.sof/.rbf), and real-time on-board testing.
- Frame loading: shift 192 bits (key 64, counter 32, payload 64, tag 32) over GPIO; the core loads the key and starts the MAC.
- SignalTap: `auth_ok`, `fresh_ok`, `done`, `host_full`, `fault`.
- On-board test: clean frame accepted (`host_full` high), corrupt frame rejected (`host_full` low, `fault` high), replay not committed.
- Reports: Fitter (ALM/FF/M10K/DSP), Timing Analyzer (Fmax, WNS), and PowerPlay.
- The organizer's FPGA/sandbox facility is used at the bootcamp.
