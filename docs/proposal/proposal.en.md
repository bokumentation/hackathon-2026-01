# TRI-ARGA: Three-Layer Portable Data Security Gate with Fail-Closed Principle for Lightweight Serial Links

Category: IC Chip Design & FPGA Implementation

Focus Area: 04 - Secure Communication (secure framing & interface integrity)

## 1. Executive Summary

**Problem:**

A serial decoder architecture parses a bitstream from an untrusted source directly into registers, then forwards the integrity field to the host without verification. On the Tiny Tapeout 07 Manchester baseline (tt07-bep-decode), we measured that both a corrupt payload and a corrupt integrity field are still forwarded to the host as a valid frame. Without a key and counter mechanism, this class of decoder cannot distinguish a genuine frame from a forged one or a replay attack (replaying an old frame).

**Solution:**

We propose a fail-closed ingress gate architecture with three layers of defense in one core:

1. **L1 Frame Loader:** Shifts a 128-bit frame (counter + payload + tag) and a 64-bit key serially, using a write-once key register lock that stays locked until the system is reset (CWE-1224).
2. **L2 Authentication:** Implements a fixed-length SIMON-32/64 CBC-MAC, together with monotonic counter verification (CWE-345, CWE-354, CWE-294).
3. **L3 Atomic Commit:** Data and the validation indicator signal are asserted together (atomic drive) in a single clock cycle only if authentication and freshness verification pass. On failure, the fault indicator is asserted and stays latched (sticky) until it receives an acknowledge signal (CWE-1264, CWE-1245).

**Chip:**

TRI-ARGA is pure digital IP that is front-end agnostic, so it can be integrated flexibly behind a TT07 SerDes, a Manchester/RF decoder, or a UART.

**Measured Results in Simulation:**

- **Security:** Rejects 100% of bit manipulation (single-bit flip 128/128), forgery, wrong keys, and replay attacks with no false reject (0/20). SymbiYosys formal verification confirms the fail-closed properties hold.
- **Performance & Latency:** Atomic verification completes in 108 clock cycles (2.16 µs at 50 MHz), giving 29 Mbit/s throughput with no bottleneck.
- **ASIC Synthesis (SkyWater 130nm):** The L1-L3 core is area-efficient (0.0756 mm²) with 2.10 mW typical power (DRC/LVS = 0, WNS = 0.00 ns). Integrating the 8b/10b link (Tier B) brings total power to 3.61 mW.

**DE10-Nano FPGA Implementation:**

The prototype is mapped onto the Cyclone V fabric (DE10-Nano) at 50 MHz without using the HPS (Hard Processor System). The on-board demonstration applies an internal loopback mechanism (link_tx to link_rx across the L2+L3 core), with test scenarios (valid, corrupt, or replay) injectable via DIP switch. Validation status and the fault indicator are monitored through on-board LEDs and a SignalTap logic analyzer.

**Impact & Benefits:**

- **Hardware-Level Security:** Eliminating overhead ensures the host only processes data that has already been verified.
- **Silicon Efficiency:** The silicon area requirement is only **0.0756 mm²** with **2.10 mW** power on the SkyWater 130nm ASIC. When integrated with the optional 8b/10b serial link module (Tier B), total power becomes **3.61 mW**.

**Target Users:**

Secure-element and identity-device designers, IP integrators needing an ingress-hardening block, and software/firmware teams that need assurance that a frame read by the host has been authenticated.

## 2. Background and Problem Statement

### 2.1 Background

Lightweight serial and RF links carry data between transceivers, terminals, secure elements, and hosts in identity-device ecosystems such as e-KTP. In hardware security architecture, the fail-closed principle states that any process failure (due to data error, key mismatch, or an attack indication) automatically isolates the output data path and blocks data release to the host. Unlike the fail-open approach, which risks forwarding corrupt data during a fault, fail-closed guarantees that the system always returns to a total denial condition (default-deny state).

The case study of the 433 MHz Manchester baseline module `tt07-bep-decode` by Zachary Kohnen (2024) is analyzed as an example of a digital receiver decoder architecture. This module processes the digital signal resulting from demodulation by an external RF front-end. In his report, Kohnen explicitly states that the module was designed by prioritizing area efficiency and meeting the submission deadline, so hardware-level security validation was not implemented. Several key findings:

