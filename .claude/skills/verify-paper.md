---
name: verify-paper
description: Verify the TRI-ARGA proposal against PERURI Chip Hackathon 2026 guidelines and check for overclaims, missing sections, and reference quality. Run when asked to check the proposal, review references, or audit claims.
---

Audit the TRI-ARGA competition proposal for the PERURI Chip Hackathon 2026, Area 04 (deadline 8 Oktober 2026).
Work through all eight checks, then produce a summary table and overall verdict.

## Check 1 - Structure: 5 required sections

Read `docs/proposal/proposal.id.md`.
Verify all five sections from `docs/competition/ketentuan-proposal.md` are present with substantive content:
1. Ringkasan Ide / Executive Summary
2. Latar Belakang & Rumusan Masalah
3. Proposed Chip Design (must include: architecture, block diagram, I/O, verification strategy, simulation strategy, FPGA/ASIC target)
4. Referensi
5. Lampiran (must include: rencana bootcamp, identitas personal tim dengan nama/keahlian/peran, pembagian peran)

PASS: all present with content. WARN: section exists but thin. FAIL: section missing.

## Check 2 - Claims audit: must-not-claim

Search for violations of the AGENTS.md / VISION.md rules:
- No cryptographic proof of security (tag 32 bit = ~2^-32 forgery probability, not "cryptographically secure")
- No real-frame RF detection rate (RF is problem evidence only, field is unsolved ECC)
- No serial link result beyond the Tier B simulation loopback; no CDC result before Tier C is built
- No key provisioning, persistent counter, or side-channel resistance
- No "works with any protocol" - say "reusable core demonstrated on RF appendix plus one synthetic profile"
- No target portability as result before synthesis
- RF must be "problem evidence" not a solved path

Quote any suspicious sentence and state which rule it may violate. FAIL for confirmed overclaim, WARN for borderline.

## Check 3 - Reference quality

For each reference in the Referensi section:
- Must have: author name(s), title, year - FAIL if any missing
- URL quality: academic/technical source = OK, bare blog/broken link = WARN
- Cross-reference: flag references cited in body but not in list, or list entries not cited in body

## Check 4 - Technical accuracy

Cross-check against sim/RESULTS.md and synth/area.md (ground truth):

| Claim | Expected |
| --- | --- |
| End-to-end latency | 108 cycles |
| Bit-flip rejection | 128/128 |
| False reject (20 frames) | 0 |
| sky130 RF die area (1x2) | 0.0363 mm^2 |
| sky130 core die area (2x2) | 0.0756 mm^2 |
| Core typical power | 2.10 mW |
| Tier B link typical power | 3.61 mW (2 antenna) |
| FPGA Tier B loopback wrapper | 421 ALM, 1029 FF, Fmax 97.9 MHz, 426.2 mW |
| Formal properties passing | 9 jobs (5 core, 1 Tier B, 3 RF) |
| DRC violations | 0 |

FAIL for any mismatch. WARN for absent expected numbers.

## Check 5 - Rubric self-score

Score against the 7 official criteria (0-100 each). Flag any below 75 as WARN.

| # | Criterion | Weight | Score | Justification |
| --- | --- | --- | --- | --- |
| 1 | Relevansi Masalah | 15 | | |
| 2 | Kebaruan dan Keunggulan | 15 | | |
| 3 | Kualitas Teknis | 20 | | |
| 4 | Keamanan dan Threat Model | 20 | | |
| 5 | Kelayakan dan Verifikasi | 15 | | |
| 6 | Dampak dan Hilirisasi | 10 | | |
| 7 | Kepatuhan dan Kejelasan | 5 | | |

Report weighted total (sum of score*weight/100).

## Check 6 - Honesty: RF framing and SIMON description

RF: every mention of RF/tt07-bep-decode must frame it as "problem evidence", not a solved path. The integrity field must be described as "undocumented error-correcting code" or equivalent. No detection rate claimed.

SIMON: tag must be described as 32 bits / ~2^-32 forgery probability. Forbidden phrases: "cryptographic proof", "cryptographically secure", "proven secure", "authenticated encryption".

## Check 7 - Bold subheadings

Check that inline subheadings in the proposal use `**bold:**` format, not plain text.
Key patterns to check in proposal.id.md:
`Masalah yang Diangkat:`, `Solusi yang Ditawarkan:`, `Chip yang Dirancang:`, `Target Pengguna:`, `Hasil Terukur:`, `Dampak:`, `Latar Belakang:`, `Bukti dari Tautan Nyata:`, `Rumusan Masalah:`, `Gap terhadap Solusi yang Tersedia:`

Note: the build.mjs pipeline now auto-bolds these patterns at HTML generation time, so this check is for the Markdown source quality.

## Check 8 - English version parity

Read `docs/proposal/proposal.en.md`. Verify same 5 sections exist and key numbers match the Indonesian version. WARN for any discrepancy.

## Output

After all checks:

| # | Check | Result | Notes |
| --- | --- | --- | --- |
| 1 | Structure: 5 required sections | | |
| 2 | Claims audit | | |
| 3 | Reference quality | | |
| 4 | Technical numbers | | |
| 5 | Rubric self-score | | weighted: X/100 |
| 6 | Honesty: RF + SIMON | | |
| 7 | Bold subheadings | | |
| 8 | English parity | | |

List all FAIL and WARN items with quote, location, and recommended fix.
End with one-paragraph overall verdict: ready to submit, or blocking issues remain.
