# Setup and workflow on Debian 13

Host setup and day-to-day workflow for this repository on Debian 13 (Trixie).
This document covers two independent workflows.

- Workflow A: RTL simulation, formal, synthesis, and the ASIC evidence flow that runs through GitHub Actions, all of which are fully supported on Debian.
- Workflow B: the DE10-Nano Quartus build, which targets Cyclone V and is documented for a native Debian install with the caveats below.

Read `AGENTS.md` for the project invariants before changing RTL.

## 1. Host prerequisites

Install the base tools with apt.

```bash
sudo apt update
sudo apt install -y git make build-essential python3 python3-venv python3-pip verilator yosys iverilog gtkwave
```

- `verilator` is used by `make lint`.
- `yosys` is used by `make synth-check` and `make area`.
- `iverilog` is the cocotb simulator for every test target.
- `build-essential` provides `gcc`/`g++`, which cocotb needs to build the simulator VPI interface; without a compiler every cocotb target fails at build time.
- `gtkwave` is only for viewing waveforms and is optional.
- `git` and `make` are required by every target.

Formal verification needs `sby` (SymbiYosys), which is not in the base Debian repositories.
Install the YosysHQ OSS CAD Suite and add its `bin` directory to `PATH`, then confirm with `sby --version`.
`make formal` fails fast with a clear message when `sby` is not on `PATH`.

Building documentation PDFs is optional and needs Node plus extra tools:

```bash
sudo apt install -y nodejs npm chromium inkscape libreoffice
```

- `nodejs` and `npm` are required by the proposal, deck, and progress builds; Debian 13 ships Node 20, which is sufficient (Node 18 or newer). `npm ci` needs network access.
- `chromium` (or `google-chrome`) renders the HTML to PDF.
- `inkscape` rasterizes the deck diagrams.
- `libreoffice` converts the deck pptx to PDF.

`make docs` builds only the proposal and needs Node plus Chromium.
`make docs-all` also builds the deck and needs inkscape and libreoffice.
Run `make doctor` to check which of these tools are missing.

## 2. Clone the repository

Clone with submodules so the vendored baselines are present.

```bash
git clone --recurse-submodules git@github.com:bokumentation/hackathon-2026-01.git
cd hackathon-2026-01
```

The three submodules are `baseline/tt07-bep-decode`, `baseline/TT_UM_SERDES`, and `baseline/tt07_cdc_fifo`.
If you cloned without submodules, or the baseline directories are empty, run:

```bash
make submodules
```

## 3. Python environment

Create the virtual environment and install the pinned packages.

```bash
make env
source venv/bin/activate
```

`make env` runs `python3 -m venv venv` and `pip install -r requirements.txt`.
The pinned packages are `cocotb==2.1.0`, `pytest==9.1.1`, `matplotlib==3.11.2`, and `vcdvcd==2.6.0`.
Activate the virtual environment in every new shell before running any test target.

## 4. Smoke check the toolchain

Confirm lint and synthesis before running the full suite.

```bash
make lint
make synth-check
```

`make lint` runs Verilator in lint-only mode.
`make synth-check` runs a Yosys `proc; opt; check; stat` pass to prove the RTL is synthesizable.

## 5. Repository workflow

The top-level `Makefile` is the single entry point.
Run `make help` to list every target.

