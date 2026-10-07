#!/usr/bin/env bash
# Build the documentation artifacts into the repository output folder.
#
# Usage:
#   docs/build.sh [target] [--force]
#
#   target   proposal (default) | deck | progress | all
#   --force  rebuild even when the sources look unchanged
#
# The generated PDFs land in output/pdf, the intermediate HTML in output/html,
# and the presentation in output/pptx. All are git-ignored.
set -euo pipefail

DOCS_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-proposal}"
FORCE="${2:-}"

run_one() {
  case "$1" in
    proposal) bash "$DOCS_DIR/proposal/build.sh" $FORCE ;;
    deck)     bash "$DOCS_DIR/deck/build.sh" $FORCE ;;
    progress) bash "$DOCS_DIR/progress/build.sh" $FORCE ;;
    *) echo "unknown target: $1" >&2; exit 1 ;;
  esac
}

case "$TARGET" in
  all)
    run_one proposal
    run_one deck
    run_one progress
    ;;
  proposal|deck|progress)
    run_one "$TARGET"
    ;;
  *)
    echo "usage: docs/build.sh [proposal|deck|progress|all] [--force]" >&2
    exit 1
    ;;
esac
