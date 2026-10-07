# Failure Mode and Effects Analysis

Hardware-native FMEA for the TRI-ARGA authenticated ingress boundary (Tier A) and its secure serial link (Tier B).
Scope: `simon32_64.v`, `l2_auth.v`, `l3_commit_gatekeeper.v`, `boundary_top.v`, `l1_serial_loader.v`, `project.v`, and the Tier B link (`link_enc_8b10b.v`, `link_dec_10b8b.v`, `l1_link_framing.v`, `link_tx.v`, `link_rx.v`, `link_top.v`, `project_link.v`).

**Severity scale:** 10 = safety critical; 7-9 = security breach; 4-6 = functional error; 1-3 = minor.

**Occurrence scale:** 10 = near certain in field use; 7-9 = likely; 4-6 = occasional; 1-3 = rare.

**Detectability scale:** 10 = undetectable by any current method; 7-9 = hard to detect; 4-6 = detectable with effort; 1-3 = easily detected.

**RPN = Severity x Occurrence x Detectability.** Lower is better.

Table is sorted by RPN descending.

---

| ID | Component | Failure Mode | Effect | Severity | Cause | Detection Method | Mitigation | Detectability | Occurrence | RPN | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FM-05 | Counter register | TOCTOU: data committed is different from data authenticated (Bug 1, fixed) | A forged or modified payload reaches the host with `host_full=1` despite failing MAC; fail-closed invariant violated | 9 | The commit latch sampled registered MAC result on the same clock edge that produced it, so the commit could use a stale decision | Regression test in `test_auth_top.py`; formal property `host_full -> mac_verified AND fresh_ok` | Fixed: `l3_commit_gatekeeper` samples `mac_ok` and `fresh_ok` one cycle after they are stable; commit latency is 1 cycle after verification | 2 | 2 | 36 | CLOSED |
| FM-04 | Key register | Key loaded from frame path instead of key-load path (Bug 2, fixed) | Attacker-supplied frame data overwrites the secret key; all subsequent MACs use the attacker key | 9 | Pin mux in `project.v` used `frame_shift_bit` for key shift instead of `key_shift_bit` when `key_mode=1` | `test_project.py` test `test_second_key_load_ignored`; `test_key_then_clean_frame` fails if key is corrupted | Fixed: `project.v` gates key-shift path on `key_mode` control bit; key is locked after first load (`key_loaded` latch) | 2 | 2 | 36 | CLOSED |
| FM-08 | Tiny Tapeout wrapper | Frame accepted before key is loaded | An unauthenticated frame (MAC verified against key=0 or undefined) is committed to the host | 8 | No `key_loaded` guard in the commit path; reset state of key register is all-zeros | `test_project.py` test `test_frame_before_key_ignored`: sends a valid-tagged frame before any key shift and checks `host_full=0, fault=0` | `project.v` holds `mac_enable` low until `key_loaded` is set; L2 does not start until key is ready | 2 | 3 | 48 | MITIGATED |
| FM-03 | L3 commit | `host_full` raised on authentication failure (fail-closed invariant breach) | Forged or replayed frame appears valid to host; security boundary defeated | 9 | Missing or incorrect guard on `host_full`: raised unconditionally or on wrong signal | Formal property `host_full -> mac_ok AND fresh_ok` checked by SymbiYosys (`synth/formal/l3_commit_core.sby`); L3 integration test `test_auth_top.py` case `Forgery` | `l3_commit_gatekeeper` raises `host_full` only when both `mac_ok` and `fresh_ok` are asserted; verified by the committed-core formal property | 1 | 2 | 18 | MITIGATED |
| FM-10 | Counter freshness | Equal counter accepted: off-by-one in `>` vs `>=` comparison | A replay of the most recent frame is accepted; replay resistance (CWE-294) broken for the last accepted counter | 7 | Comparator uses `>=` (greater-than-or-equal) instead of `>` (strictly greater); boundary condition off by one | `test_l2_auth.py` test `test_replay_and_stale`: sends same counter twice, expects `fresh_ok=0` on second send | `l2_auth.v` implements strict `counter_rx > counter_last`; regression test covers the equal case explicitly | 2 | 3 | 42 | MITIGATED |
| FM-02 | L3 commit | Fault not sticky: `fault` cleared without `fault_ack` | Host misses a fault signal; a rejected frame may be silently dropped with no indication to the host | 6 | `fault` register is reset on every clock or on any next frame start rather than on `fault_ack` | Formal property `fault -> held until fault_ack` checked by SymbiYosys; `test_auth_top.py` case `Sticky fault` | `l3_commit_gatekeeper` implements a set-reset latch: `fault` sets on rejection, clears only on `fault_ack` pulse | 1 | 2 | 12 | MITIGATED |
| FM-09 | CBC-MAC | IV not zeroed on new frame start | Second and subsequent frames use the previous frame's final ciphertext block as IV; MAC is correlated across frames and a forgery may succeed by exploiting the residue | 8 | `iv_reg` not cleared when `frame_start` is asserted; state machine skips reset branch | `test_l2_auth.py` consistency check: 20 clean frames all accepted with distinct MACs; `test_clean_and_false_reject` checks no cross-frame correlation | `l2_auth.v` resets `iv_reg` to zero at the start of each new frame (on `frame_start` assertion) | 2 | 2 | 32 | MITIGATED |
| FM-06 | Frame shift register | Bit count overflow: bit counter wraps to wrong state | Shift register accepts a frame with too few or too many bits; MAC is computed over partial or overlapping data | 6 | Bit counter is too narrow (e.g., 7-bit counter for a 128-bit frame); overflow alias causes premature `frame_done` | Integration test `test_project.py`: frame is exactly 128 bits, checks `done` fires after full shift; boundary test checks no early `done` | Bit counter is sized to cover 128-bit frame (8-bit counter minimum); counter width is verified in RTL review | 3 | 2 | 36 | MITIGATED |
| FM-01 | L2 SIMON cipher | Stuck in WAIT state: FSM does not return to IDLE after block computation | Authentication never completes; `mac_done` is never asserted; `l2_auth` stalls indefinitely; `host_full` is never raised | 5 | Round counter not decrementing; missing transition out of WAIT on `round_done`; incomplete FSM default branch | cocotb timeout: `test_simon.py` asserts `done` within 40 cycles per block; `test_l2_auth.py` global timeout of 512 cycles per frame | `simon32_64.v` uses a 5-bit round counter (0-31) with a direct `round == 31` termination condition; FSM has explicit default transition to IDLE | 2 | 2 | 20 | MITIGATED |
| FM-07 | Clock | Metastability on asynchronous reset release | Flip-flops in different logic cones capture different reset release edges; FSM enters an inconsistent initial state; early spurious outputs possible | 6 | `rst_n` released asynchronously without a synchronizer; setup-time violation on the rising edge of `rst_n` | Testbench uses synchronous reset sequence: `rst_n` deasserted on a rising clock edge after 4-cycle hold; cocotb reset helper `_reset()` enforces this | Single-clock design uses synchronous reset in all flip-flops; testbench `_reset()` in `test_project.py` holds reset for 4 cycles then releases on rising edge | 3 | 2 | 36 | MITIGATED |

