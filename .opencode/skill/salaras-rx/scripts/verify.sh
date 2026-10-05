#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
cd "$ROOT"

fail=0

run() {
    local name="$1"
    shift
    printf '== %s ==\n' "$name"
    if "$@"; then
        printf 'PASS %s\n\n' "$name"
    else
        printf 'FAIL %s\n\n' "$name"
        fail=1
    fi
}

run lint make lint
run synth-check make synth-check
run area make area

if command -v sby >/dev/null 2>&1; then
    run formal make formal
else
    printf '== formal ==\nSKIP formal (sby not found)\n\n'
fi

run test make test
run sim make sim

if [ "$fail" -eq 0 ]; then
    printf 'All gates passed.\n'
else
    printf 'One or more gates failed.\n'
fi

exit "$fail"
