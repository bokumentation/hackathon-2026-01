# Simulation evidence

Simulation harness and evidence for the SALARAS proposal. Runs with cocotb
and Icarus Verilog.

## Layout

| File | Purpose |
| --- | --- |
| `frame_gen.py` | Builds the 192-bit `tt07-bep-decode` frame, bit-accurate |
| `tb_serial_baseline.v` | Drives the baseline `serial_decode` at its serial interface |
| `tb_boundary.v` | Instantiates L1 and L3 |
| `test_baseline_vuln.py` | Baseline vulnerability evidence |
| `test_salaras_boundary.py` | SALARAS fail-closed boundary evidence |
| `plot_waveforms.py` | Renders VCDs to PNG figures |
| `RESULTS.md` | Evidence summary |
| `out/` | Generated VCDs and PNGs (not tracked) |

## Run

```bash
source ../venv/bin/activate
make            # baseline vulnerability tests
make boundary   # SALARAS boundary tests
```

Figures:

```bash
python plot_waveforms.py out/tb_boundary.vcd out/boundary_commit_reject.png \
    --t0 0 --t1 620 transmission_begin framing_ok timing_fault frame_done \
    crc_ok host_full fault
```

## Dependencies

`matplotlib` and `vcdvcd`, in addition to the root `requirements.txt`.
