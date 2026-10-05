# Synthesis area estimate

Preliminary, technology-independent estimate of the SALARAS-RX top
(`tt_um_bokumentation_salaras_rx`). Reproduce with `make area`; raw Yosys logs
are written to `synth/area/` (not tracked).

- Revision: `main` (Phase B integration)
- RTL: `src/` with the baseline front-end (`edge_detect`, `state_machine`, `data_validate`) integrated
- Tool: Yosys 0.52

## Method

- `synth` then `flatten` gives the technology-independent gate count.
- `synth_intel_alm -family cyclonev` maps to the Intel ALM model (MISTRAL
  primitives) as a Cyclone V proxy. This is not a substitute for a Quartus
  Fitter report.

## Generic synthesis

| Metric | Value |
| --- | --- |
| Cells | 1352 |
| Registers (DFF) | 352 |
| Combinational cells | 1000 |

## Cyclone V ALM mapping (proxy)

| Resource | Value |
| --- | --- |
| Mapped cells | 923 |
| Registers (MISTRAL_FF) | 360 |
| LUTs (ALUT2/3/4/5/6) | 508 |
| Arithmetic LUTs (ALUT_ARITH) | 88 |

## Cyclone V resource table (preliminary, for the proposal)

| Resource | Estimate | DE10-Nano capacity |
| --- | --- | --- |
| Logic elements / LUT | about 508 LUT equivalent | 41,910 ALMs |
| Registers / flip-flops | 360 | 166,542 |
| Block RAM (M10K) | 0 (no buffer) | 5,570 Kbits |
| DSP blocks | 0 (LFSR-based CRC) | 112 DSP |

Quartus Fitter numbers replace these once the integrated design is synthesized.

## Tier A link estimate (salaras_auth_top)

The committed successor is the authenticated boundary (`simon32_64`, `l2_auth`,
`l3_commit_gatekeeper`, `salaras_auth_top`). Reproduce with `make area-link`.

| Resource | Value |
| --- | --- |
| Generic cells | 1280 |
| Generic flip-flops | 500 |
| Cyclone V mapped cells | 1162 |
| Cyclone V flip-flops | 500 |
| Cyclone V LUTs (ALUT) | 360 |
| Arithmetic LUTs (ALUT_ARITH) | 88 |
| Block RAM (M10K) | 0 |
| DSP blocks | 0 |

This is a pre-integration estimate: it does not yet include the Tier B link
layer or the Tier C CDC FIFO.

### Real sky130 signoff (link, 2x2)

Hardened through `.github/workflows/gds.yaml` on the link
(`tt_um_bokumentation_auth_boundary`). The 1x2 tile does not fit (GPL-0302 at
density 0.6 and 0.8), so a 2x2 tile is used.

| Metric | Value |
| --- | --- |
| Tile | 2x2 |
| Die area | 334.88 x 225.76 um = 0.0756 mm^2 |
| Synthesis cells | 2354 |
| Magic DRC | 0 violations |
| LVS | 0 errors |
| Setup WNS / TNS | 0.00 / 0.00 (timing met) |
| Worst setup slack | +10.79 ns |
| Worst hold slack | +0.12 ns |
| Power, typical | 1.87 mW |
| Power, fastest | 2.20 mW |
| Power, slowest | 1.46 mW |

## ASIC (sky130) estimate

Technology-independent gate count is 1352 cells with 352 flip-flops. The
baseline `tt07-bep-decode` occupies a single 1x1 Tiny Tapeout tile; SALARAS-RX
adds a 24-bit CRC LFSR, a comparator, timing and timeout counters, and a small
commit register.

## Real sky130 signoff (OpenLane, Tiny Tapeout GDS action)

Hardened through `.github/workflows/gds.yaml` (run `37273399910`).

The 1x1 tile is too small for the integrated design: OpenLane placement reported
`GPL-0301 Utilization 105.57% exceeds 100%`. The documented 1x2 fallback was
used.

| Metric | Value |
| --- | --- |
| Tile | 1x2 |
| Die area | 161.0 x 225.76 um = 0.0363 mm^2 |
| Core area | 158.24 x 223.04 um |
| Synthesis cells | 1233 |
| Placed cells | 1671 |
| Magic DRC | 0 violations |
| Setup WNS / TNS | 0.00 / 0.00 (timing met) |
| Worst setup slack | +7.97 ns |
| Worst hold slack | +0.13 ns |
| Power, typical | 1.21 mW |
| Power, fastest | 1.42 mW |
| Power, slowest | 0.95 mW |
| Runtime | 1 m 29 s |

Power split at the typical corner: sequential 61%, clock 33%, combinational 6%.
Gate-level simulation of the netlist passes the cocotb suite (3/3).

## Power considerations

Single clock, pure digital logic, no block RAM, no DSP, and no internal PLL.
The CRC LFSR and comparator are active only while a frame arrives, so switching
activity is minimal when idle. Measured power is pending the OpenLane power
report and Quartus PowerPlay.
