# src/

Committed RTL for TRI-ARGA: the authenticated, replay-resistant, fail-closed ingress boundary (Tier A) and the 8b/10b secure serial link (Tier B).

`src/` is the Tiny Tapeout source root. The current Tiny Tapeout top is `tt_um_link` (`project_link.v`, the Tier B link); the Tier A wrapper is `project.v` (`tt_um_auth_boundary`).

## Modules

| File | Role |
| --- | --- |
| `simon32_64.v` | Serialized SIMON-32/64 block cipher, one round per cycle |
| `l2_auth.v` | CBC-MAC over counter plus payload, tag compare, counter freshness |
| `l3_commit_gatekeeper.v` | Atomic fail-closed commit, sticky fault (shared with the RF appendix) |
| `boundary_top.v` | L2 and L3 integration, gated by the framing signal |
| `l1_serial_loader.v` | Serial key and frame loader with write-once key, framing and timeout watchdogs |
| `link_enc_8b10b.v` | 8b/10b encoder with running disparity |
| `link_dec_10b8b.v` | 8b/10b decoder with code and disparity error flags |
| `l1_link_framing.v` | Serial shift, K28.5 comma detect, word lock, and timeout |
| `link_tx.v` | Serial transmitter: comma plus 16-byte frame |
| `link_rx.v` | Deserializer plus frame assembly into `boundary_top` |
| `link_top.v` | `link_rx` and `boundary_top` integration |
| `project.v` | Tier A Tiny Tapeout wrapper (`tt_um_auth_boundary`) |
| `project_link.v` | Tier B Tiny Tapeout wrapper (`tt_um_link`) |
| `defs.svh` | Shared constants, including `DEF_PAYLOAD_BITS` used by L3 |
| `config.tcl` | Tiny Tapeout and OpenLane hardening configuration |
| `user_config.tcl` | Project hardening overrides (50 MHz, `CLOCK_PERIOD 20`) |

## Hierarchy

```
tt_um_auth_boundary   (project.v, Tier A)
└── l1_serial_loader
└── boundary_top
    ├── l2_auth
    │   └── simon32_64
    └── l3_commit_gatekeeper

tt_um_link            (project_link.v, Tier B)
├── l1_serial_loader
└── link_top
    ├── link_rx
    │   ├── l1_link_framing
    │   └── link_dec_10b8b
    ├── link_tx
    │   └── link_enc_8b10b
    └── boundary_top
        ├── l2_auth
        │   └── simon32_64
        └── l3_commit_gatekeeper
```

## Frame

`counter (32) + payload (64) + tag (32)`; CBC-MAC over the 96 authenticated bits (three 32-bit blocks), 64-bit key, 32-bit tag. Tier B adds a K28.5 comma symbol and 8b/10b line coding around the same frame.

## Checks

```bash
make lint
make synth-check
make area
make formal
make simon
make l2
make auth
make wrapper
make link-codec
make link-framing
make link-top
```

The Manchester/RF predecessor is archived under `appendix/rf/` as the CWE-354 problem evidence; its design docs moved to `appendix/rf/docs/`.
