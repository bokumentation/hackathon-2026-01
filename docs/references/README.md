# References

Third-party papers and vendor notes reviewed for the SALARAS prior-art and positioning analysis.
The Markdown files are the tracked, text-extracted form; the original PDFs sit alongside them and are not tracked in git.

| Reference | Markdown | Source PDF (not tracked) |
| --- | --- | --- |
| Ascon on FPGA: Post-Quantum Safe Authenticated Encryption with Replay Protection for IoT. Meera Gladis Kurian and Yuhua Chen, 2025. | [`ascon-fpga-replay-protection.md`](ascon-fpga-replay-protection.md) | `ascon-fpga-replay-protection.pdf` |
| KORD: Breaking the Key-Generation Bottleneck in Dealerless FSS via Protocol-Hardware Co-Design. Yijing Peng et al., 2026. | [`kord-dealerless-fss.md`](kord-dealerless-fss.md) | `kord-dealerless-fss.pdf` |
| KiviCore and CAST Release Post-Quantum Cryptographic Key Encapsulation IP Core. CAST, 2025. | [`kivicore-cast-pqc-kem-ip.md`](kivicore-cast-pqc-kem-ip.md) | `kivicore-cast-pqc-kem-ip.pdf` |
| KiviPQC-KEM. KiviCore. | [`kivipqc-kem.md`](kivipqc-kem.md) | `kivipqc-kem.pdf` |

## Notes

- The Markdown is extracted with `pdftotext -layout`, so figures, tables, and equations are not preserved.
- The original PDFs are for local reading only and are excluded by `.gitignore` (`docs/references/*.pdf`).
- The positioning analysis that uses these references is in `../judging/prior-art-analysis.id.md`.
