# tools/

Analysis scripts.

## `crc_reveng.py`

Reverse-engineering attempt for the 24-bit integrity field of `tt07-bep-decode`.

- Input: the 7 golden `(payload, tail)` pairs from the proposal appendix.
- Method: the field is affine over GF(2), so `tail = A*payload ^ c`. Deltas
  against a reference pair cancel `c`, leaving only the polynomial, coverage,
  and bit convention to search.
- Search: all odd 24-bit polynomials (2^23), refIn/refOut, MSB/LSB bit order,
  big/little byte order, and three field subsets, pruned delta by delta.

Result: no polynomial matched. The field is therefore most likely a custom
linear code rather than a standard CRC-24. The proposal documents this as the
main L2 risk with an affine-reconstruction fallback.

The baseline author reached the same conclusion independently: the field is
undocumented, no CRC matched, and it is suspected to be an error-correcting
code up to 24 bits (Kohnen, BSc Thesis, 2024). The baseline deliberately ships
without any integrity check.

## `affine_field.py`

Quantifies whether the affine map `tail = A*payload ^ c` (GF(2)) is recoverable.

Result with the 7 pairs: only 13 payload bit positions vary, the delta rank is
5, and 67 of 72 payload dimensions are unconstrained. The map is therefore
determined only on a 5-dimensional subspace. Full reconstruction needs many
more `(payload, tail)` pairs so the delta rank reaches the payload size.

Run:

```bash
python tools/crc_reveng.py
python tools/affine_field.py
```
