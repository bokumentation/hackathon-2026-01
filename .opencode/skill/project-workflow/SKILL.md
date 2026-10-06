---
name: project-workflow
description: Project workflow, design program, and invariants for this Tiny Tapeout hardware repository (sky130 RTL, cocotb verification, SymbiYosys formal, simulation evidence, and the tracked proposal docs). Use when working in this repository on src/, test/, sim/, synth/, tools/, fpga/, the Makefile, README, or the proposal.
---

# Project workflow

Use this when changing anything in this repository.

## Design program

- TRI-ARGA is the fail-closed Manchester/RF ingress boundary on `tt07-bep-decode`; it is the CWE-354 problem evidence and is kept as an appendix.
- The committed successor is the authenticated, replay-resistant, fail-closed boundary (Tier A): SIMON-32/64 CBC-MAC plus a freshness counter, single clock.
- Tier B (next): a purpose-built link layer on `TT_UM_SERDES` (`link_enc_8b10b`, `link_dec_10b8b`, `link_tx`, `link_rx`, `l1_link_framing`).
- Tier C (future): two-clock operation using the vendored `cdc_fifo`, real hardening, FPGA.
- Execution is in `PLAN-02.md`; vision and proposal framing are in `PLAN.md`.

## Repository map

- `src/` committed link RTL: `simon32_64`, `l2_auth`, `l3_commit_gatekeeper`, `boundary_top`, `project.v`, plus the Tiny Tapeout config.
- `appendix/rf/` archived Manchester/RF design, its FPGA project, and the ESP32 replay.
- `test/` cocotb suites (link tests plus the RF unit suite).
- `sim/` simulation evidence harness and results (`make sim`), plus `RESULTS.md`.
- `synth/` formal proofs (`synth/formal/*.sby`) and the area report (`synth/area.md`).
- `tools/` integrity-field analysis (`crc_reveng.py`, `affine_field.py`).
- `fpga/` DE10-Nano link project.
- `baseline/` pinned Tiny Tapeout 07 submodules; `docs/` is tracked (generated HTML is ignored).

## Commands

- `make lint` Verilator RTL lint.
- `make synth-check` Yosys synthesizability check.
- `make area` Yosys cell/FF estimate and a Cyclone V ALM proxy.
- `make formal` SymbiYosys proofs (needs `sby`).
- `make test` RF appendix unit cocotb suite.
- `make simon` SIMON-32/64 block and CBC-MAC tests.
- `make l2` L2 authentication and freshness tests.
- `make auth` integrated authentication and commit tests.
- `make crc` RF CRC streaming latency (comparison).
- `make sim` RF appendix simulation evidence suites (baseline + boundary).
- `.opencode/skill/project-workflow/scripts/verify.sh` runs all gates and reports a pass/fail summary.

## Invariants to respect

- Keep the Tier A core single clock; introduce a second clock only through the vendored CDC FIFO (Tier C).
- Keep RTL lint-clean and synthesizable; plain Verilog-2001 with `default_nettype none`.
- Keep the 8b/10b tables verbatim; rewriting the framing, alignment, and serial datapath around them is allowed.
- Do not rewrite the vendored CDC FIFO; wrap or parameterize it.
- L3 is fail-closed: on any failure, hold `host_full` low and raise a sticky `fault` until acknowledged.
- Do not add a large buffer or change the frame format of a link we do not own.

## Field status (do not overclaim)

- The TRI-ARGA 24-bit on-wire field is affine over GF(2) but is not a standard CRC-24; the baseline author suspects an error-correcting code.
- With the 7 available pairs the delta rank is only 5, so the RF L2 is parameterized and real-frame detection is not claimed.
- The RF sky130 result is 1x2 (1x1 overflows at 105.57%): die 0.0363 mm^2, WNS 0.00, typical power 1.21 mW. It belongs to the appendix and does not transfer to the MAC module set.

## Must not claim

- No cryptographic proof of security; a 32-bit tag gives about 2^-32 forgery probability.
- No real-frame RF detection rate; the RF field is unsolved, so RF is problem evidence only.
- No serial link or CDC result until Tier B or Tier C is built.
- No key provisioning, persistent counter, or side-channel resistance.
- No "works with any protocol"; say "reusable core demonstrated on the RF appendix plus one synthetic profile".
- No target portability (ASIC plus FPGA) as a result until synthesis.

## Evidence and honesty

- Run `make lint` and `make synth-check` before every commit, and `make sim` when touching the boundary or the capture path.
- Keep CI green (lint, synth, test, formal, sim); never weaken or delete evidence to make a check pass.
- Label preliminary estimates as estimates.

## Docs

- Build the proposal with `make docs` (which calls `docs/proposal/build.sh`).
- Use the `penulisan` skill for Indonesian text.
- `docs/` is tracked; generated HTML is ignored.
