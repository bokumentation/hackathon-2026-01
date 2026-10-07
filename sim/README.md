# Simulation evidence

Simulation harness and evidence for the TRI-ARGA proposal. Runs with cocotb
and Icarus Verilog.

This folder holds the RF appendix simulation evidence. The committed link
evidence lives in the cocotb suites under `test/` (run with `make simon`, `make
l2`, `make auth`, `make wrapper`, `make link-codec`, `make link-framing`, `make
link-top`) and in the formal proofs under `synth/formal/`.

## Layout

| File | Purpose |
| --- | --- |
| `frame_gen.py` | Builds the 192-bit `tt07-bep-decode` frame, bit-accurate |
| `tb_serial_baseline.v` | Drives the baseline `serial_decode` at its serial interface |
| `tb_boundary.v` | Instantiates L1 and L3 |
| `test_baseline_vuln.py` | Baseline vulnerability evidence |
| `test_boundary.py` | TRI-ARGA fail-closed boundary evidence |
| `plot_waveforms.py` | Renders VCDs to PNG figures |
| `RESULTS.md` | Evidence summary |
| `out/` | Generated VCDs and PNGs (not tracked) |

## Run

```bash
source ../venv/bin/activate
make            # baseline vulnerability tests
make boundary   # TRI-ARGA boundary tests
```

Figures:

```bash
python plot_waveforms.py out/tb_boundary.vcd appendix/rf/figures/sim-boundary-timeout.png \
    --t0 41000 --t1 41700 framing_ok timeout_fault
```

## Dependencies

`matplotlib` and `vcdvcd`, in addition to the root `requirements.txt`.
