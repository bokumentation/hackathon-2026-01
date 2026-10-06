# SALARAS documentation

Entry point for all project documentation.

## Sections

| Directory | Contents |
| --- | --- |
| [`proposal/`](proposal/proposal-salaras.id.md) | Competition proposal (ID + EN) and build |
| [`design/`](design/README.md) | Architecture, threat model, verification plan, trade study, FMEA, Quartus plan and report, SignalTap plan, ideas |
| [`setup/`](setup/debian-13.md) | Host setup, repository workflow, and Quartus install notes for Debian 13 |
| [`judging/`](judging/README.md) | Submission audit, judge QnA, feasibility, prior-art analysis |
| [`competition/`](competition/ketentuan-proposal.md) | PERURI Chip Hackathon handbook, rules, and site notes |
| [`references/`](references/README.md) | Third-party papers (Markdown) and citation index |
| [`datasheet/`](datasheet/README.md) | Board and device datasheet notes |
| [`submission/`](submission/checklist.md) | Submission checklist and deliverables |
| [`deck/`](deck/build.mjs) | Presentation deck sources (builds into `output/`) |

Generated PDFs, intermediate HTML, and the presentation are written to the git-ignored `output/` folder by `make docs` and `make docs-all`.

## Quick links

- Canonical proposal (ID): [`proposal/proposal-salaras.id.md`](proposal/proposal-salaras.id.md)
- Canonical proposal (EN): [`proposal/proposal-salaras.en.md`](proposal/proposal-salaras.en.md)
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
- Prior-art analysis: [`judging/prior-art-analysis.id.md`](judging/prior-art-analysis.id.md)
- Submission audit: [`judging/submission-verification.md`](judging/submission-verification.md)
- Judge QnA: [`judging/judge-qna.md`](judging/judge-qna.md)
- Security budget: [`proposal/security-budget.md`](proposal/security-budget.md)
