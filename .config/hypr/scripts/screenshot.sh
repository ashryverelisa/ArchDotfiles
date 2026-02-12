#!/usr/bin/env bash

set -euo pipefail

# --- Config ---
SAVE_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

# --- Temp file ---
TEMP_FILE="$(mktemp --suffix=.png)"
trap 'rm -f "$TEMP_FILE"' EXIT

# --- Freeze screen ---
wayfreeze &
WAYFREEZE_PID=$!
trap 'kill "$WAYFREEZE_PID" 2>/dev/null || true' EXIT

sleep 0.1

# --- Select region ---
REGION="$(slurp)"
if [[ -z "$REGION" ]]; then
  notify-send -a "Screenshot" "Screenshot Cancelled" "No region selected"
  exit 0
fi

# --- Take screenshot ---
grim -g "$REGION" -t png "$TEMP_FILE"

# --- Save + copy ---
TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S_%3N")"
SAVE_PATH="$SAVE_DIR/${TIMESTAMP}.png"

cp "$TEMP_FILE" "$SAVE_PATH"
wl-copy -t image/png < "$TEMP_FILE"

notify-send -a "Screenshot" "Screenshot Saved" "Saved to $SAVE_PATH" --icon="$SAVE_PATH"