# Evidence index

Every measured claim in the proposal, mapped to its artifact and the command that reproduces it.
Raw numbers live in `sim/RESULTS.md`, `synth/area.md`, and `docs/design/quartus-report.md`.

## Simulation (Tier A core)

| Claim | Value | Artifact | Reproduce |
| --- | --- | --- | --- |
| SIMON-32/64 block vectors | 49 vectors (published plus random) | `sim/RESULTS.md`, `test/simon_ref.py` | `make simon` |
| SIMON block latency | 33 cycles per block | `sim/RESULTS.md` | `make simon` |
| CBC-MAC and freshness latency | 107 cycles | `sim/RESULTS.md` | `make l2` |
| End-to-end latency | 108 cycles (2.16 us at 50 MHz) | `sim/RESULTS.md` | `make auth` |
| Single-bit flip rejection | 128 of 128 rejected | `sim/RESULTS.md` | `make l2` |
| False reject | 0 of 20 clean frames | `sim/RESULTS.md` | `make l2` |
| Forgery, wrong key, replay, stale counter | rejected | `sim/RESULTS.md` | `make l2`, `make auth` |
| Commit latency and sticky fault | 1 cycle, fault holds until ack | `sim/RESULTS.md` | `make auth` |
| Key separation and frame loading | wrapper accepted/rejected cases | `test/test_project.py` | `make wrapper` |

## Formal

| Claim | Value | Artifact | Reproduce |
| --- | --- | --- | --- |
| Fail-closed commit invariant | 9 jobs pass (5 core, 1 Tier B, 3 RF appendix) | `synth/formal/` | `make formal` |
| Committed L3 commit gate | `host_full` high only if the last commit accepted the frame | `synth/formal/l3_commit_core.sby` | `make formal` |
| L1 loader properties | 8 properties (key policy, pulses, framing, timeout) | `synth/formal/l1_link.sby` | `make formal` |
| Tier B link framing | 8b/10b framing and word lock never rise together with a fault | `synth/formal/link_framing.sby` | `make formal` |
| Data integrity | committed data equals the authenticated frame (BMC depth 20, abstracted cipher) | `synth/formal/auth_data_integrity.sby` | `make formal` |
| Framing and timeout rejection | truncated burst raises a sticky framing fault, stalled core raises a timeout fault | `test/test_project.py` | `make wrapper` |

## Problem evidence (CWE-354)

| Claim | Value | Artifact | Reproduce |
| --- | --- | --- | --- |
| Baseline accepts corrupt frames | `full=1` for corrupt payload and corrupt field | `sim/RESULTS.md` (E1) | `make sim` |
| Affine integrity field, not CRC-24 | affine over GF(2), no standard CRC match | `tools/README.md` | `python3 tools/affine_field.py` |

## ASIC (sky130)

| Claim | Value | Artifact | Reproduce |
| --- | --- | --- | --- |
| Die area and cells | 2x2 tile, 0.0756 mm2, 2511 cells | `synth/area.md` | CI `gds.yaml` |
| DRC, LVS, antenna, timing, power | 0 DRC, 0 LVS, 0 antenna, WNS 0.00, 2.10 mW typical | `synth/area.md` | CI `gds.yaml` |
| Tier B link signoff | 2x2 tile, 3220 cells, 2 antenna violations, WNS 0.00, 3.61 mW typical | `synth/area.md` | CI `gds.yaml` |

## FPGA (DE10-Nano, Cyclone V)

| Claim | Value | Artifact | Reproduce |
| --- | --- | --- | --- |
| Resource usage | 421 ALM, 1029 FF, 0 M10K, 0 DSP (Tier B loopback wrapper) | `docs/design/quartus-report.md` | `cd fpga/de10nano && make link` |
| Timing | Fmax 97.9 MHz, WNS +9.785 ns | `docs/design/quartus-report.md` | `cd fpga/de10nano && make link` |
| Power (vector-less) | 426.2 mW total, 3.76 mW core dynamic | `docs/design/quartus-report.md` | `cd fpga/de10nano && quartus_pow link_demo_top` |

## How to run everything

```bash
make lint
make synth-check
make simon
make l2
make auth
make wrapper
make formal
make sim
```

`make test` and `make sim` exercise the archived RF appendix.
The committed link is exercised by `make simon`, `make l2`, `make auth`, and `make wrapper`.
