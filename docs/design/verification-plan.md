# Verification plan

Verification plan for the committed Tier A authenticated boundary and the Tier B 8b/10b serial link. The archived RF appendix plan is in `appendix/rf/docs/verification-plan-rf.md`.

## Goals

- Prove the fail-closed invariant: no corrupt, forged, replayed, or malformed frame is committed to the host.
- Measure detection, false-reject, and latency behavior.

## Paths

### S1, simulation (CI)

cocotb drives the RTL directly. The core suites cover SIMON vectors, L2 authentication and freshness, the integrated commit, and the Tiny Tapeout wrapper. The link suites cover the 8b/10b codec, comma/word lock/timeout, and a full loopback through the boundary. Fault injection and latency metrics are computed automatically. This path is deterministic and runs in CI.

### S2, hardware-in-the-loop

On the DE10-Nano the `link_demo_top` wrapper closes the loop internally: `link_tx` drives `link_rx` into `boundary_top`, so no external source or second clock is needed. A switch selects clean, corrupt, or replay. The on-board capture (SignalTap on `auth_ok`, `fresh_ok`, `done`, `host_full`, `fault`, `word_lock`) runs at the bootcamp.

## Checks

| Check | Tool | Command |
| --- | --- | --- |
| RTL lint | Verilator | `make lint` |
| Synthesizability | Yosys | `make synth-check` |
| Resource estimate | Yosys | `make area` |
| Core tests | cocotb | `make simon`, `make l2`, `make auth`, `make wrapper` |
| Link tests | cocotb | `make link-codec`, `make link-framing`, `make link-top` |
| Formal properties | SymbiYosys | `make formal` |
| ASIC hardening | Tiny Tapeout GDS action | `make gds` |
| FPGA build | Quartus Prime | `make fpga`, `cd fpga/de10nano && make link` |

## Formal properties

Nine `.sby` jobs pass under `synth/formal/`:

- Core: `auth_top` (fail-closed commit), `auth_data_integrity` (committed data equals the authenticated frame), `l3_commit_core` (committed commit gate), `simon32_64` (exactly 32 rounds), `l1_link` (loader key policy, pulses, framing, and timeout).
- Tier B: `link_framing` (framing and word lock never rise together with a fault).
- RF appendix: `l1_framing`, `l2_integrity`, `l3_commit` verify the archived appendix RTL, not the committed link modules.

`auth_data_integrity` is a bounded proof (`mode bmc`, depth 20) with the cipher abstracted.

## Acceptance criteria

| Criterion | Target | Evidence |
| --- | --- | --- |
| Single-bit fault detection | 128/128 injected flips rejected | `make l2` |
| False reject | 0 of 20 clean frames | `make l2` |
| Forgery, wrong key, replay, stale counter | Rejected | `make l2`, `make auth` |
| Serial link loopback | clean commit; forgery/replay/line error rejected | `make link-top` |
| Commit latency | 1 clock cycle | `make auth` |
| End-to-end latency | 108 clock cycles | `make auth` |
| Fail-closed invariant | 9 formal jobs pass | `make formal` |
| FPGA timing | Fmax at least 50 MHz (97.9 MHz measured on the loopback wrapper) | Quartus Timing Analyzer |

## Status and known risk

S1 evidence is in place for the core and the link. The link result is simulation loopback only until the bootcamp; the on-board capture and the real on-board power measurement are pending. No real-frame RF detection rate is claimed, because the RF integrity field is an unsolved error-correcting code (`tools/README.md`).
