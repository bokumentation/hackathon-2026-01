# Architecture

TRI-ARGA is a hardware-enforced, fail-closed ingress boundary for lightweight serial and RF links. The committed design has two tiers:

- Tier A: the single-clock authenticated boundary core (`l1_serial_loader`, `simon32_64`, `l2_auth`, `l3_commit_gatekeeper`, `boundary_top`).
- Tier B: a secure 8b/10b serial link in front of the core (`link_enc_8b10b`, `link_dec_10b8b`, `l1_link_framing`, `link_tx`, `link_rx`, `link_top`).

The archived Manchester/RF predecessor is described in `appendix/rf/docs/architecture-rf.md`.

## Data flow (Tier B)

```
serial_in --> link_rx --> boundary_top --> host
               |  |            |
               |  |            +-- l2_auth (simon32_64)
               |  |            +-- l3_commit_gatekeeper
               |  +-- link_dec_10b8b
               +----- l1_link_framing (comma, word lock, timeout)

link_tx --> serial_out     (peer transmitter, sharing the same clock)
```

In the loopback demonstration `link_tx` drives `serial_in`, so the FPGA generates the wire traffic itself.

The Tier A core alone accepts a frame block directly: `counter`, `payload`, and `tag` into `boundary_top`, with the key loaded from the host.

## Layers

### L1, frame loading

`l1_serial_loader` shifts in the 64-bit key (write-once, locked until reset) and then the 128-bit frame MSB-first on a single-bit interface. `key_mode` selects the session; a truncated session raises a sticky framing fault, and a stalled auth core raises a timeout fault. Key and frame never share a path.

### L2, authentication and freshness

`l2_auth` recomputes a keyed CBC-MAC over `counter + payload` (three 32-bit blocks, IV 0, 64-bit key) with the serialized `simon32_64` cipher, compares the 32-bit tag, and checks that the counter is strictly greater than the last accepted counter. The tag is always recomputed, so a corrupt or forged frame cannot pass.

### L3, atomic commit gatekeeper

`l3_commit_gatekeeper` releases `host_data` and `host_full` together in one cycle, only if authentication and freshness pass and the framing signal is high. The committed values are the latched frame, not the live inputs. On any failure, `host_full` stays low and a sticky `fault` is raised until the host asserts `fault_ack`.

### Tier B, secure serial link

`l1_link_framing` assembles 10-bit symbols, detects the K28.5 comma, and establishes word lock; `link_dec_10b8b` decodes symbols and flags code and disparity errors; `link_rx` assembles the 128-bit frame and starts `boundary_top`. `link_tx` sends a comma followed by the 16-byte frame through `link_enc_8b10b` with running disparity. A line error, a lock loss, or a framing fault fails closed.

## Frame

`counter (32) + payload (64) + tag (32)`; CBC-MAC over the 96 authenticated bits (three 32-bit blocks), 64-bit key, 32-bit tag. Tier B wraps the same frame with a K28.5 comma and 8b/10b coding.

## Clock domains

Single clock. The Tier A core and the Tier B link both run on the same clock. A second clock domain is deferred to Tier C and would cross only through the vendored CDC FIFO.

## Targets and area

- FPGA: Terasic DE10-Nano, Cyclone V `5CSEBA6U23I7`. Tier B loopback wrapper `link_demo_top`: 421 ALM, 1029 registers, Fmax 97.9 MHz, 426.2 mW vector-less. Tier A wrapper `de10nano_top`: 242 ALM, 654 registers, Fmax 136.37 MHz.
- ASIC: Tiny Tapeout sky130 via OpenLane. Core 2x2, die 0.0756 mm^2, 2511 cells, 0 DRC/LVS/antenna, WNS 0.00, 2.10 mW typical. Tier B link 2x2, 3220 cells, 2 antenna violations, 3.61 mW typical.
- RF appendix (separate): 1x2, die 0.0363 mm^2, 1233 cells, 1.21 mW typical. This does not transfer to the core.
