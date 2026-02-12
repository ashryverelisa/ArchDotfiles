#!/usr/bin/env bash
set -euo pipefail

# ---------------------------
# Find battery path (BAT0 or BAT1)
# ---------------------------
BAT_PATH=""
for b in /sys/class/power_supply/BAT{0,1}; do
  [[ -d "$b" ]] && { BAT_PATH="$b"; break; }
done

if [[ -z "$BAT_PATH" ]]; then
  echo '{"text":"󰐥","tooltip":"Power Menu","class":"no-battery"}'
  exit 0
fi

# ---------------------------
# Helpers
# ---------------------------
read_val() {
  local file="$1"
  [[ -f "$file" ]] && cat "$file" || echo ""
}

safe_div() {
  local num=$1 den=$2
  (( den == 0 )) && echo 0 || echo $(( num / den ))
}

# ---------------------------
# Read values
# ---------------------------
capacity=$(read_val "$BAT_PATH/capacity")
status=$(read_val "$BAT_PATH/status")

# Determine icon/class
icon="󰁹"
class="full"

if [[ "$status" == "Charging" ]]; then
  icon="󰂄"
  class="charging"
elif [[ "$status" == "Full" ]]; then
  icon="󰁹"
  class="full"
else
  case $capacity in
    ''|*[!0-9]*) icon="󰂃"; class="unknown" ;;
    [9][0-9]|100) icon="󰁹"; class="full" ;;
    [7-8][0-9]) icon="󰂀"; class="good" ;;
    [5-6][0-9]) icon="󰁾"; class="medium" ;;
    [3-4][0-9]) icon="󰁼"; class="low" ;;
    [1-2][0-9]) icon="󰁺"; class="critical" ;;
    0) icon="󰂃"; class="critical" ;;
  esac
fi

# ---------------------------
# Calculate time remaining / until full
# ---------------------------
tooltip="$icon ${capacity:-?}% - ${status:-Unknown}"

# energy_* (preferred)
energy_now=$(read_val "$BAT_PATH/energy_now")
power_now=$(read_val "$BAT_PATH/power_now")
energy_full=$(read_val "$BAT_PATH/energy_full")

# fallback charge_* if energy_* not available
if [[ -z "$energy_now" || -z "$power_now" ]]; then
  energy_now=$(read_val "$BAT_PATH/charge_now")
  power_now=$(read_val "$BAT_PATH/current_now")
  energy_full=$(read_val "$BAT_PATH/charge_full")
fi

if [[ -n "$energy_now" && -n "$power_now" && "$power_now" -gt 0 ]]; then
  if [[ "$status" == "Charging" ]]; then
    remaining=$(( (energy_full - energy_now) * 3600 / power_now ))
    label="until full"
  else
    remaining=$(( energy_now * 3600 / power_now ))
    label="remaining"
  fi

  hours=$(( remaining / 3600 ))
  mins=$(( (remaining % 3600) / 60 ))
  tooltip="$icon ${capacity:-?}% - ${hours}h ${mins}m ${label}"
fi

# ---------------------------
# Output JSON
# ---------------------------
printf '{"text":"%s %s%%","tooltip":"%s","class":"%s"}\n' \
  "$icon" "$capacity" "$tooltip" "$class"