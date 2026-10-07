# PLAN.md - Committed implementation plan

Actionable plan for the committed scope.
Read AGENTS.md for the invariant rules and VISION.md for the strategy, title,
problem statement, threat model, and must-not-claim list.
This plan does not override AGENTS.md.

## 1. Objective

Deliver simulation evidence for a keyed, replay-resistant, fail-closed integrity
engine, enough to put measured results in the proposal.

Committed scope (Tier A):

- A keyed MAC (SIMON-32/64 in fixed-length CBC-MAC mode) with a freshness
  counter.
- Measured authentication behavior: forgery, wrong key, replay, stale counter,
  and bit flips rejected; clean frames accepted.
- A fail-closed atomic commit with a sticky fault and a measured latency.
- Machine-checked invariants for the commit path.
- The RF work (TRI-ARGA) retained as the CWE-354 problem appendix.

Tier A is single clock and does not require the SerDes link or the CDC crossing.
Those are Tier B and Tier C, described at the end.

## 2. Decisions (locked)

- Integrity engine: keyed MAC, SIMON-32/64, fixed-length CBC-MAC, 64-bit key,
  32-bit tag.
- Freshness: 32-bit monotonic counter; reject a counter that is not strictly
  greater than the last accepted.
- Defense level: Level 3 (MAC plus counter). Forgery and replay are in scope.
- Single clock for the committed scope.
- Key loaded by the host into a register; no hardcoded key.
- RF Manchester stays as the CWE-354 appendix.
- Tier B line coding: true 8b/10b with running disparity (RD+/RD-), K-character
  comma framing, and invalid-code error.
- Baseline tables are retained as the seed; coding and framing wrappers are
  rewritten.

## 3. Architecture (Tier A)

    frame_in -> framing validity -> L2 auth -> L3 commit -> host
    counter (32) + payload (64) + tag (32)

- The frame arrives as a block; there is no serial link in Tier A.
- L2 recomputes the CBC-MAC over counter plus payload, compares the tag, then
  checks counter freshness.
- L3 commits atomically and raises a sticky fault on any failure.
- The link and the CDC crossing are added in Tier B and Tier C.

## 4. Frame format

    [ counter (32) ][ payload (64) ][ tag (32) ]

- Total authenticated bits: 96 (counter plus payload), three 32-bit blocks for
  CBC-MAC.
- MAC: SIMON-32/64, fixed-length CBC-MAC, IV 0, 64-bit key, 32-bit tag.
- A START control symbol (K-character comma) and 8b/10b framing are added in
  Tier B.

## 5. RTL modules

Tier A (committed, in the link tree):

| File | Role | CWE |
| ---- | ---- | --- |
| simon32_64.v | serialized SIMON block cipher, one round per cycle | - |
| l2_auth.v | CBC-MAC compute and verify, counter freshness | CWE-354, 345, 294 |
| l3_commit_gatekeeper.v | atomic commit, sticky fault, host ack | CWE-1264 |
| boundary_top.v | integration of L2 and L3 | - |
| project.v | Tiny Tapeout wrapper, key-load and status pins | - |

Tier B (built on `Security-V3-Serdes`) adds `link_enc_8b10b.v`,
`link_dec_10b8b.v`, `l1_link_framing.v`, `link_tx.v`, `link_rx.v`, `link_top.v`,
and `project_link.v` (`tt_um_link`). Tier C adds the vendored `cdc_fifo.v`.

## 6. Disk layout

    src/                 the submitted link design (Tier A top). Tiny Tapeout
                         requires the top sources in ./src, so the link is the
                         root tree.
    appendix/rf/         the Manchester/RF design and evidence, with its own
                         project.v, info.yaml, config.tcl, user_config.tcl.

Planned move, to run as the first Tier A implementation step: relocate the RF
modules (`sync2`, `edge_detect`, `state_machine`, `data_validate`,
`frame_capture`, `l1_framing_validator`, `l2_integrity_verify`,
`l3_commit_gatekeeper`, `salaras_rx_top`, `project`, `defs.svh`) to
`appendix/rf/src/`, and add `appendix/rf/info.yaml`. The root `src/` then holds
the link design. The move is deferred until the link top exists, so lint, synth,
test, formal, and the FPGA build stay green in the meantime.

## 7. Clock contract

One clock source of truth per design. Every testbench derives its period from the
design constants; no hardcoded periods in timing tests.

| Design | Clock(s) | Sim period | FPGA | OpenLane | info.yaml |
| ------ | -------- | ---------- | ---- | -------- | --------- |
| RF appendix | 20 kHz | 50 us | `CLOCK_50` / 2500 | `CLOCK_PERIOD 50000` | `clock_hz 20000` |
| Link Tier A/B | `clk` 50 MHz | 20 ns | `CLOCK_50` | `CLOCK_PERIOD 20` | `clock_hz 50000000` |
| Link Tier C | `clk_link` 50 MHz, `clk_host` about 33 MHz | 20 ns and 30 ns (non-integer) | `CLOCK_50` plus divided or PLL host clock | 20 ns (link) | `clk_host` on a `uio` input |

Constants: `SRX_RF_CLK_HZ` and `SRX_HALF_PERIOD` for the RF appendix;
`SLINK_CLK_HZ` and, for Tier C, `SLINK_HOST_CLK_HZ` for the link.

Rules:

- The RF appendix stays at 20 kHz everywhere: captures, replay, FPGA divider,
  OpenLane, and the RF unit test.
- The link uses one clock in Tier A and B, and two independent non-integer
  clocks in Tier C, to stress the CDC.
- The two designs never share a top, a config, or a clock.

