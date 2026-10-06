# Submission Verification Report

Date: 2026-10-06
Proposal: `docs/proposal/proposal.id.md` and `docs/proposal/proposal.en.md`
Guidelines: `docs/competition/ketentuan-proposal.md`, `docs/competition/buku-panduan-peruri-chip-hackathon.md`
Ground truth: `sim/RESULTS.md`, `synth/area.md`, `docs/design/quartus-report.md`, `docs/evidence.md`
Rules: `AGENTS.md`, `VISION.md`

This report replaces the earlier audit, which was written before the proposal was rewritten and is no longer accurate.

## Overall Verdict

**PASS WITH MINOR NOTES**

The identity item is resolved: Lampiran A lists the team and each member's expertise and role (per `docs/identity/identity.md`).
No disqualifying structural defect and no inaccurate measured claim was found.

## A. Structure Compliance

| # | Requirement | Status | Note |
| --- | --- | --- | --- |
| A1 | Section 1 Executive Summary present | PASS | Covers problem, solution, chip, users, impact |
| A2 | Section 2 Background and Problem Statement | PASS | Includes the measured baseline evidence |
| A3 | Section 3 Proposed Chip Design | PASS | Architecture, interface, memory, power, tools |
| A4 | Section 4 References | PASS | 13 entries with author, title, year |
| A5 | Section 5 Lampiran | PASS | Lampiran A through H present |
| A6 | Lampiran: bootcamp plan | PASS | Three days with deliverables |
| A7 | Lampiran: identitas personal tim | PASS | Team and members listed with expertise and role |
| A8 | Lampiran: role split | PASS | Roles listed per member |

## B. Claims Accuracy

Checked against the ground-truth files.

| Claim | Source | Ground truth | Status |
| --- | --- | --- | --- |
| 108 cycles end to end | Sec 1, Sec 3.4 | `sim/RESULTS.md` L3: 108 | PASS |
| 107 cycles MAC plus freshness | Sec 3.4 | `sim/RESULTS.md` L2: 107 | PASS |
| 33 cycles per SIMON block | Sec 3.4 | `sim/RESULTS.md` L1: 33 | PASS |
| 128/128 single-bit flips rejected | Sec 1, Sec 3.4 | `sim/RESULTS.md` L2 | PASS |
| False reject 0 of 20 clean frames | Sec 1, Sec 3.4 | `sim/RESULTS.md` L2 | PASS |
| sky130 2x2, 0.0756 mm2, 2354 cells, 1.87 mW | Sec 1, Sec 3.3 | `synth/area.md` 2x2 | PASS |
| FPGA 242 ALM, 654 FF, 0 M10K, 0 DSP | Sec 1, Sec 3.3 | `docs/design/quartus-report.md` | PASS |
| FPGA Fmax 136.37 MHz | Sec 3.4 | `docs/design/quartus-report.md` | PASS |
| FPGA power 425.4 mW vector-less | Sec 1, Sec 3.3 | `docs/design/quartus-report.md` | PASS |
| Formal 5 blocking plus 6 L1 plus 1 non-blocking | Sec 1, Sec 3.4 | `synth/formal/`: 7 `.sby` files | PASS |

## C. Overclaims Audit (AGENTS.md and VISION.md must-not-claim)

| Rule | Status | Note |
| --- | --- | --- |
| No cryptographic proof | PASS | Lampiran G states about 2^-32 forgery for a 32-bit tag |
| No real-frame RF detection rate | PASS | RF framed as problem evidence only |
| No serial link result before Tier B | PASS | No serial link throughput or end-to-end serial result claimed |
| No key provisioning or cross-power replay claim | PASS | Lampiran G states the limitation |
| No portability as result before synthesis | PASS | ASIC and FPGA numbers are measured; Tier B/C are future work |
| RF as problem evidence, not solved path | PASS | Section 2 keeps the RF framing |

## D. Reference Quality

All 13 entries carry an author or organization and a year.

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

## F. Subheading Formatting

`docs/proposal/build.mjs` bolds standalone subheadings in the built HTML and PDF.
The Markdown source still contains some plain subheadings (`Masalah yang Diangkat:` and similar).
This is cosmetic for the rendered submission and is checked informationally by `.github/workflows/docs.yaml`.

## Critical Issues

None.

## Minor Issues

| # | Item | Location | Action |
| --- | --- | --- | --- |
| M1 | Plain subheadings in the Markdown source | Section 1 and 3 | Optional: bold them in the source |
| M2 | Terasic reference missing year | Section 4 | Add the publication year |
| M3 | PERURI datasheet reference lacks a year | Section 4 | Add a year if available |

## Confirmed Correct

- All simulation numbers match `sim/RESULTS.md`.
- All ASIC numbers match `synth/area.md`.
- All FPGA numbers match `docs/design/quartus-report.md`.
- The formal-property count matches `synth/formal/` and is decomposed correctly.
- The RF appendix is framed as problem evidence, not a solved integrity path.
- No cryptographic proof, key provisioning, or cross-power replay is claimed.
- CWE numbers are used consistently with the mitigation table.
