#!/usr/bin/env bash
# Local calendar entries for the Quickshell calendar popover.
# Stored as one atomically replaced JSON document.
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
file="$config_home/quickshell/calendar.json"
command="${1:-list}"

mkdir -p "$(dirname "$file")"
if [ ! -r "$file" ]; then
    printf '%s\n' '{"events":[]}' > "$file"
fi

case "$command" in
    list)
        jq -c . "$file"
        ;;
    add)
        date="${2:-}"
        time="${3:-}"
        title="${4:-}"

        if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            echo "invalid date" >&2
            exit 2
        fi
        if [ -z "$title" ]; then
            echo "empty title" >&2
            exit 2
        fi
        if [ -n "$time" ] && [[ ! "$time" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
            echo "invalid time" >&2
            exit 2
        fi

        id="$(date +%s%N)"
        created="$(date +%s)"
        tmp="$(mktemp "${file}.XXXXXX")"
        jq --arg id "$id" \
            --arg date "$date" \
            --arg time "$time" \
            --arg title "$title" \
            --argjson created "$created" \
            '.events = ((.events // []) + [{
                id: $id,
                date: $date,
                time: $time,
                title: $title,
                created: $created
            }])' "$file" > "$tmp"
        mv "$tmp" "$file"
        ;;
    remove)
        id="${2:-}"
        if [ -z "$id" ]; then
            echo "missing id" >&2
            exit 2
        fi
        tmp="$(mktemp "${file}.XXXXXX")"
        jq --arg id "$id" \
            '.events = [(.events // [])[] | select(.id != $id)]' "$file" > "$tmp"
        mv "$tmp" "$file"
        ;;
    *)
        echo "usage: calendar-events.sh list|add|remove" >&2
        exit 2
        ;;
esac
