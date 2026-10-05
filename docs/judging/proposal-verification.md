# Proposal Verification Report

Date: 2026-10-05
Proposal: `docs/proposal/salaras-rx-proposal.id.md`
Guidelines: `docs/competition/ketentuan-proposal.md`, `docs/competition/buku-panduan-peruri-chip-hackathon.md`
Ground truth: `sim/RESULTS.md`, `synth/area.md`
Rules: `AGENTS.md`, `VISION.md`

---

## Overall Verdict

**NEEDS REVISION**

No disqualifying structural defects. Three issues require correction before submission: one claims-accuracy discrepancy (formal property count), one missing required content (personal identity details in Lampiran), and one subheading formatting convention not followed throughout.

---

## A. Structure Compliance

| # | Requirement | Status | Note |
|---|---|---|---|
| A1 | Section 1: Ringkasan Ide - present | PASS | Section 1 is present and titled correctly |
| A2 | Section 1: covers masalah | PASS | "Masalah yang Diangkat" present |
| A3 | Section 1: covers solusi | PASS | "Solusi yang Ditawarkan" present |
| A4 | Section 1: covers chip yang dirancang | PASS | "Chip yang Dirancang" present |
| A5 | Section 1: covers target pengguna | PASS | "Target Pengguna" present |
| A6 | Section 1: covers dampak | PASS | "Dampak" present |
| A7 | Section 2: Latar Belakang & Rumusan Masalah - present | PASS | Section 2 is present |
| A8 | Section 2: explains why chip is needed | PASS | Serial/RF authentication gap explained |
| A9 | Section 2: explains gap vs existing solutions | PASS | Comparison table with 5 approaches present |
| A10 | Section 3: Proposed Chip Design - present | PASS | Section 3 with subsections 3.1-3.3 present |
| A11 | Section 3: architecture description | PASS | Module-level breakdown in 3.1 |
| A12 | Section 3: block diagram | PASS | Referenced as figure (SVG asset) |
| A13 | Section 3: I/O description | PASS | Inputs and outputs listed in 3.1 |
| A14 | Section 3: processing/memory architecture | PASS | Covered in 3.1 |
| A15 | Section 3: power considerations | PASS | Covered in 3.1 |
| A16 | Section 3: RTL approach | PASS | Module names and Verilog-2001 approach stated |
| A17 | Section 3: verification strategy | PASS | cocotb suite, fault injection matrix in 3.3 |
| A18 | Section 3: simulation strategy | PASS | Simulation plan in 3.3 |
| A19 | Section 3: FPGA target | PASS | DE10-Nano named; FPGA resource table present |
| A20 | Section 3: ASIC target | PASS | sky130 via OpenLane named |
| A21 | Section 4: Referensi - present | PASS | Section 4 present with 7 entries |
| A22 | Section 5: Lampiran - present | PASS | Sections Lampiran A through H present |
| A23 | Section 5: rencana bootcamp 3 hari | PASS | Lampiran C covers all 3 days |
| A24 | Section 5: identitas personal tim | FAIL | Lampiran A lists names, expertise, and roles but omits NIM, university, faculty, and program. The handbook requires "identitas personal tim". |
| A25 | Section 5: pembagian peran | PASS | Lampiran A table has role column |

---

## B. Claims Accuracy

Each figure in the proposal is checked against `sim/RESULTS.md` and `synth/area.md`.

