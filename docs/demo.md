# Demo and bring-up

Plan for the DE10-Nano hardware demo of the authenticated ingress boundary and its serial link.
The board pinout is in `docs/datasheet/de10-nano.md`, and the on-board capture procedure is in `docs/design/signaltap-plan.md`.

## Bill of materials

| Item | Quantity | Note |
| --- | --- | --- |
| Terasic DE10-Nano | 1 | Cyclone V SoC `5CSEBA6U23I7` |
| micro-USB cable | 1 | JTAG (USB-Blaster II) |

No external serial source is needed. The demo uses an internal loopback from `link_tx` to `link_rx`, so the FPGA generates the wire traffic itself and timing cannot be disturbed by wiring.

## Control map

| Resource | Function |
| --- | --- |
| `KEY[0]` | Reset (active low) |
| `KEY[1]` | Send one frame |
| `SW[1:0]` | Mode: `00` clean, `01` corrupt (tag bit flipped), `10` replay (resend last clean frame) |
| `SW[2]` | `fault_ack` (clears the sticky fault) |
| `LEDR[0]` | `done` |
| `LEDR[1]` | `host_full` |
| `LEDR[2]` | `fault` |
| `LEDR[3]` | `auth_ok` |
| `LEDR[4]` | `fresh_ok` |
| `LEDR[5]` | `word_lock` |
| `LEDR[6]` | `tx_busy` |
| `LEDR[7]` | clean-mode indicator |

The demo key and four pre-computed valid frames are held in `link_demo_top.v`. The key is loaded once at reset; each clean send uses the next frame with a fresh counter.

## Demo cases

| Case | Mode | Expected |
| --- | --- | --- |
| Clean frame, correct tag, fresh counter | `00` | `host_full=1`, `fault=0` |
| Corrupt frame, tag bit flipped | `01` | `host_full=0`, `fault=1` |
| Replay of the previous clean frame | `10` | authenticated, `fresh_ok=0`, `fault=1` |
| Clean frame after `fault_ack` | `00` | recovers, `host_full=1` |

## Procedure

```bash
cd fpga/de10nano
make link
quartus_pgm -m jtag -o "p;output_files/link_demo_top.sof"
```

Then select a mode with `SW[1:0]`, press `KEY[1]` to send, and read the LEDs. Use `SW[2]` to clear a sticky fault between cases.

Capture `auth_ok`, `fresh_ok`, `done`, `host_full`, and `fault` with SignalTap or an external logic analyzer.

## Preparation checklist

- [ ] Board connected and visible to `jtagconfig`.
- [ ] Bitstream `link_demo_top.sof` programmed.
- [ ] Reset released, `LEDR[5]` (`word_lock`) high.
- [ ] Capture tool armed for the clean and corrupt cases.

## Notes

- The demo requires the physical board; it is a bootcamp deliverable.
- The design is single clock and needs no external memory.
- The Tier A wrapper (`de10nano_top`) remains available for a bit-serial key/frame demo if needed.
