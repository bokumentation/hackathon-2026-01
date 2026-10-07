#!/usr/bin/env bash
# Build the progress report HTML and PDF into the repository output folder.
#
# The timestamp in the file name comes from the mtime of the Markdown source.
# Usage: docs/progress/build.sh [--force]
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"
OUT_HTML="$ROOT/output/html"
OUT_PDF="$ROOT/output/pdf"

SRC="$DIR/progress-report.md"
[ -f "$SRC" ] || { echo "ERROR: missing $SRC" >&2; exit 1; }

newest() {
  local m=0 t
  for f in "$@"; do
    t="$(stat -c %Y "$f")"
    [ "$t" -gt "$m" ] && m="$t"
  done
  echo "$m"
}

SRC_MTIME="$(newest "$SRC" "$DIR/build.mjs" "$DIR/progress.css" "$DIR/cover.json")"
TS="$(date -d "@$SRC_MTIME" +%Y%m%d-%H%M)"
BASE="PROGRESS-TRIARGA-$TS"

FORCE=""
[ "${1:-}" = "--force" ] && FORCE=1

if [ -z "$FORCE" ] \
   && [ -f "$OUT_PDF/$BASE.pdf" ] \
   && [ "$(stat -c %Y "$OUT_PDF/$BASE.pdf")" -ge "$SRC_MTIME" ]; then
  echo "progress report up to date ($TS)"
  exit 0
fi

if [ ! -d "$DIR/node_modules/marked" ] || [ ! -d "$DIR/node_modules/puppeteer-core" ] || [ ! -d "$DIR/node_modules/pdf-lib" ]; then
  echo "Installing build dependencies (marked, puppeteer-core, pdf-lib)..."
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
cp "$DIR/progress.css" "$OUT_HTML/progress.css"

PROGRESS_TS="$TS" PROGRESS_HTML_DIR="$OUT_HTML" node "$DIR/build.mjs"

COVER_FILE="$DIR/cover.json" node "$DIR/print-pdf.mjs" "$OUT_HTML/$BASE.html" "$OUT_PDF/$BASE.pdf" "$CHROME" en
echo "built $OUT_PDF/$BASE.pdf"

find "$OUT_PDF" -maxdepth 1 -name 'PROGRESS-TRIARGA-*.pdf' ! -name "$BASE.pdf" -delete
find "$OUT_HTML" -maxdepth 1 -name 'PROGRESS-TRIARGA-*.html' ! -name "$BASE.html" -delete
echo "progress report version $TS"
