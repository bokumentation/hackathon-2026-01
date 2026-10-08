#!/usr/bin/env bash
# Build the proposal HTML and PDF into the repository output folder.
#
# The timestamp in the file name comes from the mtime of the Markdown sources:
#   - if the sources are unchanged, the existing timestamped PDF is kept and the
#     build is skipped;
#   - if a source is edited, a new timestamp is stamped and older outputs are
#     removed, so only the latest proposal is kept.
#
# Usage: docs/proposal/build.sh [--force]
#   --force  rebuild even when the sources look unchanged.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
OUT_HTML="$ROOT/output/html"
OUT_PDF="$ROOT/output/pdf"

SRC_ID="$DIR/proposal.id.md"
SRC_EN="$DIR/proposal.en.md"
for f in "$SRC_ID" "$SRC_EN"; do
  [ -f "$f" ] || { echo "ERROR: missing $f" >&2; exit 1; }
done

newest() {
  local m=0 t
  for f in "$@"; do
    t="$(stat -c %Y "$f")"
    [ "$t" -gt "$m" ] && m="$t"
  done
  echo "$m"
}

SRC_MTIME="$(newest "$SRC_ID" "$SRC_EN" "$DIR/build.mjs" "$DIR/proposal.css" "$DIR/cover.json")"
TS="$(date -d "@$SRC_MTIME" +%Y%m%d-%H%M)"
BASE="PROPOSAL-TRIARGA-$TS"

FORCE=""
[ "${1:-}" = "--force" ] && FORCE=1

if [ -z "$FORCE" ] \
   && [ -f "$OUT_PDF/$BASE.id.pdf" ] && [ -f "$OUT_PDF/$BASE.en.pdf" ] \
   && [ "$(stat -c %Y "$OUT_PDF/$BASE.id.pdf")" -ge "$SRC_MTIME" ]; then
  echo "proposal up to date ($TS)"
  exit 0
fi

if [ ! -d "$DIR/node_modules/marked" ] || [ ! -d "$DIR/node_modules/puppeteer-core" ] || [ ! -d "$DIR/node_modules/pdf-lib" ] || [ ! -d "$DIR/node_modules/katex" ] || [ ! -d "$DIR/node_modules/marked-katex-extension" ]; then
  echo "Installing build dependencies (marked, marked-katex-extension, katex, puppeteer-core, pdf-lib)..."
  if [ -f "$DIR/package-lock.json" ]; then
    (cd "$DIR" && npm ci --silent)
  else
    (cd "$DIR" && npm install --silent)
  fi
fi

CHROME="$(command -v google-chrome || command -v google-chrome-stable || command -v chromium || command -v chromium-browser || true)"
if [ -z "$CHROME" ]; then
  echo "ERROR: google-chrome/chromium not found" >&2
  exit 1
fi

mkdir -p "$OUT_HTML" "$OUT_PDF"
rm -rf "$OUT_HTML/assets"
cp -r "$DIR/assets" "$OUT_HTML/assets"
mkdir -p "$OUT_HTML/assets/katex"
cp "$DIR/node_modules/katex/dist/katex.min.css" "$OUT_HTML/assets/katex/"
cp -r "$DIR/node_modules/katex/dist/fonts" "$OUT_HTML/assets/katex/fonts"
cp "$DIR/proposal.css" "$OUT_HTML/proposal.css"

PROPOSAL_TS="$TS" PROPOSAL_HTML_DIR="$OUT_HTML" node "$DIR/build.mjs"

for L in id en; do
  node "$DIR/print-pdf.mjs" "$OUT_HTML/$BASE.$L.html" "$OUT_PDF/$BASE.$L.pdf" "$CHROME" "$L"
  echo "built $OUT_PDF/$BASE.$L.pdf"
done

# keep only the latest proposal build
find "$OUT_PDF" -maxdepth 1 -name 'PROPOSAL-TRIARGA-*.pdf' ! -name "$BASE.*" -delete
find "$OUT_HTML" -maxdepth 1 -name 'PROPOSAL-TRIARGA-*.html' ! -name "$BASE.*" -delete
echo "proposal version $TS"
