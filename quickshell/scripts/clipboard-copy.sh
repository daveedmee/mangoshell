#!/usr/bin/env bash
# Copy one cliphist entry to the Wayland clipboard.
set -euo pipefail
[ -n "${1:-}" ] || exit 2
cliphist decode "$1" | wl-copy
