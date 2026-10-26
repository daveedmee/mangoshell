#!/usr/bin/env bash
# Lock the session, using the last cached wallpaper as the lock background.
set -uo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
wall=$(bash "$config_home/mango/scripts/wallpaper-path.sh" 2>/dev/null || true)
if [ -n "$wall" ] && [ -r "$wall" ] && command -v swaylock >/dev/null 2>&1; then
    exec swaylock -f -i "$wall" -s fill
elif command -v swaylock >/dev/null 2>&1; then
    exec swaylock -f -c 000000
else
    notify-send "Lock unavailable" "swaylock is not installed." 2>/dev/null || true
    exit 1
fi