| Target | What it runs | Prerequisites |
| --- | --- | --- |
| `make submodules` | `git submodule update --init --recursive` | git |
| `make env` | create `venv` and install `requirements.txt` | python3-venv |
| `make lint` | Verilator lint of `src/` | verilator |
| `make synth-check` | Yosys synthesizability check | yosys |
| `make area` | Yosys generic and Cyclone V area estimate into `synth/area/` | yosys |
| `make formal` | SymbiYosys over every `synth/formal/*.sby` | sby |
| `make simon` | SIMON-32/64 block and CBC-MAC tests | iverilog, cocotb |
| `make l2` | L2 authentication and freshness tests | iverilog, cocotb |
| `make auth` | integrated authentication and commit tests | iverilog, cocotb |
| `make crc` | RF CRC streaming latency comparison | iverilog, cocotb |
| `make wrapper` | Tiny Tapeout wrapper key-separation and frame tests | iverilog, cocotb |
| `make link-codec` | 8b/10b encoder/decoder tests | iverilog, cocotb |
| `make link-framing` | link comma/word-lock/timeout tests | iverilog, cocotb |
| `make link-top` | serial link loopback through the boundary | iverilog, cocotb |
| `make test` | archived RF appendix cocotb suite | iverilog, cocotb |
| `make sim` | archived RF appendix simulation evidence (baseline plus boundary) | iverilog, cocotb |
| `make figures` | regenerate proposal/appendix figures from VCDs | iverilog, python (matplotlib, vcdvcd) |
| `make docs` | build the proposal PDF into `output/` | node, chromium |
| `make docs-force` | rebuild the proposal even if unchanged | node, chromium |
| `make docs-all` | build the proposal, deck, and progress report | node, chromium, inkscape, libreoffice |
| `make progress` | build the progress report into `output/` | node, chromium |
| `make gds` | instructions for the Tiny Tapeout GDS action | none |
| `make fpga` | instructions for the DE10-Nano build | none |
| `make clean` | remove build outputs | none |

The committed link is exercised by `simon`, `l2`, `auth`, `wrapper`, `link-codec`, `link-framing`, and `link-top`.
The archived Manchester/RF problem evidence is exercised by `crc`, `test`, and `sim` and is not the committed design.

On a host without `make`, the same cocotb suites can be launched directly with the helpers under `test/`.

```bash
source venv/bin/activate
python test/run_simon_test.py
python test/run_l2_test.py
python test/run_auth_test.py
python test/run_project_test.py
```

## 6. Quartus Prime Lite on Debian 13

This section documents a native Debian 13 install as the primary route.
Debian 13 is not on the vendor supported-OS list, so treat the host as unsupported and expect minor compatibility work.
The vendor list for Quartus Prime Lite 25.1 is Red Hat Enterprise Linux 8.6, 8.7, 9.0, and 9.1, SUSE SLE, and Ubuntu 18.04, 20.04, and 22.04.
A container based on Ubuntu 22.04 or a Red Hat 9 image is the fallback when the native install misbehaves, and the competition FPGA sandbox is the last resort.

### 6.1 Install components

Run the combined installer and select the following components.

- `Quartus Prime Lite Edition (Free)`, which provides `quartus_sh`, `quartus_map`, `quartus_fit`, `quartus_sta`, and `quartus_pow`.
- `Devices -> Cyclone V device support`, which matches the DE10-Nano `5CSEBA6U23I7`.
- `Quartus Prime Programmer and Tools`, which provides `quartus_pgm`, only if you will program the board.

Do not select the `Quartus Prime` entry, which is a different, paid edition; the free Lite tools are sufficient.
Note that Cyclone V is not supported by the Pro edition, so Lite is the correct choice anyway.
Skip the other device families, the Questa and ModelSim simulators, the Help package, and the RiscFree IDE to save disk.
The `Quartus Prime Driver Installer` is the Windows USB-Blaster driver and is not used on Linux.

### 6.2 Install on Debian

Download the Linux installer tar from the Altera Download Center, which requires a free account.
Extract the archive and the device support files into the same temporary directory, then run the installer.

```bash
tar -xf Quartus-lite-*-linux.tar
sudo ./setup.sh
```

The installer may warn that the operating system is unsupported.
For a command-line-only install, prefer the unattended mode offered by `setup.sh --help` to avoid the GUI.
The default install root is `/opt/intelFPGA_lite/<version>`.

Add the tools to `PATH`, then confirm the version.

```bash
export PATH="$PATH:/opt/intelFPGA_lite/<version>/quartus/bin"
quartus_sh --version
```

For CLI use, very few runtime libraries are needed.
Quartus expects `libusb-1.0-0` for JTAG and, on some hosts, an older `libtinfo` or `libncurses`.
If a tool reports a missing shared library, install the matching package and retry.
GUI libraries such as `libxft2`, `libxext6`, `libpng16-16`, `libfreetype6`, and `libfontconfig1` are only needed for the graphical tools.

### 6.3 Container fallback

If the native install fails on Debian 13, run the same CLI inside a supported base image.
Mount the repository into the container and use the identical commands from section 7.
JTAG programming from inside a container needs USB passthrough for `/dev/bus/usb` and the udev rule from section 8.

