# Quartus Prime FPGA synthesis report

Measured Quartus Prime results for the authenticated ingress boundary on the Terasic DE10-Nano.
The board project lives in `fpga/de10nano/` and targets the Cyclone V SoC `5CSEBA6U23I7`.
This report replaces the earlier Yosys proxy estimate with post-fit Fitter, Timing Analyzer, and PowerPlay numbers.

## Tool and device

| Item | Value |
| --- | --- |
| Tool | Quartus Prime Lite Edition 25.1std.0, build 1129 |
| Device | Cyclone V `5CSEBA6U23I7` |
| Board | Terasic DE10-Nano |
| Project | `fpga/de10nano/de10nano_top` |
| Top entity | `de10nano_top` |
| Result | Full compilation successful, 0 errors, 14 warnings |

## Method

The project is defined by `de10nano_top.qsf` with the timing constraints in `de10nano_top.sdc`.

```bash
cd fpga/de10nano
quartus_sh --flow compile de10nano_top
quartus_pow de10nano_top
```

`quartus_sh --flow compile` runs Analysis and Synthesis, the Fitter, the Assembler, and the Timing Analyzer.
`quartus_pow` then runs the PowerPlay Power Analyzer in vector-less mode.

## Resource usage (post-fit Fitter)

| Resource | Usage | Device capacity | Utilization |
| --- | --- | --- | --- |
| Logic utilization (ALMs) | 242 | 41,910 | < 1% |
| Registers (FF) | 654 | 166,036 | < 1% |
| I/O pins | 21 | 314 | 7% |
| Embedded memory (M10K) | 0 | 5,570 Kbits | 0% |
| DSP blocks | 0 | 112 | 0% |
| PLLs | 0 | 6 | 0% |

The design maps cleanly with no block memory, no DSP, and no PLL.
For reference, the earlier Yosys proxy estimate was about 360 LUT equivalents and 500 flip-flops for `boundary_top`; the Fitter number covers the full board wrapper including the L1 serial loader.

## Timing (Slow 1100mV 100C, final models)

| Metric | Value |
| --- | --- |
| Fmax | 136.37 MHz |
| Worst-case setup slack (WNS) | +12.667 ns |
| Worst-case hold slack | +0.270 ns |
| Worst-case minimum pulse width slack | +9.330 ns |
| Total Negative Slack (TNS) | 0.000 ns |

The clock constraint is 50 MHz (`create_clock -period 20.000`).
The design closes timing with a large margin and the reported Fmax is well above the 50 MHz target.

## Power (PowerPlay, vector-less)

| Component | Value |
| --- | --- |
| Total thermal power | 425.40 mW |
| Core dynamic thermal power | 2.42 mW |
| Core static thermal power | 412.23 mW |
| I/O thermal power | 10.75 mW |
| Power estimation confidence | Low (vector-less) |

This is a vector-less estimate, so it uses default toggle rates and the reported confidence is low.
The total is dominated by device static power, not by the design switching activity.
The core dynamic power for the authenticated core is 2.42 mW, which is the meaningful figure for a duty-cycled link.
Quartus also reports the critical warning that HPS power is analyzed for a device with an HPS without HPS power, because the project targets the SoC part without instantiating the HPS.

## Board pin map

The pin assignments were corrected against the Terasic System Builder golden hardware reference design for the DE10-Nano.
The DE10-Nano has 8 user LEDs (LED0-LED7) and 4 slide switches (SW0-SW3), so the wrapper ports were reduced to match.