---

## Tier B link failure modes

| ID | Component | Failure Mode | Effect | Severity | Cause | Detection / Mitigation | Detectability | Occurrence | RPN | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FM-11 | `l1_link_framing` | Word lock lost or never acquired | Frames are never assembled; no commit | 5 | No comma in the stream, or a stalled line | Timeout counter raises a sticky fault and drops `word_lock`; formal `link_framing`; `test_link_framing.py` | 2 | 3 | 30 | MITIGATED |
| FM-12 | `link_dec_10b8b` | Invalid 10b code or running-disparity error | Corrupted symbol; wrong frame data | 7 | Line error or an illegal code word | Decoder flags `code_error` and `disp_error`; `link_rx` raises a link fault; `test_link_codec.py` | 2 | 3 | 42 | MITIGATED |
| FM-13 | `link_rx` | Frame assembled from wrongly aligned symbols | Wrong `counter`/`payload`/`tag`; MAC fails closed | 7 | Word misalignment after a lock glitch | Comma realignment and word lock; a wrong frame fails the MAC and sets `fault` | 3 | 2 | 42 | MITIGATED |
| FM-14 | `link_tx` | Sends an unbalanced or incomplete symbol stream | Decoder disparity or framing error at the receiver | 5 | Encoder state or bit counter error | Running-disparity encoder checked by `test_link_codec.py`; loopback `test_link_top.py` | 2 | 2 | 20 | MITIGATED |

---

## RPN top-5 summary

| Rank | ID | Component | Failure Mode | RPN | Status |
| --- | --- | --- | --- | --- | --- |
| 1 | FM-08 | Tiny Tapeout wrapper | Frame accepted before key loaded | 48 | MITIGATED |
| 2 | FM-10 | Counter freshness | Equal counter accepted (off-by-one `>=` vs `>`) | 42 | MITIGATED |
| 3 | FM-05 | Counter register | TOCTOU: committed data differs from authenticated data | 36 | CLOSED |
| 3 | FM-04 | Key register | Key loaded from frame path | 36 | CLOSED |
| 3 | FM-06 | Frame shift register | Bit count overflow wraps to wrong state | 36 | MITIGATED |
| 3 | FM-07 | Clock | Metastability on async reset release | 36 | MITIGATED |

Items FM-05 and FM-04 are CLOSED because the root-cause bugs were found and fixed before tape-out submission; the fixes are covered by regression tests.
Items FM-08, FM-10, FM-06, and FM-07 are MITIGATED: the design includes a structural guard, but the guard has not been independently proven at the formal level beyond what is noted in the Detection Method column.

---

## Notes on scope

- Key provisioning security (e.g., key loaded over an untrusted bus) is out of scope; see `PLAN.md` section 14.
- Persistent replay counter across power cycles is out of scope.
- Physical side-channel attacks (power analysis, fault injection at the pin level) are out of scope.
- Tier B link failure modes are covered in the table above (framing, word lock, code/disparity, alignment, and transmit balance); Tier C (CDC FIFO) failure modes will be added when that tier is implemented.
