#!/bin/bash
#
# screenshot.sh — Screenshot with annotation
#
# Modes: full, area, window, timer
# Tools: grim+slurp, flameshot, maim

set -euo pipefail

MODE="${1:-area}"
DELAY="${2:-0}"
SAVE_DIR="${HOME}/Pictures/screenshots"
CLIPBOARD=true

mkdir -p "$SAVE_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }

FILENAME="screenshot-$(date +%Y%m%d-%H%M%S).png"
FILEPATH="$SAVE_DIR/$FILENAME"

take_screenshot() {
  if command -v grim &>/dev/null && command -v slurp &>/dev/null; then
    case "$MODE" in
      full)
        grim "$FILEPATH"
        ;;
      area)
        grim -g "$(slurp)" "$FILEPATH"
        ;;
      window)
        grim -g "$(slurp -w)" "$FILEPATH"
        ;;
      timer)
        sleep "$DELAY"
        grim "$FILEPATH"
        ;;
    esac
  elif command -v flameshot &>/dev/null; then
    case "$MODE" in
      full) flameshot full -p "$SAVE_DIR" ;;
      area|window) flameshot gui -p "$SAVE_DIR" ;;
      timer) flameshot full -d "$((DELAY * 1000))" -p "$SAVE_DIR" ;;
    esac
  elif command -v maim &>/dev/null; then
    case "$MODE" in
      full) maim "$FILEPATH" ;;
      area) maim -s "$FILEPATH" ;;
      window) maim -i "$(xdotool getactivewindow)" "$FILEPATH" ;;
      timer) sleep "$DELAY" && maim "$FILEPATH" ;;
    esac
  else
    fail "No screenshot tool found. Install grim+slurp, flameshot, or maim"
  fi
}

take_screenshot

# Copy to clipboard
if $CLIPBOARD && [ -f "$FILEPATH" ]; then
  if command -v wl-copy &>/dev/null; then
    wl-copy < "$FILEPATH"
  elif command -v xclip &>/dev/null; then
    xclip -selection clipboard -t image/png < "$FILEPATH"
  fi
  pass "Copied to clipboard"
fi

if [ -f "$FILEPATH" ]; then
  pass "Saved: $FILEPATH"
fi
