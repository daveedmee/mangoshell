#!/usr/bin/env bash
# Set the wallpaper, regenerate the pywal palette and reload mango.
# Usage: set-wallpaper.sh <image>
set -euo pipefail

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
state_home="${XDG_STATE_HOME:-$HOME/.local/state}"

src="${1:-}"
if [ -z "$src" ] || [ ! -f "$src" ]; then
    echo "usage: set-wallpaper.sh <image>" >&2
    exit 1
fi

dst="$config_home/mango/wallpaper.png"

# Normalise the copy (strips metadata, fixes odd extensions).
if [ "$(readlink -f -- "$src")" != "$(readlink -f -- "$dst")" ]; then
    if command -v magick >/dev/null 2>&1; then
        magick "$src" -strip "$dst"
    elif command -v convert >/dev/null 2>&1; then
        convert "$src" -strip "$dst"
    else
        cp -- "$src" "$dst"
    fi
fi

# Remember Mango's own choice. Other desktop environments may rewrite the
# shared pywal cache, but they never touch this state file.
dst_abs=$(readlink -f -- "$dst")
state_dir="$state_home/mango"
state_file="$state_dir/wallpaper"
mkdir -p "$state_dir"
tmp_state=$(mktemp "${state_file}.XXXXXX")
printf '%s\n' "$dst_abs" > "$tmp_state"
mv "$tmp_state" "$state_file"

# Regenerate colors. -n keeps pywal from setting the wallpaper itself; -s
# stops it from broadcasting OSC colour sequences to every terminal, which
# kwrited turns into a noisy "local system message" notification.
wal -i "$dst" -n -q -s

# Regenerate the adaptive rofi and Quickshell bar colors.
bash "$script_dir/theme-refresh.sh" "$dst" >/dev/null 2>&1 || true

# Apply the new palette to mangowm.
mmsg dispatch reload_config >/dev/null 2>&1 || true

# Quickshell watches ~/.cache/wal and recolours itself. Restart from the
# recorded Mango wallpaper path so live changes and login use the same image.
setsid bash "$script_dir/restore-wallpaper.sh" >/dev/null 2>&1 &
