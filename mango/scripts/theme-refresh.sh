#!/usr/bin/env bash
# Generate adaptive light/dark colors for rofi and the Quickshell bar from the
# current wallpaper. Auto mode follows the wallpaper as a whole (Matugen's
# smart mode when possible); the top strip only decides whether the bar needs
# a text halo.
set -euo pipefail

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
cache_home="${XDG_CACHE_HOME:-$HOME/.cache}"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

# ImageMagick 7 installs `magick`; some distributions only ship `convert`.
if command -v magick >/dev/null 2>&1; then
    im=magick
elif command -v convert >/dev/null 2>&1; then
    im=convert
else
    im=""
fi

wall="${1:-}"
if [ -z "$wall" ] || [ ! -r "$wall" ]; then
    # No explicit path: use the wallpaper Mango recorded.
    wall=$(bash "$script_dir/wallpaper-path.sh" 2>/dev/null || true)
fi

colors="$cache_home/wal/colors.sh"
mode_file="$cache_home/wal/surface-mode"
outline_file="$cache_home/wal/surface-outline"
rofi_css="$config_home/rofi/colors.rasi"
settings_file="$config_home/quickshell/matugen.json"

matugen_scheme="scheme-tonal-spot"
matugen_contrast="0"
matugen_mode="auto"
matugen_prefer="saturation"
matugen_source=""
matugen_text_color=""
matugen_active_color=""
matugen_background_color=""
matugen_lightness_dark="0"
matugen_lightness_light="0"

if [ -r "$settings_file" ] && command -v jq >/dev/null 2>&1; then
    matugen_scheme=$(jq -r '.scheme // "scheme-tonal-spot"' "$settings_file" 2>/dev/null || true)
    matugen_contrast=$(jq -r '.contrast // 0' "$settings_file" 2>/dev/null || true)
    matugen_mode=$(jq -r '.mode // "auto"' "$settings_file" 2>/dev/null || true)
    matugen_prefer=$(jq -r '.prefer // "saturation"' "$settings_file" 2>/dev/null || true)
    matugen_source=$(jq -r '.sourceColor // ""' "$settings_file" 2>/dev/null || true)
    matugen_text_color=$(jq -r '.textColor // ""' "$settings_file" 2>/dev/null || true)
    matugen_active_color=$(jq -r '.activeColor // ""' "$settings_file" 2>/dev/null || true)
    matugen_background_color=$(jq -r '.backgroundColor // ""' "$settings_file" 2>/dev/null || true)
    matugen_lightness_dark=$(jq -r '.lightnessDark // 0' "$settings_file" 2>/dev/null || true)
    matugen_lightness_light=$(jq -r '.lightnessLight // 0' "$settings_file" 2>/dev/null || true)
fi

[ -r "$colors" ] || exit 0
mkdir -p "$cache_home/wal" "$config_home/rofi"

# colors.sh uses $FZF_DEFAULT_OPTS/$LS_COLORS, which may be unset.
set +u
# shellcheck disable=SC1090
source "$colors"
set -u

# Small colour helpers so every generated value comes from the wal palette.
hex_normalize() {
    local hex="${1#\#}"
    if [ "${#hex}" -eq 3 ]; then
        hex="${hex:0:1}${hex:0:1}${hex:1:1}${hex:1:1}${hex:2:1}${hex:2:1}"
    fi
    printf '%s' "${hex:0:6}"
}

rgba_color() {
    local hex alpha
    hex=$(hex_normalize "$1")
    alpha="$2"
    printf 'rgba(%d, %d, %d, %s)' \
        "$((16#${hex:0:2}))" \
        "$((16#${hex:2:2}))" \
        "$((16#${hex:4:2}))" \
        "$alpha"
}

luma() {
    local hex r g b
    hex=$(hex_normalize "$1")
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))
    printf '%d' "$(((r * 299 + g * 587 + b * 114) / 1000))"
}

top_mean="0.5"
top_std="0"
whole_mean="0.5"
if [ -n "$im" ] && [ -r "$wall" ]; then
    stats=$("$im" "$wall" -gravity north -crop 100%x3%+0+0 +repage \
        -colorspace Gray -format '%[fx:mean] %[fx:standard_deviation]' info: 2>/dev/null \
        || echo "0.5 0")
    top_mean="${stats%% *}"
    top_std="${stats##* }"
    whole_mean=$("$im" "$wall" -colorspace Gray -format '%[fx:mean]' info: 2>/dev/null \
        || echo "0.5")
fi

