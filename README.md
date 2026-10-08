<h1 align="center">TRI-ARGA - Gerbang Keamanan Data Portabel Tiga Lapis (Fail-Closed) untuk Tautan Serial Ringan</h1>

<p align="center">PERURI Chip Design Hackathon 2026 - Topic Area 04 - Secure Communication</p>

<p align="center">Tim Tri Arga · Universitas Telkom</p>

<p align="center">
  <a href="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/link.yaml"><img src="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/link.yaml/badge.svg" alt="link"></a>
  <a href="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/lint.yaml"><img src="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/lint.yaml/badge.svg" alt="lint"></a>
  <a href="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/synth.yaml"><img src="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/synth.yaml/badge.svg" alt="synth"></a>
  <a href="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/test.yaml"><img src="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/test.yaml/badge.svg" alt="test"></a>
  <a href="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/formal.yaml"><img src="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/formal.yaml/badge.svg" alt="formal"></a>
  <a href="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/sim.yaml"><img src="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/sim.yaml/badge.svg" alt="sim"></a>
  <a href="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/docs.yaml"><img src="https://github.com/bokumentation/hackathon-2026-01/actions/workflows/docs.yaml/badge.svg" alt="docs"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-blue.svg" alt="License: Apache-2.0"></a>
</p>

<p align="center">
  <a href="https://bokumentation.github.io/hackathon-2026-01/"><img src="https://img.shields.io/badge/GDS-3D%20viewer-blue.svg" alt="GDS viewer"></a>
</p>

<p align="center"><strong>Tiny Tapeout note.</strong> This is a PERURI Chip Hackathon 2026 submission (Topic Area 04), not a Tiny Tapeout shuttle submission, so it does not follow the Tiny Tapeout submission guidance. It uses the Tiny Tapeout 07 SerDes <code>TT_UM_SERDES</code> as the link baseline (rewritten), and includes <code>tt07-bep-decode</code> only as CWE-354 problem evidence.</p>

---

## What this is

A small, reusable hardware IP block that closes the gap between receiving a serial/RF frame and trusting it.

The problem is measured on a real reference design: the Tiny Tapeout 07 Manchester decoder `tt07-bep-decode` receives a 24-bit integrity field and never checks it, so a corrupt or fault-injected frame still appears valid to the host. The integrity field itself is an undocumented error-correcting code, unsolved.

TRI-ARGA fixes this with three composable layers (L1 frame loader, L2 authentication, L3 fail-closed commit). Each frame is counter 32 + payload 64 + tag 32 = 128 bit, authenticated with a fixed-length SIMON-32/64 CBC-MAC; the 64-bit key is loaded from the host over a separate path and never crosses the link.

![Authenticated ingress boundary architecture](assets/block-diagram.svg)

---

## Baseline

This project builds on the Tiny Tapeout 07 SerDes reference, not on the RF decoder.

