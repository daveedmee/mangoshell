#!/usr/bin/env bash
# Resolve the metadata and Matugen preview palette for one wallpaper.
set -euo pipefail

path="${1:-}"
[ -r "$path" ] || { printf '%s\n' '{"error":"unreadable"}'; exit 0; }
command -v jq >/dev/null 2>&1 || { printf '%s\n' '{"error":"jq missing"}'; exit 0; }

if command -v magick >/dev/null 2>&1; then
    identify_cmd=(magick identify)
elif command -v identify >/dev/null 2>&1; then
    identify_cmd=(identify)
else
    identify_cmd=()
fi

identify=""
if [ "${#identify_cmd[@]}" -gt 0 ]; then
    identify=$("${identify_cmd[@]}" -format '%w %h' "$path" 2>/dev/null || true)
fi
set -- $identify
width=${1:-0}
height=${2:-0}
size=$(stat -c '%s' "$path" 2>/dev/null || echo 0)

palette='[]'
source_colors='[]'
if command -v matugen >/dev/null 2>&1; then
    palette=$(matugen image "$path" --dry-run --mode dark --type scheme-tonal-spot --json hex --prefer saturation 2>/dev/null |
        jq -c '[.colors.surface_container_lowest.default.color, .colors.primary.default.color, .colors.secondary.default.color, .colors.tertiary.default.color, .colors.on_surface.default.color]' 2>/dev/null || echo '[]')
    source_colors=$(matugen image "$path" --dry-run --show-source-colors 2>/dev/null |
        jq -R -s -c 'split("\n") | map(select(test("^#[0-9a-fA-F]{6}$")))' 2>/dev/null || echo '[]')
fi

jq -cn \
    --arg path "$path" \
    --arg name "$(basename "$path")" \
    --arg folder "$(basename "$(dirname "$path")")" \
    --argjson size "$size" \
    --argjson width "$width" \
    --argjson height "$height" \
    --argjson palette "$palette" \
    --argjson sourceColors "$source_colors" \
    '{path:$path, name:$name, folder:$folder, size:$size, width:$width, height:$height, palette:$palette, sourceColors:$sourceColors}'
