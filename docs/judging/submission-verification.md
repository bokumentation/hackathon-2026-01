# Submission Verification Report

Date: 2026-10-06 (revision 2)
Proposal: `docs/proposal/proposal.id.md` and `docs/proposal/proposal.en.md`
Guidelines: `docs/competition/ketentuan-proposal.md`, `docs/competition/buku-panduan-peruri-chip-hackathon.md`, `docs/competition/peruri-chip-hackathon-2026.md`
Ground truth: `sim/RESULTS.md`, `synth/area.md`, `synth/formal/`, `docs/design/quartus-report.md`, `docs/evidence.md`
Rules: `AGENTS.md`, `VISION.md`

This revision updates the earlier audit after the `auth_data_integrity` formal proof was fixed and the formal results were re-decomposed in the proposal.
It also records two open action items that the earlier audit did not flag: the core proposal length and the currency of the ASIC numbers.

## Overall Verdict

PASS WITH NOTES.

No disqualifying structural defect was found, and the measured simulation and FPGA claims match their artifacts.
The earlier framing gap is closed: the committed L1 now validates framing and times out a stalled session, so the CWE-20 claim is backed by core logic, and the committed commit gate has its own formal proof (eight jobs total).

Two items still require action before submission:

1. The core proposal exceeds the six-page limit set by the competition FAQ.
2. The ASIC numbers are from a prior revision and are presented without that caveat.

Neither is disqualifying on its own, but both should be resolved or annotated honestly.

## A. Structure Compliance

| # | Requirement | Status | Note |
| --- | --- | --- | --- |
| A1 | Section 1 Executive Summary present | PASS | Covers problem, solution, chip, users, impact |
| A2 | Section 2 Background and Problem Statement | PASS | Includes the measured baseline evidence |
| A3 | Section 3 Proposed Chip Design | PASS | Architecture, interface, memory, power, tools |
| A4 | Section 4 References | PASS | 13 entries with author, title, year |
| A5 | Section 5 Lampiran | PASS | Lampiran A through I present |
| A6 | Lampiran: bootcamp plan | PASS | Three days with deliverables |
| A7 | Lampiran: identitas personal tim | PASS | Team and members listed with expertise and role |
| A8 | Lampiran: role split | PASS | Roles listed per member |
| A9 | Core length at most six pages, excluding cover, references, and technical appendix | ACTION REQUIRED | Built PDFs are 15 pages (ID) and 14 pages (EN); the core body almost certainly exceeds six pages |

Rule source for A9: `docs/competition/peruri-chip-hackathon-2026.md:185`.
Note: the FAQ lists the five structures as ending in Technical Design and Security Design, while `ketentuan-proposal.md` lists References and Lampiran.
The proposal follows the latter and embeds Security Design as Section 3.2.
This is acceptable under `ketentuan-proposal.md` but diverges from the FAQ wording.

## B. Claims Accuracy

Checked against the ground-truth files.

| Claim | Source | Ground truth | Status |
| --- | --- | --- | --- |
| 108 cycles end to end | Sec 1, Sec 3.4 | `sim/RESULTS.md` L3: 108 | PASS |
| 107 cycles MAC plus freshness | Sec 3.4 | `sim/RESULTS.md` L2: 107 | PASS |
| 33 cycles per SIMON block | Sec 3.4 | `sim/RESULTS.md` L1: 33 | PASS |
| 128/128 single-bit flips rejected | Sec 1, Sec 3.4 | `sim/RESULTS.md` L2 | PASS |
| False reject 0 of 20 clean frames | Sec 1, Sec 3.4 | `sim/RESULTS.md` L2 | PASS |
| sky130 2x2, 0.0756 mm2, 2354 cells, 1.87 mW | Sec 1, Sec 3.3 | `synth/area.md` 2x2 signoff | WARN: this is a prior revision; the GDS action must be re-run for the current wrapper, as noted in `README.md` |
| FPGA 242 ALM, 654 FF, 0 M10K, 0 DSP | Sec 1, Sec 3.3 | `docs/design/quartus-report.md` | PASS |
| FPGA Fmax 136.37 MHz | Sec 3.4 | `docs/design/quartus-report.md` | PASS |
| FPGA power 425.4 mW vector-less | Sec 1, Sec 3.3 | `docs/design/quartus-report.md` | PASS |
| Formal 8 jobs pass (5 core/link, 3 RF appendix) | Sec 1, Sec 3.4 | `synth/formal/`: 8 `.sby` files, all pass | PASS |

