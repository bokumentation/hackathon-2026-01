# Threat model

Threat model for the committed Tier A authenticated boundary and the Tier B 8b/10b serial link. The archived RF appendix threat model is in `appendix/rf/docs/threat-model-rf.md`.

## Assets

- Frame integrity and authenticity: the host must never observe a corrupt or forged frame as valid.
- Frame freshness: a previously valid frame must not be accepted again within a power session.
- MAC key confidentiality: the key must never cross the untrusted link.

## Trust boundary

- Untrusted: everything arriving from the link, including the front-end (`link_rx`, SerDes, Manchester/RF, UART) and the `counter`, `payload`, and `tag` fields.
- Trusted: the host and the key-loading port. The key is loaded from the host through a separate path and never travels over the link.

## Attacker capability

The attacker can eavesdrop, insert, modify, delete, and replay frames on the link, and can introduce random bit errors. The attacker does not have the key, cannot read internal registers, and does not perform side-channel or physical glitch attacks (out of scope).

## Threats

| ID | Threat | CWE | Mitigation |
| --- | --- | --- | --- |
| T1 | Forged frame | CWE-345 | L2 keyed SIMON-32/64 CBC-MAC, 32-bit tag |
| T2 | Integrity value received but never verified | CWE-354 | Tag always recomputed and compared before commit |
| T3 | Replay of an old frame | CWE-294 | Strictly increasing counter freshness |
| T4 | Control/data de-synchronization | CWE-1264 | One-cycle atomic commit of the latched frame |
| T5 | Stuck or illegal FSM state | CWE-1245 | Fully enumerated FSM, timeout, sticky fault |
| T6 | Invalid framing or length | CWE-20 | Loader framing watchdog and Tier B comma/word-lock/timeout |

## Fail-closed behavior

On any authentication, freshness, framing, or line failure, `host_full` stays low and a sticky `fault` is raised until the host asserts `fault_ack`.

## Evidence

- Simulation: 128/128 single-bit flips rejected, forgery/wrong key/replay/stale counter rejected, serial-link loopback clean commit with forgery/replay/line-error rejection.
- Formal: `auth_top`, `auth_data_integrity`, `l3_commit_core`, `simon32_64`, `l1_link`, and `link_framing` (see `synth/formal/`).

## Out of scope

- No payload confidentiality: confidentiality can be added with an AEAD (for example Ascon) behind the block interface.
- No key provisioning or persistent replay counter across power cycles.
- No side-channel or physical glitch resistance; the formal properties prove logic only.
- The RF appendix integrity field is unsolved and remains problem evidence, not a solved path.
