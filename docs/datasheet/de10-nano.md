# DE10-Nano datasheet notes

Reference notes for the Terasic DE10-Nano board used in `fpga/de10nano/`.

## Board

- Vendor: Terasic.
- Device: Intel Cyclone V SoC `5CSEBA6U23I7`.
- Clock: `CLOCK_50` (50 MHz, `FPGA_CLK1_50`, pin `PIN_V11`).
- User I/O: 8 LEDs (LED0-LED7), 4 slide switches (SW0-SW3), 2 keys (KEY0-KEY1).
- Headers: GPIO_0 and GPIO_1, 36 pins each.

## Sources

- Terasic DE10-Nano product and documentation page:
  https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=167&No=1046&PartNo=1#contents
- Intel DE10-Nano User Manual (pin assignment tables).
- Terasic System Builder golden hardware reference design (authoritative pin map).

## Pin map used by TRI-ARGA

| Signal | Device pin | Board resource |
| --- | --- | --- |
| `CLOCK_50` | PIN_V11 | FPGA_CLK1_50, 50 MHz |
| `KEY[0]` | PIN_AH17 | Reset (active low) |
| `KEY[1]` | PIN_AH16 | User key |
| `SW[0]` | PIN_Y24 | Switch, `key_mode` |
| `SW[1]` | PIN_W24 | Switch |
| `SW[2]` | PIN_W21 | Switch |
| `SW[3]` | PIN_W20 | Switch |
| `LEDR[0]` | PIN_W15 | LED, `done` |
| `LEDR[1]` | PIN_AA24 | LED, `host_full` |
| `LEDR[2]` | PIN_V16 | LED, `fault` |
| `LEDR[3]` | PIN_V15 | LED, `auth_ok` |
| `LEDR[4]` | PIN_AF26 | LED, `fresh_ok` |
| `LEDR[5]` | PIN_AE26 | LED, `key_locked` |
| `LEDR[6]` | PIN_Y16 | LED, tied low |
| `LEDR[7]` | PIN_AA23 | LED, tied low |
| `gpio_frame_bit` | PIN_V12 | GPIO_0[0] |
| `gpio_load_en` | PIN_E8 | GPIO_0[1] |
| `gpio_fault_ack` | PIN_W12 | GPIO_0[2] |
| `gpio_host_full` | PIN_D11 | GPIO_0[3] |
| `gpio_fault` | PIN_D8 | GPIO_0[4] |
| `gpio_done` | PIN_AH13 | GPIO_0[5] |

The full report for the current build is in `../design/quartus-report.md`.
