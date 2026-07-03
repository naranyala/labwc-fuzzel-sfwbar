#!/bin/bash
#
# quick-settings.sh — Quick settings panel (dark mode, DND, night mode, etc.)
#
# Modes: dark-mode, dnd, night-mode, auto-rotate, touchpad, show

set -euo pipefail

MODE="${1:-show}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}→${NC} $1"; }

notify() {
  local msg="$1"
  if command -v notify-send &>/dev/null; then
    notify-send -a "Settings" -t 2000 "$msg"
  fi
}

# --- Dark Mode ---
toggle_dark_mode() {
  if command -v gsettings &>/dev/null; then
    local current=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'default'")
    if echo "$current" | grep -q "dark"; then
      gsettings set org.gnome.desktop.interface color-scheme 'default'
      notify "Light mode"
      pass "Light mode"
    else
      gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
      notify "Dark mode"
      pass "Dark mode"
    fi
  else
    info "gsettings not available"
  fi
}

get_dark_mode() {
  if command -v gsettings &>/dev/null; then
    local scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'default'")
    if echo "$scheme" | grep -q "dark"; then
      echo "on"
    else
      echo "off"
    fi
  else
    echo "unknown"
  fi
}

# --- Do Not Disturb ---
toggle_dnd() {
  if command -v mako &>/dev/null; then
    # makoctl for mako
    if command -v makoctl &>/dev/null; then
      makoctl set-mode 2>/dev/null && pass "DND toggled (mako)" || info "Could not toggle mako DND"
    fi
  elif command -v dunstctl &>/dev/null; then
    dunstctl set-paused toggle 2>/dev/null && pass "DND toggled (dunst)"
  else
    info "No notification daemon with DND support found"
  fi
}

get_dnd() {
  if command -v dunstctl &>/dev/null; then
    local paused=$(dunstctl is-paused 2>/dev/null)
    if [ "$paused" = "true" ]; then
      echo "on"
    else
      echo "off"
    fi
  else
    echo "unknown"
  fi
}

# --- Night Mode ---
toggle_night_mode() {
  if pgrep -x gammastep &>/dev/null || pgrep -x redshift &>/dev/null; then
    pkill -x gammastep 2>/dev/null; pkill -x redshift 2>/dev/null
    notify "Night mode off"
    pass "Night mode off"
  else
    if command -v gammastep &>/dev/null; then
      gammastep -m randr -t 6500:3500 -g 1.0 -r &
      notify "Night mode on"
      pass "Night mode on"
    elif command -v redshift &>/dev/null; then
      redshift -m randr -t 6500:3500 -g 1.0 -r &
      notify "Night mode on"
      pass "Night mode on"
    else
      info "No night mode tool found"
    fi
  fi
}

get_night_mode() {
  if pgrep -x gammastep &>/dev/null || pgrep -x redshift &>/dev/null; then
    echo "on"
  else
    echo "off"
  fi
}

# --- Wallpaper Auto-Rotate ---
toggle_wallpaper_rotate() {
  if pgrep -f "wallpaper daemon" &>/dev/null; then
    pkill -f "wallpaper daemon"
    notify "Auto-rotate off"
    pass "Auto-rotate off"
  else
    wallpaper daemon 3600 &
    notify "Auto-rotate on (hourly)"
    pass "Auto-rotate on"
  fi
}

# --- Touchpad ---
toggle_touchpad() {
  if command -v gsettings &>/dev/null; then
    local current=$(gsettings get org.gnome.desktop.peripherals.touchpad send-events 2>/dev/null || echo "'enabled'")
    if echo "$current" | grep -q "enabled"; then
      gsettings set org.gnome.desktop.peripherals.touchpad send-events 'disabled'
      notify "Touchpad disabled"
      pass "Touchpad off"
    else
      gsettings set org.gnome.desktop.peripherals.touchpad send-events 'enabled'
      notify "Touchpad enabled"
      pass "Touchpad on"
    fi
  fi
}

# --- Show All Settings ---
show_settings() {
  echo ""
  echo "== Quick Settings =="
  echo ""
  
  local dark=$(get_dark_mode)
  local dnd=$(get_dnd)
  local night=$(get_night_mode)
  
  if [ "$dark" = "on" ]; then
    echo -e "  Dark Mode:    ${GREEN}●${NC} On"
  else
    echo -e "  Dark Mode:    ○ Off"
  fi
  
  if [ "$dnd" = "on" ]; then
    echo -e "  DND:          ${GREEN}●${NC} On"
  else
    echo -e "  DND:          ○ Off"
  fi
  
  if [ "$night" = "on" ]; then
    echo -e "  Night Mode:   ${GREEN}●${NC} On"
  else
    echo -e "  Night Mode:   ○ Off"
  fi
  
  echo ""
  echo "Commands:"
  echo "  $0 dark-mode     Toggle dark mode"
  echo "  $0 dnd           Toggle do not disturb"
  echo "  $0 night-mode    Toggle night mode"
  echo "  $0 auto-rotate   Toggle wallpaper auto-rotate"
  echo "  $0 touchpad      Toggle touchpad"
  echo ""
}

case "$MODE" in
  dark-mode|dark)     toggle_dark_mode ;;
  dnd|quiet)          toggle_dnd ;;
  night-mode|night)   toggle_night_mode ;;
  auto-rotate|rotate) toggle_wallpaper_rotate ;;
  touchpad)           toggle_touchpad ;;
  show|status)        show_settings ;;
  help|--help|-h|*)
    echo ""
    echo "Quick Settings"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  dark-mode     Toggle dark/light mode"
    echo "  dnd           Toggle do not disturb"
    echo "  night-mode    Toggle night mode (blue light filter)"
    echo "  auto-rotate   Toggle wallpaper auto-rotation"
    echo "  touchpad      Toggle touchpad"
    echo "  show          Show current settings"
    echo ""
    ;;
esac
