# References

Third-party papers and vendor notes reviewed for the TRI-ARGA prior-art and positioning analysis.
The Markdown files are the tracked, text-extracted form; the original PDFs sit alongside them and are not tracked in git.

| Reference | Markdown | Source PDF (not tracked) | Source |
| --- | --- | --- | --- |
| Ascon on FPGA: Post-Quantum Safe Authenticated Encryption with Replay Protection for IoT. Meera Gladis Kurian and Yuhua Chen, 2025. | [`ascon-fpga-replay-protection.md`](ascon-fpga-replay-protection.md) | `ascon-fpga-replay-protection.pdf` | https://doi.org/10.3390/electronics14132668 |
| KORD: Breaking the Key-Generation Bottleneck in Dealerless FSS via Protocol-Hardware Co-Design. Yijing Peng et al., 2026. | [`kord-dealerless-fss.md`](kord-dealerless-fss.md) | `kord-dealerless-fss.pdf` | https://eprint.iacr.org/2026/1615 |
| KiviCore and CAST Release Post-Quantum Cryptographic Key Encapsulation IP Core. CAST, 2025. | [`kivicore-cast-pqc-kem-ip.md`](kivicore-cast-pqc-kem-ip.md) | `kivicore-cast-pqc-kem-ip.pdf` | https://www.cast-inc.com/press-releases/kivicore-and-cast-release-post-quantum-cryptographic-key-encapsulation-ip-core |
| KiviPQC-KEM. KiviCore, 2025. | [`kivipqc-kem.md`](kivipqc-kem.md) | `kivipqc-kem.pdf` | https://www.cast-inc.com/press-releases/cast-enter-post-quantum-cryptography-era-new-kivipqc-kem-ip-core |

## Notes

- The Markdown is extracted with `pdftotext -layout`, so figures, tables, and equations are not preserved.
- The original PDFs are for local reading only and are excluded by `.gitignore` (`docs/references/*.pdf`).
- The Source column gives the canonical public location of each document.
- These references support the cipher and protocol choices discussed in `../design/trade-study.md` and the proposal.
