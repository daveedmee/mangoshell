#!/usr/bin/env bash
# Open the source of a notification, or a file attached by a system notifier.
# Usage: notification-open.sh <desktop-entry> <app-name> <body>
set -uo pipefail

entry="${1:-}"
app="${2:-}"
body="${3:-}"

# Screenshot notifications from notify-send put the image path in the body.
if [ -n "$body" ] && [ -f "$body" ]; then
    case "$body" in
        *.png|*.jpg|*.jpeg|*.webp|*.gif|*.bmp|*.svg)
            exec xdg-open "$body"
            ;;
    esac
fi

normalize() {
    printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]' |
        sed -E 's/\.desktop$//; s/[^a-z0-9]//g'
}

entry_norm=$(normalize "$entry")
app_norm=$(normalize "$app")

# Prefer focusing an existing window instead of spawning a duplicate. Mango
# has focus_cross_tag disabled here, so switch tags before focusing when needed.
if command -v mmsg >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    clients=$(mmsg get all-clients 2>/dev/null || true)
    if [ -n "$clients" ]; then
        client=$(jq -r --arg entry "$entry_norm" --arg app "$app_norm" '
            def norm: ascii_downcase | gsub("[^a-z0-9]"; "");
            [ .clients[]? | . + { _appid: (.appid | norm) } ]
            | map(select(
                ($entry != "" and ._appid == $entry)
                or ($app != "" and ._appid == $app)
                or ($app != "" and (._appid | contains($app)))
            ))
            | (.[0] // empty)
            | (((.id // "") | tostring) + " " + ((.tags[0] // "") | tostring))
        ' <<<"$clients" 2>/dev/null || true)

        if [ -n "$client" ]; then
            client_id="${client%% *}"
            client_tag="${client#* }"
            # Mango has focus_cross_tag disabled in this setup, so focusid
            # alone cannot reveal a client on another workspace.
            if [ -n "$client_tag" ]; then
                mmsg dispatch "view,$client_tag,0" >/dev/null 2>&1 || true
                sleep 0.08
            fi
            mmsg dispatch "focusid,$client_id" >/dev/null 2>&1 && exit 0
        fi
    fi
fi

# Nothing running yet: launch the application attached to the notification.
desktop_file=""
entry_base="${entry%.desktop}"
if [ -n "$entry" ]; then
    if [ -f "$entry" ]; then
        desktop_file="$entry"
    else
        for base in "$HOME/.local/share/applications" \
                    "/usr/local/share/applications" \
                    "/usr/share/applications"; do
            if [ -f "$base/$entry_base.desktop" ]; then
                desktop_file="$base/$entry_base.desktop"
                break
            fi
        done
    fi
fi

if [ -z "$desktop_file" ] && [ -n "$app" ]; then
    while IFS= read -r candidate; do
        name=$(sed -n 's/^Name=//p' "$candidate" | head -n 1)
        if [ "${name,,}" = "${app,,}" ]; then
            desktop_file="$candidate"
            break
        fi
    done < <(find "$HOME/.local/share/applications" \
                  "/usr/local/share/applications" \
                  "/usr/share/applications" \
                  -maxdepth 1 -type f -name '*.desktop' 2>/dev/null)
fi

if [ -n "$desktop_file" ]; then
    gtk-launch "$(basename "$desktop_file" .desktop)" >/dev/null 2>&1 && exit 0
    gio launch "$desktop_file" >/dev/null 2>&1 && exit 0
fi

if [ -n "$entry_base" ] && command -v gtk-launch >/dev/null 2>&1; then
    gtk-launch "$entry_base" >/dev/null 2>&1 && exit 0
fi

exit 1