# Fallback when Matugen's smart mode cannot inspect the image (for example
# when an explicit source colour is configured).
mode=$(awk -v m="${whole_mean:-0.5}" 'BEGIN { print (m > 0.55) ? "light" : "dark" }')
if [ "$matugen_mode" = "dark" ] || [ "$matugen_mode" = "light" ]; then
    mode="$matugen_mode"
fi

# Mixed black/white or mid-grey tops cannot support either text colour alone.
# In that case the bar adds a one-pixel halo behind its text and icons.
outline=$(awk -v m="${top_mean:-0.5}" -v s="${top_std:-0}" 'BEGIN {
    mid = (m > 0.32 && m < 0.68) ? 1 : 0
    busy = (s > 0.20) ? 1 : 0
    print (mid || busy) ? 1 : 0
}')

wal_bg="${background:-${color0:-}}"
wal_fg="${foreground:-${color7:-}}"
if [ -z "$wal_bg" ] || [ -z "$wal_fg" ]; then
    echo "theme-refresh: wal palette is missing background/foreground" >&2
    exit 0
fi

if [ "$mode" = "light" ]; then
    # Use the lighter of color6/color7 for large light surfaces.
    surface_hex="${color6:-$wal_fg}"
    if [ "$(luma "$wal_fg")" -gt "$(luma "$surface_hex")" ]; then
        surface_hex="$wal_fg"
    fi
    text_hex="$wal_bg"
    overlay_hex="$wal_bg"
    border_alpha="0.12"
    input_alpha="0.05"
    rofi_selected_alpha="0.09"
else
    surface_hex="$wal_bg"
    text_hex="$wal_fg"
    overlay_hex="$wal_fg"
    border_alpha="0.14"
    input_alpha="0.07"
    rofi_selected_alpha="0.10"
fi

text_dim="${color8:-$text_hex}"
text="$text_hex"
border=$(rgba_color "$overlay_hex" "$border_alpha")
rofi_bg=$(rgba_color "$surface_hex" 0.96)
rofi_input=$(rgba_color "$overlay_hex" "$input_alpha")
rofi_selected=$(rgba_color "$overlay_hex" "$rofi_selected_alpha")

printf '%s\n' "$outline" > "$outline_file"

tmp_rasi=$(mktemp "${rofi_css}.XXXXXX")
cat > "$tmp_rasi" <<EOF
/* Generated by theme-refresh.sh from the pywal palette ($mode, whole mean $whole_mean, top mean $top_mean, top std $top_std, outline $outline). */
* {
    col-bg: $rofi_bg;
    col-fg: $text;
    col-dim: $text_dim;
    col-border: $border;
    col-input: $rofi_input;
    col-selected: $rofi_selected;
}
EOF
mv "$tmp_rasi" "$rofi_css"

