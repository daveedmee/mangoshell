#!/usr/bin/env bash
# Capture one preview per top-level window without entering Mango's native
# overview. ext-image-copy-capture can read a toplevel's own buffer even while
# the Quickshell overview is covering the screen.
set -euo pipefail

runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
socket="${MANGO_INSTANCE_SIGNATURE:-}"
if [ -z "$socket" ] || [ ! -S "$socket" ]; then
    socket=$(ls -t "$runtime"/mango-*.sock 2>/dev/null | head -n 1 || true)
fi
if [ -z "$socket" ] || [ ! -S "$socket" ]; then
    printf '%s\n' '{"previews":[]}'
    exit 0
fi
export MANGO_INSTANCE_SIGNATURE="$socket"

cache="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/overview"
mkdir -p "$cache"
find "$cache" -maxdepth 1 -type f -name '*.png' -delete 2>/dev/null || true

clients=$(mmsg get all-clients)
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

jq -r '.clients[]?
    | select(.foreign_toplevel_id != null and .foreign_toplevel_id != "")
    | [.id, .foreign_toplevel_id] | @tsv' <<< "$clients" > "$tmp"

while IFS=$'\t' read -r id toplevel; do
    [ -n "$id" ] && [ -n "$toplevel" ] || continue
    grim -T "$toplevel" "$cache/$id.png" >/dev/null 2>&1 &
done < "$tmp"
wait

jq -Rn --arg cache "$cache" '
    [inputs | split("\t") | select(length == 2)
        | {id: .[0], preview: ($cache + "/" + .[0] + ".png")}]
    | {previews: .}
' < "$tmp"
