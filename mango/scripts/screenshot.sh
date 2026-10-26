#!/usr/bin/env bash
# Screenshots for mango (and Plasma).
#   region | fullscreen | window
#
# Spectacle cannot capture on Wayland outside KWin, so Mango uses grim+slurp.
# Under Plasma the script still delegates to Spectacle.
set -uo pipefail

mode="${1:-region}"

if pgrep -x kwin_wayland >/dev/null 2>&1 || [[ "${XDG_CURRENT_DESKTOP:-}" == *KDE* ]]; then
    case "$mode" in
        region)     exec spectacle -r ;;
        fullscreen) exec spectacle -f ;;
        window)     exec spectacle -a ;;
    esac
fi

if ! command -v grim >/dev/null 2>&1; then
    command -v notify-send >/dev/null 2>&1 &&
        notify-send "Screenshot" "grim is not installed."
    exit 1
fi

pictures=""
if command -v xdg-user-dir >/dev/null 2>&1; then
    pictures=$(xdg-user-dir PICTURES 2>/dev/null || true)
fi
if [ -z "$pictures" ] || [ "$pictures" = "$HOME" ]; then
    if [ -d "$HOME/Bilder" ]; then
        pictures="$HOME/Bilder"
    else
        pictures="$HOME/Pictures"
    fi
fi
dir="$pictures/Screenshots"
if ! mkdir -p "$dir"; then
    command -v notify-send >/dev/null 2>&1 &&
        notify-send "Screenshot failed" "Could not create $dir"
    exit 1
fi
file="$dir/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

case "$mode" in
    region)
        command -v slurp >/dev/null 2>&1 || exit 1
        # Dim the screen slightly while selecting, but leave the selected
        # rectangle clear so the captured area remains readable.
        # The matching "selection" layer rule in Mango disables layer blur.
        geometry=$(slurp -b '#00000014' -s '#00000000' -c '#ffffffff' -w 1) || exit 0
        grim -g "$geometry" "$file" || exit 1
        ;;
    window)
        geometry=""
        if command -v mmsg >/dev/null 2>&1; then
            geometry=$(mmsg get focusing-client 2>/dev/null | jq -r '
                if (.x != null and .y != null and .width != null and .height != null)
                then "\(.x),\(.y) \(.width)x\(.height)" else empty end' 2>/dev/null)
        fi
        if [ -n "$geometry" ]; then
            grim -g "$geometry" "$file" || exit 1
        else
            grim "$file" || exit 1
        fi
        ;;
    *)
        grim "$file" || exit 1
        ;;
esac

wl-copy < "$file" 2>/dev/null || true
command -v notify-send >/dev/null 2>&1 &&
    notify-send -i "$file" "Screenshot saved" "$file"
