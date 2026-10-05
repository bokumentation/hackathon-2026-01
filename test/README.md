# test/

cocotb verification for SALARAS-RX.

## Running

```bash
source venv/bin/activate
make          # from this directory
make test     # from the repository root
```

The default simulator is Icarus Verilog (`SIM=icarus`). To use Verilator:

```bash
make SIM=verilator
```

## Contents

- `tb.v` - Tiny Tapeout top wrapper exposing `digital_in`, `fault_ack`, `address`,
  and the `host_data`, `host_full`, `fault`, `manchester_clock`, `manchester_data`
  outputs.
- `test_salaras_rx.py` - cocotb tests. Current coverage:
  - reset leaves the host interface idle,
  - random noise never commits a frame (fail-closed invariant).
- `vectors/` - golden captures and frame-level vectors. See `vectors/README.md`.

Frame-level tests that replay captured Manchester waveforms will be added once
the integrity field parameters are confirmed.
