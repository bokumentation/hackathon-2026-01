# src/

Committed RTL: the authenticated, replay-resistant, fail-closed ingress boundary.

## Modules

| File | Role |
| --- | --- |
| `simon32_64.v` | Serialized SIMON-32/64 block cipher, one round per cycle |
| `l2_auth.v` | CBC-MAC over counter plus payload, counter freshness |
| `l3_commit_gatekeeper.v` | Atomic fail-closed commit, sticky fault (shared with the RF appendix) |
| `salaras_auth_top.v` | L2 and L3 integration |
| `project.v` | Tiny Tapeout wrapper (`tt_um_bokumentation_auth_boundary`) with a serial frame loader |
| `salaras_rx_defs.svh` | Shared protocol constants and MAC parameters |
| `config.tcl` | Tiny Tapeout and OpenLane hardening configuration |
| `user_config.tcl` | Project hardening overrides (50 MHz, `CLOCK_PERIOD 20`) |

## Hierarchy

```
tt_um_bokumentation_auth_boundary   (project.v)
└── salaras_auth_top
    ├── l2_auth
    │   └── simon32_64
    └── l3_commit_gatekeeper
```

## Frame

`counter (32) + payload (64) + tag (32)`; CBC-MAC over the 96 authenticated bits
(three 32-bit blocks), 64-bit key, 32-bit tag.

## Checks

```bash
make lint
make synth-check
make area
make formal
make simon
make l2
make auth
```

The Manchester/RF predecessor is archived under `appendix/rf/` as the CWE-354
problem evidence.
