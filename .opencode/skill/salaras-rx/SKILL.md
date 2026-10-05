---
name: salaras-rx
description: Project workflow and invariants for the SALARAS-RX hardware repository (Tiny Tapeout sky130 RTL, cocotb verification, SymbiYosys formal, simulation evidence, and the untracked proposal docs). Use when working in this repository on src/, test/, sim/, synth/, tools/, fpga/, the Makefile, README, or the proposal.
---

# SALARAS-RX project workflow

Use this when changing anything in this repository.

## What the design is

- SALARAS-RX is a fail-closed ingress boundary for Manchester/RF serial links.
- It sits between the decoder and the host register file and does not change the frame format.
- Three layers: L1 framing and timing validity, L2 integrity verification, L3 atomic commit gatekeeper.
- The target is Tiny Tapeout sky130 (1x2 tile confirmed) and the Terasic DE10-Nano (Cyclone V).

## Repository map

- `src/` RTL: `sync2`, vendored `edge_detect`/`state_machine`/`data_validate`, `frame_capture`, `l1_framing_validator`, `l2_integrity_verify`, `l3_commit_gatekeeper`, `salaras_rx_top`, `project.v`.
- `test/` unit cocotb suite (`make test`).
- `sim/` simulation evidence harness and results (`make sim`), plus `RESULTS.md`.
- `synth/` formal proofs (`synth/formal/*.sby`) and the area report (`synth/area.md`).
- `tools/` integrity-field analysis (`crc_reveng.py`, `affine_field.py`).
- `fpga/` DE10-Nano Quartus project and the ESP32 wired replay path.
- `baseline/` pinned Tiny Tapeout 07 submodules; `docs/` is untracked and stays local.

## Commands

- `make lint` Verilator RTL lint.
- `make synth-check` Yosys synthesizability check.
- `make area` Yosys cell/FF estimate and a Cyclone V ALM proxy.
- `make formal` SymbiYosys proofs (needs `sby`).
- `make test` unit cocotb suite.
- `make sim` simulation evidence suites (baseline + boundary).
- `./scripts/verify.sh` runs all gates and reports a pass/fail summary.

## Invariants to respect

- Keep the core single clock at 20 kHz; the Tiny Tapeout `info.yaml` and OpenLane `CLOCK_PERIOD` must agree.
- Keep RTL lint-clean and synthesizable; plain Verilog-2001 with `default_nettype none`.
- L3 is fail-closed: on any failure, hold `host_full` low and raise a sticky `fault` until acknowledged.
- Do not add a large buffer or change the frame format.

## Field status (do not overclaim)

- The 24-bit on-wire integrity field is affine over GF(2) but is not a standard CRC-24; the baseline author suspects an error-correcting code.
- With the 7 available pairs the delta rank is only 5, so L2 is parameterized and real-frame detection is not claimed.
- Report field work as pending; never claim a detection-rate number that was not measured.
- The sky130 result is 1x2 (1x1 overflows at 105.57%): die 0.0363 mm^2, WNS 0.00, typical power 1.21 mW.

## Evidence and honesty

- Run `make lint` and `make synth-check` before every commit, and `make sim` when touching the boundary or the capture path.
- Keep CI green (lint, synth, test, formal, sim); never weaken or delete evidence to make a check pass.
- Label preliminary estimates as estimates.

## Docs

- Build the proposal with `bash docs/proposal/build.sh`.
- Use the `penulisan` skill for Indonesian text.
- Do not commit `docs/`; it is intentionally local.
