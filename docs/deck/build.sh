#!/usr/bin/env bash
# Build the SALARAS-RX presentation: SVG -> PNG -> pptx -> pdf.
# Requires: node/npm, inkscape, libreoffice (soffice).
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -d node_modules/pptxgenjs ]; then
  echo "Installing build dependencies (pptxgenjs)..."
  if [ -f package-lock.json ]; then
    npm ci --silent
  else
    npm install --silent
  fi
fi

mkdir -p assets
echo "Rasterizing diagrams..."
inkscape ../proposal/assets/block-diagram.svg -o assets/block-diagram.png -w 1600 >/dev/null 2>&1
inkscape ../proposal/assets/prototype-s1.svg -o assets/prototype-s1.png -w 1600 >/dev/null 2>&1
inkscape ../proposal/assets/prototype-s2.svg -o assets/prototype-s2.png -w 1600 >/dev/null 2>&1

node build.mjs

echo "Converting to PDF..."
SOFFICE="$(command -v soffice || command -v libreoffice || true)"
if [ -z "$SOFFICE" ]; then
  echo "ERROR: libreoffice/soffice not found; pptx was generated." >&2
  exit 1
fi
"$SOFFICE" --headless -env:UserInstallation=file:///tmp/salaras-lo \
  --convert-to pdf --outdir . salaras-rx-deck.pptx >/dev/null 2>&1

for f in salaras-rx-deck.pptx salaras-rx-deck.pdf; do
  [ -f "$f" ] && echo "built $f"
done
