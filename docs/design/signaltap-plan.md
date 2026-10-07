# SignalTap on-board capture plan

Plan to capture the fail-closed behavior of the authenticated ingress boundary on the DE10-Nano with SignalTap.
This is the on-board real-time evidence step (S2) that complements the off-board Quartus synthesis, fit, and timing numbers in `../quartus-report.md`.

## Why this needs the board

SignalTap is an on-chip logic analyzer.
The capture logic is compiled into the FPGA image and the sample buffer is read back over JTAG.
There is no capture without the physical DE10-Nano and a USB-Blaster connection.

A `.stp` file is created in the Quartus Prime GUI.
Intel recommends against hand-editing the file, and a hand-authored file is often rejected or silently ignored by the compiler.

## Signals to tap

| Signal | Meaning | Clock |
| --- | --- | --- |
| `host_full` | data committed to the host on a valid frame | `CLOCK_50` |
| `fault` | sticky rejection flag | `CLOCK_50` |
| `auth_ok` | MAC tag matched | `CLOCK_50` |
| `fresh_ok` | counter freshness passed | `CLOCK_50` |
| `done` | frame processing finished | `CLOCK_50` |
| `word_lock` | 8b/10b link word alignment achieved | `CLOCK_50` |

These are the signals kept in the `link_demo_top` wrapper. The Tier A `de10nano_top` wrapper keeps `key_locked` instead of `word_lock`.

The wrapper declares these wires with `(* preserve, noprune *)` so they survive synthesis and appear in Node Finder.

## Session settings

- Sample clock: `CLOCK_50`.
- Sample depth: 2048 samples.
- Trigger position: pre-trigger, 25 percent.
- Trigger: `host_full` rising edge (accept case) or `fault` rising edge (reject case), on separate runs.

## Create the .stp in the GUI

1. Open the project in Quartus Prime: `quartus fpga/de10nano/de10nano_top.qpf`.
2. Tools > SignalTap Logic Analyzer.
3. Set the sample clock to `CLOCK_50`, the depth to 2048, and the position to pre-trigger.
4. Add the six signals above using Node Finder.
5. Set the trigger to `host_full` rising edge and save as `de10nano_top.stp` in `fpga/de10nano/`.
6. The `.stp` file is not committed, because the compiled SLD wiring is project-specific.

## Generate the SLD wiring and recompile

Saving the file in the GUI is not enough, and `quartus_sh --flow compile` does not add the analyzer by itself.
Run the conversion, then recompile.

```bash
cd fpga/de10nano
quartus_stp de10nano_top --stp_file de10nano_top.stp --enable
quartus_sh --flow compile de10nano_top
```

The `.qsf` contains these three assignments as a commented block.
Uncomment them only after the `.stp` exists, otherwise a fresh clone fails to build.

```
set_global_assignment -name ENABLE_SIGNALTAP ON
set_global_assignment -name USE_SIGNALTAP_FILE de10nano_top.stp
set_global_assignment -name SIGNALTAP_FILE de10nano_top.stp
```

## Resource impact

SignalTap stores samples in M10K block memory, so enabling it adds RAM blocks to the fit and slightly increases power and logic.
Record the new Fitter numbers from `output_files/de10nano_top.fit.rpt` and report them as the SignalTap-enabled build.

## Program and capture

```bash
jtagconfig
quartus_pgm -m jtag -o "p;output_files/de10nano_top.sof"
quartus_stp -t signaltap_acquire.tcl
```

The helper script `fpga/de10nano/signaltap_acquire.tcl` opens the session, runs one acquisition with a timeout, exports a VCD, and closes the session.
The instance, signal set, and trigger names come from the `.stp` file and may need to be adjusted in the script.
The same capture can also be run from the SignalTap GUI with the Run Analysis button.

## Test cases to capture

1. Clean frame with the correct tag and a fresh counter: `host_full` high, `fault` low.
2. Corrupt frame with a wrong tag: `host_full` low, `fault` high.
3. Replay with an equal counter: `host_full` low, `fresh_ok` low, `fault` high.
4. Word lock achieved after the comma symbol: `word_lock` high.
5. A clean frame after `fault_ack`: `fault` returns low and `host_full` rises again.

## Evidence to keep

- The exported waveform (`.vcd` or `.csv`) for each case, stored outside the repository or under an ignored path.
- A screenshot of the SignalTap window for the clean and corrupt cases.
- The Fitter report for the SignalTap-enabled build, for the updated resource line.

## Limitations

SignalTap is a debug instrument and is not present in the production image.
The on-board capture requires the board and the bootcamp sandbox.
Until then, the simulation evidence and the Quartus fit/timing numbers remain the measured results.

## See also

- `../quartus-report.md` for the off-board synthesis, fit, timing, and power numbers.
- `quartus-plan.md` for the earlier capture plan.
- `../../fpga/de10nano/README.md` for the board pinout and the on-board test procedure.
