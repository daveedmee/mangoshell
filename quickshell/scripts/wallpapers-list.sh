#!/usr/bin/env bash
# Index wallpapers under the configured folder (default: ~/Bilder, then
# ~/Pictures) without touching hidden folders or Photos libraries.
# Dimensions are resolved on demand by wallpaper-info.sh.
set -euo pipefail

root="${1:-}"
if [ -z "$root" ] || [ ! -d "$root" ]; then
    if [ -n "${XDG_PICTURES_DIR:-}" ] && [ -d "$XDG_PICTURES_DIR" ]; then
        root="$XDG_PICTURES_DIR"
    elif [ -d "$HOME/Bilder" ]; then
        root="$HOME/Bilder"
    else
        root="$HOME/Pictures"
    fi
fi
[ -d "$root" ] || { printf '[]\n'; exit 0; }

python3 - "$root" <<'PY'
import json
import os
import sys

root = os.path.abspath(sys.argv[1])
exts = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".avif"}
skip_dirs = {".debris", "Photos Library.photoslibrary", "lost+found"}
items = []

for current, dirs, files in os.walk(root):
    rel = os.path.relpath(current, root)
    depth = 0 if rel == "." else rel.count(os.sep) + 1
    dirs[:] = sorted(
        d for d in dirs
        if not d.startswith(".") and d not in skip_dirs and depth < 4
    )
    for name in files:
        if name.startswith("."):
            continue
        ext = os.path.splitext(name)[1].lower()
        if ext not in exts:
            continue
        path = os.path.join(current, name)
        try:
            stat = os.stat(path)
        except OSError:
            continue
        items.append({
            "path": path,
            "name": name,
            "folder": "All" if rel == "." else rel.split(os.sep)[0],
            "size": stat.st_size,
            "mtime": int(stat.st_mtime),
        })

items.sort(key=lambda item: item["mtime"], reverse=True)
print(json.dumps(items, separators=(",", ":")))
PY
