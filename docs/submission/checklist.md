# Submission checklist

Checklist for the PERURI Chip Hackathon 2026 submission.
Source of requirements: `docs/competition/ketentuan-proposal.md` and `docs/competition/buku-panduan-peruri-chip-hackathon.md`.

## Required proposal structure

The proposal must follow the five sections in order.
Status is against `docs/proposal/proposal.id.md`.

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
| Proposal (Indonesian) | PDF | `make docs` -> `output/pdf/PROPOSAL-TRIARGA-<ts>.id.pdf` | Done |
| Proposal (English) | PDF | `make docs` -> `output/pdf/PROPOSAL-TRIARGA-<ts>.en.pdf` | Done |
| Markdown sources | `.md` | `docs/proposal/proposal.{id,en}.md` | Done |
| Presentation deck | pptx and pdf | `make docs-all` -> `output/pptx` and `output/pdf` | Done |
| RTL source | `.v` | `src/` | Done |
| Testbench | cocotb `.py` | `test/` | Done |
| Formal properties | SymbiYosys `.sby`/`.sv` | `synth/formal/` | Done |
| ASIC GDS | sky130 GDS | CI `gds.yaml` | Done |
| FPGA bitstream | `.sof`/`.rbf` | `fpga/de10nano/` on hardware | Pending bootcamp |
| On-board demo evidence | SignalTap/VCD | `docs/design/signaltap-plan.md` | Pending bootcamp |

## Pre-submission checklist

- [x] Team identity recorded in Lampiran A (per `docs/identity/identity.md`). Done.
- [ ] Build the proposal PDF with `make docs` and attach it to the submission portal.
- [ ] Build the deck with `make docs-all`.
- [ ] Confirm every reference has an author, title, and year (Section 4). Done.
- [ ] Confirm the claim set matches `docs/evidence.md`. Done.
- [ ] Review `docs/judging/submission-verification.md` and clear any open issue.
- [ ] Verify the links in `docs/index.md` and `README.md`. Done.

## Open items

- Team identity is recorded in `docs/identity/identity.md` (name, expertise, role, contact); NIM is not used.
- On-board results and SignalTap capture require the DE10-Nano at bootcamp.
- Tier B (serial link) is built and claimed as simulation loopback plus sky130 signoff; Tier C (CDC) is future work and is not claimed.

## Notes

- PDFs are generated locally into the git-ignored `output/` folder, so a fresh clone has no PDF until `make docs` runs.
- The competition submission is the proposal PDF; the repository is the supporting source.
