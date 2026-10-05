# src/

RTL for SALARAS-RX.

## Modules

| File | Role |
| --- | --- |
| `salaras_rx_defs.svh` | Shared protocol constants and CRC parameters |
| `sync2.v` | Two-flop synchronizer for the asynchronous `digital_in` input |
| `manchester_rx.v` | Edge detect and Manchester decode front-end |
| `frame_capture.v` | Header validation, payload capture, bit indexing |
| `l1_framing_validator.v` | L1: half-period timing window, timeout, framing validity |
| `l2_integrity_verify.v` | L2: streaming CRC-24 verification of the integrity field |
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
    ├── manchester_rx
    ├── frame_capture
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

The integrity field parameters in `salaras_rx_defs.svh` are the current working
hypothesis (CRC-24/OPENPGP) and are confirmed against the baseline captures as
part of the L2 risk milestone.
