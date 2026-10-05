# Simulation evidence

Tier 1 evidence, reproducible with `make -C sim`, `make -C sim boundary`, and
`make simon`. Values are captured from the cocotb runs and the waveform figures
in `out/`.

## L1 - SIMON-32/64 MAC latency (Tier A, M1)

SIMON-32/64 is implemented as a serialized block cipher, one round per cycle,
and validated against an independent Python reference (`test/simon_ref.py`) that
matches the published SIMON-32/64 vector (key `1918111009080100`, plaintext
`65656877`, ciphertext `C69BE9BB`).

| Metric | Value |
| --- | --- |
| Block vectors validated | 49 (1 published plus 48 random) |
| Rounds per block | 32 |
| Block latency (start to done) | 33 clock cycles |
| CBC-MAC | matches the reference over 3 blocks |

The measured 33 cycles equals 32 rounds plus one pipeline cycle. This is the
dominant term in the Tier A latency budget; the commit adds 1 to 2 cycles and
the host visibility adds 0 to 1.

## L2 - Authentication and freshness (Tier A, M2)

`l2_auth` runs a CBC-MAC over counter plus payload (three blocks) and a strict
freshness counter. Measured with `make l2`.

| Case | Result |
| --- | --- |
| 20 clean frames (increasing counters) | all accepted, false reject 0 |
| Forgery (payload modified, tag kept) | rejected |
| Wrong key | rejected |
| Replay (same counter) | authenticated but `fresh_ok=0`, not committed |
| Stale counter | `fresh_ok=0` |
| Fresh counter | accepted |
| Single-bit flips (32 counter, 64 payload, 32 tag) | 128 of 128 rejected |
| End-to-end MAC plus freshness latency | 107 clock cycles |

The measured 107 cycles matches the estimate (three blocks at 33 cycles each
plus FSM overhead). This is the measured Tier A latency for the authentication
path; the commit and host visibility stages are added in M3.

## L3 - Integrated authentication and commit (Tier A, M3)

`salaras_auth_top` wires L2 into the shared `l3_commit_gatekeeper`. Measured with
`make auth`.

| Case | Result |
| --- | --- |
| Clean commit | `host_full=1`, `fault=0`, committed `{counter, payload}` matches |
| Forgery | `host_full=0`, `fault=1` |
| Replay | authenticated but `fresh_ok=0`, `host_full=0`, `fault=1` |
| Sticky fault | holds until `fault_ack` |
| Commit latency | 1 cycle |
| End-to-end latency (start to `host_full`) | 108 cycles |
| Two profiles | the same commit core is used for a synthetic CRC profile and the MAC profile |

The Tier A end-to-end latency is 108 cycles: 107 for MAC plus freshness, plus 1
for the commit. The RF appendix boundary commit was also 1 cycle, so the shared
gate adds the same single cycle.

## E1 - Baseline accepts corrupted frames (CWE-354)

Stimulus drives the baseline `tt07-bep-decode` `serial_decode` at its serial
interface with a 192-bit frame.

| Case | `full` | Decoded result |
| --- | --- | --- |
| Clean frame | 1 | id `0x03391F89`, room `0x00F6`, set `0x00B5`, state `0x00`, tail `0x94AE16` |
| Payload bit flipped | 1 | id becomes `0x07391F89` (corrupted), tail unchanged |
| Integrity field bit flipped | 1 | tail becomes `0x14AE16` (corrupted), payload unchanged |

The baseline has no error output and never checks the integrity field, so both
corrupted frames are latched as valid. Figure: `out/baseline_vulnerability.png`.

## E2 - SALARAS-RX fail-closed boundary

Stimulus drives L1 (timing/timeout) and L3 (atomic commit) directly, with
`crc_ok` standing in for L2.

| Case | Result |
| --- | --- |
| Clean frame, `crc_ok=1` | `host_full=1`, `fault=0`, committed data matches |
| Integrity fail, `crc_ok=0` | `host_full=0`, `fault=1` |
| Fault hold | `fault` stays high until `fault_ack` |
| Timing violation (half-period 1 tick) | `timing_fault=1`, `framing_ok=0`, frame rejected |
| No-edge timeout (4096 cycles) | `timeout_fault=1`, `framing_ok=0` |
| Commit latency | 1 clock cycle |

Figure: `out/boundary_commit_reject.png` and `out/boundary_timeout.png`.

## Not yet covered

End-to-end detection rate on real captures requires the confirmed integrity
field parameters (Phase S2). Until then, `crc_ok` is driven directly and no
detection-rate number is claimed.

## Integrity field status

The field is affine over GF(2) (a one-bit payload flip gives a constant tail
delta), but no standard CRC-24 matched. The exhaustive search is in
`tools/crc_reveng.py` and the recoverability analysis in
`tools/affine_field.py`; see `tools/README.md`.

The baseline author reports the same: the field is undocumented, no CRC matched
during his testing, and it is suspected to be an error-correcting code up to
24 bits (Kohnen, BSc Thesis, 2024). With 7 pairs the delta rank is only 5, so
the full map is not recoverable; L2 stays parameterized and the proposal keeps
the affine-reconstruction fallback.
