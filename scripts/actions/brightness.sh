#!/bin/bash

# Centralized error handling + desktop notifications (ocws-notify / mako / dunst)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/ocws-err.sh"
ocws_enable_strict

#
# brightness.sh — Brightness control
#
# Modes: up, down, set, get, up-0.5, down-0.5
# Tools: brightnessctl, light, xbacklight

set -euo pipefail

MODE="${1:-up}"
STEP="${2:-10%}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }

# --- C Native Rewrite (Phase 7b) ---
if command -v ocws-brightness >/dev/null 2>&1; then
    case "$MODE" in
        up|raise) exec ocws-brightness --step "${STEP%\%}" up ;;
        down|lower) exec ocws-brightness --step "${STEP%\%}" down ;;
        up-0.5|up-half|up-half-percent|brightness-up-0.5|inc-0.5|increase-0.5) exec ocws-brightness --step 0.5 up ;;
        down-0.5|down-half|down-half-percent|brightness-down-0.5|dec-0.5|decrease-0.5) exec ocws-brightness --step 0.5 down ;;
        set) exec ocws-brightness set "${2%\%}" ;;
        get|status) exec ocws-brightness get ;;
    esac
fi

# --- Bash Fallback (Legacy) ---
get_brightness() {
  if command -v brightnessctl &>/dev/null; then
    brightnessctl -m 2>/dev/null | cut -d',' -f4 | tr -d '%'
  elif command -v light &>/dev/null; then
    light -G 2>/dev/null | cut -d'.' -f1
  else
    echo "0"
  fi
}

notify() {
  local msg="$1"
  local val="$2"
  if command -v notify-send &>/dev/null; then
    notify-send -a "Brightness" -t 2000 -h int:value:"$val" "$msg"
  fi
}

case "$MODE" in
  up|raise)
    if command -v brightnessctl &>/dev/null; then
      brightnessctl set "+${STEP}" 2>/dev/null
    elif command -v light &>/dev/null; then
      light -A "${STEP}" 2>/dev/null
    else
      fail "No brightness tool found. Install brightnessctl or light"
    fi
    val=$(get_brightness)
    notify "Brightness: ${val}%" "$val"
    ;;

  down|lower)
    if command -v brightnessctl &>/dev/null; then
      brightnessctl set "${STEP}-" 2>/dev/null
    elif command -v light &>/dev/null; then
      light -U "${STEP}" 2>/dev/null
    else
      fail "No brightness tool found. Install brightnessctl or light"
    fi
    val=$(get_brightness)
    notify "Brightness: ${val}%" "$val"
    ;;

  up-0.5|up-half|up-half-percent|brightness-up-0.5|inc-0.5|increase-0.5)
    if command -v brightnessctl &>/dev/null; then
      brightnessctl set "+0.5%" 2>/dev/null
    elif command -v light &>/dev/null; then
      light -A "0.5%" 2>/dev/null
    else
      fail "No brightness tool found. Install brightnessctl or light"
    fi
    val=$(get_brightness)
    pass "Brightness increased by 0.5% to ${val}%"
    ;;

  down-0.5|down-half|down-half-percent|brightness-down-0.5|dec-0.5|decrease-0.5)
    if command -v brightnessctl &>/dev/null; then
      brightnessctl set "-0.5%" 2>/dev/null
    elif command -v light &>/dev/null; then
      light -U "0.5%" 2>/dev/null
    else
      fail "No brightness tool found. Install brightnessctl or light"
    fi
    val=$(get_brightness)
    pass "Brightness decreased by 0.5% to ${val}%"
    ;;

  set)
    local_val="${2:-50}"
    if command -v brightnessctl &>/dev/null; then
      brightnessctl set "${local_val}%" 2>/dev/null
    elif command -v light &>/dev/null; then
      light -S "${local_val}" 2>/dev/null
    else
      fail "No brightness tool found"
    fi
    val=$(get_brightness)
    pass "Brightness set to ${val}%"
    ;;

  get|status)
    val=$(get_brightness)
    echo "Brightness: ${val}%"
    ;;

  help|--help|-h|*)
    echo ""
    echo "Brightness Control (C Proxy)"
    echo ""
    echo "Usage: $0 <command> [step]"
    echo ""
    echo "Commands:"
    echo "  up [step]     Increase brightness (default: 10%)"
    echo "  down [step]   Decrease brightness (default: 10%)"
    echo "  set <value>   Set brightness to value"
    echo "  get           Show current brightness"
    echo ""
    ;;
esac
