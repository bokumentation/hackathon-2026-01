# Threat model

## Assets

- Frame integrity: the host must never observe a corrupt frame as valid.
- Control/data consistency: the `full` flag, bit counter, and latch enable must stay aligned with the shift-register data.

## Trust boundary

The boundary is the handshake between the decoder and the host register file.
Everything before the boundary is untrusted.

## Threats

| ID | Threat | CWE | Mitigation |
| --- | --- | --- | --- |
| T1 | Integrity field received but never verified, so corrupt payloads appear valid | CWE-354 | L2 streaming linear verification before commit |

The 24-bit field is affine over GF(2) but does not match a standard CRC-24, so
L2 is parameterized until the field is reconstructed (`tools/README.md`).
| T2 | Fragile FSM, no timeout, no recovery from unexpected transitions | CWE-1245 | L1 timeout, timing window, default/recovery branch |
| T3 | Glitch or jitter causes control/data desynchronization | CWE-1264 | L3 atomic commit of `full` and latch enable |

## Attack surface

- The `digital_in` pin.
- The Manchester half-period timing.
- The `full` handshake signal.
- The `uo_out` data bus.

## Fail-closed behavior

On any verification failure the boundary holds `full` low and raises `fault`.
The `fault` flag is sticky until acknowledged by the host.

## Out of scope

Physical and side-channel attacks, certified secure element requirements, and
software integrity after data has crossed the boundary.
