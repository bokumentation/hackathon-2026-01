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

Run:

```bash
python tools/crc_reveng.py
```
