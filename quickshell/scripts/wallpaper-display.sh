#!/usr/bin/env bash
# Persist and apply wallpaper placement independently of the Matugen palette.
# swaybg handles the actual placement: fill scales/crops to cover, fit scales
# the whole image, and center/tile/fit use the base colour for exposed areas.
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
settings_file="$config_home/quickshell/wallpaper.json"
wallpaper_path="$config_home/mango/scripts/wallpaper-path.sh"

mode="fill"
color="#000000"

if [ -r "$settings_file" ] && command -v jq >/dev/null 2>&1; then
    mode=$(jq -r '.mode // "fill"' "$settings_file" 2>/dev/null || true)
    color=$(jq -r '.color // "#000000"' "$settings_file" 2>/dev/null || true)
fi

normalize_mode() {
    case "$1" in
        crop|fill) printf '%s' fill ;;
        scale|fit) printf '%s' fit ;;
        stretch|tile|center) printf '%s' "$1" ;;
        *) printf '%s' fill ;;
    esac
}

normalize_color() {
    local value="${1:-}"
    if [[ "$value" =~ ^#[0-9a-fA-F]{6}$ ]]; then
        printf '%s' "${value,,}"
    else
        printf '%s' "#000000"
    fi
}

mode=$(normalize_mode "$mode")
color=$(normalize_color "$color")

case "${1:-get}" in
    get)
        printf '{"mode":"%s","color":"%s"}\n' "$mode" "$color"
        ;;
    apply)
        shift
        new_mode=""
        new_color=""
        while [ "$#" -gt 0 ]; do
            case "$1" in
                --mode) new_mode="${2:-}"; shift 2 ;;
                --color) new_color="${2:-}"; shift 2 ;;
                *) shift ;;
            esac
        done

        [ -n "$new_mode" ] && mode=$(normalize_mode "$new_mode")
        [ -n "$new_color" ] && color=$(normalize_color "$new_color")

        mkdir -p "$(dirname "$settings_file")"
        tmp=$(mktemp "${settings_file}.XXXXXX")
        jq -n --arg mode "$mode" --arg color "$color" \
            '{mode:$mode, color:$color}' > "$tmp"
        mv "$tmp" "$settings_file"

        wall=$(bash "$wallpaper_path" 2>/dev/null || true)
        if [ -n "$wall" ] && [ -r "$wall" ]; then
            pkill -x swaybg >/dev/null 2>&1 || true
            setsid swaybg -i "$wall" -m "$mode" -c "${color#\#}" \
                >/dev/null 2>&1 &
        fi
        printf '{"mode":"%s","color":"%s"}\n' "$mode" "$color"
        ;;
    *)
        echo "usage: wallpaper-display.sh [get|apply --mode fill|fit|stretch|tile|center --color #RRGGBB]" >&2
        exit 1
        ;;
esac
