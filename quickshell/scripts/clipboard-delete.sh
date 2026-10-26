#!/usr/bin/env bash
# Delete one cliphist entry by id.
set -euo pipefail
[ -n "${1:-}" ] || exit 2
cliphist list | awk -F '\t' -v id="$1" '$1 == id' | cliphist delete
