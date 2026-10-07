# Verification plan

## Goals

- Prove the fail-closed invariant: no corrupt or malformed frame is ever committed to the host.
- Measure detection rate, false-reject rate, and commit latency.

## Paths

### S1, simulation (CI)

cocotb drives `digital_in` from captured vectors.
Single-bit-flip fault injection happens at the vector level.
Detection rate and latency metrics are computed automatically.
This path is fully deterministic and runs in CI.

### S2, wired hardware-in-the-loop

An ESP32 replays a capture in real time into the DE10-Nano `digital_in` pin.
The host reads `host_full`, `fault`, and `host_data` over USB-UART.
Fault injection flips bits in the replay buffer before transmission.
See `fpga/replay/README.md`.

## Checks

| Check | Tool | Command |
| --- | --- | --- |
| RTL lint | Verilator | `make lint` |
| Synthesizability | Yosys | `make synth-check` |
| Resource estimate | Yosys | `make area` |
| Functional tests | cocotb | `make test` |
| Simulation evidence | cocotb | `make sim` |
| Formal properties | SymbiYosys | `make formal` |
| ASIC hardening | Tiny Tapeout GDS action | `make gds` |
| FPGA build | Quartus Prime | `make fpga` |

## Formal properties

`synth/formal/l1_framing.sby`, `synth/formal/l2_integrity.sby`, and `synth/formal/l3_commit.sby` prove:

- L1: `framing_ok` implies neither `timing_fault` nor `timeout_fault` is set.
- L2: a frame start reloads the LFSR register to its seed.
- L3: `host_full` implies a frame was accepted, and a rejected frame sets `fault`.

## Acceptance criteria

| Criterion | Target | Evidence |
| --- | --- | --- |
| Corrupt payload detection | 100% of injected single-bit faults rejected | S1 and S2 fault injection |
| False reject | 0 clean frames rejected | S1 golden vectors |
| Commit latency | 1 clock cycle | Boundary simulation (`sim/`) |
| Area | 1x2 tile (1x1 overflows) | OpenLane report |

## Status and known risk

S1 evidence is in place: the baseline accepts corrupted payload and integrity
field (`full=1`, CWE-354), and the boundary is fail-closed (reject, sticky
fault, 1-cycle commit). Detection rate on real captures is not yet claimed.

The integrity field is affine over GF(2) but does not match any standard CRC-24
(exhaustive search in `tools/crc_reveng.py`). With the 7 available pairs the
delta rank is only 5, so the full map is not recoverable
(`tools/affine_field.py`); the baseline author reports the same and suspects an
error-correcting code. L2 is parameterized until more `(payload, tail)` pairs
are collected.
