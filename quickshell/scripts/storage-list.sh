#!/usr/bin/env bash
# Emit every real block-device filesystem and its usage, including unmounted
# partitions, so the shell can show all drives rather than only /.
#
# The extra transport/removable metadata is used by the Devices popover to
# distinguish USB sticks from external hard drives and to decide whether a
# device can be mounted or unmounted.
set -euo pipefail

command -v lsblk >/dev/null 2>&1 || { printf '%s\n' '[]'; exit 0; }
command -v findmnt >/dev/null 2>&1 || { printf '%s\n' '[]'; exit 0; }
command -v jq >/dev/null 2>&1 || { printf '%s\n' '[]'; exit 0; }

devices=$(lsblk -J -b -o NAME,PATH,TYPE,FSTYPE,SIZE,LABEL,MODEL,RO,TRAN,RM,HOTPLUG)
mounts=$(findmnt -J -b -o TARGET,SOURCE,FSTYPE,SIZE,USED,AVAIL,USE% 2>/dev/null |
    jq -c '[.. | objects | select(.source? != null and (.source | startswith("/dev/")))]')

jq -cn --argjson devices "$devices" --argjson mounts "$mounts" '
    def flatten($parent):
        . as $node
        | ([$node + {
            _tran: ($node.tran // $parent.tran // ""),
            _model: ($node.model // $parent.model // ""),
            _rm: ($node.rm // $parent.rm // false),
            _hotplug: ($node.hotplug // $parent.hotplug // false)
        }]
        + ([($node.children // [])[] | flatten($node)] | add // []));

    [ $devices.blockdevices[] | flatten({})[] ]
    | map(select(.type == "part" or (.type == "disk" and ((.fstype // "") | length) > 0)))
    | map(select((.fstype // "") as $fs | ($fs != "" and $fs != "swap" and $fs != "crypto_LUKS")))
    | map(
        . as $disk
        | ($mounts
            | map(select((.source | split("[")[0]) == $disk.path))
            | sort_by(.target | length)
            | .[0]) as $mount
        | {
            name: (.label // .name),
            device: .path,
            size: .size,
            fstype: .fstype,
            model: (._model // ""),
            transport: (._tran // ""),
            removable: (._rm == true),
            hotplug: (._hotplug == true),
            usb: ((._tran // "") == "usb"),
            kind: (if (._tran // "") == "usb"
                then (if ._rm == true then "usb-stick" else "usb-drive" end)
                else "drive" end),
            mounted: ($mount != null),
            mountpoint: ($mount.target // ""),
            used: (if $mount then $mount.used else null end),
            avail: (if $mount then $mount.avail else null end),
            percent: (if $mount and .size > 0
                then (($mount.used * 100 / .size) | floor)
                else null end)
        }
    )
    | sort_by([(if .mounted then 0 else 1 end), .mountpoint, .name])
'
