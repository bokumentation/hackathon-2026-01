# VISION.md - Strategy and long-range direction

Strategy document for the project.
Read AGENTS.md first for the invariant rules; this document does not override them.
PLAN.md holds the committed, actionable plan; VISION.md holds the why, the scope,
and the claims that must stay honest.

## 1. Purpose

Build a reusable, fail-closed ingress boundary that authenticates and protects
frames crossing a serial or RF link, so corrupt or forged data never reaches the
host as valid.

The boundary is the reusable asset; the transport is a swappable adapter.

## 2. Title (locked)

    A Reusable, Fail-Closed Authenticated Ingress Boundary for Serial/RF Links

- "Reusable" states the design intent, with appendix evidence.
- "Fail-closed" is the most defensible property (formal plus measured).
- "Authenticated" is true in the committed scope (keyed MAC).
- "Ingress Boundary for Serial/RF Links" anchors the work in Area 04.
- Replay resistance is claimed in the body, not the title, because it is
  session-scoped.

## 3. Problem statement

### Background

Serial and RF links carry data between transceivers, terminals, and hosts in
identity and payment systems. In lightweight designs the physical line coding
(Manchester, 8b/10b) is treated as sufficient, so the receiver parses an
untrusted bitstream into a shift register and exposes fields to the host. The
transport layer is assumed trusted, and no frame is authenticated.

### The problem

Two failure classes follow.

1. No validation of the received integrity value (CWE-354): a keyless CRC or ECC
   detects random errors but is forgeable by an active attacker, and an
   unimplemented check provides nothing.
2. Non-atomic commit (CWE-1264): data and control can de-synchronize under
   glitches or jitter. A fragile FSM (CWE-1245) and unvalidated input (CWE-20)
   compound it.

### Evidence from a real link

The 433 MHz Manchester decoder baseline `tt07-bep-decode` receives a 24-bit
integrity field (`tail_1..3`) and never checks it. We reproduced the consequence:
the baseline latches a corrupted payload and a corrupted integrity field with
`full=1` (CWE-354, measured). The field is an undocumented error-correcting code,
not a standard CRC, confirmed independently by the baseline author; it cannot be
validated without the algorithm, which is unsolved. The RF case therefore
demonstrates the vulnerability class; it is not a solved integrity path.

### Why existing approaches fall short

| Approach | Limit |
| -------- | ----- |
| Parity or CRC byte | Detects random errors; no framing; forgeable |
| Full 8b/10b | DC balance only, no integrity |
| Software verification | Runs after data crosses the trust boundary |
| Standard decoders | Validate only the start of the frame |
| MAC without freshness | Forge-resistant but replayable |

None combine authentication, freshness, and atomic fail-closed commit at the
boundary, transport-agnostic and small.

### Problem statement

1. How to authenticate a received frame against forgery (CWE-345)?
2. How to reject replayed frames without persistent state (CWE-294)?
3. How to commit data and control atomically, fail-closed, so a failed check
   never reaches the host (CWE-1264, CWE-1245)?
4. How to make this a reusable core that fits different front-ends
   (Manchester/RF, SerDes, UART) and both FPGA and ASIC?

## 4. Threat model (Level 3)

| ID | Threat | CWE | Mitigation |
| -- | ------ | --- | ---------- |
| T1 | Bit flip or noise | CWE-354 | MAC mismatch rejects |
| T2 | Fault injection (single bit, glitch) | CWE-354 | MAC plus timing (Tier B) |
| T3 | Invalid code or malformed frame | CWE-20 | Framing validity |
| T4 | FSM hang or illegal transition | CWE-1245 | Lock, timeout, recovery |
| T5 | Forged frame, payload modified | CWE-345 | Keyed MAC |
| T6 | Replay of a captured valid frame | CWE-294 | Freshness counter |
| T7 | Control/data de-synchronization | CWE-1264 | Atomic fail-closed commit |

CWE map: CWE-354, CWE-345, CWE-294, CWE-1264, CWE-1245, CWE-20. CWE-345 and
CWE-294 are closed in the committed scope; the RF field is explicitly out of
scope.