Formal decomposition, verified against the `.sby` scripts:

- Committed link: `auth_top`, `auth_data_integrity`, `l3_commit_core`, `simon32_64`, `l1_link`.
- RF appendix: `l1_framing`, `l2_integrity`, `l3_commit` read `appendix/rf/src/`, not the committed link modules.
- `auth_data_integrity` is a bounded proof (`mode bmc`, depth 20) with `simon32_64` abstracted by `synth/formal/simon32_64_stub.v`.
- `l3_commit_core` proves the committed `src/l3_commit_gatekeeper.v`, so the core is covered independently of the appendix proof.

## C. Overclaims Audit (AGENTS.md and VISION.md must-not-claim)

| Rule | Status | Note |
| --- | --- | --- |
| No cryptographic proof | PASS | Lampiran G states about 2^-32 forgery for a 32-bit tag |
| No real-frame RF detection rate | PASS | RF framed as problem evidence only |
| No serial link result before Tier B | PASS | No serial link throughput or end-to-end serial result claimed |
| No key provisioning or cross-power replay claim | PASS | Lampiran G states the limitation |
| No portability as result before synthesis | PASS WITH NOTE | FPGA measured; ASIC measured but on a prior revision |
| RF as problem evidence, not solved path | PASS | Section 2 keeps the RF framing |
| No claim that framing validation closes CWE-20 in the committed core | PASS | The committed loader rejects a truncated burst with a sticky framing fault and times out a stalled session; `boundary_top` gates the commit on the L1 `framing_ok` signal |

## D. Reference Quality

All 13 entries carry an author or organization and a year, except the two vendor entries below.

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
| Framing validation independent of the MAC | `l1_serial_loader.v` framing and timeout watchdog; `boundary_top.v` gates the commit with `framing_ok` | PASS |

## F. Subheading Formatting

`docs/proposal/build.mjs` bolds standalone subheadings in the built HTML and PDF.
The Markdown source still contains some plain subheadings (`Masalah yang Diangkat:` and similar).
This is cosmetic for the rendered submission and is checked informationally by `.github/workflows/docs.yaml`.

## Action Items

Required before submission:

| # | Item | Location | Action |
| --- | --- | --- | --- |
| R1 | Core length exceeds six pages | Proposal Sections 1 to 3 | Trim the core to six pages; move detail into the technical appendix |
| R2 | ASIC numbers are a prior revision | Sec 1, Sec 3.3 | Re-run the GDS action for the current wrapper and update the numbers, or label them as a prior revision |

Minor:

| # | Item | Location | Action |
| --- | --- | --- | --- |
| M1 | Plain subheadings in the Markdown source | Section 1 and 3 | Optional: bold them in the source |
| M2 | Terasic reference missing year | Section 4 | Add the publication year |
| M3 | PERURI datasheet reference lacks a year | Section 4 | Add a year if available |

## Confirmed Correct

- All simulation numbers match `sim/RESULTS.md`.
- All ASIC numbers match `synth/area.md`, but they describe a prior revision.
- All FPGA numbers match `docs/design/quartus-report.md`.
- The formal-property count and decomposition match `synth/formal/` (8 jobs), and the proposal labels the RF appendix jobs correctly.
- The committed loader now rejects truncated bursts and stalled sessions fail-closed, backing the CWE-20 claim with core logic.
- The RF appendix is framed as problem evidence, not a solved integrity path.
- No cryptographic proof, key provisioning, or cross-power replay is claimed.
- CWE numbers are used consistently with the mitigation table.
