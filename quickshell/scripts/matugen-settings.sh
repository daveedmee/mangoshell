#!/usr/bin/env bash
# Read and persist the Matugen options used by the Quickshell wallpaper
# gallery. Regenerating always uses the wallpaper currently applied through
# set-wallpaper.sh; changing settings never changes the wallpaper itself.
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
settings_file="$config_home/quickshell/matugen.json"
theme_refresh="$config_home/mango/scripts/theme-refresh.sh"

defaults='{
    "scheme": "scheme-tonal-spot",
    "contrast": 0,
    "mode": "auto",
    "prefer": "saturation",
    "sourceColor": "",
    "textColor": "",
    "activeColor": "",
    "backgroundColor": "",
    "lightnessDark": 0,
    "lightnessLight": 0
}'

valid_schemes=" scheme-content scheme-expressive scheme-fidelity scheme-fruit-salad scheme-monochrome scheme-neutral scheme-rainbow scheme-tonal-spot scheme-vibrant scheme-smart "
valid_prefers=" darkness lightness saturation less-saturation value closest-to-fallback "

ensure_settings() {
    mkdir -p "$(dirname "$settings_file")"
    if [ ! -s "$settings_file" ] || ! jq -e . "$settings_file" >/dev/null 2>&1; then
        printf '%s\n' "$defaults" > "$settings_file"
        return 0
    fi

    local merged
    merged=$(jq -c --argjson defaults "$defaults" '$defaults * .' "$settings_file")
    printf '%s\n' "$merged" > "$settings_file"
}

get_settings() {
    ensure_settings
    jq -c . "$settings_file"
}

apply_settings() {
    local scheme="" contrast="" mode="" prefer="" source_color="" text_color="" active_color="" background_color="" lightness_dark="" lightness_light=""

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --scheme) scheme="${2:-}"; shift 2 ;;
            --contrast) contrast="${2:-}"; shift 2 ;;
            --mode) mode="${2:-}"; shift 2 ;;
            --prefer) prefer="${2:-}"; shift 2 ;;
            --source-color) source_color="${2:-}"; shift 2 ;;
            --text-color) text_color="${2:-}"; shift 2 ;;
            --active-color) active_color="${2:-}"; shift 2 ;;
            --background-color) background_color="${2:-}"; shift 2 ;;
            --lightness-dark) lightness_dark="${2:-}"; shift 2 ;;
            --lightness-light) lightness_light="${2:-}"; shift 2 ;;
            *) shift ;;
        esac
    done

    ensure_settings
    local current
    current=$(jq -c . "$settings_file")

    [ -n "$scheme" ] || scheme=$(jq -r '.scheme' <<< "$current")
    [ -n "$contrast" ] || contrast=$(jq -r '.contrast' <<< "$current")
    [ -n "$mode" ] || mode=$(jq -r '.mode' <<< "$current")
    [ -n "$prefer" ] || prefer=$(jq -r '.prefer' <<< "$current")
    [ -n "$source_color" ] || source_color=$(jq -r '.sourceColor' <<< "$current")
    [ -n "$text_color" ] || text_color=$(jq -r '.textColor // ""' <<< "$current")
    [ -n "$active_color" ] || active_color=$(jq -r '.activeColor // ""' <<< "$current")
    [ -n "$background_color" ] || background_color=$(jq -r '.backgroundColor // ""' <<< "$current")
    [ -n "$lightness_dark" ] || lightness_dark=$(jq -r '.lightnessDark' <<< "$current")
    [ -n "$lightness_light" ] || lightness_light=$(jq -r '.lightnessLight' <<< "$current")

    case "$valid_schemes" in *" $scheme "*) ;; *) scheme="scheme-tonal-spot" ;; esac
    case "$valid_prefers" in *" $prefer "*) ;; *) prefer="saturation" ;; esac
    case "$mode" in auto|dark|light) ;; *) mode="auto" ;; esac

    [[ "$source_color" =~ ^#[0-9a-fA-F]{6}$ ]] || source_color=""
    [[ "$text_color" =~ ^#[0-9a-fA-F]{6}$ ]] || text_color=""
    [[ "$active_color" =~ ^#[0-9a-fA-F]{6}$ ]] || active_color=""
    [[ "$background_color" =~ ^#[0-9a-fA-F]{6}$ ]] || background_color=""

    contrast=$(awk -v value="$contrast" 'BEGIN { v=value+0; if (v < -1) v=-1; if (v > 1) v=1; printf "%.4f", v }')
    lightness_dark=$(awk -v value="$lightness_dark" 'BEGIN { v=value+0; if (v < -0.8) v=-0.8; if (v > 0.8) v=0.8; printf "%.4f", v }')
    lightness_light=$(awk -v value="$lightness_light" 'BEGIN { v=value+0; if (v < -0.8) v=-0.8; if (v > 0.8) v=0.8; printf "%.4f", v }')

    local tmp
    tmp=$(mktemp "${settings_file}.XXXXXX")
    jq -n \
        --arg scheme "$scheme" \
        --argjson contrast "$contrast" \
        --arg mode "$mode" \
        --arg prefer "$prefer" \
        --arg sourceColor "$source_color" \
        --arg textColor "$text_color" \
        --arg activeColor "$active_color" \
        --arg backgroundColor "$background_color" \
        --argjson lightnessDark "$lightness_dark" \
        --argjson lightnessLight "$lightness_light" \
        '{scheme:$scheme, contrast:$contrast, mode:$mode, prefer:$prefer, sourceColor:$sourceColor, textColor:$textColor, activeColor:$activeColor, backgroundColor:$backgroundColor, lightnessDark:$lightnessDark, lightnessLight:$lightnessLight}' \
        > "$tmp"
    mv "$tmp" "$settings_file"

    bash "$theme_refresh" >/dev/null 2>&1 || true
}

case "${1:-get}" in
    get) get_settings ;;
    apply) shift; apply_settings "$@" ;;
    reset)
        printf '%s\n' "$defaults" > "$settings_file"
        bash "$theme_refresh" >/dev/null 2>&1 || true
        ;;
    *)
        echo "usage: matugen-settings.sh [get|apply|reset]" >&2
        exit 1
        ;;
esac
