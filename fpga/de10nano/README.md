# DE10-Nano prototype

Synthesis and hardware-in-the-loop target for SALARAS-RX (proposal path S2).

## Board

Terasic DE10-Nano, Intel Cyclone V SoC `5CSEBA6U23I7`.

## Clocking

The core runs on a 20 kHz clock derived from `CLOCK_50` by a divide-by-2500
counter, matching the baseline decoder half-period of 9 ticks. The
`salaras_rx_top` core samples `digital_in` on this clock.

## Pinout

| Signal | Board resource |
| --- | --- |
| `CLOCK_50` | 50 MHz oscillator |
| `KEY[0]` | Reset (active low) |
| `SW[3:0]` | Host read address |
| `SW[4]` | Fault acknowledge |
| `LEDR[7:0]` | Committed host data |
| `LEDR[8]` | `host_full` |
| `LEDR[9]` | `fault` |
| `digital_in` | GPIO input from the ESP32 replay wire |

Verify every pin location in `salaras_rx_de10nano.qsf` against the DE10-Nano
user manual or Quartus Pin Planner before programming. The default assignments
target the standard DE10-Nano headers and LED bank.

## Build

```bash
make          # quartus_sh --flow compile
make program  # quartus_pgm over JTAG
```

After fitting, record the resource and timing numbers from the Fitter Summary
and Timing Analyzer, then update the local project documentation accordingly.

## Debug

Add a SignalTap instance on `fault`, `host_full`, the frame capture shift
register, and the L1 timeout counter to observe frame-level behavior on the
board.
