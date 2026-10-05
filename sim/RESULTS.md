# Simulation evidence

Tier 1 evidence, reproducible with `make -C sim` and `make -C sim boundary`.
Values are captured from the cocotb runs and the waveform figures in `out/`.

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

End-to-end detection rate on real captures requires the confirmed CRC-24
parameters (Phase S2). Until then, `crc_ok` is driven directly and no
detection-rate number is claimed.
