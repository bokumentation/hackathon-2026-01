# TRI-ARGA Progress Report

Authenticated, replay-resistant, fail-closed ingress boundary.
Team Tri Arga, Universitas Telkom.
PERURI Chip Hackathon 2026, Focus Area 04 Secure Communication.

## Summary

The committed Tier A core is complete and verified: a serial loader, a keyed MAC over counter and payload, and an atomic fail-closed commit gate.
All simulation suites, the lint and synthesis checks, and the formal properties pass.
This cycle added real framing and timeout validation to the committed core, a dedicated formal proof for the core commit gate, an independent latency measurement, and a lint-clean RTL.

## Committed core

| Module | Role |
| --- | --- |
| `l1_serial_loader.v` | Shifts the 64-bit key and the 128-bit frame; write-once key; framing and timeout watchdogs |
| `simon32_64.v` | Serialized SIMON-32/64 block cipher, one round per cycle |
| `l2_auth.v` | CBC-MAC over counter and payload, tag compare, counter freshness |
| `l3_commit_gatekeeper.v` | Atomic fail-closed commit with a sticky fault |
| `boundary_top.v` | L2 and L3 integration, gated by the L1 framing signal |
| `project.v` | Tiny Tapeout wrapper |

## Verification status

| Check | Result |
| --- | --- |
| Unit and integration tests | `make simon`, `make l2`, `make auth`, `make wrapper` pass |
| RF appendix suites | `make test`, `make sim`, `make crc` pass |
| Lint | `make lint` clean, no warnings |
| Synthesis | `make synth-check` passes |
| Formal | 8 of 8 jobs pass: `auth_data_integrity`, `auth_top`, `l1_framing`, `l1_link`, `l2_integrity`, `l3_commit`, `l3_commit_core`, `simon32_64` |
| Measured simulation | 128 of 128 single-bit flips rejected, 0 of 20 clean frames rejected, 108-cycle end-to-end |
| FPGA | Quartus DE10-Nano: 242 ALM, 654 flip-flops, Fmax 136.37 MHz, 425.4 mW vector-less |
| ASIC | sky130 2x2, 0.0756 mm2, 2354 cells, prior revision; GDS re-run pending for the current wrapper |

## Changes this cycle

- Framing and timeout validation added to the committed L1.
  A truncated serial burst raises a sticky framing fault and a stalled auth core raises a timeout fault.
  The commit path is gated by an explicit `framing_ok` signal in addition to the MAC and freshness results, so the CWE-20 claim is backed by core logic and not only by the RF appendix.
- A dedicated formal proof for the committed `l3_commit_gatekeeper` (`synth/formal/l3_commit_core.sby`) now covers the core, alongside the existing RF appendix proof.
- The commit-latency test observes `host_full` independently instead of deriving it from the internal counter.
- Lint is clean: the SIMON z-index width and the unused signals were fixed.

## Open work

- Re-run the sky130 GDS action for the current wrapper and update the ASIC numbers, or keep them labeled as a prior revision.
- Build the serial link (Tier B) on the `TT_UM_SERDES` baseline with 8b/10b framing, alignment, and word lock.
- Trim the competition proposal core to the six-page limit.
- Add the clock-domain crossing (Tier C) with the vendored CDC FIFO.

## Risks

- The ASIC figures do not yet describe the current netlist.
- Tier B and Tier C are unbuilt, so no serial link or CDC result is claimed.
- Limits: no confidentiality, no key provisioning, no cross-power replay counter, and no side-channel claim.

## Evidence

- Simulation: `sim/RESULTS.md`
- Formal: `synth/formal/`
- Area and signoff: `synth/area.md`
- FPGA: `docs/design/quartus-report.md`
- Claim index: `docs/evidence.md`