## 8. Latency measurement

Latency is a required result.

Reference events:

- `frame_start`: the frame block is presented.
- `mac_verified`: MAC compare and counter freshness resolved.
- `host_full`: committed result visible.
- `host_data_valid`: data readable with `host_full` high.

Per-stage budget (estimates, replaced by measured values):

| Stage | Estimate |
| ----- | -------- |
| L2 MAC verify | about 96 cycles (three blocks, one round per cycle) plus overhead |
| Counter freshness | 1 to 2 cycles |
| L3 commit | 1 to 2 cycles |
| Host visibility | 0 to 1 cycle |

Method: a counter measures from `frame_start` to `mac_verified` and to
`host_full`; cocotb timestamps the events, converts to time with the configured
clock, and emits a per-stage and total table. Cycles are primary; microseconds
are derived at the configured clock. A CI assertion checks the end-to-end
latency against a chosen bound. The serialized and partially unrolled SIMON
variants are both measured for the area and latency tradeoff.

## 9. Success matrix (Tier A)

| Metric | Stimulus | Target |
| ------ | -------- | ------ |
| Clean frame accepted | valid counter, payload, MAC | full=1, fault=0 |
| False reject | many clean frames | 0 percent |
| Forgery rejected | modify payload, keep tag | 100 percent |
| Wrong key rejected | wrong key | 100 percent |
| Replay rejected | resend same counter | 100 percent |
| Stale counter rejected | counter minus one | 100 percent |
| Fresh counter accepted | counter plus one | 100 percent |
| Bit-flip detection | flip each bit | about 1 minus 2^-32 |
| MAC latency | measure | per block and per frame, cycles |
| Commit latency | measure | cycles |
| End-to-end latency | measure | cycles and microseconds |
| Throughput | measure | frames per second |
| Same boundary core reused across two profiles (synthetic CRC and MAC) with identical commit semantics | two-profile testbench | pass |
| Area | synthesis | estimate, then OpenLane |

Every row maps to one test case.

## 10. Testbenches

| TB | Demonstrates |
| -- | ------------ |
| test/test_simon.py | SIMON block and CBC-MAC vectors against a Python reference |
| test/test_l2_auth.py | forgery, wrong key, replay, stale counter, bit flips, false reject |
| test/test_auth_top.py | fail-closed commit, sticky fault, commit and end-to-end latency |
| test/test_rf_boundary.py | RF appendix still passes |

## 11. Execution order

1. Implement simon32_64.v and validate block and CBC-MAC vectors against an
   independent Python reference written from the SIMON specification.
2. Implement l2_auth.v; run the success matrix for forgery, wrong key, replay,
   stale counter, and bit flips.
3. Adapt l3_commit_gatekeeper.v for the authenticated frame; keep it fail-closed
   and avoid the stale-decision pattern (do not sample a registered result on
   the same edge that produces it).
4. Integrate boundary_top.v and add the commit and latency tests.
5. Add the two-profile portability testbench (synthetic CRC plus MAC).
6. Extend synth/formal: host_full implies MAC-verified and fresh, and
   fail-closed.
7. Estimate area with Yosys.
8. Emit the latency table and waveform figures; assemble the Tier A evidence.
9. Update the proposal (id and en) with the Level 3 threat table, CWE map,
   success matrix, and measured latency; keep the RF appendix; rebuild PDFs.
10. Perform the disk move (`appendix/rf/` and root link tree) and retarget
    info.yaml; the link top must build first.
11. Update AGENTS.md and the project-workflow skill with the new modules and the Tier A
    scope, and keep CI green.
12. Tier B (built on `Security-V3-Serdes`): the boundary is attached to an
    a self-contained 8b/10b serial link with running disparity, K-character comma
    framing, word lock, and invalid-code error, and the single-clock loopback
    through the Tier A core passes (clean commit, forgery, replay, line error).
    This earns the secure serial link headline in simulation.

Dates: proposal deadline 8 October 2026; bootcamp 18 to 20 October 2026.

## 12. Verification gates

- make lint
- make synth-check
- make area
- make formal
- make test
- make sim
- Run the verify helper before every commit.
- Keep CI green. Never weaken or delete evidence to make a check pass.

## 13. Invariants

- Fail-closed: on any authentication or freshness failure, hold host_full low and
  raise a sticky fault until acknowledged.
- No detection, security, or latency number is claimed without a measured test.
- Keep the headline as secure communication, not a crypto accelerator, so the
  work stays in Area 04.
- Document each stage as measured or estimated; label estimates as estimates.
- Keep one clock source of truth per design.

## 14. Out of scope and residual

- Key provisioning and secure key storage.
- Persistent replay counter across power cycles.
- Physical and side-channel key extraction.
- Host software integrity after data has crossed the boundary.
- SerDes link, CDC crossing, real hardening, and FPGA (Tier B and Tier C).

## 15. Open items

- CHOOSE the SIMON unroll degree, if any, after the latency and area tradeoff is
  measured.
- CHOOSE the CI latency bound once a baseline is measured.
- CONFIRM the Python reference is written from the SIMON specification.
- CONFIRM the `clk_host` rate for Tier C (about 33 MHz proposed).

## 16. Risks

- SIMON is our own implementation and must be vector-validated; the linked
  hackathon resource is a Makerchip template, not a drop-in core.
- Area grows with the MAC; confirm with Yosys, and revisit unrolling only if
  latency demands it.
- Mixed Verilog and SystemVerilog; ensure Yosys and OpenLane read both.
- The disk move must not break the RF sim or FPGA flow; perform it only once the
  link top builds.
