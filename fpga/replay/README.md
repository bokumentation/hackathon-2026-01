# Wired replay (proposal path S2)

The replay path feeds captured Manchester waveforms into the DE10-Nano
`digital_in` pin over a 3.3 V wire. Both boards are 3.3 V, so no level shifter
is required. The link is deterministic and supports single-bit-flip fault
injection.

## Components

- `esp32_replay/esp32_replay.ino` - ESP32 Arduino sketch. Drives the data pin
  from half-period and level commands received on serial, so the host can replay
  any capture and flip bits for fault injection.
- `host_uart.py` - host-side reader for the board status line. Read-only.

## Wiring

| ESP32 | DE10-Nano |
| --- | --- |
| GPIO4 | `digital_in` (GPIO header) |
| GND | GND |

## Procedure

1. Flash `esp32_replay.ino` to the ESP32.
2. Connect the data wire and common ground.
3. Program the DE10-Nano with `make -C ../de10nano program`.
4. Stream a captured waveform from the host to the ESP32 serial port.
5. Read `host_full`, `fault`, and the committed data over USB-UART with
   `python host_uart.py /dev/ttyUSB0`.

## Fault injection

Flip a single bit in the replay buffer before transmission to emulate a fault
on the payload or on the integrity field. A correct design must reject the
frame: `host_full` stays low and `fault` raises.
