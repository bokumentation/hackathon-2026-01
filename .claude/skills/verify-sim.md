---
name: verify-sim
description: Verify RTL code correctness and simulation results for the SALARAS-RX authenticated ingress boundary. Run when asked to verify code, check simulation results, validate a change, or confirm no regressions.
---

Verify the SALARAS-RX authenticated ingress boundary.
Never claim a result that was not actually measured - check real test output before reporting.

## Step 1 - RTL static checks

For each source file in `src/`: simon32_64.v, l2_auth.v, l3_commit_gatekeeper.v, salaras_auth_top.v, project.v:

1. Confirm the file begins with `` `default_nettype none ``.
2. Confirm every `output` port is driven on all paths (no inferred latches).
3. Run iverilog syntax check (iverilog is available locally; verilator/yosys run in CI only):

Windows:
```
iverilog -g2012 -o NUL -Isrc -Wall src\simon32_64.v src\l2_auth.v src\l3_commit_gatekeeper.v src\salaras_auth_top.v src\project.v
```
Linux/CI:
```
iverilog -g2012 -o /dev/null -Isrc -Wall src/simon32_64.v src/l2_auth.v src/l3_commit_gatekeeper.v src/salaras_auth_top.v src/project.v
```

Report every warning and error.

## Step 2 - Run simulation tests

Windows (no make):
```
python run_simon_test.py
python run_l2_test.py
python run_auth_test.py
python run_project_test.py
```

Linux/CI:
```
make simon
make l2
make auth
make wrapper
```

Read the actual stdout output from each run. Do not invent results.

## Step 3 - Compare against baseline in sim/RESULTS.md

Expected baseline:

| Suite | Pass count | Key metric |
| --- | --- | --- |
| simon | 2/2 | 49 vectors (1 published + 48 random) |
| l2 | 4/4 | 128/128 single-bit flips rejected |
| auth | 6/6 incl. TOCTOU regression | 108-cycle end-to-end latency |
| wrapper/project | 5/5 | key separation, replay, pre-key frame ignored |

Latency numbers (regression if any differ by even 1 cycle):

| Path | Expected |
| --- | --- |
| SIMON block (start to done) | 33 cycles |
| L2 CBC-MAC + freshness | 107 cycles |
| End-to-end start to host_full | 108 cycles |
| Commit only | 1 cycle |

## Step 4 - Formal status

List .sby files under `synth/formal/`: simon32_64.sby, l1_framing.sby, l2_integrity.sby, l3_commit.sby, auth_top.sby, auth_data_integrity.sby.

If sby is available run each; otherwise report "formal not run - sby not installed locally, CI gate is authoritative".

## Step 5 - Summary table

Fill with actual measured values only:

| Component | Tests | Latency | Formal | Status |
| --- | --- | --- | --- | --- |
| SIMON-32/64 | ?/2 | ? cycles/block | ? | PASS/FAIL |
| L2 auth+freshness | ?/4 | ? cycles | ? | PASS/FAIL |
| Auth top (L2+L3) | ?/6 | ? cycles e2e | ? | PASS/FAIL |
| Wrapper/project | ?/5 | - | - | PASS/FAIL |

## Step 6 - Regression report

Flag a regression if:
- Any test count is below the baseline.
- Any latency differs from the expected cycle count.
- The TOCTOU test (test_inputs_changed_mid_frame_not_committed) is missing from auth suite.
- 128/128 bit-flip rejection drops below 128.

State "All checks pass. No regressions against sim/RESULTS.md baseline." only if every item matches.
