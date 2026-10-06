# Quartus plan for real FPGA numbers

Goal: replace the Yosys proxy numbers with real Quartus fitter and timing
reports for the authenticated boundary on the DE10-Nano (Cyclone V SoC,
5CSEBA6U23I7).

The measured results are recorded in [`../quartus-report.md`](../quartus-report.md).

## Board wrapper

The board project lives in `fpga/de10nano/`:

- `salaras_auth_de10nano.v` instantiates `l1_serial_loader` and `salaras_auth_top`;
  the 64-bit key and the 128-bit frame (counter + payload + tag) are shifted over
  GPIO, with `SW[0]` selecting key mode or frame mode.
- `salaras_auth_de10nano.sdc` constrains `CLOCK_50` at 20 ns and marks the reset
  and GPIO inputs as false paths.
- `salaras_auth_de10nano.qsf` lists the sources and pin assignments, using the
  official Terasic DE10-Nano pin map (8 LEDs, 4 switches).
- `salaras_auth_de10nano.qpf` is the Quartus project file.
- `Makefile` runs `quartus_sh --flow compile` and `quartus_pgm`.

The archived RF board project is at `appendix/rf/fpga/de10nano/`.

## Pin and timing constraints

- `create_clock -period 20.000 [get_ports {CLOCK_50}]`.
- `set_false_path` for `KEY[0]`, the switches, and the asynchronous GPIO inputs.
- If a second clock is added for Tier C, treat the CDC inputs with the vendored
  FIFO and constrain the crossing explicitly.

## Sign-off artifacts to capture

| Report | What to record |
| --- | --- |
| Fitter Summary | ALMs, registers, block memory, DSP |
| Timing Analyzer | Fmax, WNS, TNS, worst setup and hold slack |
| PowerPlay Power Analyzer | total thermal power, split by clock/enable |
| SignalTap | `auth_ok`, `fresh_ok`, `done`, `host_full`, `fault` during a frame |

## How it maps to the proposal

- Replace the FPGA resource table estimates with the Fitter numbers.
- Add an Fmax and slack line to the latency section.
- Keep the ASIC sky130 result from the RF appendix separate; do not attach the RF
  1x2 area to the link module set.

## Sanity reference (Yosys proxy, not a substitute)

| Resource | Link estimate |
| --- | --- |
| Logic cells (generic) | 1280 |
| Flip-flops | 500 |
| Cyclone V LUTs (ALUT proxy) | 360 |
| Block RAM | 0 |
| DSP | 0 |

## Steps

1. Open `fpga/de10nano/` and run `make` (which calls `quartus_sh --flow compile`).
2. Program the board with `make program`.
3. Capture the Fitter, Timing Analyzer, and PowerPlay reports and record them.
4. Run SignalTap on a clean frame, a corrupted frame, and a replay.

## Risks and notes

- On a machine without Quartus, run this at the bootcamp using the provided
  FPGA/sandbox facility.
- At 50 MHz the serialized SIMON design should meet timing; confirm with WNS.
- Verify the GPIO pin assignments in the `.qsf` against Quartus Pin Planner.
- Keep the TT `clock_hz` and the Quartus clock consistent (50 MHz).
- The DE10-Nano power is dominated by the clock and I/O, not the MAC.
