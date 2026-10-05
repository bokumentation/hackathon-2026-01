---
name: judges
description: Simulate the PERURI Chip Hackathon 2026 jury panel scoring the SALARAS-RX proposal. Run when asked to simulate judges, get jury scores, predict panel scores, or identify weaknesses to fix before submission.
---

Simulate a full jury panel evaluation of the SALARAS-RX proposal for the PERURI Chip Hackathon 2026.
Follow all steps in order and produce the full output in one response.

## Step 1 - Read source documents

Before scoring, read these three files:
1. `docs/proposal/salaras-rx-proposal.id.md` - the main proposal
2. `sim/RESULTS.md` - simulation evidence: SIMON vectors, auth matrix, latency, bit-flip rejection
3. `synth/area.md` - synthesis evidence: Yosys estimates, sky130 signoff 2x2, DRC 0, LVS 0, timing met

Note: the previous SALARAS-SERDES (CRC) simulation scored 77.53/100. The key weakness was CRC being forgeable (CWE-345 not closed). The current design uses keyed SIMON-32/64 MAC which closes that gap.

## Step 2 - Rubric weights

| # | Criterion | Weight |
| --- | --- | --- |
| 1 | Relevansi Masalah | 15 |
| 2 | Kebaruan dan Keunggulan | 15 |
| 3 | Kualitas Teknis dan Arsitektur | 20 |
| 4 | Keamanan dan Threat Model | 20 |
| 5 | Kelayakan dan Verifikasi | 15 |
| 6 | Dampak dan Hilirisasi | 10 |
| 7 | Kepatuhan dan Kejelasan | 5 |

## Step 3 - Five judge personas

Score each criterion (0-100) from each judge's perspective:

**Juri 1 - Pakar keamanan perangkat keras**
Focuses on: threat model completeness, CWE coverage, key strength (64-bit SIMON vs AES), tag size (32-bit = 2^-32 forgery probability), honest scope, no overclaims.
Strengths to credit: CWE-354/345/294/1264 all addressed, formal fail-closed proof, honest 32-bit tag disclosure, RF framed as evidence not solution.
Weaknesses to probe: no hardware key protection, session-only replay resistance, CBC-MAC not authenticated encryption.

**Juri 2 - Pakar RTL dan ASIC**
Focuses on: correct SIMON-32/64 implementation (32 rounds, 16-bit words, Z0 sequence), CBC-MAC correctness (3 blocks, IV=0), Verilog-2001 style, Yosys synthesizability, real sky130 signoff numbers.
Strengths to credit: 49 vector validation, 0 DRC/LVS, WNS +10.79 ns margin, 2354 cells in 2x2 tile.
Weaknesses to probe: no partial unrolling discussed, FPGA numbers are Yosys estimates not Quartus.

**Juri 3 - Pakar sistem dan FPGA**
Focuses on: DE10-Nano prototype feasibility, key-load vs frame-load protocol (SW[0]), 50 MHz clock, SignalTap plan.
Strengths to credit: pinout documented, key-locked flag (LEDR[5]), GPIO protocol specified.
Weaknesses to probe: no Quartus Fitter report yet, FPGA demo is "rencana bootcamp" not done.

**Juri 4 - Juri produk dan hilirisasi**
Focuses on: relevance to Peruri (identity/payment systems), adoption potential, honest product scope, separation of prototype vs product.
Strengths to credit: targets contactless smart card and secure element integrators, honest about no key provisioning / no persistent counter.
Weaknesses to probe: no concrete Peruri use case named, "reusable core" claim needs evidence beyond one synthetic profile.

**Juri 5 - Juri kompetisi dan kepatuhan**
Focuses on: all 5 required sections present, Lampiran completeness (bootcamp plan, identitas tim with NIM, peran), no rule violations.
Strengths to credit: proposal is well-structured, bilingual (ID+EN), has measured evidence table and latency appendix.
Weaknesses to probe: Lampiran A may lack full NIM/NIP/institution details; reference list may be missing year/title for some entries.

## Step 4 - Score table

Fill this table with the scores from each judge persona:

| Criterion | Weight | Juri 1 Keamanan | Juri 2 RTL/ASIC | Juri 3 Sistem/FPGA | Juri 4 Produk | Juri 5 Kepatuhan |
| --- | --- | --- | --- | --- | --- | --- |
| Relevansi Masalah | 15 | | | | | |
| Kebaruan dan Keunggulan | 15 | | | | | |
| Kualitas Teknis | 20 | | | | | |
| Keamanan dan Threat Model | 20 | | | | | |
| Kelayakan dan Verifikasi | 15 | | | | | |
| Dampak dan Hilirisasi | 10 | | | | | |
| Kepatuhan dan Kejelasan | 5 | | | | | |
| **Total tertimbang** | **100** | | | | | |

Compute each judge's weighted total (sum of score*weight/100).
Compute the panel average (mean of 5 weighted totals).

## Step 5 - Top 3 questions per judge

For each judge, list the 3 critical questions they would ask in a Q&A:
- Questions must be specific to SALARAS-RX, not generic
- Questions should probe the actual weaknesses identified in Step 3
- Provide a suggested answer for each question based on what the proposal and evidence can support

## Step 6 - Panel analysis

**Three strongest points** (list with criterion and evidence reference):
- e.g., "Keamanan: keyed MAC closes CWE-345 that CRC left open - evidenced by test_l2_auth.py 128/128 bit flips rejected"

**Three weakest points** (list with criterion and specific gap):
- e.g., "Kelayakan: FPGA numbers are Yosys proxy, not Quartus Fitter - S2 hardware test is planned, not done"

**Comparison to SALARAS-SERDES score (77.53)**:
- Explain the expected delta per criterion
- State the expected direction of change (higher/lower/same) for each criterion
- Give overall panel score estimate and rationale

## Step 7 - Recommendations

For each weakness identified, give one concrete action to take before the 8 Oktober 2026 deadline:
- Must be achievable in the remaining time
- Reference the specific section of the proposal to update
- Specify the exact content to add or change
