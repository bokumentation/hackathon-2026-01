#!/usr/bin/env bash
# Build the SALARAS-RX ideas PDFs:
#   - pdf/ideas-combined.pdf            (index + ideas 01-05)
#   - pdf/salaras-serdes-crc-outline.pdf (the CRC outline, standalone)
# Requires: node/npm and google-chrome (or chromium).
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -d node_modules/marked ]; then
  echo "Installing build dependencies (marked)..."
  if [ -f package-lock.json ]; then
    npm ci --silent
  else
    npm install --silent
  fi
fi

node build.mjs

CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser || true)"
if [ -z "$CHROME" ]; then
  echo "ERROR: google-chrome/chromium not found; HTML files were generated." >&2
  exit 1
fi

"$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
  --virtual-time-budget=10000 \
  --print-to-pdf="pdf/ideas-combined.pdf" \
  "file://$PWD/ideas-combined.html" >/dev/null 2>&1
echo "built pdf/ideas-combined.pdf"

if [ -f salaras-serdes-crc-outline.html ]; then
  "$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
    --virtual-time-budget=10000 \
    --print-to-pdf="pdf/salaras-serdes-crc-outline.pdf" \
    "file://$PWD/salaras-serdes-crc-outline.html" >/dev/null 2>&1
  echo "built pdf/salaras-serdes-crc-outline.pdf"
fi
