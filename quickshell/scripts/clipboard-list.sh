#!/usr/bin/env bash
# Index cliphist entries, decoding image items into a cache directory once.
set -euo pipefail

command -v cliphist >/dev/null 2>&1 || { printf '[]\n'; exit 0; }
command -v jq >/dev/null 2>&1 || { printf '[]\n'; exit 0; }

cache="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/clipboard"
mkdir -p "$cache"

limit="${1:-80}"
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

cliphist list 2>/dev/null | head -n "$limit" | while IFS=$'\t' read -r id preview; do
    [ -n "${id:-}" ] || continue
    if ! cliphist decode "$id" > "$tmp" 2>/dev/null; then
        continue
    fi

    mime=$(file -b --mime-type "$tmp" 2>/dev/null || echo text/plain)
    type=text
    image=""
    ext=""
    case "$mime" in
        image/png) type=image; ext=png ;;
        image/jpeg) type=image; ext=jpg ;;
        image/webp) type=image; ext=webp ;;
        image/gif) type=image; ext=gif ;;
        image/bmp) type=image; ext=bmp ;;
    esac

    if [ "$type" = "image" ]; then
        image="$cache/$id.$ext"
        cp -f "$tmp" "$image"
    fi

    length=$(wc -c < "$tmp" | tr -d ' ')
    jq -cn \
        --arg id "$id" \
        --arg preview "$preview" \
        --arg type "$type" \
        --arg image "$image" \
        --argjson length "$length" \
        --arg mime "$mime" \
        '{id:$id, preview:$preview, type:$type, image:$image, length:$length, mime:$mime}'
done | jq -s '.'
