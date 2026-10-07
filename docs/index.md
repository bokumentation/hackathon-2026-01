# TRI-ARGA documentation

Entry point for all project documentation.

## Sections

| Directory | Contents |
| --- | --- |
| [`proposal/`](proposal/proposal.id.md) | Competition proposal (ID + EN) and build |
| [`design/`](design/README.md) | Architecture, threat model, verification plan, trade study, FMEA, Quartus plan and report, SignalTap plan, ideas |
| [`setup/`](setup/debian-13.md) | Host setup, repository workflow, and Quartus install notes for Debian 13 |
| [`judging/`](judging/submission-verification.md) | Submission audit |
| [`competition/`](competition/ketentuan-proposal.md) | PERURI Chip Hackathon handbook, rules, and site notes |
| [`references/`](references/README.md) | Third-party papers (Markdown) and citation index |
| [`datasheet/`](datasheet/README.md) | Board and device datasheet notes |
| [`submission/`](submission/checklist.md) | Submission checklist and deliverables |
| [`progress/`](progress/progress-report.md) | Progress report source and PDF build |
| [`deck/`](deck/build.mjs) | Presentation deck sources (builds into `output/`) |

Generated PDFs, intermediate HTML, and the presentation are written to the git-ignored `output/` folder by `make docs` and `make docs-all`.

## Quick links

- Canonical proposal (ID): [`proposal/proposal.id.md`](proposal/proposal.id.md)
- Canonical proposal (EN): [`proposal/proposal.en.md`](proposal/proposal.en.md)
- Video demo deck: [`deck/build.mjs`](deck/build.mjs)
- Progress report: [`progress/progress-report.md`](progress/progress-report.md)
- Submission checklist: [`submission/checklist.md`](submission/checklist.md)
- Evidence index: [`evidence.md`](evidence.md)
- Glossary: [`glossary.md`](glossary.md)
- Demo and bring-up: [`demo.md`](demo.md)
- Quartus FPGA report: [`design/quartus-report.md`](design/quartus-report.md)
- SignalTap capture plan: [`design/signaltap-plan.md`](design/signaltap-plan.md)
- Setup and workflow (Debian 13): [`setup/debian-13.md`](setup/debian-13.md)
- Architecture: [`design/architecture.md`](design/architecture.md)
- Threat model: [`design/threat-model.md`](design/threat-model.md)
- Trade study: [`design/trade-study.md`](design/trade-study.md)
- FMEA: [`design/fmea.md`](design/fmea.md)
- Submission audit: [`judging/submission-verification.md`](judging/submission-verification.md)
