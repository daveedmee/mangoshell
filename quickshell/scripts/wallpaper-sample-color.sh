#!/usr/bin/env bash
# Read one pixel from a wallpaper and print it as #rrggbb.
# The click position is passed as fractions in the range 0..1.
set -euo pipefail

path="${1:-}"
fx="${2:-0.5}"
fy="${3:-0.5}"

[ -r "$path" ] || exit 1

if command -v magick >/dev/null 2>&1; then
    im=magick
    identify_cmd=(magick identify)
elif command -v convert >/dev/null 2>&1; then
    im=convert
    identify_cmd=(identify)
else
    exit 1
fi

size=$("${identify_cmd[@]}" -format '%w %h' "$path" 2>/dev/null) || exit 1
read -r width height <<< "$size"
[[ "$width" =~ ^[0-9]+$ && "$height" =~ ^[0-9]+$ ]] || exit 1

px=$(awk -v f="$fx" -v n="$width" 'BEGIN {
    if (f < 0) f = 0
    if (f > 1) f = 1
    x = int(f * (n - 1) + 0.5)
    if (x >= n) x = n - 1
    print x
}')
py=$(awk -v f="$fy" -v n="$height" 'BEGIN {
    if (f < 0) f = 0
    if (f > 1) f = 1
    y = int(f * (n - 1) + 0.5)
    if (y >= n) y = n - 1
    print y
}')

hex=$(magick "$path" -format "%[hex:p{$px,$py}]" info: 2>/dev/null) || exit 1
[[ "$hex" =~ ^[0-9A-Fa-f]{6,8}$ ]] || exit 1
printf '#%s\n' "${hex:0:6}"
