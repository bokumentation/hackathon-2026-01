# A Reusable, Fail-Closed Authenticated Ingress Boundary for Serial/RF Links

[![link](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/link.yaml/badge.svg)](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/link.yaml)
[![lint](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/lint.yaml/badge.svg)](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/lint.yaml)
[![synth](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/synth.yaml/badge.svg)](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/synth.yaml)
[![test](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/test.yaml/badge.svg)](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/test.yaml)
[![formal](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/formal.yaml/badge.svg)](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/formal.yaml)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

## Overview

This repository is the committed design for the PERURI Chip Hackathon 2026,
Area 04 Secure Communication.

The problem is measured on a real baseline: the Tiny Tapeout 07 Manchester
decoder `tt07-bep-decode` receives a 24-bit integrity field and never checks it,
so a corrupt or fault-injected frame still appears valid to the host (CWE-354).
The field itself is an undocumented error-correcting code and is unsolved.

The committed design, the authenticated ingress boundary, closes that gap:

- **L2 auth**: SIMON-32/64 in fixed-length CBC-MAC mode over `counter + payload`,
  plus a counter freshness check (CWE-354, CWE-345, CWE-294).
- **L3 commit**: atomic fail-closed commit of data and control, with a sticky
  fault until acknowledged (CWE-1264).

```
frame (counter + payload + tag)
        |
   L2 auth  (SIMON-32/64 CBC-MAC + counter freshness)
        |
   L3 commit  (fail-closed, sticky fault)
        |
   host  (host_full, host_data, fault)
```

The Manchester/RF predecessor is archived under `appendix/rf/` as the CWE-354
problem evidence and is not the committed design.

## How to use this repository

### Prerequisites

- `git`
- Python 3.11 or newer
- Verilator (RTL lint)
- Yosys (synthesizability check)
- SymbiYosys or the OSS CAD Suite (formal properties)
- Icarus Verilog or Verilator with cocotb (simulation)
- Quartus Prime Lite (optional, for the DE10-Nano FPGA build)

### Clone

```bash
git clone --recurse-submodules git@github.com:bokumentation/hackathon-2026-01.git
cd hackathon-2026-01
```

If you cloned without submodules, or the baseline directories are empty:

```bash
git submodule update --init --recursive
```

### Environment

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

Or run `make env`, which does the same.

### Common tasks

| Command | What it does |
| --- | --- |
| `make help` | List every target |
| `make submodules` | Initialize and update the baseline submodules |
| `make env` | Create the Python virtual environment |
| `make lint` | Lint the committed RTL with Verilator |
| `make synth-check` | Check synthesizability with Yosys |
| `make area` | Estimate cell, FF, and Cyclone V resource usage |
| `make formal` | Run the SymbiYosys formal properties |
| `make simon` | SIMON-32/64 block and CBC-MAC tests |
| `make l2` | L2 authentication and freshness tests |
| `make auth` | Integrated authentication and commit tests |
| `make crc` | RF CRC streaming latency (comparison) |
| `make test` | RF appendix unit cocotb suite |
| `make sim` | RF appendix simulation evidence suites |
| `make gds` | Instructions for ASIC hardening |
| `make fpga` | Instructions for the DE10-Nano build |
| `make clean` | Remove build outputs |

A typical first run:

```bash
make lint
make synth-check
make simon
make l2
make auth
```

### ASIC hardening

ASIC hardening runs through the official Tiny Tapeout GDS GitHub Action in
[`.github/workflows/gds.yaml`](.github/workflows/gds.yaml).
Trigger it with a workflow dispatch or a `v*` tag.
The configuration lives in [`src/config.tcl`](src/config.tcl),
[`src/user_config.tcl`](src/user_config.tcl), and [`info.yaml`](info.yaml).

### FPGA build

The DE10-Nano flow is documented in [`fpga/de10nano/README.md`](fpga/de10nano/README.md).

## Repository layout

```
.
├── .github/                 CI workflows, PR and issue templates
├── appendix/rf/             Archived Manchester/RF design (problem evidence)
├── baseline/                Pinned Tiny Tapeout 07 submodules
├── docs/                    Proposal and supporting documents (untracked)
├── fpga/                    DE10-Nano project and ESP32 replay path
├── gds/                     Generated ASIC output (not committed)
├── openlane/                OpenLane entry configuration
├── sim/                     RF simulation evidence harness and results
├── src/                     Committed link RTL
├── synth/                   Yosys, SymbiYosys, and the area report
├── test/                    cocotb suites
├── tools/                   Integrity-field analysis scripts
├── info.yaml                Tiny Tapeout project metadata
├── Makefile                 Build entry point
└── requirements.txt         Python verification dependencies
```

## Results

- L2 and L3 simulation: 128 of 128 single-bit flips rejected, forgery, wrong
  key, replay, and stale counter rejected, 20 clean frames accepted.
- End-to-end latency: 108 cycles (107 for MAC and freshness, 1 for commit).
- Integrity comparison: CRC 73 cycles (keyless), MAC 107 cycles, MAC plus
  counter 108 cycles.
- Formal: five properties pass, proving the fail-closed structure.
- RF appendix: real sky130 hardening on a 1x2 tile, die 0.0363 mm^2, WNS 0.00,
  typical power 1.21 mW.

Full detail is in [`sim/RESULTS.md`](sim/RESULTS.md) and
[`synth/area.md`](synth/area.md).

## Baselines

| Submodule | Upstream | Role |
| --- | --- | --- |
| `baseline/tt07-bep-decode` | [DusterTheFirst/tt07-bep-decode](https://github.com/DusterTheFirst/tt07-bep-decode) | Manchester/RF problem evidence |
| `baseline/TT_UM_SERDES` | [Santeep/TT_UM_SERDES](https://github.com/Santeep/TT_UM_SERDES) | Serial link reference (next stage) |
| `baseline/tt07_cdc_fifo` | [Pa1mantri/tt07_cdc_fifo](https://github.com/Pa1mantri/tt07_cdc_fifo) | Clock domain crossing (next stage) |

All three are Apache-2.0. See [`NOTICE`](NOTICE) for attribution.

## Targets

- **ASIC:** Tiny Tapeout sky130 130nm via OpenLane.
- **FPGA:** Terasic DE10-Nano, Intel Cyclone V SoC.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).
Run `make lint` and `make synth-check` before opening a pull request.

## License

Apache-2.0. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
