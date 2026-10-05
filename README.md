# A Hardware-Enforced Secure Ingress Barrier for Manchester/RF Serial Links

[![lint](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/lint.yaml/badge.svg)](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/lint.yaml)
[![synth](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/synth.yaml/badge.svg)](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/synth.yaml)
[![test](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/test.yaml/badge.svg)](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/test.yaml)
[![formal](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/formal.yaml/badge.svg)](https://github.com/bokumentation/hackathon-2026-01/actions/workflows/formal.yaml)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

## Overview

This design inserts a fail-closed hardware boundary between a Manchester/RF decoder and the host register file.
The boundary verifies the frame integrity field in hardware, before any data crosses the trust boundary, without changing the frame format and without a large buffer.

The design extends a Tiny Tapeout 07 baseline Manchester decoder (`tt07-bep-decode`) that receives a 24-bit integrity field (`tail_1..3`) but never checks it.
As a result, corrupt or fault-injected payloads can appear valid to the host.
The boundary closes that gap.

```
digital_in --> sync2 --> manchester_rx --> frame_capture
                                               |
                    +--------------------------+--------------------------+
                    |                          |                          |
              l1_framing_validator       l2_integrity_verify       (payload bits)
                    |                          |
                    +------------+-------------+
                                 |
                        l3_commit_gatekeeper
                                 |
                    host_data / host_full / fault
```

- **L1, framing and FSM validation:** half-period timing window, timeout counter, and recovery from unexpected transitions.
- **L2, integrity verification:** streaming CRC-24 LFSR compared against the field carried by the frame.
- **L3, atomic commit gatekeeper:** commits data and control together only for a valid frame, otherwise holds `full` low and raises a sticky `fault`.

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

All tasks run through the top-level Makefile.

| Command | What it does |
| --- | --- |
| `make help` | List every target |
| `make submodules` | Initialize and update the baseline submodules |
| `make env` | Create the Python virtual environment |
| `make lint` | Lint the RTL with Verilator |
| `make synth-check` | Check synthesizability with Yosys |
| `make formal` | Run the SymbiYosys formal properties |
| `make test` | Run the cocotb testbench |
| `make gds` | Instructions for ASIC hardening |
| `make fpga` | Instructions for the DE10-Nano build |
| `make clean` | Remove build outputs |

A typical first run:

```bash
make lint
make synth-check
make test
```

### ASIC hardening

ASIC hardening runs through the official Tiny Tapeout GDS GitHub Action defined in [`.github/workflows/gds.yaml`](.github/workflows/gds.yaml).
Trigger it with a manual `workflow_dispatch` or by pushing a `v*` tag.
The configuration lives in [`src/config.tcl`](src/config.tcl), [`src/user_config.tcl`](src/user_config.tcl), and [`info.yaml`](info.yaml).
The generated GDS is uploaded as a workflow artifact and is not committed.

### FPGA build

The DE10-Nano flow is documented in [`fpga/de10nano/README.md`](fpga/de10nano/README.md).
The wired replay path is documented in [`fpga/replay/README.md`](fpga/replay/README.md).

## Repository layout

```
.
├── .github/                 CI workflows, PR and issue templates
├── baseline/                Pinned git submodules (Tiny Tapeout 07 references)
├── fpga/                    DE10-Nano prototype and ESP32 replay generator
│   ├── de10nano/            Quartus project, pin assignments, SDC
│   └── replay/              Wired replay path (proposal path S2)
├── gds/                     Generated ASIC output (not committed)
├── openlane/                OpenLane entry configuration
├── src/                     RTL design
├── synth/                   Yosys and SymbiYosys configuration
├── test/                    cocotb testbench and vectors
├── info.yaml                Tiny Tapeout project metadata
├── Makefile                 Build entry point
├── requirements.txt         Python verification dependencies
├── CHANGELOG.md             Release history
├── CONTRIBUTING.md          Contribution guide
├── NOTICE                   Third-party attribution
└── SECURITY.md              Security policy
```

## Baselines

The design builds on three Tiny Tapeout 07 references, pinned as submodules:

| Submodule | Upstream | Role |
| --- | --- | --- |
| `baseline/tt07-bep-decode` | [DusterTheFirst/tt07-bep-decode](https://github.com/DusterTheFirst/tt07-bep-decode) | Manchester/RF ingress baseline |
| `baseline/TT_UM_SERDES` | [Santeep/TT_UM_SERDES](https://github.com/Santeep/TT_UM_SERDES) | Serial/parallel transport reference |
| `baseline/tt07_cdc_fifo` | [Pa1mantri/tt07_cdc_fifo](https://github.com/Pa1mantri/tt07_cdc_fifo) | Clock domain crossing reference |

All three are Apache-2.0. See [`NOTICE`](NOTICE) for attribution.

## Targets

- **ASIC:** Tiny Tapeout 07 flow, SkyWater sky130, target 1x1 tile with a 1x2 fallback.
- **FPGA:** Terasic DE10-Nano, Intel Cyclone V SoC.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).
Run `make lint` and `make synth-check` before opening a pull request.

## License

Apache-2.0. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
