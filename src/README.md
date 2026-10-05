# src/

RTL for SALARAS-RX.

## Modules

| File | Role |
| --- | --- |
| `salaras_rx_defs.svh` | Shared protocol constants and L2 parameters |
| `sync2.v` | Two-flop synchronizer for the asynchronous `digital_in` input |
| `edge_detect.v` | Baseline edge detect (vendored from tt07-bep-decode) |
| `state_machine.v` | Baseline Manchester decode front-end (vendored) |
| `data_validate.v` | Baseline header validation (vendored) |
| `frame_capture.v` | Header validation, payload capture, bit indexing |
| `l1_framing_validator.v` | L1: half-period timing window, timeout, framing validity |
| `l2_integrity_verify.v` | L2: streaming LFSR verification of the integrity field |
| `l3_commit_gatekeeper.v` | L3: atomic commit, sticky fault, fail-closed host interface |
| `salaras_rx_top.v` | Core integration of the three layers |
| `project.v` | Tiny Tapeout wrapper (`tt_um_bokumentation_salaras_rx`) |
| `config.tcl` | Tiny Tapeout and OpenLane hardening configuration |
| `user_config.tcl` | Project hardening overrides |

## Hierarchy

```
tt_um_bokumentation_salaras_rx   (project.v)
└── salaras_rx_top
    ├── sync2
    ├── edge_detect
    ├── state_machine
    ├── frame_capture
    │   └── data_validate
    ├── l1_framing_validator
    ├── l2_integrity_verify
    └── l3_commit_gatekeeper
```

## Checks

```bash
make lint
make synth-check
make formal
```

The integrity field is affine over GF(2) but does not match a standard CRC-24,
so the parameters in `salaras_rx_defs.svh` are placeholders until the field is
reconstructed (see `tools/README.md`).