| Claim in proposal | Source in proposal | Ground-truth value | Status | Note |
|---|---|---|---|---|
| 108 cycles end-to-end latency | Sec 1, Sec 3.3, Lampiran D | sim/RESULTS.md L3: 108 cycles | PASS | Exact match |
| 107 cycles MAC + freshness | Sec 3.3, Lampiran D | sim/RESULTS.md L2: 107 cycles | PASS | Exact match |
| 33 cycles per SIMON block | Sec 3.3, Lampiran D | sim/RESULTS.md L1: 33 cycles | PASS | Exact match |
| 128/128 single-bit flips rejected | Sec 1, Sec 3.3 | sim/RESULTS.md L2: 128 of 128 rejected | PASS | Exact match |
| False reject 0 (20 clean frames) | Sec 1, Sec 3.3 | sim/RESULTS.md L2: false reject 0, 20 clean frames accepted | PASS | Exact match |
| Die 0.0756 mm2 (2x2 tile) | Sec 3.2 | synth/area.md 2x2: 334.88 x 225.76 um = 0.0756 mm^2 | PASS | Exact match |
| 2354 cells (2x2 tile) | Sec 3.2 | synth/area.md 2x2: synthesis cells 2354 | PASS | Exact match |
| Power 1.87 mW typical (2x2) | Sec 3.2 | synth/area.md 2x2: power typical 1.87 mW | PASS | Exact match |
| RF lampiran: die 0.0363 mm2, 1.21 mW (1x2) | Sec 1, Sec 3.2 | synth/area.md 1x2: 0.0363 mm^2, 1.21 mW | PASS | Exact match |
| "Lima properti formal lolos" (5 formal properties) | Sec 1, Sec 3.3 | synth/formal/: 6 .sby files, each with 1 assert = 6 properties | FAIL | The repo has 6 formal properties (simon32_64, l1_framing, l2_integrity, l3_commit, auth_top, auth_data_integrity). The proposal claims 5. The sixth (auth_data_integrity.sby) is present in the formal directory and run by `make formal`. The claim must be corrected to 6, or the basis for "5" must be documented. |
| FPGA: "sekitar 360 LUT-setara" | Sec 3.2 | synth/area.md Tier A link: 360 Cyclone V LUTs | PASS | Matches the Tier A link estimate row |
| FPGA: 500 flip-flops | Sec 3.2 | synth/area.md Tier A link: 500 flip-flops | PASS | Exact match |

---

## C. Overclaims Audit (AGENTS.md and VISION.md Must-Not-Claim)

| Rule | Status | Note |
|---|---|---|
| No crypto proof of security | PASS | Lampiran G explicitly states: "Tidak ada klaim kriptografis penuh; tag 32 bit memberi peluang forgery sekitar 2 pangkat -32." |
| No real-frame RF detection rate | PASS | Sec 2 and Lampiran F explicitly frame RF as "bukti kelas kerentanan, bukan jalur integritas kami yang sudah terpecahkan." No detection-rate number is given for RF. |
| No serial link result before Tier B | PASS | No serial link throughput or end-to-end serial result is claimed. The description of the serial loader in project.v is design intent, not a result. |
| No key provisioning claim | PASS | Lampiran G states "Tidak ada provisi kunci". |
| No portability as result before synthesis | WARN | Sec 1 says "target ASIC sky130 dan FPGA DE10-Nano" and Sec 3.2 reports real sky130 ASIC numbers. The FPGA table is labeled "Estimasi FPGA (Yosys, sebelum sintesis Quartus)" - correctly marked as estimate. Sec 3.3 S2 is labeled "rencana". The warning is that the phrasing "IP digital murni berukuran kecil dengan satu clock untuk cakupan yang dikomit, target ASIC sky130 dan FPGA DE10-Nano" in Sec 1 lists both targets without qualification; a reader could interpret both as achieved. Adding a parenthetical "(ASIC: terukur; FPGA: estimasi)" would remove ambiguity. |
| RF described as problem evidence, not solved path | PASS | Sec 2 uses the required framing: "Kasus RF karena itu menjadi bukti kelas kerentanan, bukan jalur integritas kami yang sudah terpecahkan." |

---

## D. Reference Quality