- **Pass-Through Without Verification:** The baseline module receives a 24-bit integrity field (`tail_1..3`). However, this field is forwarded raw to the host.
- **Measured Validation Vulnerability:** In simulation, the baseline latches a corrupt payload or integrity field, then automatically asserts `full=1` right after 96 bits are received without checking the validity of the data.
- **Absence of Cryptographic & Replay Protection:** The baseline design has no keyed authentication or monotonic counter mechanism, so it cannot distinguish a genuine frame from a forged one or a replay attack.

Mitigating this security gap in software is insufficient, because processing happens after data has already crossed the hardware trust boundary. A hardware-level interface protection module is therefore needed before data is handed to the host.

### 2.2 Trade-Off Analysis and Architectural Gap vs Available Solutions

Existing industry solutions generally fall into several tiers, but each has its own architectural limitations for low-power applications:

| **Approach / Architecture**            | **Protection Coverage**                                          | **Architectural Limitation (Trade-Off)**                                                                          |
| -------------------------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Parity / Keyless CRC                   | Random line error detection                                      | Cannot prevent forgery, replay attack, or active tampering.                                                      |
| Physical Coding (8b/10b)               | DC-balance and clock synchronization                             | Does not verify the integrity or validity of payload content.                                                    |
| Software-Level Verification            | Logic flexibility and easy updates                               | Execution happens after data crosses the hardware trust boundary.                                                |
| Standard Keyed-MAC (Without Counter)   | Message authentication and integrity (forgery protection)        | Vulnerable to replay of old frames (replay attack).                                                              |
| Full AEAD Cryptography (e.g. Ascon)    | Authentication, integrity, and confidentiality                   | Requires larger area overhead; still needs separate atomic commit logic on the ingress path.                     |
| TRI-ARGA (Proposed)                    | Authentication, replay protection, and atomic fail-closed commit | Data confidentiality is not implemented directly (out of scope)                                                  |

### 2.3 Problem Statement

1. **Low-Power Authentication (CWE-345):** How to design a hardware-level frame authentication mechanism resistant to forgery while meeting the tight silicon area budget of the Tiny Tapeout shuttle?
2. **Replay Protection Without Non-Volatile Memory (CWE-294):** How to verify message freshness and reject replayed frames within a single power session without relying on non-volatile memory?
3. **Atomic Commit & Fail-Closed Mechanism (CWE-1264, CWE-1245):** How to guarantee that data release and the validation indicator signal happen atomically and follow the fail-closed principle, so a frame that fails verification is never accessed by the host?
4. **Front-End Portability & Integrity:** How to design a front-end agnostic core architecture so it can be integrated flexibly behind various serial interfaces (such as the Area 04 TT07 SerDes baseline, a Manchester/RF decoder, or UART), on both ASIC (sky130) and FPGA (Cyclone V) synthesis targets?

## 3. Proposed Chip Design

### 3.1 Solution & System Architecture

<figure class="proto"><img src="assets/block-diagram.svg" alt="Authenticated boundary architecture"><figcaption>Figure 1. TRI-ARGA architecture: trust boundary, three layers, separate key path.</figcaption></figure>

Notes:

- All data coming from the link is considered untrusted.
- The key enters from the host through a separate path, and only L3 may release data to the host.

**Frame Format and Authentication (See Appendix I, Figure I.1 and Table I.1)**

The data packet received by TRI-ARGA is 128 bits total, processed in a streaming manner, consisting of a 32-bit counter for message freshness verification (freshness check to prevent replay attacks), a 64-bit payload as the main application data, and a 32-bit CBC-MAC tag computed over the counter and payload. This authentication process is combined with a 64-bit secret key injected from the host through a trusted path (port) isolated from the data path.

Authentication is computed using a CBC-MAC chain over three 32-bit blocks ($B_1 = \text{counter}$, $B_2 \text{ and } B_3 = \text{payload}$) with Initial Vector $\text{IV} = 0$ and a 64-bit key $K$:

$$C_1 = E_K(B_1), \quad C_2 = E_K(C_1 \oplus B_2), \quad \text{Tag} = C_3 = E_K(C_2 \oplus B_3)$$

A frame is valid only if the internally computed $\text{Tag}$ exactly equals the $\text{Tag}$ received from the link, and the $\text{Counter}$ value is proven greater than the last recorded counter.

**RTL Module Details**

