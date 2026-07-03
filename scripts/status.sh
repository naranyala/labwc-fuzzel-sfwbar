#!/bin/bash
#
# status.sh — Show comprehensive status of labwc + zebar + crystal-dock
#
# Displays: running processes, config state, widget status, themes, wallpapers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.config/labwc"
ZEBAR_DIR="${HOME}/.config/zebar"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

section() { echo -e "\n${BOLD}$1${NC}"; }
item()    { echo -e "  $1"; }
label()   { echo -e "  ${DIM}${1}:${NC} "; }

# ============================================================
echo -e "${BOLD}== labwc Desktop Status ==${NC}"
echo -e "${DIM}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
# ============================================================

# --- Running Processes ---
section "Processes"

check_process() {
  local name="$1"
  local display="$2"
  if pgrep -x "$name" &>/dev/null; then
    local pid=$(pgrep -x "$name" | head -1)
    item "${GREEN}●${NC} $display ${DIM}(PID: $pid)${NC}"
  else
    item "${RED}○${NC} $display ${DIM}(not running)${NC}"
  fi
}

check_process labwc "labwc"
check_process crystal-dock "crystal-dock"
check_process zebar "zebar"
check_process swaybg "swaybg (wallpaper)"
check_process gammastep "gammastep (screen protection)"
check_process redshift "redshift (screen protection)"
check_process mako "mako (notifications)"
check_process dunst "dunst (notifications)"
check_process rofi "rofi (launcher)"
check_process foot "foot (terminal)"
check_process lxpolkit "lxpolkit (policykit)"

# --- Wayland Session ---
section "Session"

if [ -n "${WAYLAND_DISPLAY:-}" ]; then
  item "${GREEN}●${NC} Wayland: ${WAYLAND_DISPLAY}"
else
  item "${RED}○${NC} Wayland: not active"
fi

if [ -n "${XDG_SESSION_TYPE:-}" ]; then
  item "${CYAN}→${NC} Session type: ${XDG_SESSION_TYPE}"
fi

if [ -n "${XDG_CURRENT_DESKTOP:-}" ]; then
  item "${CYAN}→${NC} Desktop: ${XDG_CURRENT_DESKTOP}"
fi

# --- labwc Configuration ---
section "Configuration"

if [ -d "$CONFIG_DIR" ]; then
  item "${GREEN}✓${NC} Config dir: $CONFIG_DIR"
else
  item "${RED}✗${NC} Config dir: MISSING"
fi

for cfg in rc.xml autostart environment menu.xml themerc-override; do
  if [ -f "$CONFIG_DIR/$cfg" ]; then
    local size=$(wc -c < "$CONFIG_DIR/$cfg" 2>/dev/null || echo "?")
    item "  ${GREEN}✓${NC} $cfg ${DIM}($size bytes)${NC}"
  else
    item "  ${RED}✗${NC} $cfg MISSING"
  fi
done

# --- Autostart Items ---
section "Autostart"

if [ -f "$CONFIG_DIR/autostart" ]; then
  while IFS= read -r line; do
    case "$line" in
      \#*|"") continue ;;
      *"crystal-dock"*)
        if pgrep -x crystal-dock &>/dev/null; then
          item "${GREEN}●${NC} crystal-dock"
        else
          item "${YELLOW}○${NC} crystal-dock (configured, not running)"
        fi
        ;;
      *"zebar"*)
        if pgrep -x zebar &>/dev/null; then
          item "${GREEN}●${NC} zebar"
        else
          item "${YELLOW}○${NC} zebar (configured, not running)"
        fi
        ;;
      *"wallpaper"*|*"swaybg"*)
        if pgrep -x swaybg &>/dev/null; then
          item "${GREEN}●${NC} wallpaper (swaybg)"
        else
          item "${YELLOW}○${NC} wallpaper (configured, not running)"
        fi
        ;;
      *"gammastep"*|*"redshift"*)
        if pgrep -x gammastep &>/dev/null || pgrep -x redshift &>/dev/null; then
          item "${GREEN}●${NC} screen protection"
        else
          item "${YELLOW}○${NC} screen protection (configured, not running)"
        fi
        ;;
      *"natural-scroll"*)
        item "${CYAN}→${NC} natural scroll: enabled"
        ;;
    esac
  done < "$CONFIG_DIR/autostart"
fi

# --- Zebar Widgets ---
section "Widgets"

if [ -d "$ZEBAR_DIR" ]; then
  item "${GREEN}✓${NC} Zebar config: $ZEBAR_DIR"
  
  if [ -d "$ZEBAR_DIR/main" ] && [ -f "$ZEBAR_DIR/main/index.html" ]; then
    item "  ${GREEN}✓${NC} main (status bar)"
  fi
  
  for widget_dir in "$ZEBAR_DIR"/widgets/*/; do
    if [ -d "$widget_dir" ] && [ -f "$widget_dir/index.html" ]; then
      local name=$(basename "$widget_dir")
      item "  ${GREEN}✓${NC} $name"
    fi
  done 2>/dev/null
else
  item "${RED}✗${NC} Zebar config: MISSING"
fi

# --- Theme ---
section "Theme"

if [ -f "$CONFIG_DIR/themerc-override" ]; then
  local theme=$(grep -E "^name=" "$CONFIG_DIR/themerc-override" 2>/dev/null || echo "default")
  item "Current theme: ${CYAN}${theme}${NC}"
else
  item "Theme: ${DIM}using defaults${NC}"
fi

# Check installed Openbox themes
THEME_DIR="$HOME/.local/share/themes"
if [ -d "$THEME_DIR" ]; then
  local count=$(ls -1d "$THEME_DIR"/*/labwc 2>/dev/null | wc -l)
  if [ "$count" -gt 0 ]; then
    item "Installed labwc themes: ${count}"
    for theme_dir in "$THEME_DIR"/*/labwc; do
      if [ -d "$theme_dir" ]; then
        local name=$(basename "$(dirname "$theme_dir")")
        item "  - $name"
      fi
    done 2>/dev/null
  fi
fi

# --- Wallpaper ---
section "Wallpaper"

if [ -d "$HOME/Pictures/wallpapers" ]; then
  local count=$(find "$HOME/Pictures/wallpapers" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | wc -l)
  item "Wallpaper dir: ${count} images"
else
  item "Wallpaper dir: not found"
fi

# Current wallpaper (if swaybg running)
if pgrep -x swaybg &>/dev/null; then
  local wp_cmd=$(ps aux | grep swaybg | grep -v grep | head -1)
  if echo "$wp_cmd" | grep -q "\-i"; then
    local wp_file=$(echo "$wp_cmd" | grep -oP '(?<=-i )\S+')
    local wp_name=$(basename "$wp_file" 2>/dev/null || echo "?")
    item "Current: ${CYAN}${wp_name}${NC}"
  fi
fi

# --- Keybindings ---
section "Keybindings (top 10)"

if [ -f "$CONFIG_DIR/rc.xml" ]; then
  grep -oP 'key="[^"]+' "$CONFIG_DIR/rc.xml" 2>/dev/null | head -10 | while read -r key; do
    key="${key#key=}"
    item "$key"
  done
fi

# --- System Info ---
section "System"

item "Kernel: $(uname -r)"
item "Arch: $(uname -m)"

if command -v labwc &>/dev/null; then
  local ver=$(labwc --version 2>/dev/null || echo "?")
  item "labwc: $ver"
fi

# Memory usage
if command -v free &>/dev/null; then
  local mem=$(free -h | awk '/^Mem:/ {print $3"/"$2}')
  item "Memory: $mem"
fi

echo ""
