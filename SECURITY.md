# Security Policy

## Scope

This repository contains hardware description languages and documentation. It
does not run a network service. Security-relevant items include:

- Fault-handling correctness in the TRI-ARGA ingress boundary (`src/`).
- Verification claims (detection rate, false-reject rate) in `test/` and
  `synth/formal/`.
- Any leak of credentials or private material in the repository.

## Reporting

If you find a security-relevant issue, report it privately to the repository
maintainers rather than opening a public issue.

Please include a description, affected files, reproduction steps, and any
suggested fix. We aim to acknowledge reports within a few days.

## Design security notes

TRI-ARGA is a fail-closed hardware boundary: a frame is committed only when
its embedded integrity field verifies. The integrity field parameters are still
under investigation, so L2 is parameterized and does not yet accept real frames.
The threat model and mitigations are maintained in the local design
documentation. The intended scope is a digital RTL proof of concept. It is not a
certified secure element and has not been evaluated against physical or
side-channel attacks at this stage.