|**RTL Module Name**|**Layer**|**Function and Hardware Logic**|
|---|---|---|
|`l1_serial_loader.v`|L1|Shifts a 64-bit key and a 128-bit frame serially; applies write-once key register locking until reset (CWE-1224) [9].|
|`simon32_64.v`|L2|Serialized lightweight SIMON-32/64 cipher engine (one round per clock cycle).|
|`l2_auth.v`|L2|CBC-MAC computation engine, tag comparator, and counter freshness verifier.|
|`l3_commit_gatekeeper.v`|L3|Atomic commit executor; releases data only if `auth_ok` and `fresh_ok` are high. On failure, holds `host_full` and asserts a sticky `fault` signal.|
|`boundary_top.v`|L2+L3|Integration module combining the L2 and L3 security processing blocks.|
|`project.v`|_Wrapper_|Standard Tiny Tapeout top-level wrapper (instantiates the L1 module and `boundary_top`).|
|`link_enc_8b10b.v`, `link_dec_10b8b.v`, `l1_link_framing.v`, `link_tx.v`, `link_rx.v`, `link_top.v`|Tier B|Optional 8b/10b serial link module with running disparity, K-character framing, word lock, and loopback testing.|

**`boundary_top` Module Interface**

The signal interface between the `boundary_top` security module and the host system is defined as follows:

|**Signal Name**|**Direction**|**Bit Width**|**Functional Description**|
|---|---|---|---|
|`key`|Input (host)|64|MAC key, loaded via a trusted internal port.|
|`counter`, `payload`, `tag`|Input (link)|32, 64, 32|Frame fields from the front-end to be verified.|
|`host_data`|Output|96|Combined counter and payload, valid to read only if committed.|
|`host_full`|Output|1|Validation latch signal; high only if authentication and freshness are confirmed.|
|`auth_ok`, `fresh_ok`, `done`|Output|1|Per-frame processing status indicators.|
|`fault`|Output|1|Failure indicator (sticky fault); stays high until acknowledged by the host.|

**Processing and Memory Architecture**

- One-way streaming flow; CBC-MAC runs as blocks arrive.
- No block RAM and no frame buffer. State is register only: cipher state, last counter, and status flags.

**Power Consumption (Synthesis Results)**

- **Core (L1-L3):** OpenLane synthesis (SkyWater 130nm ASIC) records 2.10 mW typical power.
- **Optional Link (Tier B 8b/10b):** OpenLane sky130 hardening gives 3.61 mW total typical power. As a supporting estimate, Quartus Prime synthesis for the DE10-Nano gives a vector-less PowerPlay estimate of 3.76 mW core dynamic power; this estimate has low confidence and is dominated by device static power, so it is labeled an estimate, not a measurement.
- The MAC engine is dynamic only while a frame is received, keeping switching activity minimal when idle.

**FPGA Resource Usage Estimate for the DE10-Nano from Quartus Prime Synthesis:**

| **Hardware Component**        | **Usage Result (Fit)** | **DE10-Nano Total Capacity** | **Utilization Percentage** |
| ----------------------------- | ---------------------- | ---------------------------- | -------------------------- |
| Logic Utilization (ALM)       | 421 ALM                | 41,910 ALM                   | < 1.1%                     |
| Registers (Flip-Flop)         | 1,029 FF               | 166,036 FF                   | < 0.7%                     |
| Block RAM (M10K)              | 0 Kbit                 | 5,570 Kbit                   | 0.0%                       |
| DSP Blocks                    | 0                      | 112                          | 0.0%                       |
| Phase-Locked Loop (PLL)       | 0                      | 6                            | 0.0%                       |
| Maximum Frequency ($F_{max}$) | 97.9 MHz               | System Target: 50.0 MHz      | Meets Target               |

**Software and Design Tools:**

- Intel Quartus Prime (synthesis, fit, timing, SignalTap) for the DE10-Nano.
- OpenLane/OpenROAD and Yosys for the sky130 ASIC path.
- Verilator and Icarus Verilog for simulation and lint.
- cocotb and pytest for automated testbenches.
- SymbiYosys (formal proofs, smtbmc z3 engine).

ASIC target: Tiny Tapeout sky130 130 nm via OpenLane. Results as follows:

- sky130 hardening of the core: 2×2 tile, die 0.0756 mm², 2511 cells, 0 DRC, 0 LVS, 0 antenna, WNS 0.00, typical power 2.10 mW.
- sky130 hardening of the core with the serial link (tt_um_link): 2×2 tile, 3220 cells, 2 antenna violations, WNS 0.00, typical power 3.61 mW.

