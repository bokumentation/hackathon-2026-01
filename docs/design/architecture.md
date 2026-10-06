# Architecture

SALARAS is a hardware-enforced, fail-closed ingress boundary for Manchester/RF serial links.
It sits between a Manchester decoder and the host register file without changing the frame format.

## Data flow

```
digital_in --> sync2 --> edge_detect --> state_machine --> frame_capture
                                                                |
                    +-------------------------------------------+---------+
                    |                                           |         |
              l1_framing_validator                     l2_integrity_verify |
                    |                                           |         |
                    +---------------------+---------------------+         |
                                          |                               |
                                 l3_commit_gatekeeper <-------------------+
                                          |
                                host_data / host_full / fault
```

The front-end (`edge_detect`, `state_machine`) and header validation (`data_validate`, used inside `frame_capture`) are the baseline modules.

## Layers

### L1, framing and FSM validation

`l1_framing_validator` adds a half-period timing window, a timeout counter, and fault latches on top of the baseline framing.
It asserts `framing_ok` while a frame is in progress and no timing or timeout fault has been seen.
The timing window is `SRX_HALF_PERIOD` plus or minus `SRX_TIMING_TOLERANCE` clock cycles.

### L2, integrity verification

`l2_integrity_verify` is a streaming LFSR that consumes the first `SRX_PAYLOAD_DATA_BITS` payload bits and compares the computed value with the integrity field carried by the frame.
The comparator output `crc_ok` is valid when `frame_done` pulses.
The field is affine over GF(2) but does not match a standard CRC-24; the polynomial and seed are therefore placeholders until the field is reconstructed (see `tools/README.md`).

### L3, atomic commit gatekeeper

`l3_commit_gatekeeper` commits data and control atomically.
A frame is latched to the host interface only when `framing_ok` and `crc_ok` are both high at `frame_done`.
Otherwise `host_full` stays low and a sticky `fault` flag is raised until the host acknowledges it.

## Clock domains

The core is single clock.
The asynchronous `digital_in` is synchronized by `sync2` before use.
On the FPGA target the core clock is a divided 20 kHz clock that matches the baseline half-period of 9 ticks; on the ASIC target the core runs directly at 20 kHz.

## Area

The target was a 1x1 Tiny Tapeout tile.
The integrated design overflows 1x1 at 105.57% placement utilization, so the documented 1x2 fallback is used: die 0.0363 mm^2 (161.0 x 225.76 um), 1233 synthesis cells, 0 Magic DRC, timing met (WNS 0.00), typical power 1.21 mW.
The design adds an LFSR, a comparator, a timing counter, and a commit register to the baseline.
