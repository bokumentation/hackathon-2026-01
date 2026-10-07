---
name: verilog-rtl
description: RTL conventions for this repository's Verilog and SystemVerilog. Use when writing or editing .v or .sv files under src/, test/, sim/, or fpga/.
---

# Verilog and SystemVerilog conventions

Apply these to every `.v` / `.sv` change.

## Style

- Write plain Verilog-2001 style that Yosys and OpenLane accept; avoid vendor-specific constructs.
- Start each file with `` `default_nettype none `` and end with `` `default_nettype wire ``.
- Use synchronous logic with a single clock; keep the core at 20 kHz.
- Use an active-low asynchronous reset consistently (`rst_n`).
- Declare explicit bit widths; avoid unsized literals in expressions.
- Avoid inferred latches: assign every output on all paths.
- Do not add comments unless the user asks.

## Structure

- Keep modules small and single-purpose; one file per module.
- Vendor baseline modules (`edge_detect`, `state_machine`, `data_validate`) verbatim; do not rewrite them.
- Put shared constants in `src/defs.svh`.
- The committed Tiny Tapeout top module must start with `tt_um_` (`tt_um_auth_boundary` in `src/project.v`).
- The archived Manchester/RF design lives under `appendix/rf/src/`.
- List every `src/` file in `info.yaml` `source_files`.

## Tiny Tapeout and hardening

- Keep one clock domain and no large buffers.
- Keep the design synthesizable and lint-clean; `info.yaml` and `src/user_config.tcl` must agree on the clock (20 kHz, `CLOCK_PERIOD 50000`).
- Do not hand-edit generated GDS or build outputs.

## Verify before finishing

- `make lint` (Verilator) and `make synth-check` (Yosys) must pass.
- For boundary or capture changes, run `make sim`.
- For formal-relevant changes, run `make formal`.
