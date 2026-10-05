# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-10-05

### Added

- Initial repository structure for the SALARAS-RX Tiny Tapeout and DE10-Nano flow.
- Pinned baseline submodules: `tt07-bep-decode`, `TT_UM_SERDES`, `tt07_cdc_fifo`.
- RTL skeletons for layer L1 (framing/FSM validator), L2 (integrity verify), and
  L3 (atomic commit gatekeeper).
- cocotb verification scaffold with golden capture vectors.
- Yosys synthesizability check and SymbiYosys formal properties.
- Top-level Makefile and GitHub Actions workflows.
- DE10-Nano prototype and ESP32 wired replay path.
- Project documentation is maintained locally and is not tracked in this repository.

[Unreleased]: https://github.com/bokumentation/hackathon-2026-01/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/bokumentation/hackathon-2026-01/releases/tag/v0.1.0
