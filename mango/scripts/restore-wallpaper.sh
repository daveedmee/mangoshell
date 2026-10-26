#!/usr/bin/env bash
# Restore the wallpaper Mango recorded and start swaybg on it.
set -euo pipefail

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
display_file="$config_home/quickshell/wallpaper.json"

# A missing wallpaper must not abort the whole restore before swaybg starts.
# The session then falls back to the recorded base colour below.
wall=""
if ! wall=$(bash "$script_dir/wallpaper-path.sh" 2>/dev/null); then
    wall=""
fi

mode="fill"
color="#000000"
if [ -r "$display_file" ] && command -v jq >/dev/null 2>&1; then
    mode=$(jq -r '.mode // "fill"' "$display_file" 2>/dev/null || true)
    color=$(jq -r '.color // "#000000"' "$display_file" 2>/dev/null || true)
fi
case "$mode" in
    fill|fit|stretch|tile|center) ;;
    *) mode="fill" ;;
esac
[[ "$color" =~ ^#[0-9a-fA-F]{6}$ ]] || color="#000000"

pkill -x swaybg >/dev/null 2>&1 || true

if [ -z "$wall" ] || [ ! -r "$wall" ]; then
    echo "restore-wallpaper: no wallpaper recorded; using base colour" >&2
    exec swaybg -c "${color#\#}"
fi

exec swaybg -i "$wall" -m "$mode" -c "${color#\#}"
