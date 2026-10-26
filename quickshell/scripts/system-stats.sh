#!/usr/bin/env bash
# Emit one live system-stats JSON object every two seconds.
set -uo pipefail

read_cpu() {
    local _ user nice system idle iowait irq softirq steal _rest
    read -r _ user nice system idle iowait irq softirq steal _rest < /proc/stat
    total=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle_all=$((idle + iowait))
}

read_net() {
    rx=0
    tx=0
    while read -r line; do
        case "$line" in
            *:*)
                iface=${line%%:*}
                iface=$(printf '%s' "$iface" | tr -d ' ')
                [ "$iface" = "lo" ] && continue
                rest=${line#*:}
                set -- $rest
                rx=$((rx + $1))
                tx=$((tx + $9))
                ;;
        esac
    done < /proc/net/dev
}

format_rate() {
    local bytes="$1"
    if [ "$bytes" -ge 1048576 ]; then
        awk -v b="$bytes" 'BEGIN { printf "%.1f MB/s", b / 1048576 }'
    elif [ "$bytes" -ge 1024 ]; then
        awk -v b="$bytes" 'BEGIN { printf "%.0f KB/s", b / 1024 }'
    else
        printf '%s B/s' "$bytes"
    fi
}

read_swap() {
    local total free
    total=$(awk '/^SwapTotal:/ { print $2; exit }' /proc/meminfo)
    free=$(awk '/^SwapFree:/ { print $2; exit }' /proc/meminfo)
    total=${total:-0}
    free=${free:-0}
    if [ "$total" -gt 0 ]; then
        swap=$((100 * (total - free) / total))
    else
        swap=0
    fi
}

read_gpu() {
    gpu=0
    gpu_available=false
    local path value

    for path in /sys/class/drm/card*/device/gpu_busy_percent; do
        [ -r "$path" ] || continue
        value=$(cat "$path" 2>/dev/null || echo 0)
        [[ "$value" =~ ^[0-9]+$ ]] || continue
        gpu_available=true
        [ "$value" -gt "$gpu" ] && gpu=$value
    done

    if [ "$gpu_available" = false ] && command -v nvidia-smi >/dev/null 2>&1; then
        value=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null |
            head -n 1 | tr -d ' ')
        if [[ "$value" =~ ^[0-9]+$ ]]; then
            gpu=$value
            gpu_available=true
        fi
    fi
}

network_label() {
    local iface freq connection
    for path in /sys/class/net/*/wireless; do
        [ -e "$path" ] || continue
        iface=$(basename "$(dirname "$path")")
        break
    done

    if [ -n "${iface:-}" ]; then
        command -v iw >/dev/null 2>&1 || { printf '%s' "Wi-Fi"; return 0; }
        freq=$(iw dev "$iface" link 2>/dev/null | awk '/freq:/ { print $2; exit }')
        case "${freq:-0}" in
            24[0-9][0-9]) printf '%s' "Wi-Fi · 2.4 GHz" ;;
            5[0-9][0-9][0-9]) printf '%s' "Wi-Fi · 5 GHz" ;;
            6[0-9][0-9][0-9]) printf '%s' "Wi-Fi · 6 GHz" ;;
            *) printf '%s' "Wi-Fi" ;;
        esac
        return 0
    fi

    if command -v nmcli >/dev/null 2>&1; then
        connection=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null |
            awk -F ':' '$2 == "ethernet" && $3 == "connected" { print $4; exit }')
        if [ -n "${connection:-}" ]; then
            printf 'Wired · %s' "$connection"
            return 0
        fi
    fi

    printf '%s' "Offline"
}

read_cpu
prev_total=$total
prev_idle=$idle_all
read_net
prev_rx=$rx
prev_tx=$tx

while true; do
    sleep 2

    read_cpu
    dt=$((total - prev_total))
    di=$((idle_all - prev_idle))
    if [ "$dt" -gt 0 ]; then
        cpu=$((100 * (dt - di) / dt))
    else
        cpu=0
    fi
    prev_total=$total
    prev_idle=$idle_all

    mem_total=$(awk '/^MemTotal:/ { print $2; exit }' /proc/meminfo)
    mem_avail=$(awk '/^MemAvailable:/ { print $2; exit }' /proc/meminfo)
    mem_used=$((mem_total - mem_avail))
    if [ "$mem_total" -gt 0 ]; then
        ram=$((100 * mem_used / mem_total))
    else
        ram=0
    fi
    ram_gb=$(awk -v kb="$mem_used" 'BEGIN { printf "%.1f G", kb / 1048576 }')

    read_swap
    read_gpu

    temp=0
    for input in /sys/class/hwmon/hwmon*/temp*_input; do
        [ -r "$input" ] || continue
        value=$(cat "$input" 2>/dev/null || echo 0)
        [ "$value" -gt "$temp" ] 2>/dev/null && temp=$value
    done
    temp=$((temp / 1000))

    read_net
    rx_rate=$(((rx - prev_rx) / 2))
    tx_rate=$(((tx - prev_tx) / 2))
    prev_rx=$rx
    prev_tx=$tx

    jq -cn \
        --argjson cpu "$cpu" \
        --argjson ram "$ram" \
        --arg ramUsed "$ram_gb" \
        --argjson swap "$swap" \
        --argjson gpu "$gpu" \
        --argjson gpuAvailable "$gpu_available" \
        --argjson temp "$temp" \
        --arg rx "$(format_rate "$rx_rate")" \
        --arg tx "$(format_rate "$tx_rate")" \
        --arg network "$(network_label)" \
        '{cpu:$cpu, ram:$ram, ramUsed:$ramUsed, swap:$swap, gpu:$gpu, gpuAvailable:$gpuAvailable, temp:$temp, rx:$rx, tx:$tx, network:$network}'
done
