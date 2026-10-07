# DE10-Nano prototype (link)

Synthesis and hardware-in-the-loop target for the authenticated ingress boundary.

Two wrappers are provided:

- `de10nano_top` (Tier A): the L1 serial loader plus `boundary_top`, with an external bit-serial key/frame source.
- `link_demo_top` (Tier B): an internal 8b/10b loopback, `link_tx` -> `link_rx` -> `boundary_top`, with the FPGA generating the wire traffic itself.

## Board

Terasic DE10-Nano, Intel Cyclone V SoC `5CSEBA6U23I7`. Quartus Prime is required.

## Clocking

The core runs directly on `CLOCK_50` (50 MHz). One clock domain in the
committed scope.

## Tier B loopback demo (link_demo_top)

```bash
make link          # quartus_sh --flow compile link_demo_top
make program-link  # quartus_pgm over JTAG
```

Control map:

| Resource | Function |
| --- | --- |
| `KEY[0]` | Reset (active low) |
| `KEY[1]` | Send one frame |
| `SW[1:0]` | Mode: `00` clean, `01` corrupt (tag bit flipped), `10` replay (resend last clean frame) |
| `SW[2]` | `fault_ack` (clears the sticky fault) |
| `LEDR[0..5]` | `done`, `host_full`, `fault`, `auth_ok`, `fresh_ok`, `word_lock` |
| `LEDR[6]` | `tx_busy` |
| `LEDR[7]` | clean-mode indicator |

The demo key and four pre-computed valid frames are held in `link_demo_top.v`; the key is loaded once at reset. Expected: clean commits (`host_full` high), corrupt and replay are rejected (`fault` high, sticky until `SW[2]`). Measured post-fit: 421 ALM, 1029 registers, Fmax 97.9 MHz, 426.2 mW vector-less.

## Key loading

The key path is separate from the frame path and must be loaded once before any
frame is accepted.
Set `SW[0] = 1` (key_mode) and clock in the 64-bit key MSB first through
`gpio_frame_bit` while `gpio_load_en` is high.
After 64 bits the core pulses `key_load`, sets the `key_locked` latch, and
returns to S_LOAD.
The key remains locked until reset; a second attempt to load a key while
`key_locked` is set has no effect.
`LEDR[5]` indicates `key_locked`.

## Frame loading

After the key is loaded, set `SW[0] = 0` (frame mode) and shift the 128-bit
frame MSB first through `gpio_frame_bit` while `gpio_load_en` is high:
`counter (32) + payload (64) + tag (32)`.
After 128 bits the core starts the MAC, and commits or faults.
Frames received before the key is loaded are ignored.

## Pinout

| Signal | Board resource |
| --- | --- |
| `CLOCK_50` | 50 MHz oscillator |
| `KEY[0]` | Reset (active low) |
| `SW[0]` | `key_mode`: 1 = load key, 0 = load frame |
| `LEDR[0]` | `done` |
| `LEDR[1]` | `host_full` |
| `LEDR[2]` | `fault` |
| `LEDR[3]` | `auth_ok` |
| `LEDR[4]` | `fresh_ok` |
| `LEDR[5]` | `key_locked` |
| `gpio_frame_bit` | GPIO frame/key input (shared, mode-selected) |
| `gpio_load_en` | GPIO load strobe |
| `gpio_fault_ack` | GPIO fault acknowledge |
| `gpio_host_full` | GPIO status output |
| `gpio_fault` | GPIO status output |
| `gpio_done` | GPIO status output |

Verify every pin location in `de10nano_top.qsf` against the DE10-Nano
user manual or Quartus Pin Planner before programming.

## Build

```bash
make          # quartus_sh --flow compile
make program  # quartus_pgm over JTAG
```

After fitting, record the resource and timing numbers from the Fitter Summary and
Timing Analyzer, then update the proposal tables and `synth/area.md`.

## On-board test

1. Assert `KEY[0]` low to reset; release.
2. Set `SW[0] = 1`. Clock in the 64-bit key MSB first with `gpio_load_en` high.
   `LEDR[5]` rises when `key_locked`.
3. Set `SW[0] = 0`. Clock in a 128-bit authenticated frame
   (counter + payload + tag, 128 bits total).
4. After `gpio_done` rises: `LEDR[1]` (`host_full`) high and `LEDR[2]` (`fault`)
   low for a clean frame.
5. With `SW[0] = 0`, attempt to tamper with the payload (change a bit, keep tag):
   `LEDR[2]` rises; it stays high until `gpio_fault_ack`.
6. Replay (same counter): authenticated but not committed - `LEDR[4]`
   (`fresh_ok`) low, `LEDR[2]` rises.
7. With `SW[0] = 1` again after reset, confirm a second key-load attempt while
   `LEDR[5]` is set has no effect.

## Reports to capture

| Report | What to record |
| --- | --- |
| Fitter Summary | ALMs, registers, block memory, DSP |
| Timing Analyzer | Fmax, WNS, TNS, worst setup and hold slack |
| PowerPlay | total thermal power and the clock/sequential split |
