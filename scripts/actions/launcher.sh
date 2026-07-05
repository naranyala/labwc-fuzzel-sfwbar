#!/bin/bash
#
# launcher.sh — Enhanced application launcher
#
# Modes: apps, run, recent, favorites, calculate, emoji, color-picker, url

set -euo pipefail

MODE="${1:-apps}"
QUERY="${2:-}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }

# --- App Launcher ---
launch_apps() {
  if command -v fuzzel >/dev/null 2>&1; then
    fuzzel --config "$HOME/.config/fuzzel/fuzzel.ini"
  elif command -v rofi >/dev/null 2>&1; then
    rofi -show drun -theme-str 'window {width: 600px;}'
  elif command -v wofi >/dev/null 2>&1; then
    wofi --show drun
  elif command -v bemenu >/dev/null 2>&1; then
    bemenu-run
  else
    fail "No launcher found. Install fuzzel, rofi, wofi, or bemenu"
  fi
}

# --- Run Command ---
r 
local cmd="${*:-}"
  if [ -z "$cmd" ]; then
    if command -v fuzzel >/dev/null 2>&1; then
      cmd=$(fuzzel --config "$HOME/.config/fuzzel/fuzzel.ini" -p "Run:" --placeholder "Type command...")
    elif command -v rofi >/dev/null 2>&1; then
      cmd=$(rofi -show run -theme-str 'window {width: 600px;}')
    elif command -v wofi >/dev/null 2>&1; then
      cmd=$(wofi --show run)
    fi
  fi
  
  if [ -n "$cmd" ]; then
    eval "$cmd" &
    pass "Running: $cmd"
  fi
}

# --- Recent Files ---
show_recent() {
  local files=$(find ~ -maxdepth 3 -type f \( -name "*.txt" -o -name "*.md" -o -name "*.pdf" \) -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -20 | cut -d' ' -f2-)
  if command -v fuzzel >/dev/null 2>&1; then
    selected=$(echo "$files" | fuzzel --dmenu --theme="$HOME/.config/fuzzel/fuzzel.ini" -p "Recent Files" --placeholder "Search files..." --match-mode="fuzzy" --width 500)
  elif command -v rofi >/dev/null 2>&1; then
    selected=$(echo "$files" | rofi -dmenu -p "Recent Files" -theme-str 'window {width: 500px;}')
  fi
  if [ -n "$selected" ]; then
    xdg-open "$selected" 2>/dev/null &
  fi
}

# --- Favorites ---
FAVORITES_FILE="${HOME}/.config/labwc/favorites.txt"

show_favorites() {
  if [ ! -f "$FAVORITES_FILE" ]; then
    echo "# Add your favorite apps (one per line)" > "$FAVORITES_FILE"
    echo "foot" >> "$FAVORITES_FILE"
    echo "firefox" >> "$FAVORITES_FILE"
  fi
  
  if command -v rofi &>/dev/null; then
    selected=$(cat "$FAVORITES_FILE" | grep -v '^#' | rofi -dmenu -p "Favorites" -theme-str 'window {width: 300px;}')
    if [ -n "$selected" ]; then
      eval "$selected" &
    fi
  fi
}

# --- Calculator ---
calculate() {
  local expr="${*:-}"
  if [ -z "$expr" ]; then
    if command -v rofi &>/dev/null; then
      expr=$(rofi -dmenu -p "Calculate" -theme-str 'window {width: 300px;}')
    fi
  fi
  
  if [ -n "$expr" ]; then
    local result=$(echo "$expr" | bc -l 2>/dev/null || python3 -c "print($expr)" 2>/dev/null)
    if [ -n "$result" ]; then
      echo "$result"
      if command -v wl-copy &>/dev/null; then
        echo "$result" | wl-copy
        pass "Result copied: $result"
      fi
    else
      fail "Invalid expression"
    fi
  fi
}

# --- Emoji Picker ---
show_emoji() {
  local emojis="😀 😃 😄 😁 😆 😅 🤣 😂 🙂 🙃 😉 😊 😇 🥰 😍 🤩 😘 😗 😚 😙 🥲 😋 😛 😜 🤪 😝 🤑 🤗 🤭 🤫 🤔 🫡 🤐 🤨 😐 😑 😶 🫥 😏 😒 🙄 😬 🤥 😌 😔 😪 🤤 😴 😷 🤒 🤕 🤢 🤮 🥵 🥶 🥴 😵 🤯 🤠 🥳 🥸 😎 🤓 🧐 😕 🫤 😟 🙁 ☹️ 😮 😯 😲 😳 🥺 🥹 😦 😧 😨 😰 😥 😢 😭 😱 😖 😣 😞 😓 😩 😫 🥱 😤 😡 😠 🤬 👍 👎 👊 ✊ 🤛 🤜 🤞 ✌️ 🤟 🤘 👌 🤏 👈 👉 👆 👇 ☝️ ✋ 🤚 🖐 🖖 👋 🤙 💪 🦾 🖕 ✍️ 🙏 🤝 🤗 🦻 🫂 👀 👁 👅 👄 💋"
  
  if command -v rofi &>/dev/null; then
    selected=$(echo "$emojis" | tr ' ' '\n' | rofi -dmenu -p "Emoji" -theme-str 'window {width: 400px; height: 400px;}')
    if [ -n "$selected" ]; then
      echo -n "$selected" | wl-copy 2>/dev/null || echo -n "$selected" | xclip 2>/dev/null
      pass "Copied: $selected"
    fi
  else
    echo "$emojis"
  fi
}

# --- Color Picker ---
pick_color() {
  if command -v grim &>/dev/null && command -v slurp &>/dev/null; then
    local color=$(grim -g "$(slurp -p)" -t ppm - 2>/dev/null | convert -format '%[fx:p{0,0}]' txt:- 2>/dev/null | tail -1)
    if [ -n "$color" ]; then
      echo "$color"
      if command -v wl-copy &>/dev/null; then
        echo "$color" | wl-copy
        pass "Color copied: $color"
      fi
    fi
  elif command -v xcolor &>/dev/null; then
    xcolor
  else
    fail "No color picker found. Install grim+slurp or xcolor"
  fi
}

# --- URL Opener ---
open_url() {
  local url="${*:-}"
  if [ -z "$url" ]; then
    if command -v rofi &>/dev/null; then
      url=$(rofi -dmenu -p "URL" -theme-str 'window {width: 500px;}')
    fi
  fi
  
  if [ -n "$url" ]; then
    # Add https:// if no protocol
    if [[ ! "$url" =~ ^https?:// ]]; then
      url="https://$url"
    fi
    xdg-open "$url" 2>/dev/null &
    pass "Opening: $url"
  fi
}

case "$MODE" in
  apps|drun)     launch_apps ;;
  run|command)   run_command "$QUERY" ;;
  recent)        show_recent ;;
  favorites)     show_favorites ;;
  calc|calculate) calculate "$QUERY" ;;
  emoji)         show_emoji ;;
  color)         pick_color ;;
  url|open)      open_url "$QUERY" ;;
  help|--help|-h|*)
    echo ""
    echo "Enhanced Launcher"
    echo ""
    echo "Usage: $0 <command> [query]"
    echo ""
    echo "Commands:"
    echo "  apps          Launch applications"
    echo "  run [cmd]     Run a command"
    echo "  recent        Show recent files"
    echo "  favorites     Show favorite apps"
    echo "  calc [expr]   Calculator"
    echo "  emoji         Emoji picker"
    echo "  color         Color picker"
    echo "  url [url]     Open URL"
    echo ""
    ;;
esac