## 5. Tiered roadmap

- Tier A (committed): the authenticated, replay-resistant, fail-closed boundary
  core. Single clock, simulation evidence, formal invariants. This is the
  submitted scope.
- Tier B (next): attach the boundary to a serial link built on `TT_UM_SERDES`,
  with true 8b/10b (running disparity), K-character comma framing, word lock, and
  invalid-code error. Single clock end-to-end. This is when the "secure serial
  link" headline is earned.
- Tier C (future, stretch): add the clock-domain crossing with the vendored
  `cdc_fifo`, two clocks, real sky130 hardening, and a DE10-Nano demo.

## 6. Boundary as a reusable asset

The reusable IP is the boundary core (framing validity, integrity engine, and
atomic fail-closed commit), not the transport. The core exposes a stable
interface: frame bytes plus validity in, committed data plus `host_full` and
`fault` out, with a parameterized frame descriptor and a pluggable integrity
engine (a keyless CRC for legacy fixed frames, or the keyed MAC plus counter for
frames we define).

### Three senses of portable

| Sense | Meaning | Evidence status |
| ----- | ------- | --------------- |
| Front-end / transport | One boundary core attaches to Manchester/RF, SerDes, UART | Reusable core demonstrated on the RF appendix (L1 framing and L3 commit, L2 honest-scoped) plus one synthetic profile (MAC path). SerDes is Tier B; UART is unbuilt. |
| Frame-schema | Parameterized frame descriptor; pluggable integrity engine | Demonstrated on a synthetic fixed-shape profile only; no real legacy protocol is modeled. |
| Target | One RTL source for sky130 ASIC and Cyclone V FPGA | Design intent only. The prior sky130 1x2 result belongs to the RF appendix and does not transfer to the MAC module set until it is synthesized. |

### Layer split (precise)

- L1 framing and FSM hardening, and L3 atomic fail-closed commit, are portable to
  any frame, including legacy frames we do not own.
- L2 MAC plus counter is portable only to frames we define, because it needs a
  counter and a tag.
- The RF appendix and the MAC path do not share L2. The reuse demonstrated is the
  L1 and L3 boundary plus a pluggable L2 interface.

### Synthetic profile note

The legacy-shaped frame checked with a keyless CRC is synthetic and
illustrative. It exercises the boundary interface and a CRC engine to show
frame-schema reuse. It does not model the thermostat protocol and must not be
read as validating the RF integrity field, which is an undocumented ECC and
remains unsolved.

Claim placement: appendix only, not the Executive Summary.

## 7. Novelty and benefits

- A fail-closed ingress boundary that authenticates, enforces freshness, and
  commits atomically before data reaches the host.
- A reusable core with a pluggable integrity engine and a parameterized frame
  descriptor, demonstrated on the RF appendix plus one synthetic profile.
- Machine-checked fail-closed invariants, not only simulation.
- Measured authentication behavior (forgery, wrong key, replay, stale counter,
  bit flips) and a measured latency budget.
- Honest scope: the RF field is problem evidence, not a solved path.

## 8. Must not claim

- No cryptographic proof of security; a 32-bit tag gives about 2^-32 forgery
  probability, and CBC-MAC with a fixed key is not authenticated encryption.
- No real-frame RF detection rate; the RF field is unsolved, so RF stays as
  problem evidence only.
- No two-clock or CDC result, and no serial link result, until Tier B and Tier C
  are built.
- No key provisioning, persistent replay counter across power cycles, or
  side-channel resistance.
- No "works with any protocol"; say "reusable core, parameterized descriptor,
  demonstrated on the RF appendix plus one synthetic profile".
- No target portability (ASIC plus FPGA from one source) as a result until
  synthesis.
- No MAC portability to frames we do not own.
- No production or certified secure-element readiness.

## 9. Out of scope and residual

- Key provisioning and secure key storage.
- Persistent replay counter across power cycles.
- Physical and side-channel key extraction.
- Host software integrity after data has crossed the boundary.
- SerDes link, CDC crossing, real hardening, and FPGA (Tier B and Tier C).
