# Synthesis area estimate

Preliminary, technology-independent estimate of the TRI-ARGA top
(`tt_um_auth_boundary`). Reproduce with `make area`; raw Yosys logs
are written to `synth/area/` (not tracked).

- Revision: `main` (Tier A core and Tier B serial link)
- RTL: `src/` (Tier A core plus the Tier B 8b/10b link)
- Tool: Yosys 0.52

## Method

- `synth` then `flatten` gives the technology-independent gate count.
- `synth_intel_alm -family cyclonev` maps to the Intel ALM model (MISTRAL
  primitives) as a Cyclone V proxy. This is not a substitute for a Quartus
  Fitter report.

## Generic synthesis

| Metric | Value |
| --- | --- |
| Cells | 1670 |
| Registers (DFF) | 636 |
| Combinational cells | 1029 |

## Cyclone V ALM mapping (proxy)

| Resource | Value |
| --- | --- |
| Mapped cells | 1134 |
| Registers (MISTRAL_FF) | 636 |
| LUTs (ALUT2/3/4/5/6) | 353 |
| Arithmetic LUTs (ALUT_ARITH) | 95 |

## Cyclone V device capacity (5CSEBA6U23I7)

Source: Intel Cyclone V Product Table and Device Overview (CV-51001).

| Resource | Capacity |
| --- | --- |
| ALMs | 41,910 |
| Registers (4 per ALM) | 166,036 |
| Block RAM (M10K) | 5,570 Kbits |
| DSP blocks | 112 |

Measured results for the Tier B link (`tt_um_link`) and the FPGA loopback
wrapper (421 ALM, 1029 registers, 0 M10K, 0 DSP) are in the sky130 signoff
below and `docs/design/quartus-report.md`.

### Real sky130 signoff (core, 2x2)

Hardened through `.github/workflows/gds.yaml` on the core
(`tt_um_auth_boundary`, the L1 + L2 + L3 wrapper). The 1x2 tile does not fit
(GPL-0302 at density 0.6 and 0.8), so a 2x2 tile is used.

Signoff run `37504588955` at commit `00fc423` (OpenLane 2024.04.22, sky130A).

| Metric | Value |
| --- | --- |
| Tile | 2x2 |
| Die area | 334.88 x 225.76 um = 0.0756 mm^2 |
| Synthesis cells | 2511 |
| Magic DRC | 0 violations |
| LVS | 0 errors |
| Antenna | 0 violations |
| Setup WNS / TNS | 0.00 / 0.00 (timing met) |
| Worst setup slack | +10.87 ns |
| Worst hold slack | +0.12 ns |
| Power, typical | 2.10 mW |
| Power, fastest | 2.47 mW |
| Power, slowest | 1.65 mW |

### Real sky130 signoff (serial link, Tier B, 2x2)

Hardened through `.github/workflows/gds.yaml` on the Tier B serial link
(`tt_um_link`): the Tier A core behind the 8b/10b link.

Signoff run `37511052813` at commit `9bbb2e0`.

| Metric | Value |
| --- | --- |
| Tile | 2x2 |
| Die area | 334.88 x 225.76 um = 0.0756 mm^2 |
| Synthesis cells | 3220 |
| Magic DRC | 0 violations |
| LVS | 0 errors |
| Antenna | 2 violations (u_l2.u_simon.x[3], u_rx.frame_sr[30]) |
| Setup WNS / TNS | 0.00 / 0.00 (timing met) |
| Worst setup slack | +9.28 ns |
| Worst hold slack | +0.11 ns |
| Power, typical | 3.61 mW |
| Power, fastest | 4.23 mW |
| Power, slowest | 2.84 mW |

## ASIC (sky130) estimate

The committed design is the SIMON-32/64 CBC-MAC boundary (`simon32_64`,
`l2_auth`, `l3_commit_gatekeeper`, `boundary_top`) plus the Tier B 8b/10b link.
The measured sky130 signoff for each is in the sections below; the RF appendix
result is kept separate.

## Real sky130 signoff (RF appendix, 1x2)

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
The MAC cipher is active only while a frame arrives, so switching activity is
minimal when idle. Measured power is reported in the signoff tables above and in
`docs/design/quartus-report.md`.
