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
| Registers / flip-flops | 360 | 415,000 |
| Block RAM (M10K) | 0 (no buffer) | 5,570 Kbits |
| DSP blocks | 0 (LFSR-based CRC) | 112 DSP |

Quartus Fitter numbers replace these once the integrated design is synthesized.

## ASIC (sky130) estimate

Technology-independent gate count is 1353 cells with 360 flip-flops. The
baseline `tt07-bep-decode` occupies a single 1x1 Tiny Tapeout tile; SALARAS-RX
adds a 24-bit CRC LFSR, a comparator, timing and timeout counters, and a small
commit register. The target is a 1x1 tile with a 1x2 fallback. Real area,
timing, and power come from OpenLane through the Tiny Tapeout GDS action
(Phase E).

## Power considerations

Single clock, pure digital logic, no block RAM, no DSP, and no internal PLL.
The CRC LFSR and comparator are active only while a frame arrives, so switching
activity is minimal when idle. Measured power is pending the OpenLane power
report and Quartus PowerPlay.