| Design | Upstream | Role |
| --- | --- | --- |
| `TT_UM_SERDES` (TT07) | [Santeep/TT_UM_SERDES](https://github.com/Santeep/TT_UM_SERDES) | Link baseline for Tier B. We keep its 8b/10b tables as the seed and rewrite the framing, alignment, and serial datapath with running disparity, K-characters, and word lock. |
| `tt07-bep-decode` (TT07) | [DusterTheFirst/tt07-bep-decode](https://github.com/DusterTheFirst/tt07-bep-decode) | Not a baseline. Measured CWE-354 problem evidence: it forwards a corrupt payload and a corrupt 24-bit integrity field to the host with `full=1`. |
| `tt07_cdc_fifo` (TT07) | [Pa1mantri/tt07_cdc_fifo](https://github.com/Pa1mantri/tt07_cdc_fifo) | Future clock-domain-crossing reference for Tier C; not yet integrated. |

All three are Apache-2.0. See [`NOTICE`](NOTICE) for attribution.

---

## Results

| Metric | Tier A core | Tier B link | Reproduce |
| --- | --- | --- | --- |
| Single-bit flip rejection | 128/128 | 128/128 | `make l2`, `make link-top` |
| Line error rejected | - | yes | `make link-top` |
| Forgery rejected | yes | yes | `make l2`, `make auth`, `make link-top` |
| Replay / stale counter rejected | yes | yes | `make auth`, `make link-top` |
| False reject (clean commit) | 0% (20/20 clean frames) | clean commit accepted | `make l2`, `make link-top` |
| SIMON-32/64 block latency | 33 cycles | 33 cycles (same core) | `make simon` |
| CBC-MAC + freshness latency | 107 cycles | 107 cycles (same core) | `make l2` |
| End-to-end latency | 108 cycles @ 50 MHz = 2.16 µs | 288 cycles @ 50 MHz = 5.76 µs | `make auth`, `make link-top` |
| Payload throughput | ~29 Mbit/s | ~11 Mbit/s | `make auth`, `make link-top` |
| Commit latency | 1 cycle | 1 cycle (same core) | `make auth` |
| ASIC tile / die area | 2×2, 0.0756 mm² | 2×2, 0.0756 mm² | `gds.yaml` |
| ASIC cells | 2511 | 3220 | `gds.yaml` |
| ASIC power | 2.10 mW typical | 3.61 mW typical | `gds.yaml` |
| DRC / LVS / antenna | 0 / 0 / 0 | 0 / 0 / 2 | `gds.yaml` |
| Setup WNS / TNS | 0.00 / 0.00 ns | 0.00 / 0.00 ns | `gds.yaml` |
| Worst setup / hold slack | +10.87 / +0.12 ns | +9.28 / +0.11 ns | `gds.yaml` |
| FPGA resources | 242 ALM, 654 FF, 0 M10K, 0 DSP, 0 PLL | 421 ALM, 1029 FF, 0 M10K, 0 DSP, 0 PLL | `fpga/de10nano` |
| FPGA Fmax | 136.37 MHz (WNS +12.667 ns) | 97.9 MHz (WNS +9.785 ns) | `fpga/de10nano` |
| FPGA power (vector-less) | 425.40 mW total, 2.42 mW core dynamic | 426.19 mW total, 3.76 mW core dynamic | `quartus_pow` |
| Formal verification (SymbiYosys) | 5 jobs pass | 1 job passes | `make formal` |

Tier B is a single-clock loopback (`link_tx` -> link -> `link_rx` -> Tier A core), so the SIMON, CBC-MAC, and commit latencies are the shared core values; the end-to-end latency includes 8b/10b framing. Formal also has 3 RF appendix jobs (`l1_framing`, `l2_integrity`, `l3_commit`), not attributed to a tier. The ASIC core numbers are the signoff at commit `00fc423` (run `37504588955`); the Tier B link signoff is commit `9bbb2e0` (run `37511052813`). Full evidence: [`sim/RESULTS.md`](sim/RESULTS.md) · [`synth/area.md`](synth/area.md) · [`docs/evidence.md`](docs/evidence.md) · [`docs/design/quartus-report.md`](docs/design/quartus-report.md).

---

## Limitation

It is a research prototype, not a certified secure element. Known limits: no payload confidentiality, no side-channel or glitch resistance, and the RF integrity field remains an unsolved error-correcting code; all results apply only to the artifacts described here.

Cryptography notes:

- The 32-bit tag gives about a 2^-32 per-attempt forgery probability.
- CBC-MAC is secure only for fixed-length messages; the 128-bit frame is fixed at three 32-bit blocks.
- With 32-bit blocks, rotate the key well below the birthday bound (recommended every 2^12 frames).
- The freshness counter resets to 0 on reset, so load a fresh session key each boot.
- The cipher is wrapped in a modular block interface and can be swapped for SIMON-64/128 or Ascon without changing L2 or L3.

See [`docs/proposal/`](docs/proposal/) for the full limits (Lampiran G / Appendix G) and cryptography notes (Lampiran J / Appendix J).

---

## Scope

| Tier | Status | Description |
| --- | --- | --- |
| **Tier A** | Committed | Authenticated, replay-resistant, fail-closed boundary. Single clock. Simulation evidence, formal proofs, sky130 2×2 signoff. |
| **Tier B** | Built | 8b/10b serial link with running disparity, K-character comma framing, word lock, and a single-clock loopback through the Tier A core. Simulation only. |
| **Tier C** | Future | Clock-domain crossing using `tt07_cdc_fifo`. |
| **Appendix RF** | Archived | Manchester/RF predecessor kept as problem evidence in `appendix/rf/`. |

---

## Quick start Debian 13

### Prerequisites

- Python 3.11+
- Icarus Verilog (`iverilog`)
- Verilator (RTL lint)
- Yosys (synthesis check)
- SymbiYosys / OSS CAD Suite (formal, optional)
- Node.js and npm, plus Chromium or Google Chrome (documentation build, optional)
- Inkscape and LibreOffice (`make docs-all`, optional)
- Intel Quartus Prime Lite (DE10-Nano FPGA, optional)

See [`docs/setup/debian-13.md`](docs/setup/debian-13.md) for the full Debian 13 setup, and run `make doctor` to list what is installed.

### 1. Clone

```bash
git clone --recurse-submodules git@github.com:bokumentation/hackathon-2026-01.git
cd hackathon-2026-01
```

If you cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

### 2. Set up the environment

```bash
make env
```

`make env` creates `venv/` and installs `requirements.txt`. The cocotb targets add `venv/bin` to `PATH` automatically, so `source venv/bin/activate` is only needed if you want to run the Python tools by hand.

### 3. Run the verification stack

```bash
make doctor        # check for the required host tools
make lint          # RTL lint with Verilator
make synth-check   # Synthesizability check with Yosys
make simon         # SIMON-32/64 cipher tests (2 tests, 49 vectors)
make l2            # L2 auth + freshness tests (4 tests, 128 bit-flip checks)
make auth          # Integrated auth + commit tests (6 tests, 108-cycle latency)
make wrapper       # Tiny Tapeout wrapper tests (6 tests)
make link-codec    # 8b/10b encoder/decoder tests (6 tests)
make link-framing  # link comma/word-lock/timeout tests (2 tests)
make link-top      # serial link loopback through the boundary (5 tests)
make figures       # regenerate the proposal and appendix figures from VCDs
make docs          # build the proposal PDF into output/
```

Formal verification is optional; run `make formal` (jobs in `synth/formal/`).

---

## ASIC hardening

Hardening runs through the official Tiny Tapeout GDS GitHub Action
[`.github/workflows/gds.yaml`](.github/workflows/gds.yaml).
Trigger it with a workflow dispatch or push a `v*` tag.

Configuration: [`src/config.tcl`](src/config.tcl), [`src/user_config.tcl`](src/user_config.tcl), [`info.yaml`](info.yaml).

Core signoff (run 37504588955, commit 00fc423): 2×2 tile, 2511 cells, 0 DRC, 0 LVS, 0 antenna, WNS 0.00, 2.10 mW typical. Tier B link signoff (run 37511052813, commit 9bbb2e0): 2×2 tile, 3220 cells, 0 DRC, 0 LVS, 2 antenna, WNS 0.00, 3.61 mW typical.

## FPGA build

DE10-Nano flow: [`fpga/de10nano/README.md`](fpga/de10nano/README.md).

Tier A (`de10nano_top`): `SW[0]` selects key mode (high, shift the 64-bit key MSB-first, `LEDR[5]` lights when locked) or frame mode (low, shift the 128-bit frame counter + payload + tag).

Tier B loopback demo (`link_demo_top`): `make -C fpga/de10nano link`. `SW[1:0]` selects clean (`00`), corrupt (`01`), or replay (`10`); `KEY[1]` sends one frame; `SW[2]` is `fault_ack`. The FPGA generates the 8b/10b stream internally, so no external device is needed.

## Proposal

- Indonesian: [`docs/proposal/proposal.id.md`](docs/proposal/proposal.id.md)
- English: [`docs/proposal/proposal.en.md`](docs/proposal/proposal.en.md)

Build the proposal HTML and PDF from the repository root:

```bash
make docs
```

Output: `output/pdf/PROPOSAL-TRIARGA-<timestamp>.pdf`, with the intermediate HTML in `output/html/`. The `output/` folder is git-ignored. The timestamp comes from the source mtime, so an unchanged proposal keeps its existing file and an edit stamps a new one.

Build the proposal and the presentation deck:

```bash
make docs-all
```

This adds `output/pptx/DECK-TRIARGA-<timestamp>.pptx` and `output/pdf/DECK-TRIARGA-<timestamp>.pdf`.

---

## Documentation

- Documentation entry point: [`docs/index.md`](docs/index.md)
- Evidence index (claims to artifacts to commands): [`docs/evidence.md`](docs/evidence.md)
- Proposal (ID and EN): [`docs/proposal/`](docs/proposal/)
- Presentation deck: [`docs/deck/`](docs/deck/)
- Progress report: [`docs/progress/progress-report.md`](docs/progress/progress-report.md)
- Setup and workflow on Debian 13: [`docs/setup/debian-13.md`](docs/setup/debian-13.md)
- Submission checklist: [`docs/submission/checklist.md`](docs/submission/checklist.md)
- On-board demo and bring-up: [`docs/demo.md`](docs/demo.md)
- Quartus FPGA report: [`docs/design/quartus-report.md`](docs/design/quartus-report.md)

## Repository layout

```
.
├── src/                  Committed RTL (Tier A core plus the Tier B link: link_enc_8b10b, link_dec_10b8b, l1_link_framing, link_tx, link_rx, link_top, project_link)
├── test/                 cocotb suites (plus run_*.py runners)
├── synth/
│   ├── formal/           SymbiYosys properties (.sby + .sv)
│   └── area.md           Yosys estimates and sky130 signoff numbers
├── sim/                  Simulation evidence (boundary + RF appendix), RESULTS.md, and the figures script
├── fpga/de10nano/        DE10-Nano Quartus project (.qpf/.qsf) and SignalTap script
├── appendix/rf/          Archived Manchester/RF design (problem evidence)
├── baseline/             Pinned Tiny Tapeout 07 submodules
├── docs/
│   ├── index.md          Documentation entry point
│   ├── evidence.md       Claim to artifact to reproduce-command index
│   ├── glossary.md       Terms, abbreviations, and CWE list
│   ├── demo.md           On-board demo plan (loopback, control map, cases)
│   ├── proposal/        Competition proposal (ID + EN) and PDF build
│   ├── progress/        Progress report source and PDF build
│   ├── design/           Architecture, threat model, trade study, FMEA, Quartus plan/report, SignalTap
│   ├── setup/            Host setup and repository workflow (Debian 13)
│   ├── judging/          Submission audit, judge QnA, feasibility, prior-art analysis
│   ├── competition/      PERURI Chip Hackathon handbook and rules
│   ├── references/       Third-party papers (Markdown; original PDFs not tracked)
│   ├── datasheet/        Board and device datasheet notes
│   ├── submission/       Submission checklist and deliverables
│   └── deck/             Presentation deck sources (builds into output/)
├── assets/               SVG figures referenced in README and proposal
├── output/               Generated PDFs, HTML, and deck (not committed)
├── gds/                  Generated ASIC output (not committed; see gds.yaml)
├── openlane/             OpenLane entry configuration
├── tools/                Integrity-field analysis scripts
├── .github/workflows/    CI: link, lint, synth, test, formal, sim, gds, and a docs heading check
├── info.yaml             Tiny Tapeout project metadata
├── Makefile              Build entry point (`make help` to list all targets)
└── requirements.txt      Python verification dependencies
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).
Run `make lint` and `make synth-check` before opening a pull request.

## License

Apache-2.0. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
