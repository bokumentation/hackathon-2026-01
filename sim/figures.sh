#!/usr/bin/env bash
# Render the simulation figures for the proposal and the RF appendix from real
# VCD captures produced by the cocotb suites.
#
# Requires: `make env` (the venv) and the simulators. Run from any directory.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PY="$ROOT/venv/bin/python"
[ -x "$PY" ] || PY=python3

echo "Generating VCD captures..."
make auth
make sim

echo "Rendering link-core figure (authentication and commit)..."
"$PY" sim/plot_waveforms.py test/auth_top.vcd docs/proposal/assets/sim-auth-commit.png \
  --t0 0 --t1 2600 \
  --title "TRI-ARGA core: authentication and commit (accept then reject)" \
  start done auth_ok fresh_ok host_full fault

echo "Rendering RF appendix figure (no-edge timeout)..."
mkdir -p appendix/rf/figures
"$PY" sim/plot_waveforms.py sim/out/tb_boundary.vcd appendix/rf/figures/sim-boundary-timeout.png \
  --t0 41000 --t1 41700 \
  --title "RF appendix L1: no-edge timeout" \
  framing_ok timeout_fault

echo "Figures written."
