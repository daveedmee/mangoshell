#!/usr/bin/env bash
# DDC/CI brightness helper for the AOC external display.
set -euo pipefail

command -v ddcutil >/dev/null 2>&1 || exit 0

get_brightness() {
    ddcutil getvcp 10 --brief 2>/dev/null |
        awk '{ for (i = 1; i <= NF; i++) if ($i == "C") { print $(i + 1); exit } }'
}

set_brightness() {
    local value="$1"
    (( value < 0 )) && value=0
    (( value > 100 )) && value=100
    ddcutil setvcp 10 "$value" >/dev/null 2>&1 || true
    qs ipc call osd brightness "$value" >/dev/null 2>&1 || true
}

current=$(get_brightness || true)
[ -n "${current:-}" ] || current=100

case "${1:-}" in
    up)
        set_brightness $((current + 5))
        ;;
    down)
        set_brightness $((current - 5))
        ;;
    get)
        printf '%s\n' "$current"
        ;;
    set)
        set_brightness "${2:-$current}"
        ;;
    *)
        echo "usage: brightness.sh get|up|down|set <0-100>" >&2
        exit 2
        ;;
esac
