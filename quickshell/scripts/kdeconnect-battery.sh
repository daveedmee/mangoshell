#!/usr/bin/env bash
# Report battery state from KDE Connect. BlueZ's Battery1 value can lag behind
# the phone's own battery reading; KDE Connect receives the phone status over
# the paired LAN connection. Output is a JSON array for the shell popover.
set -uo pipefail

command -v kdeconnect-cli >/dev/null 2>&1 || { printf '%s\n' '[]'; exit 0; }
command -v busctl >/dev/null 2>&1 || { printf '%s\n' '[]'; exit 0; }
command -v jq >/dev/null 2>&1 || { printf '%s\n' '[]'; exit 0; }

entries=()
while IFS= read -r line; do
    [ -n "$line" ] || continue
    id="${line%% *}"
    name="${line#* }"
    [ -n "$id" ] && [ "$name" != "$line" ] || continue

    base="/modules/kdeconnect/devices/${id}/battery"
    has_battery=$(busctl --user get-property org.kde.kdeconnect "$base" \
        org.kde.kdeconnect.device.battery hasBattery 2>/dev/null | awk '{print $2}')
    [ "$has_battery" = "true" ] || continue

    charge=$(busctl --user get-property org.kde.kdeconnect "$base" \
        org.kde.kdeconnect.device.battery charge 2>/dev/null | awk '{print $2}')
    [[ "$charge" =~ ^[0-9]+$ ]] || continue

    charging=$(busctl --user get-property org.kde.kdeconnect "$base" \
        org.kde.kdeconnect.device.battery isCharging 2>/dev/null | awk '{print $2}')
    [ "$charging" = "true" ] || charging=false

    entries+=("$(jq -cn \
        --arg name "$name" \
        --argjson charge "$charge" \
        --argjson charging "$charging" \
        '{name: $name, charge: $charge, charging: $charging}')")
done < <(kdeconnect-cli -l --id-name-only 2>/dev/null || true)

if [ "${#entries[@]}" -eq 0 ]; then
    printf '%s\n' '[]'
else
    printf '%s\n' "${entries[@]}" | jq -s .
fi