### 3.2 Test Plan

**RTL Simulation (Measured results in Appendix D; waveform in Appendix I, Figure I.2):**

- cocotb testbenches drive L1, L2, and commit with the success matrix: clean frames accepted; forgery, wrong key, replay, and stale counter rejected; and 128 of 128 single-bit flips rejected.
- The link testbench drives the Tier B loopback: a clean frame is committed, while forgery, replay, and line errors are rejected.
- Latency is measured per stage: 33 cycles per SIMON block, 107 cycles for MAC and freshness, 108 cycles end-to-end.

**SymbiYosys Formal Verification (Per-job detail in Appendix K):**

Nine properties pass: five for the core (`auth_top`, `auth_data_integrity`, `l3_commit_core`, `simon32_64`, `l1_link`), one for the Tier B link (`link_framing`), and three for the Appendix F (`l1_framing`, `l2_integrity`, `l3_commit`).

**DE10-Nano FPGA Board Test (Bootcamp plan in Appendix C; detail in Appendix H):**

- Synthesis procedure: Quartus project with board wrapper, SDC, and pin assignment. No external device and no second clock; CDC is out of scope.
- Bitstream implementation (.sof/.rbf) and real-time on-board testing.
- The on-board demonstration uses an internal loopback from `link_tx` to `link_rx` through the L2+L3 core. A switch selects the case: clean frame, corrupt frame (one payload/tag bit flipped), and replay (the same frame sent again).
- Internal signal verification with SignalTap on `auth_ok`, `fresh_ok`, `done`, `host_full`, and `fault`.

**Target Success Metrics:**

| Metric                 | Target                                          | Evidence                      |
| ---------------------- | ----------------------------------------------- | ----------------------------- |
| Single-bit error detection | 128/128 observed; theoretical pass probability ~2^-32 | Simulation                |
| False reject           | 0%                                              | Simulation (20 clean frames)  |
| Forgery and replay     | Rejected                                        | Simulation, then on-board     |
| End-to-end latency     | 108 cycles                                      | Simulation, then SignalTap    |
| Fail-closed            | 9 jobs pass                                     | SymbiYosys                    |
| FPGA Fmax              | 97.9 MHz measured (target at least 50 MHz)      | Quartus Timing Analyzer       |

### 3.3 Security Design (Threat Model and CWE Mapping)

The primary assets protected by the TRI-ARGA architecture include the integrity and authenticity of frames handed to the host, frame freshness, and the confidentiality and integrity of the MAC key register. The trust boundary is set strictly at the silicon level:

- **Untrusted Side:** All data entering from the front-end interface (SerDes, Manchester/RF decoder, or UART), including the counter, payload, and tag fields.
- **Trusted Side:** The internal host interface and the isolated key-loading port. The secret key never passes through the external link.

Hardware-level threat mitigation metrics and the CWE (Common Weakness Enumeration) vulnerability mapping are defined in the following table:

| **Threat / Vulnerability**             | **CWE Code** | **Hardware Mitigation**                                                              | **Validation Evidence**               |
| :------------------------------------- | :----------- | :----------------------------------------------------------------------------------- | :------------------------------------ |
| Forged frame (Forgery)                 | CWE-345      | SIMON-32/64 CBC-MAC authentication with a 32-bit tag.                                | Forgery rejected (cocotb simulation)  |
| Unchecked data integrity               | CWE-354      | Recomputed tag compared atomically before commit.                                    | 128/128 bit-flips rejected            |
| Replay of old frames                   | CWE-294      | Strictly increasing monotonic counter verification.                                  | Replay and stale counter rejected     |
| Data and control desynchronized        | CWE-1264     | 1-cycle atomic commit: `host_data` and `host_full` released together.                | SymbiYosys formal verification        |
| Stuck FSM / illegal state              | CWE-1245     | Fully enumerated FSM, timeout mechanism, and sticky `fault` signal.                  | Formal properties and timeout test    |
| Unauthorized key overwrite/modification | CWE-1224    | The L1 Loader 64-bit key register is write-once (locked until reset).                | Loader test and formal properties     |
| Invalid framing                        | CWE-20       | Frames with wrong structure/length are rejected directly at the L1 Loader.           | Timeout test (Appendix F)             |

## 4. References