| Reference | Author | Title | Year | Status | Note |
|---|---|---|---|---|---|
| PERURI handbook | PERURI (org) | "Buku Panduan Peserta PERURI Chip Hackathon 2026" | 2026 (implied, not stated) | WARN | Year not explicitly stated; URL present. This is an institutional document; year can be inferred but should be stated. |
| Kohnen BSc thesis | Kohnen, Z. | "Decoding Manchester coded transmissions in a fully digital ASIC." | 2024 | PASS | Author, title, type, year present |
| Kohnen & Alvarado FSiC | Kohnen, Z. and Alvarado, A. | "Manchester decoder of a home thermostat's wireless protocol." | 2025 | PASS | Two authors, title, venue, year present |
| Beaulieu et al. SIMON/SPECK | Beaulieu, R. et al. | "The SIMON and SPECK Families of Lightweight Block Ciphers." | 2013 (in IACR number) | PASS | Author(s), title, IACR ePrint 2013/404 present; year implicit in ePrint number |
| Tiny Tapeout | Tiny Tapeout (org) | Title not given | Year not given | FAIL | Entry is just "Tiny Tapeout. https://tinytapeout.com/" - no title and no year. Should read: Tiny Tapeout. "Tiny Tapeout Digital Design Reference." https://tinytapeout.com/ 2025. |
| MITRE CWE | MITRE | CWE entries listed | Year not given | FAIL | Entry lists only CWE numbers and the org name; no titles, no year. Each CWE should be cited as: MITRE Corporation. "CWE-354: Improper Validation of Integrity Check Value." cwe.mitre.org, 2024. Alternatively, a single MITRE CWE Database entry with year. |
| Terasic DE10-Nano guide | Terasic | "DE10-Nano - Cyclone V FPGA Guide" | Year not given | WARN | Author (org) and title present; year missing. Should add year, e.g. 2017. |

---

## E. Technical Consistency

