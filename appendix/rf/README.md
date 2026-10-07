# appendix/rf

Archived Manchester/RF design: the SALARAS-RX fail-closed ingress boundary on
`tt07-bep-decode`. It is kept as the CWE-354 problem evidence, not as the
committed design.

- `src/` RTL: `sync2`, vendored `edge_detect`/`state_machine`/`data_validate`,
  `frame_capture`, `l1_framing_validator`, `l2_integrity_verify`,
  `l3_commit_gatekeeper`, `salaras_rx_top`, and the Tiny Tapeout wrapper.
- `docs/` the RF-specific architecture, threat model, and verification plan
  (`architecture-rf.md`, `threat-model-rf.md`, `verification-plan-rf.md`).
- `info.yaml`, `config.tcl`, `user_config.tcl` Tiny Tapeout metadata.

Evidence: `sim/RESULTS.md` (E1, E2) and the sky130 1x2 signoff in
`synth/area.md`. The on-wire integrity field is an undocumented
error-correcting code and is not solved; this is intentional problem evidence.

Figure: `figures/sim-boundary-timeout.png` shows the L1 no-edge timeout
(`framing_ok` falls, `timeout_fault` rises), regenerated from the real VCD with
`make figures`.

The same `l3_commit_gatekeeper` is reused by the committed link design in the
root `src/`.
