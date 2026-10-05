#!/usr/bin/env python3
"""Host-side reader for the SALARAS-RX DE10-Nano prototype (path S2).

Reads the status line printed by the board over USB-UART and reports the
committed frame state. Expected line format:

    FULL=<0|1> FAULT=<0|1> DATA=<hex>

Usage:
    python host_uart.py /dev/ttyUSB0

This script only reads; it never writes to the board.
"""

import argparse
import sys

import serial


def parse_status(line):
    fields = {}
    for token in line.split():
        if "=" not in token:
            continue
        key, value = token.split("=", 1)
        fields[key] = value
    return fields


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("port", help="serial port, for example /dev/ttyUSB0")
    parser.add_argument("--baud", type=int, default=115200)
    args = parser.parse_args()

    with serial.Serial(args.port, args.baud, timeout=1) as link:
        for raw in link:
            line = raw.decode("ascii", errors="replace").strip()
            if not line:
                continue
            fields = parse_status(line)
            full = fields.get("FULL", "?")
            fault = fields.get("FAULT", "?")
            data = fields.get("DATA", "--")
            print(f"full={full} fault={fault} data={data}")
            if fault == "1":
                print("integrity fault raised", file=sys.stderr)


if __name__ == "__main__":
    main()
