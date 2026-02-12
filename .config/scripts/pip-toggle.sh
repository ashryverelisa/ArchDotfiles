#!/usr/bin/env bash
set -euo pipefail

MODE=$(hyprctl monitors | grep -A1 "Monitor DP-1" | tail -n1 | awk '{print $1}' | cut -d'@' -f1)

if [[ "$MODE" == "5120x1440" ]]; then
  hyprctl keyword monitor DP-1,2560x1440@240.00,0x0,1
  hyprctl keyword monitor HDMI-A-1,2560x1440@240.00,2560x0,1
else
  hyprctl keyword monitor HDMI-A-1,disable
  sleep 0.2
  hyprctl keyword monitor DP-1,5120x1440@239.76,0x0,1
fi