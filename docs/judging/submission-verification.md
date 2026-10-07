# Submission Verification Report

Date: 2026-10-07 (revision 3)
Proposal: `docs/proposal/proposal.id.md` and `docs/proposal/proposal.en.md`
Guidelines: `docs/competition/ketentuan-proposal.md`, `docs/competition/buku-panduan-peruri-chip-hackathon.md`, `docs/competition/peruri-chip-hackathon-2026.md`
Ground truth: `sim/RESULTS.md`, `synth/area.md`, `synth/formal/`, `docs/design/quartus-report.md`, `docs/evidence.md`
Rules: `AGENTS.md`, `VISION.md`

This revision supersedes revision 2.
It records that the two open action items from that revision are resolved: the proposal core is now within the six-page limit, and the ASIC and FPGA rows carry the current measured numbers.
It also records the Tier B secure serial link, which is now built and claimed as simulation evidence.

## Overall Verdict

PASS.

No disqualifying structural defect was found.
The measured simulation, formal, ASIC, and FPGA claims match their artifacts.
The core body fits the six-page limit set by the competition FAQ, and the Tier B link is claimed only as simulation loopback plus sky130 signoff.

## A. Structure Compliance

| # | Requirement | Status | Note |
| --- | --- | --- | --- |
| A1 | Section 1 Executive Summary present | PASS | Covers problem, solution, chip, users, impact |
| A2 | Section 2 Background and Problem Statement | PASS | Includes the measured baseline evidence |
| A3 | Section 3 Proposed Chip Design | PASS | 3.1 Proposed Chip Design, 3.2 Technical Design, 3.3 Security Design |
| A4 | Section 4 References | PASS | 15 IEEE-style entries, all cited |
| A5 | Section 5 Lampiran | PASS | Lampiran A through K present |
| A6 | Lampiran: bootcamp plan | PASS | Three days with deliverables |
| A7 | Lampiran: identitas personal tim | PASS | Team, members, expertise, roles, advisor, contacts on the cover |
| A8 | Lampiran: role split | PASS | Roles listed per member |
| A9 | Core length at most six pages, excluding cover, references, and technical appendix | PASS | Core body is pages 2-7 (six pages); references page 8; appendix follows |

Rule source for A9: `docs/competition/peruri-chip-hackathon-2026.md:185`.
The proposal follows `ketentuan-proposal.md` (References and Lampiran as sections 4 and 5) and also labels the FAQ's named areas inside Section 3 (Proposed Chip Design, Technical Design, Security Design).

## B. Claims Accuracy

Checked against the ground-truth files.

| Claim | Ground truth | Status |
| --- | --- | --- |
| 108 cycles end to end | `sim/RESULTS.md` L3: 108 | PASS |
| 107 cycles MAC plus freshness | `sim/RESULTS.md` L2: 107 | PASS |
| 33 cycles per SIMON block | `sim/RESULTS.md` L1: 33 | PASS |
| 128/128 single-bit flips rejected | `sim/RESULTS.md` L2 | PASS |
| False reject 0 of 20 clean frames | `sim/RESULTS.md` L2 | PASS |
| Serial link loopback clean/forgery/replay/line-error | `test_link_top.py`, `sim/RESULTS.md` | PASS |
| sky130 core 2x2, 0.0756 mm2, 2511 cells, 2.10 mW | `synth/area.md` (run 37504588955, commit 00fc423), 0 DRC/LVS/antenna | PASS |
| sky130 Tier B link 2x2, 3220 cells, 3.61 mW, 2 antenna | `synth/area.md` (run 37511052813, commit 9bbb2e0) | PASS |
| FPGA 421 ALM, 1029 FF, Fmax 97.9 MHz, 426.2 mW | `docs/design/quartus-report.md` (Tier B loopback wrapper) | PASS |
| Formal 9 jobs pass (5 core, 1 Tier B, 3 RF appendix) | `synth/formal/` | PASS |

Formal decomposition, verified against the `.sby` scripts:

- Core: `auth_top`, `auth_data_integrity`, `l3_commit_core`, `simon32_64`, `l1_link`.
- Tier B: `link_framing`.
- RF appendix: `l1_framing`, `l2_integrity`, `l3_commit` read `appendix/rf/src/`, not the committed link modules.
- `auth_data_integrity` is a bounded proof (`mode bmc`, depth 20) with `simon32_64` abstracted by `synth/formal/simon32_64_stub.v`.

## C. Overclaims Audit (AGENTS.md and VISION.md must-not-claim)

| Rule | Status | Note |
| --- | --- | --- |
| No cryptographic proof | PASS | Lampiran G states about 2^-32 forgery for a 32-bit tag |
| No real-frame RF detection rate | PASS | RF framed as problem evidence only |
| No serial link or CDC result before built | PASS | Tier B link claimed as simulation loopback plus sky130 signoff only; CDC/Tier C not claimed |
| No key provisioning or cross-power replay claim | PASS | Lampiran G states the limitation |
| Portability as result | PASS | FPGA measured in Quartus; ASIC measured in OpenLane |
| RF as problem evidence, not solved path | PASS | Section 2 keeps the RF framing |
| CWE-20 backed by core logic | PASS | The committed loader rejects a truncated burst and times out a stalled session; `boundary_top` gates the commit on the L1 `framing_ok` signal |

## D. Reference Quality

All 15 entries carry an author or organization and a year, except the vendor entries below.

| Reference | Status | Note |
| --- | --- | --- |
| Tiny Tapeout | PASS | Title and year present |
| MITRE CWE | PASS | Titles and year present |
| Terasic DE10-Nano user manual | WARN | Year not stated |
| PERURI datasheet | WARN | Institutional entry, no year |

## E. Technical Consistency

| Claim | Actual RTL | Status |
| --- | --- | --- |
| Frame: counter 32, payload 64, tag 32 | `l2_auth.v` inputs match | PASS |
| SIMON-32/64: 16-bit words, 32 rounds, 64-bit key | `simon32_64.v` | PASS |
| CBC-MAC: 3 blocks, IV 0, 32-bit tag | `l2_auth.v` | PASS |
| L3 commits latched data, not live ports | `boundary_top.v` | PASS |
| Key path separate from frame path | `l1_serial_loader.v`, wrappers | PASS |
| Tier B: 8b/10b, comma, word lock, single-clock loopback | `link_*.v`, `test_link_top.py` | PASS |

## Action Items

No required actions before submission.

Minor, optional:

| # | Item | Location | Action |
| --- | --- | --- | --- |
| M1 | Vendor references lack a year | Section 4 | Add a year if available |
| M2 | On-board capture pending | `docs/design/signaltap-plan.md` | Run at bootcamp |

## Confirmed Correct

- All simulation numbers match `sim/RESULTS.md`.
- The current ASIC signoffs (`synth/area.md`: core 2511 cells / 2.10 mW; link 3220 cells / 3.61 mW / 2 antenna) are reflected in the proposal.
- All FPGA numbers match `docs/design/quartus-report.md` (Tier B loopback wrapper).
- The formal count and decomposition match `synth/formal/` (9 jobs), and the RF appendix jobs are labeled correctly.
- The Tier B link is claimed as simulation only; no CDC or Tier C result is claimed.
- The RF appendix is framed as problem evidence, not a solved integrity path.
- No cryptographic proof, key provisioning, or cross-power replay is claimed.