1. Pa1mantri. "tt07_cdc_fifo, Tiny Tapeout 07." https://github.com/Pa1mantri/tt07_cdc_fifo
2. DusterTheFirst. "tt07-bep-decode, Tiny Tapeout 07." https://github.com/DusterTheFirst/tt07-bep-decode
3. Z. Kohnen. "Decoding Manchester coded transmissions in a fully digital ASIC." BSc Thesis, 2024.
4. R. Beaulieu et al. "The SIMON and SPECK Families of Lightweight Block Ciphers." IACR ePrint 2013/404, 2013.
5. M. Bellare, J. Kilian, and P. Rogaway. "The Security of the Cipher Block Chaining Message Authentication Code." *Journal of Computer and System Sciences*, vol. 61, no. 3, 2000.
6. NIST. SP 800-38B, "Recommendation for Block Cipher Modes of Operation: The CMAC Mode for Authentication." 2016. https://csrc.nist.gov/
7. NIST. SP 800-232, "Ascon-Based Lightweight Cryptography Standards for Constrained Devices." 2024. https://csrc.nist.gov/
8. Terasic. "DE10-Nano - Cyclone V FPGA User Manual." 2019. https://www.terasic.com.tw/
9. MITRE. "Common Weakness Enumeration (CWE): CWE-20, CWE-294, CWE-345, CWE-354, CWE-1245, CWE-1264." 2024. https://cwe.mitre.org/

## 5. Appendix

### Appendix A. Team Identity and Roles

Team Tri Arga, Universitas Telkom.

| Member Name | Primary Expertise | Responsibility & Role |
| --- | --- | --- |
| Ibrahim Fauzi Rahman | Embedded Hardware/System, IoT, PCB Design, Isolated RS485/CAN Bus | RTL: L1-L3 design and integration |
| Idris Syaifulloh | DevOps, Machine Learning, Malware Researcher, CI/CD | Verification: cocotb, fault injection, metrics, CI, analysis |

Advisor: Dr. Setia Juli Irzal Ismail, S.T., M.T. - Universitas Telkom

### Appendix B. Outputs and Demo

- Verilog RTL, cocotb testbench scripts, and SymbiYosys formal properties.
- sky130 hardening results (GDS, DRC/LVS/timing/power reports).
- FPGA bitstream (.sof/.rbf), buildable from this repository.
- Source repository: https://github.com/bokumentation/hackathon-2026-01, and a short technical report.
- GDS Viewer (Tiny Tapeout chip 3D visualization): https://bokumentation.github.io/hackathon-2026-01/

### Appendix C. Bootcamp Plan (18-20 October 2026)

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
| FSM overhead: 2 cycles start/done handshake per block (x3), 1 cycle input latch, 1 cycle decision | 8 |
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

The baseline `tt07-bep-decode` latches a corrupt payload and integrity field with `full=1` (CWE-354, measured) [2], [3]. Details in `sim/RESULTS.md`; the L1 timeout waveform is in `appendix/rf/figures/sim-boundary-timeout.png`.

<figure><img src="assets/gtkwave-tb-serial-baseline.png" alt="Baseline vulnerability"><figcaption>Figure F.1. Baseline tt07-bep-decode: full stays high for a clean frame, a corrupt payload, and a corrupt integrity field.</figcaption></figure>

sky130 hardening result for the Appendix F design (baseline front-end plus L1 framing, parameterized CRC L2 integrity, and the same L3 gate as the core): 1x2 tile, die 0.0363 mm², 1233 cells, WNS 0.00, typical power 1.21 mW. These are not the TRI-ARGA core numbers (see 3.1).

### Appendix G. Limits

| Limit | Impact | Mitigation or plan |
| --- | --- | --- |
| No payload confidentiality | Payload readable by eavesdropper | Out of scope; can be added with AEAD (e.g. Ascon) [7] |
| 32-bit tag | Forgery probability ~2^-32 per attempt | Sufficient for lightweight links; longer tag with 64-bit cipher |
| 32-bit block birthday bound | Security degrades after ~2^16 blocks per key | Mandatory key rotation, recommended every 2^12 frames |
| CBC-MAC fixed length only | Unsafe for variable-length frames | Frame format fixed at three blocks; switch to CMAC if variable [6] |
| Counter resets to 0 after reset | Old frames can be accepted again after power cycle | Fresh session key every boot |
| Key provisioning | Core does not specify key source | Host or secure-element responsibility |
| Side-channel and glitch | Not analyzed | Formal properties prove logic only, not physical resilience |
| CDC | Core is currently single clock domain | Out of scope; a second clock only via the CDC FIFO in Tier C [1] |
| FPGA power | Resource and timing measured in Quartus; power still a vector-less estimate | Measure on-board power at bootcamp |

