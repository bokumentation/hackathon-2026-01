# Contributing to SALARAS-RX

Thanks for your interest. This repository contains the hardware design and
research artifacts for SALARAS-RX.

## Ground rules

- Keep every change focused and reviewable. One logical change per pull request.
- Run `make lint` and `make synth-check` before opening a pull request.
- Do not edit generated artifacts by hand (see `AGENTS.md` and the repository
  conventions). Markdown sources are canonical; PDFs and HTML are generated.
- Do not commit secrets, credentials, or large binary build outputs.

## Development setup

```bash
git clone --recurse-submodules git@github.com:bokumentation/hackathon-2026-01.git
cd hackathon-2026-01
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
make lint
```

If you cloned without submodules, run:

```bash
git submodule update --init --recursive
```

## Branches and commits

- Branch from `main`. Use a descriptive prefix:
  `feat/`, `fix/`, `docs/`, `refactor/`, `test/`, `chore/`.
- Write commit subjects in the imperative mood, for example
  `add L2 streaming CRC verify`.
- Keep the subject under 72 characters. Use the body for rationale and context.
- Reference the affected module or document when useful.

## Pull requests

- Fill in the pull request template.
- State what changed, why, and how it was verified.
- Include the commands you ran and their results.
- Link the relevant issue or milestone.

## Verification expectations

| Change | Required checks |
| --- | --- |
| RTL in `src/` | `make lint`, `make synth-check` |
| Verification in `test/` | `make test` |
| Simulation evidence in `sim/` | `make sim` |
| Resource estimate | `make area` |
| Formal properties in `synth/formal/` | `make formal` |
| FPGA in `fpga/` | Review against the DE10-Nano flow |

## License

By contributing you agree that your contributions are licensed under the
Apache License 2.0, as described in `LICENSE`.
