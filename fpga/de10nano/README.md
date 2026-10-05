# DE10-Nano prototype (link)

Synthesis and hardware-in-the-loop target for the authenticated ingress boundary.

## Board

Terasic DE10-Nano, Intel Cyclone V SoC `5CSEBA6U23I7`. Quartus Prime is required.

## Clocking

The core runs directly on `CLOCK_50` (50 MHz). One clock domain in the
committed scope.

## Frame loading

Shift the 192-bit frame MSB first through `gpio_frame_bit` while `gpio_load_en`
is high: `key (64) + counter (32) + payload (64) + tag (32)`. After 192 bits the
core loads the key, starts the MAC, and commits or faults.

## Pinout

| Signal | Board resource |
| --- | --- |
| `CLOCK_50` | 50 MHz oscillator |
| `KEY[0]` | Reset (active low) |
| `LEDR[0]` | `done` |
| `LEDR[1]` | `host_full` |
| `LEDR[2]` | `fault` |
| `LEDR[3]` | `auth_ok` |
| `LEDR[4]` | `fresh_ok` |
| `gpio_frame_bit` | GPIO frame input |
| `gpio_load_en` | GPIO load strobe |
| `gpio_fault_ack` | GPIO fault acknowledge |
| `gpio_host_full` | GPIO status output |
| `gpio_fault` | GPIO status output |
| `gpio_done` | GPIO status output |

Verify every pin location in `salaras_auth_de10nano.qsf` against the DE10-Nano
user manual or Quartus Pin Planner before programming.

## Build

```bash
make          # quartus_sh --flow compile
make program  # quartus_pgm over JTAG
```

After fitting, record the resource and timing numbers from the Fitter Summary and
Timing Analyzer, then update the proposal tables and `synth/area.md`.

## On-board test

- Add a SignalTap instance on `auth_ok`, `fresh_ok`, `done`, `host_full`, and
  `fault`.
- Clean frame: `host_full` and `auth_ok` rise, `fault` stays low.
- Tampered frame (flip a payload bit, keep the tag): commit is blocked, `fault`
  rises, and it stays high until `gpio_fault_ack`.
- Replay (same counter): authenticated but not committed, `fresh_ok` low.

## Reports to capture

| Report | What to record |
| --- | --- |
| Fitter Summary | ALMs, registers, block memory, DSP |
| Timing Analyzer | Fmax, WNS, TNS, worst setup and hold slack |
| PowerPlay | total thermal power and the clock/sequential split |
