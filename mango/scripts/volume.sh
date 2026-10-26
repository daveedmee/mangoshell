#!/usr/bin/env bash
# Change the default sink volume in 5% steps, never leave 0..100, unmute so
# the volume keys always have an audible effect, and mute at 0%.
set -euo pipefail

direction="${1:-}"
case "$direction" in
    up|down) ;;
    *) echo "usage: volume.sh up|down" >&2; exit 2 ;;
esac

command -v pactl >/dev/null 2>&1 || exit 0

raw=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]\+%' | head -n1 | tr -d '%') || exit 0
[ -n "${raw:-}" ] || exit 0

if [ "$direction" = "up" ]; then
    new=$((raw + 5))
else
    new=$((raw - 5))
fi

(( new > 100 )) && new=100
(( new < 0 )) && new=0

pactl set-sink-volume @DEFAULT_SINK@ "${new}%"
if (( new == 0 )); then
    pactl set-sink-mute @DEFAULT_SINK@ 1
else
    pactl set-sink-mute @DEFAULT_SINK@ 0
fi

# Drive the Quickshell OSD when it is running.
qs ipc call osd volume "$new" >/dev/null 2>&1 || true
