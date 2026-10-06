# Submission checklist

Checklist for the PERURI Chip Hackathon 2026 submission.
Source of requirements: `docs/competition/ketentuan-proposal.md` and `docs/competition/buku-panduan-peruri-chip-hackathon.md`.

## Required proposal structure

The proposal must follow the five sections in order.
Status is against `docs/proposal/proposal-salaras.id.md`.

| # | Section | Status |
| --- | --- | --- |
| 1 | Ringkasan Ide / Executive Summary | Done |
| 2 | Latar Belakang and Rumusan Masalah | Done |
| 3 | Proposed Chip Design | Done |
| 4 | Referensi | Done |
| 5 | Lampiran (bootcamp plan, identitas personal tim, pembagian peran) | Partial: identity incomplete |

## Deliverables

| Artifact | Format | Where | Status |
| --- | --- | --- | --- |
| Proposal (Indonesian) | PDF | `make docs` -> `output/pdf/PROPOSAL-SALARAS-<ts>.id.pdf` | Done |
| Proposal (English) | PDF | `make docs` -> `output/pdf/PROPOSAL-SALARAS-<ts>.en.pdf` | Done |
| Markdown sources | `.md` | `docs/proposal/proposal-salaras.{id,en}.md` | Done |
| Presentation deck | pptx and pdf | `make docs-all` -> `output/pptx` and `output/pdf` | Done |
| RTL source | `.v` | `src/` | Done |
| Testbench | cocotb `.py` | `test/` | Done |
| Formal properties | SymbiYosys `.sby`/`.sv` | `synth/formal/` | Done |
| ASIC GDS | sky130 GDS | CI `gds.yaml` | Done |
| FPGA bitstream | `.sof`/`.rbf` | `fpga/de10nano/` on hardware | Pending bootcamp |
| On-board demo evidence | SignalTap/VCD | `docs/design/signaltap-plan.md` | Pending bootcamp |

## Pre-submission checklist

- [ ] Fill the NIM/NIP identity values in `docs/proposal/proposal-salaras.{id,en}.md` (Lampiran A). Open.
- [ ] Build the proposal PDF with `make docs` and attach it to the submission portal.
- [ ] Build the deck with `make docs-all`.
- [ ] Confirm every reference has an author, title, and year (Section 4). Done.
- [ ] Confirm the claim set matches `docs/evidence.md`. Done.
- [ ] Review `docs/judging/submission-verification.md` and clear any open issue.
- [ ] Verify the links in `docs/index.md` and `README.md`. Done.

## Open items

- Personal identity: NIM/NIP placeholders remain in Lampiran A.
- On-board results and SignalTap capture require the DE10-Nano at bootcamp.
- Tier B (serial link) and Tier C (CDC) are future work and are not claimed.

## Notes

- PDFs are generated locally into the git-ignored `output/` folder, so a fresh clone has no PDF until `make docs` runs.
- The competition submission is the proposal PDF; the repository is the supporting source.
