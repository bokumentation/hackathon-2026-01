# Glossary

Terms, abbreviations, and weakness identifiers used across the documentation.

## Project terms

| Term | Meaning |
| --- | --- |
| SALARAS | The authenticated, fail-closed ingress boundary for lightweight serial links |
| L1 | Serial loader: shifts in the key and the frame |
| L2 | Authentication: keyed MAC plus freshness counter |
| L3 | Commit gatekeeper: atomic fail-closed commit with a sticky fault |
| Tier A | Committed single-clock core with simulation, formal, and ASIC evidence |
| Tier B | Planned serial link on `TT_UM_SERDES` (8b/10b framing) |
| Tier C | Future clock-domain crossing with the vendored CDC FIFO |

## Cryptographic terms

| Term | Meaning |
| --- | --- |
| MAC | Message Authentication Code: a keyed tag over the frame |
| CBC-MAC | Cipher Block Chaining MAC, used here over a fixed three-block length |
| SIMON-32/64 | Lightweight block cipher, 32-bit block, 64-bit key |
| Tag | The 32-bit MAC value carried by the frame |
| Counter freshness | Rejecting a counter that is not strictly greater than the last accepted |
| Replay | Re-sending a previously valid frame |
| Forgery | Producing a valid-looking frame without the key |

## Interface and hardware terms

| Term | Meaning |
| --- | --- |
| TT07 | Tiny Tapeout 07 shuttle, sky130 |
| sky130 | SkyWater 130 nm open PDK |
| ALM | Adaptive Logic Module, the Cyclone V logic unit |
| LUT | Look-Up Table |
| M10K | Cyclone V embedded memory block |
| DSP | Dedicated multiplier block |
| Fmax | Maximum clock frequency reported by the Timing Analyzer |
| WNS / WHS | Worst Negative Setup / Hold Slack |
| SignalTap | Quartus on-chip logic analyzer for on-board capture |
| RD+/RD- | Running disparity states in 8b/10b line coding |

## Weakness identifiers (MITRE CWE)

| CWE | Title | Where addressed |
| --- | --- | --- |
| CWE-20 | Improper Input Validation | L1 rejects malformed frames |
| CWE-294 | Authentication Bypass by Capture-replay | L2 strict freshness counter |
| CWE-345 | Insufficient Verification of Data Authenticity | L2 keyed CBC-MAC |
| CWE-354 | Improper Validation of Integrity Check Value | Baseline problem; L2 closes it |
| CWE-1245 | Improper Finite State Machines in Hardware Logic | Data-validated FSM |
| CWE-1264 | Hardware Logic with Insecure De-Synchronization between Control and Data | L3 atomic commit of latched data |