| Signal | Device pin | Board resource |
| --- | --- | --- |
| `CLOCK_50` | PIN_V11 | 50 MHz oscillator (FPGA_CLK1_50) |
| `KEY[0]` | PIN_AH17 | Reset (active low) |
| `KEY[1]` | PIN_AH16 | User key |
| `SW[0]` | PIN_Y24 | `key_mode` |
| `SW[1]` | PIN_W24 | spare |
| `SW[2]` | PIN_W21 | spare |
| `SW[3]` | PIN_W20 | spare |
| `LEDR[0]` | PIN_W15 | `done` |
| `LEDR[1]` | PIN_AA24 | `host_full` |
| `LEDR[2]` | PIN_V16 | `fault` |
| `LEDR[3]` | PIN_V15 | `auth_ok` |
| `LEDR[4]` | PIN_AF26 | `fresh_ok` |
| `LEDR[5]` | PIN_AE26 | `key_locked` |
| `LEDR[6]` | PIN_Y16 | tied low |
| `LEDR[7]` | PIN_AA23 | tied low |
| `gpio_frame_bit` | PIN_V12 | GPIO_0[0] |
| `gpio_load_en` | PIN_E8 | GPIO_0[1] |
| `gpio_fault_ack` | PIN_W12 | GPIO_0[2] |
| `gpio_host_full` | PIN_D11 | GPIO_0[3] |
| `gpio_fault` | PIN_D8 | GPIO_0[4] |
| `gpio_done` | PIN_AH13 | GPIO_0[5] |

## Fixes applied before this result

The board project had never been compiled before this run.
The following fixes were required.

- `de10nano_top.qsf` now lists `../../src/l1_serial_loader.v`, which the wrapper instantiates.
- `de10nano_top.qpf` was added, because `quartus_sh --flow compile` requires a project file.
- `de10nano_top.v` ports were reduced to `SW[3:0]` and `LEDR[7:0]` to match the board.
- All invalid pin assignments were replaced with the official Terasic assignments above.

## Warnings

The full compile reports 14 warnings and no errors.
The notable warnings are LogicLock requiring a subscription license, one global input using non-dedicated clock routing, and the HPS power critical warning described above.
None of these affect the resource, timing, or power numbers.

## Reproduction

```bash
cd fpga/de10nano
quartus_sh --flow compile de10nano_top
quartus_pow de10nano_top
```

Reports are written to `fpga/de10nano/output_files/` and are not committed.

## SignalTap (on-board, prepared)

SignalTap is the on-board real-time capture step and is not included in the numbers above.
It requires the physical DE10-Nano and a USB-Blaster connection, and the `.stp` file must be created in the Quartus GUI (hand-authored `.stp` files are not reliable).

The setup is prepared in the repository:

- The wrapper declares the tapped wires (`host_full`, `fault`, `auth_ok`, `fresh_ok`, `done`, `key_locked`) with `(* preserve, noprune *)` so they appear in Node Finder.
- `fpga/de10nano/de10nano_top.qsf` contains the three SignalTap assignments as a commented block, with the exact recompile recipe.
- `fpga/de10nano/signaltap_acquire.tcl` runs one capture over JTAG with `quartus_stp -t`.

Enabling SignalTap adds M10K block memory to the fit and slightly increases power and logic.
Record the SignalTap-enabled Fitter numbers as a separate line.

The full procedure and the test cases are in `docs/design/signaltap-plan.md`.

## Tier B link loopback wrapper (link_demo_top)

The on-board demonstration uses a separate wrapper, `fpga/de10nano/link_demo_top.v`, that instantiates `link_tx` and `link_top` (`link_rx` + `boundary_top`) with an internal serial loopback. A switch selects the clean, corrupt, or replay case. The demo key is loaded at reset, so no external device is needed.

```bash
cd fpga/de10nano
quartus_sh --flow compile link_demo_top
quartus_pow link_demo_top
```

| Metric | Value |
| --- | --- |
| Top entity | `link_demo_top` |
| Logic utilization (ALMs) | 421 |
| Registers (FF) | 1029 |
| Block memory bits / M10K | 0 / 0 |
| DSP blocks | 0 |
| PLLs | 0 |
| Fmax (Slow 1100mV 100C) | 97.9 MHz |
| Worst-case setup slack (WNS) | +9.785 ns |
| Total thermal power | 426.19 mW |
| Core dynamic thermal power | 3.76 mW |
| Power estimation confidence | Low (vector-less) |

The wrapper closes timing at 50 MHz with a large margin. Power remains a vector-less estimate dominated by device static power.

## See also

- `docs/design/quartus-plan.md` for the original capture plan.
- `docs/design/signaltap-plan.md` for the on-board capture procedure.
- `synth/area.md` for the ASIC and Yosys area evidence.
- `docs/proposal/proposal.id.md` and `docs/proposal/proposal.en.md` for the proposal figures.
