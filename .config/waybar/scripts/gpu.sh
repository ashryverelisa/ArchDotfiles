#!/usr/bin/env bash

# --- RAM ---
read -r _ total used _ <<<"$(free -b | awk '/^Mem:/ {print $1,$2,$3,$4}')"
percent=$(( used * 100 / total ))

used_h=$(numfmt --to=iec --suffix=B "$used")
total_h=$(numfmt --to=iec --suffix=B "$total")

text="󰍛 ${percent}%"
tooltip="󰍛 RAM: ${used_h} / ${total_h} (${percent}%)"

# --- GPU ---
if command -v nvidia-smi >/dev/null 2>&1; then
    gpu=$(nvidia-smi \
        --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu \
        --format=csv,noheader,nounits 2>/dev/null)

    if [ -n "$gpu" ]; then
        IFS=',' read -r util v_used v_total temp <<<"$gpu"

        util=${util// /}
        temp=${temp// /}

        v_used=$(awk "BEGIN {printf \"%.1f\", $v_used/1024}")
        v_total=$(awk "BEGIN {printf \"%.1f\", $v_total/1024}")

        text+=" 󰢮 ${util}%"

        tooltip="${tooltip}\n󰢮 GPU: ${util}%\n Temp: ${temp}°C\n󰍛 VRAM: ${v_used}GB / ${v_total}GB"
    fi
fi

# Escape newlines for JSON
tooltip=${tooltip//$'\n'/\\n}
text=${text//\"/\\\"}
tooltip=${tooltip//\"/\\\"}

printf '{"text":"%s","tooltip":"%s"}\n' "$text" "$tooltip"