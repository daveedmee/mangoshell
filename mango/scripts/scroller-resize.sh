#!/usr/bin/env bash
# Grow or shrink the focused scroller column in 5% steps, clamped to 20–100%.
set -euo pipefail

direction="${1:-}"
case "$direction" in
    up|down) ;;
    *) echo "usage: scroller-resize.sh up|down" >&2; exit 2 ;;
esac

command -v mmsg >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

config_file="${XDG_CONFIG_HOME:-$HOME/.config}/mango/config.toml"
read_int() {
    local key="$1" fallback="$2" value
    value=$(awk -v key="$key" -F'=' '
        $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
            gsub(/[^0-9]/, "", $2)
            print $2
            exit
        }' "$config_file" 2>/dev/null || true)
    printf '%s\n' "${value:-$fallback}"
}

structs=$(read_int scroller_structs 20)
gap=$(read_int gap_inner_horizontal 10)

data=$(mmsg get focusing-client 2>/dev/null) || exit 0
IFS=$'\t' read -r monitor floating maximized fullscreen width < <(
    jq -r '[.monitor, .is_floating, .is_maximized, .is_fullscreen, .width] | @tsv' <<<"$data"
)

# Floating, maximized, and fullscreen windows use their own resize paths.
[ "$floating" = "true" ] && exit 0
[ "$maximized" = "true" ] && exit 0
[ "$fullscreen" = "true" ] && exit 0

monitor_width=$(mmsg get all-monitors 2>/dev/null |
    jq -r --arg monitor "$monitor" \
        '.monitors[] | select(.name == $monitor) | .width' |
    head -n1)
[ -n "$monitor_width" ] || exit 0

# Same column width formula as Mango's set_proportion dispatch.
max_width=$((monitor_width - 2 * structs - gap))
[ "$max_width" -gt 0 ] || exit 0

current=$(jq -rn --argjson width "$width" --argjson max "$max_width" \
    '$width / $max')

new=$(jq -rn --argjson current "$current" --arg direction "$direction" '
    (if $direction == "up" then 0.05 else -0.05 end) as $step
    | (($current + $step) * 1000 | round / 1000)
    | if . < 0.2 then 0.2 elif . > 1.0 then 1.0 else . end
')

mmsg dispatch "set_proportion,$new" >/dev/null 2>&1 || true
