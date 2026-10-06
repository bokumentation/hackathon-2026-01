# Demo and bring-up

Plan for the DE10-Nano hardware demo of the authenticated ingress boundary.
The board pinout is in `docs/datasheet/de10-nano.md`, and the on-board capture procedure is in `docs/design/signaltap-plan.md`.

## Bill of materials

| Item | Quantity | Note |
| --- | --- | --- |
| Terasic DE10-Nano | 1 | Cyclone V SoC `5CSEBA6U23I7` |
| micro-USB cable | 2 | one for JTAG (USB-Blaster II), one for UART power |
| Jumper wires | 4 to 6 | connect the serial source to GPIO_0 |
| 3.3 V USB-UART adapter or ESP32 | 1 | drives `gpio_frame_bit` and `gpio_load_en` |
| Common ground | 1 | tie the source ground to the board ground |

An ESP32 is optional and doubles as the replay source for the attack demo (see `appendix/rf/replay/`).

## Wiring

| Board signal | GPIO_0 pin | Direction | Connect to |
| --- | --- | --- | --- |
| `gpio_frame_bit` | PIN_V12 | input | serial data out |
| `gpio_load_en` | PIN_E8 | input | bit strobe |
| `gpio_fault_ack` | PIN_W12 | input | acknowledge button |
| `gpio_host_full` | PIN_D11 | output | scope or logic analyzer |
| `gpio_fault` | PIN_D8 | output | scope or logic analyzer |
| `gpio_done` | PIN_AH13 | output | scope or logic analyzer |

`SW[0]` selects key mode (1) or frame mode (0).
`LEDR[5:0]` show `done`, `host_full`, `fault`, `auth_ok`, `fresh_ok`, and `key_locked`.

## Loading protocol

Key load (once after reset):

1. Set `SW[0]=1`.
2. Shift the 64-bit key MSB first on `gpio_frame_bit`, one bit per cycle, with `gpio_load_en` high.
3. After 64 bits the core pulses `key_load` and `key_locked` goes high (`LEDR[5]`).

Frame load:

1. Set `SW[0]=0`.
2. Shift the 128-bit frame `counter(32) + payload(64) + tag(32)` MSB first with `gpio_load_en` high.
3. The core starts the MAC and commits or faults.

## Demo cases

| Case | Expected |
| --- | --- |
| Clean frame with a correct tag and a fresh counter | `host_full=1`, `fault=0` |
| Corrupt payload, tag kept | `host_full=0`, `fault=1` |
| Replay with an equal counter | authenticated, `fresh_ok=0`, `fault=1` |
| Frame before any key load | ignored, `host_full=0` |
| Second key load after lock | ignored, `key_locked` stays high |

## Procedure

```bash
cd fpga/de10nano
make
quartus_pgm -m jtag -o "p;output_files/de10nano_top.sof"
```

Then run the cases above and capture `auth_ok`, `fresh_ok`, `done`, `host_full`, and `fault` with SignalTap or an external logic analyzer.

## Preparation checklist

- [ ] Board connected and visible to `jtagconfig`.
- [ ] Bitstream programmed.
- [ ] Serial source ground tied to the board ground.
- [ ] Key loaded, `LEDR[5]` high.
- [ ] Capture tool armed for the clean and corrupt cases.

## Notes

- The demo requires the physical board; it is a bootcamp deliverable.
- The committed image is single clock and needs no external memory.
