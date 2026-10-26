#!/usr/bin/env bash
# Collect Mango's client list for the Quickshell overview. The compositor's
# native overview is deliberately not entered: Quickshell draws the overview
# itself, and focusid works directly outside the native overview.
set -euo pipefail

runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
socket="${MANGO_INSTANCE_SIGNATURE:-}"
if [ -z "$socket" ] || [ ! -S "$socket" ]; then
    socket=$(ls -t "$runtime"/mango-*.sock 2>/dev/null | head -n 1 || true)
fi
if [ -z "$socket" ] || [ ! -S "$socket" ]; then
    printf '%s\n' '{"error":"mango socket not found","clients":[]}'
    exit 0
fi
export MANGO_INSTANCE_SIGNATURE="$socket"

data=$(mmsg get all-clients)

jq -cn \
    --argjson data "$data" \
    '{
        shot: "",
        clients: ($data.clients // []),
        monitors: []
    }'
