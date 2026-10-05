#!/usr/bin/env bash
# Build the verification/feasibility report PDFs (all *.md in this folder).
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

for md in *.md; do
  [ -e "$md" ] || continue
  NAME="${md%.md}"
  "$CHROME" --headless=new --disable-gpu --no-pdf-header-footer \
    --virtual-time-budget=8000 \
    --print-to-pdf="$NAME.pdf" \
    "file://$PWD/$NAME.html" >/dev/null 2>&1
  echo "built $NAME.pdf"
done