# ── Matugen palettes for Quickshell ─────────────────────────────────────
# Keep one atomically replaced JSON file with both dark and light palettes so
# the shell can switch modes without invoking Matugen at runtime.
if command -v matugen >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    theme_dir="$cache_home/quickshell"
    theme_json="$theme_dir/theme.json"
    mkdir -p "$theme_dir"

    matugen_roles() {
        local scheme_mode="$1"
        local output
        local common=(
            --dry-run
            --mode "$scheme_mode"
            --type "$matugen_scheme"
            --contrast "$matugen_contrast"
            --prefer "$matugen_prefer"
            --lightness-dark "$matugen_lightness_dark"
            --lightness-light "$matugen_lightness_light"
            --json hex
        )

        if [ -n "$matugen_source" ]; then
            output=$(matugen color hex "$matugen_source" "${common[@]}" 2>/dev/null || true)
        else
            output=$(matugen image "$wall" "${common[@]}" 2>/dev/null || true)
        fi

        printf '%s' "$output" |
            jq -c '[.colors | to_entries[] | {(.key): .value.default.color}] | add' \
                2>/dev/null || true
    }

    case "$matugen_scheme" in
        scheme-content) scheme_label="Content" ;;
        scheme-expressive) scheme_label="Expressive" ;;
        scheme-fidelity) scheme_label="Fidelity" ;;
        scheme-fruit-salad) scheme_label="Fruit salad" ;;
        scheme-monochrome) scheme_label="Monochrome" ;;
        scheme-neutral) scheme_label="Neutral" ;;
        scheme-rainbow) scheme_label="Rainbow" ;;
        scheme-vibrant) scheme_label="Vibrant" ;;
        scheme-smart) scheme_label="Smart" ;;
        *) scheme_label="Tonal spot" ;;
    esac

    dark_roles=""
    light_roles=""

    # Auto mode asks Matugen to inspect the whole image. Smart mode returns a
    # light or dark palette depending on the wallpaper, which is more reliable
    # than judging a single crop. An explicit source colour cannot be used
    # with smart mode, so that case keeps the whole-image fallback above.
    if [ "$matugen_mode" = "auto" ] && [ -z "$matugen_source" ]; then
        smart_roles=$(matugen_roles smart)
        if [ -n "$smart_roles" ]; then
            smart_bg=$(printf '%s' "$smart_roles" | jq -r '.background // empty' 2>/dev/null || true)
            if [ -n "$smart_bg" ]; then
                if [ "$(luma "$smart_bg")" -ge 128 ]; then
                    mode="light"
                    light_roles="$smart_roles"
                    dark_roles=$(matugen_roles dark)
                else
                    mode="dark"
                    dark_roles="$smart_roles"
                    light_roles=$(matugen_roles light)
                fi
            fi
        fi
    fi

    if [ -z "$dark_roles" ] || [ -z "$light_roles" ]; then
        dark_roles=$(matugen_roles dark)
        light_roles=$(matugen_roles light)
    fi

    if [ -n "$dark_roles" ] && [ -n "$light_roles" ]; then
        wall_abs=$(readlink -f -- "$wall" 2>/dev/null || printf '%s' "$wall")
        tmp_theme=$(mktemp "${theme_json}.XXXXXX")
        if jq -n \
            --arg wallpaper "$wall_abs" \
            --arg mode "$mode" \
            --arg scheme "$scheme_label" \
            --arg matugenScheme "$matugen_scheme" \
            --arg matugenMode "$matugen_mode" \
            --argjson contrast "$matugen_contrast" \
            --arg sourceColor "$matugen_source" \
            --argjson dark "$dark_roles" \
            --argjson light "$light_roles" \
            '{wallpaper:$wallpaper, mode:$mode, scheme:$scheme,
              matugen:{scheme:$matugenScheme, mode:$matugenMode, contrast:$contrast, sourceColor:$sourceColor},
              dark:$dark, light:$light}' \
            > "$tmp_theme"; then
            mv "$tmp_theme" "$theme_json"
        else
            rm -f "$tmp_theme"
        fi

        # Use the same Matugen surface/text/active roles as Quickshell for
        # rofi instead of leaving rofi on the older pywal palette. Matugen
        # settings changes now visibly update every rofi launch.
        active_roles="$dark_roles"
        if [ "$mode" = "light" ]; then
            active_roles="$light_roles"
        fi

        if [ -n "$active_roles" ]; then
            role() {
                printf '%s' "$active_roles" |
                    jq -r --arg key "$1" --arg fallback "$2" '.[$key] // $fallback'
            }

            rofi_surface=$(role surface_container "$(role surface "#101010")")
            rofi_text=$(role on_surface "#eeeeee")
            rofi_dim=$(role on_surface_variant "$(role outline "#aaaaaa")")
            rofi_outline=$(role outline_variant "$(role outline "#555555")")
            rofi_active=$(role primary "#bbbbbb")

            if [[ "$matugen_background_color" =~ ^#[0-9a-fA-F]{6}$ ]]; then
                rofi_surface="$matugen_background_color"
            fi
            if [[ "$matugen_text_color" =~ ^#[0-9a-fA-F]{6}$ ]]; then
                rofi_text="$matugen_text_color"
            fi
            if [[ "$matugen_active_color" =~ ^#[0-9a-fA-F]{6}$ ]]; then
                rofi_active="$matugen_active_color"
            fi

            tmp_rasi=$(mktemp "${rofi_css}.XXXXXX")
            cat > "$tmp_rasi" <<EOF
/* Generated by theme-refresh.sh from Matugen ($scheme_label, $mode). */
* {
    col-bg: $(rgba_color "$rofi_surface" 0.97);
    col-fg: $rofi_text;
    col-dim: $(rgba_color "$rofi_dim" 0.82);
    col-border: $(rgba_color "$rofi_outline" 0.58);
    col-input: $(rgba_color "$rofi_text" 0.05);
    col-selected: $(rgba_color "$rofi_active" 0.14);
}
EOF
            mv "$tmp_rasi" "$rofi_css"
        fi
    fi
fi

printf '%s\n' "$mode" > "$mode_file"
printf 'surface mode: %s (whole mean %s, top mean %s, top std %s, outline %s)\n' \
    "$mode" "$whole_mean" "$top_mean" "$top_std" "$outline"

# Keep Qt/KDE and GTK applications on the same Matugen palette as the shell.
theme_json="$cache_home/quickshell/theme.json"
if [ -r "$theme_json" ] && [ -x "$script_dir/theme-sync-apps.py" ]; then
    python3 "$script_dir/theme-sync-apps.py" >/dev/null 2>&1 || true
fi
