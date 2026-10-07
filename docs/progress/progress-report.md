# TRI-ARGA Progress Report

Authenticated, replay-resistant, fail-closed ingress boundary.
Team Tri Arga, Universitas Telkom.
PERURI Chip Hackathon 2026, Focus Area 04 Secure Communication.

## Summary

The committed Tier A core is complete and verified: a serial loader, a keyed MAC over counter and payload, and an atomic fail-closed commit gate.
The Tier B secure serial link is now built: an 8b/10b link with running disparity, K-character comma framing, and word lock, plus a single-clock loopback through the Tier A core.
All simulation suites, the lint and synthesis checks, and the formal properties pass.
This cycle added the Tier B link and its formal proof, the DE10-Nano loopback demo wrapper with measured Quartus fit/timing/power, and a full reconciliation of the competition proposal with the measured evidence.

## Committed core (Tier A)

| Module | Role |
| --- | --- |
| `l1_serial_loader.v` | Shifts the 64-bit key and the 128-bit frame; write-once key; framing and timeout watchdogs |
| `simon32_64.v` | Serialized SIMON-32/64 block cipher, one round per cycle |
| `l2_auth.v` | CBC-MAC over counter and payload, tag compare, counter freshness |
| `l3_commit_gatekeeper.v` | Atomic fail-closed commit with a sticky fault |
| `boundary_top.v` | L2 and L3 integration, gated by the L1 framing signal |
| `project.v` | Tiny Tapeout wrapper |

## Secure serial link (Tier B)

| Module | Role |
| --- | --- |
| `link_enc_8b10b.v` | 8b/10b encoder with running disparity |
| `link_dec_10b8b.v` | 8b/10b decoder with code and disparity error flags |
| `l1_link_framing.v` | Serial shift, K28.5 comma detect, word lock, and timeout |
| `link_tx.v` / `link_rx.v` | Serial transmit and receive framing around the boundary |
| `link_top.v` | `link_rx` plus `boundary_top` integration |
| `project_link.v` | Tiny Tapeout wrapper `tt_um_link` for the link |

The link is verified by simulation only: an internal loopback commits a clean frame and rejects forgery, replay, and line errors.

## Verification status

| Check | Result |
| --- | --- |
| Unit and integration tests | `make simon`, `make l2`, `make auth`, `make wrapper` pass |
| Link suites | `make link-codec`, `make link-framing`, `make link-top` pass |
| RF appendix suites | `make test`, `make sim`, `make crc` pass |
| Lint | `make lint` clean, no warnings |
| Synthesis | `make synth-check` passes |
| Formal | 9 of 9 jobs pass: `auth_data_integrity`, `auth_top`, `l1_framing`, `l1_link`, `l2_integrity`, `l3_commit`, `l3_commit_core`, `link_framing`, `simon32_64` |
| Measured simulation | 128 of 128 single-bit flips rejected, 0 of 20 clean frames rejected, 108-cycle end-to-end |
| Serial link loopback | clean commit; forgery, replay, and line error rejected |
| FPGA | Quartus DE10-Nano, Tier B loopback wrapper `link_demo_top`: 421 ALM, 1029 flip-flops, Fmax 97.9 MHz, 426.2 mW vector-less (3.76 mW core dynamic). Tier A wrapper for reference: 242 ALM, 654 flip-flops, Fmax 136.37 MHz |
| ASIC (core) | sky130 2x2, 0.0756 mm2, 2511 cells, 0 DRC, 0 LVS, 0 antenna, WNS 0.00, 2.10 mW typical (run 37504588955, commit 00fc423) |
| ASIC (Tier B link) | sky130 2x2, 3220 cells, 2 antenna violations, WNS 0.00, 3.61 mW typical (run 37511052813, commit 9bbb2e0) |

## Changes this cycle

- The Tier B secure serial link was built and verified in simulation: 8b/10b with running disparity, K28.5 comma framing, word lock, and a loopback through the Tier A core.
- A formal proof for the Tier B link framing (`synth/formal/link_framing.sby`) was added, bringing the suite to 9 passing jobs.
- A DE10-Nano loopback demo wrapper (`fpga/de10nano/link_demo_top.v`) was added and synthesized in Quartus, with measured fit, timing, and power.
- The competition proposal (ID and EN) was reconciled with the measured evidence: corrected sky130 and FPGA numbers, the 9-job formal count, the Tier B simulation evidence, the on-chip loopback test plan, and IEEE-style citations. The core was fit to the six-page limit.
- The evidence index, README, demo, SignalTap plan, Quartus report, and submission checklist were synchronized with the current state.

## Open work

- Verify the Tier B loopback wrapper on the DE10-Nano at bootcamp, including a SignalTap capture.
- Build the clock-domain crossing (Tier C) with the vendored CDC FIFO.
- Record the 3-5 minute video demo for the Luaran dan Demo section.
- Add measured on-board power to replace the vector-less estimate.

## Risks

- The Tier B serial-link result is simulation-only until the bootcamp; no on-board link measurement is claimed yet.
- Tier C and the CDC are unbuilt, so no CDC result is claimed.
- Limits: no confidentiality, no key provisioning, no cross-power replay counter, and no side-channel claim.
- The Tier B sky130 signoff has 2 antenna violations and is reported as such.

## Evidence

- Simulation: `sim/RESULTS.md`
- Formal: `synth/formal/`
- Area and signoff: `synth/area.md`
- FPGA: `docs/design/quartus-report.md`
- Proposal: `docs/proposal/proposal.id.md`, `docs/proposal/proposal.en.md`
- Deck: `docs/deck/`
- Claim index: `docs/evidence.md`
