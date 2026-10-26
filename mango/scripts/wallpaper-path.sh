#!/usr/bin/env bash
# Print the wallpaper Mango owns. The path is recorded in Mango's XDG state
# directory so a Plasma session rewriting the shared pywal cache cannot change
# the wallpaper Mango restores on its next login.
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
state_home="${XDG_STATE_HOME:-$HOME/.local/state}"
state_file="$state_home/mango/wallpaper"

wall=""

# Preferred: the path set-wallpaper.sh recorded for this Mango setup.
if [ -r "$state_file" ]; then
    IFS= read -r wall < "$state_file" || true
    if [ -n "$wall" ] && { [ ! -f "$wall" ] || [ ! -r "$wall" ]; }; then
        wall=""
    fi
fi

# Fallback: the canonical Mango copy. This also covers installations that
# predate the state file, or a state file left behind after the image was
# moved or deleted.
if [ -z "$wall" ]; then
    for candidate in \
        "$config_home/mango/wallpaper.png" \
        "$config_home/mango/wallpaper.jpg" \
        "$config_home/mango/wallpaper.jpeg" \
        "$config_home/mango/wallpaper.webp" \
        "$config_home/mango/wallpaper-light.png" \
        "$config_home/mango/wallpaper-dark.jpg"; do
        if [ -f "$candidate" ] && [ -r "$candidate" ]; then
            wall="$candidate"
            break
        fi
    done
fi

if [ -z "$wall" ] || [ ! -f "$wall" ] || [ ! -r "$wall" ]; then
    echo "wallpaper-path: no readable Mango wallpaper found" >&2
    exit 1
fi

printf '%s\n' "$wall"