| Claim | Actual RTL | Status | Note |
|---|---|---|---|
| Frame: counter 32 + payload 64 + tag 32 | l2_auth.v inputs: counter[31:0], payload[63:0], tag_in[31:0] | PASS | Frame widths match RTL |
| SIMON-32/64: 16-bit words, 32 rounds, 64-bit key | simon32_64.v: kw0-kw3 16-bit regs, x/y 16-bit, key[63:0] input, 32 rounds (i==6'd31 terminal condition) | PASS | RTL confirms 16-bit words, 64-bit key, 32 rounds |
| CBC-MAC: 3 blocks, IV=0, 32-bit tag | l2_auth.v: tag_cbc initialized to 32'd0, blk cycles 0-2 (3 blocks), final tag_cbc compared to tag_lat | PASS | RTL confirms IV=0, 3 blocks, 32-bit tag |
| CWE-354: integrity field not validated | sim/RESULTS.md E1: baseline latches corrupted frames with full=1 | PASS | CWE-354 usage matches measured simulation evidence |
| CWE-345: forgery closed by keyed MAC | sim/RESULTS.md L2: forgery and wrong-key cases rejected | PASS | CWE-345 closure matches measurement |
| CWE-294: replay closed by freshness counter | sim/RESULTS.md L2: replay returns fresh_ok=0, not committed | PASS | CWE-294 closure matches measurement |
| CWE-1264: atomic fail-closed commit | l3_commit_gatekeeper.v + auth_formal.sv: host_full only when auth_ok & fresh_ok | PASS | Formal property confirms atomicity |
| CWE-1245: FSM hardening | l3_commit_gatekeeper has default state in FSM; formal property covers commit gatekeeper | PASS | Consistent with claims |

---

## F. Subheading Formatting

The proposal guidelines and the task require subheadings inside sections to use `**bold**` Markdown formatting. The following inline subheadings are not formatted as bold:

| Location | Subheading text (plain, not bold) |
|---|---|
| Sec 1 | `Masalah yang Diangkat:` |
| Sec 1 | `Solusi yang Ditawarkan:` |
| Sec 1 | `Chip yang Dirancang:` |
| Sec 1 | `Target Pengguna:` |
| Sec 1 | `Hasil Terukur:` |
| Sec 1 | `Dampak:` |
| Sec 2 | `Latar Belakang:` |
| Sec 2 | `Bukti dari Tautan Nyata:` |
| Sec 2 | `Gap terhadap Solusi yang Tersedia:` |
| Sec 2 | `Rumusan Masalah:` |
| Sec 3.1 | `Rincian modul:` |
| Sec 3.1 | `Antarmuka:` |
| Sec 3.1 | `Arsitektur Pemrosesan dan Memori:` |
| Sec 3.1 | `Konsumsi Daya:` |
| Sec 3.2 | `Estimasi FPGA (Yosys, sebelum sintesis Quartus):` |
| Sec 3.2 | `Perangkat Lunak dan Tools:` |
| Sec 3.3 | `Simulasi RTL (S1, terukur):` |
| Sec 3.3 | `Uji Hardware Board FPGA DE10-Nano (S2, rencana):` |
| Sec 3.3 | `Metrik Keberhasilan Target:` |

All of the above should be rendered as `**Masalah yang Diangkat:**` etc.

---

## Critical Issues (must fix before submission)

| # | Item | Location | Required action |
|---|---|---|---|
| C1 | Formal property count is wrong | Sec 1, Sec 3.3 | Proposal states "Lima properti formal lolos" (5). The repo has 6 .sby files with 6 assert properties (simon32_64, l1_framing, l2_integrity, l3_commit, auth_top, auth_data_integrity). Change "Lima" to the correct count, or if auth_data_integrity is intentionally excluded from the count (it is non-blocking in CI), document that explicitly and confirm the other 5 all pass. |
| C2 | Identitas personal tim incomplete | Lampiran A | The handbook requires "identitas personal tim". The current table has only name, expertise, and role. Add NIM/NIP, institution, faculty, and study program for each team member and the supervisor. |
| C3 | References: Tiny Tapeout and MITRE CWE missing title and year | Sec 4 | Tiny Tapeout reference lacks title and year. MITRE reference lacks titles and year. Both must be corrected to include the required fields (author, title, year). |

---

## Minor Issues (should fix)

| # | Item | Location | Recommended action |
|---|---|---|---|
| M1 | All inline subheadings not bold | Sec 1, 2, 3.1, 3.2, 3.3 | Reformat all 19 listed subheadings as `**...**` |
| M2 | PERURI handbook reference missing explicit year | Sec 4 | Add "2026" to the entry |
| M3 | Terasic reference missing year | Sec 4 | Add year (2017 or per actual publication date) |
| M4 | ASIC vs FPGA target ambiguity in Sec 1 | Sec 1 | In "target ASIC sky130 dan FPGA DE10-Nano", add parenthetical "(ASIC: terukur; FPGA: estimasi)" to be consistent with Sec 3.2 labeling |
| M5 | Handbook names FPGA board "DE1-Nano" but proposal uses "DE10-Nano" | Sec 3.2, Lampiran H | The URL in both handbook versions resolves to the same page. The ketentuan-proposal.md (the document version in docs/competition/) uses "DE10-Nano" which matches the proposal. No change required to the proposal itself, but note the discrepancy if judges flag it. |

---

## Confirmed Correct Items

- All simulation numbers (latency, bit-flip rejection, false reject rate) match sim/RESULTS.md exactly.
- All ASIC numbers (die area, cell count, power) match synth/area.md exactly.
- RF appendix figures (0.0363 mm2, 1.21 mW) match synth/area.md 1x2 row exactly.
- FPGA resource estimate (360 LUT, 500 FF) matches synth/area.md Tier A link estimate.
- RF problem evidence framing is correct and consistent with AGENTS.md and VISION.md must-not-claim rules.
- No crypto proof of security is claimed.
- No serial link result is claimed.
- No key provisioning claim is made.
- CBC-MAC parameters (IV=0, 3 blocks, 32-bit tag, 64-bit key) are consistent with RTL.
- SIMON-32/64 parameters (16-bit words, 32 rounds, 64-bit key) are consistent with RTL.
- CWE numbers are used correctly for the described vulnerability classes.
- All 5 required structural sections are present.
- Bootcamp plan covers all 3 days with concrete deliverables.
- Limitations section (Lampiran G) is present and accurate.