## 7. FPGA report generation

The Quartus projects live in `fpga/de10nano/`.

```bash
cd fpga/de10nano
make        # de10nano_top (Tier A)
make link   # link_demo_top (Tier B loopback)
```

`make` calls `quartus_sh --flow compile de10nano_top`; `make link` compiles `link_demo_top`.
Reports are written under `output_files/`.

Capture the following numbers for the proposal and for `synth/area.md`.

| Report | What to record |
| --- | --- |
| Fitter Summary | ALMs, registers, M10K block memory, DSP blocks |
| Timing Analyzer | Fmax, WNS, TNS, worst setup and hold slack |
| PowerPlay Power Analyzer | total thermal power, split by clock and enable |
| SignalTap | `auth_ok`, `fresh_ok`, `done`, `host_full`, `fault`, and `word_lock` (Tier B) or `key_locked` (Tier A) |

The proposal FPGA rows are measured Quartus results:

- Tier A `de10nano_top`: 242 ALM, 654 registers, Fmax 136.37 MHz, 425.4 mW vector-less.
- Tier B loopback `link_demo_top`: 421 ALM, 1029 registers, Fmax 97.9 MHz, 426.2 mW vector-less (3.76 mW core dynamic).

Re-run the compile after any RTL change and update `synth/area.md` and the proposal.
PowerPlay is vector-less, so label it an estimate rather than a measurement.

## 8. JTAG and USB-Blaster on Debian

The DE10-Nano exposes an onboard USB-Blaster II interface.
Grant access with a udev rule scoped to the Altera vendor ID `09fb`.

Create `/etc/udev/rules.d/51-altera-usb-blaster.rules` with the following content.

```
SUBSYSTEM=="usb", ATTR{idVendor}=="09fb", MODE="0666", GROUP="plugdev"
```

Reload the rules and add your user to the `plugdev` group.

```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo usermod -aG plugdev "$USER"
```

Log out and back in for the group change, reconnect the board, then confirm detection.

```bash
jtagconfig
```

Program the volatile bitstream over JTAG.

```bash
cd fpga/de10nano
make program        # de10nano_top
make program-link   # link_demo_top
```

These run `quartus_pgm -m jtag -o "p;output_files/<project>.sof"` (`quartus_cpf`, also installed, converts `.sof` to `.rbf`).

A `.sof` loaded over JTAG is lost on power cycle.
For persistence, convert it to a `.rbf` with `quartus_cpf` and configure it through the HPS or the onboard configuration path.

## 9. Current caveats

These are known limitations of the current tree, recorded honestly.

- The Tier B sky130 link signoff (`tt_um_link`) has 2 antenna violations; the core signoff (`tt_um_auth_boundary`) is antenna-clean. The proposal reports both as-is.
- The on-board demonstration and the SignalTap capture require the DE10-Nano and are a bootcamp deliverable; no on-board result is claimed yet.
- FPGA power is a Quartus PowerPlay vector-less estimate, not an on-board measurement.
- The clock-domain crossing (Tier C) and the vendored CDC FIFO are not built; no CDC result is claimed.
- The RF appendix integrity field is an unsolved error-correcting code and stays as problem evidence (`tools/README.md`).

## 10. Troubleshooting

- `sby not found`, install the OSS CAD Suite and put `sby` on `PATH`.
- empty baseline directories, run `make submodules`.
- `quartus_sh: command not found`, source the Quartus `PATH` export from section 6.2 in the current shell.
- the installer refuses the operating system, continue in unattended mode or use the container fallback.
- a tool reports a missing shared library, install the matching Debian package and retry.
- `quartus_pgm` does not see the board, confirm the udev rule, the `plugdev` group, and that `jtagconfig` lists the device.

## 11. Pointers

- `fpga/de10nano/README.md` for the board pinout, the Tier A key/frame procedure, and the Tier B `link_demo_top` loopback demo.
- `docs/design/quartus-plan.md` for the Fitter, Timing, and PowerPlay capture plan.
- `docs/design/quartus-report.md` for the measured Quartus results (Tier A and Tier B loopback).
- `docs/deck/` for the presentation/video-deck sources and `docs/progress/` for the progress report build.
- `README.md` for the project overview and the results table.
- `AGENTS.md` for the RTL conventions and the verification gates.