### Appendix H. DE10-Nano FPGA Hardware Test

- Board: Terasic DE10-Nano, Cyclone V SoC (5CSEBA6U23I7), Quartus Prime [8].
- Clock: `CLOCK_50` (50 MHz) directly, one clock domain.
- Procedure: synthesis (`quartus_sh --flow compile`), bitstream upload (.sof/.rbf), real-time on-board test.
- Demonstration: the loopback wrapper instantiates `link_tx` and `link_top` (`link_rx` + `boundary_top`). A switch selects the clean, corrupt, or replay case; `fault_ack` clears the sticky fault.
- SignalTap (prepared, awaiting board): taps `host_full`, `fault`, `auth_ok`, `fresh_ok`, `done`, `key_locked`; sample clock `CLOCK_50`, depth 2048, pre-trigger; trigger on `host_full` rising edge for the accept case and `fault` for the reject case. The `.stp` is created in the Quartus GUI, then `quartus_stp ... --enable` adds the SLD wiring and the design is recompiled; the acquisition script and procedure are in the repository.
- Test scenarios: clean frame committed (`host_full` high); corrupt frame rejected (`host_full` low, `fault` high); replay not committed; fault sticky until acknowledged.
- Reports for the Tier B loopback wrapper (`link_demo_top`): Fitter 421 ALM / 1029 FF, Timing Analyzer Fmax 97.9 MHz (WNS +9.785 ns), PowerPlay 426.2 mW vector-less (3.76 mW core dynamic).
- For reference, the Tier A wrapper (`de10nano_top`, L1 serial loader) was previously measured at 242 ALM / 654 FF, Fmax 136.37 MHz.
- Facility: organizer's FPGA/sandbox at bootcamp.

### Appendix I. Supporting Figures and Tables

<figure class="proto"><img src="assets/frame-link.svg" alt="Frame format and CBC-MAC chain"><figcaption>Figure I.1. 128-bit frame format (counter + payload + tag) and the SIMON-32/64 CBC-MAC chain.</figcaption></figure>

**Table I.1. Frame field specification (128-bit frame + separate 64-bit key)**

| Field | Bit Width | Function |
| --- | --- | --- |
| Counter | 32 | Freshness marker; must be greater than the last recorded counter |
| Payload | 64 | Main application data |
| Tag | 32 | CBC-MAC over counter and payload |
| Key | 64 | Not in the frame; loaded by the host via a trusted port |

<figure><img src="assets/gtkwave.png" alt="Authentication and commit"><figcaption>Figure I.2. TRI-ARGA core: first frame passes (auth_ok, fresh_ok, host_full high); second frame rejected (host_full stays low, fault high).</figcaption></figure>

### Appendix J. Cryptography Notes

- **Why SIMON-32/64.** This cipher is designed for very small hardware and serializable at one round per cycle, fitting in a 2x2 Tiny Tapeout tile [4]. We are aware that SIMON/SPECK was rejected as an ISO standard in 2018 and that the current NIST lightweight cryptography standard is Ascon [7]. The cipher is therefore wrapped in a modular block interface: it can be swapped for SIMON-64/128 or Ascon without changing L2 and L3, at a larger area cost.
- **CBC-MAC for fixed length only.** CBC-MAC is secure only if all messages have the same length [5]. The frame format is fixed at three blocks; if variable-length frames are ever needed, the mode changes to CMAC [6].
- **32-bit block birthday bound.** With a 32-bit block, CBC-MAC security degrades after about 2^16 blocks under the same key, roughly 2x10^4 frames. Integration policy: the key must be rotated well below this limit (recommendation: every 2^12 frames).
- **Forgery probability per attempt** is about 2^-32 due to the 32-bit tag [5], [6].
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
| `l1_framing` | `framing_ok` never high together with `timing_fault` or `timeout_fault` | Appendix F |
| `l2_integrity` | CRC register always starts from initial value when a frame begins | Appendix F |
| `l3_commit` | `host_full` high only if the last commit decision accepted the frame | Appendix F |
