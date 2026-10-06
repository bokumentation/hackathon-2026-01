#!/usr/bin/env bash
# Build the TRI-ARGA presentation into the repository output folder.
#
# The timestamp in the file name comes from the mtime of the deck sources
# (build.mjs and the rasterized SVG inputs): unchanged sources keep the existing
# timestamped output; an edit stamps a new timestamp and older outputs are removed.
#
# Usage: docs/deck/build.sh [--force]
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
OUT_PPTX="$ROOT/output/pptx"
OUT_PDF="$ROOT/output/pdf"

SVG_DIR="$DIR/../proposal/assets"

newest() {
  local m=0 t
  for f in "$@"; do
    [ -f "$f" ] || continue
    t="$(stat -c %Y "$f")"
    [ "$t" -gt "$m" ] && m="$t"
  done
  echo "$m"
}

SRC_MTIME="$(newest "$DIR/build.mjs" "$SVG_DIR/block-diagram.svg" "$DIR/../proposal/cover.json")"
TS="$(date -d "@$SRC_MTIME" +%Y%m%d-%H%M)"
BASE="DECK-TRIARGA-$TS"

FORCE=""
[ "${1:-}" = "--force" ] && FORCE=1

if [ -z "$FORCE" ] \
   && [ -f "$OUT_PDF/$BASE.pdf" ] \
   && [ "$(stat -c %Y "$OUT_PDF/$BASE.pdf")" -ge "$SRC_MTIME" ]; then
  echo "deck up to date ($TS)"
  exit 0
fi

if [ ! -d "$DIR/node_modules/pptxgenjs" ]; then
  echo "Installing build dependencies (pptxgenjs)..."
  if [ -f "$DIR/package-lock.json" ]; then
    (cd "$DIR" && npm ci --silent)
  else
    (cd "$DIR" && npm install --silent)
  fi
fi

SOFFICE="$(command -v soffice || command -v libreoffice || true)"
if [ -z "$SOFFICE" ]; then
  echo "ERROR: libreoffice/soffice not found" >&2
  exit 1
fi

mkdir -p "$DIR/assets" "$OUT_PPTX" "$OUT_PDF"
echo "Rasterizing diagrams..."
inkscape "$SVG_DIR/block-diagram.svg" -o "$DIR/assets/block-diagram.png" -w 1600 >/dev/null 2>&1

(cd "$DIR" && DECK_OUT_DIR="$OUT_PPTX" DECK_BASE="$BASE" node build.mjs)

echo "Converting to PDF..."
"$SOFFICE" --headless -env:UserInstallation=file:///tmp/tri-arga-lo \
  --convert-to pdf --outdir "$OUT_PDF" "$OUT_PPTX/$BASE.pptx" >/dev/null 2>&1
echo "built $OUT_PDF/$BASE.pdf"

find "$OUT_PPTX" -maxdepth 1 -name 'DECK-TRIARGA-*.pptx' ! -name "$BASE.*" -delete
find "$OUT_PDF" -maxdepth 1 -name 'DECK-TRIARGA-*.pdf' ! -name "$BASE.*" -delete
echo "deck version $TS"
