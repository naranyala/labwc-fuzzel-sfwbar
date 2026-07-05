#!/bin/bash
#
# clipboard.sh — Clipboard manager
#
# Modes: show (history), clear, paste, copy-from
# Requires: cliphist, wl-copy, wl-paste

set -euo pipefail

MODE="${1:-show}"
MAX_ITEMS=50

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

show_history() {
  if command -v cliphist &>/dev/null; then
    cliphist list | head -n "$MAX_ITEMS"
  elif command -v wl-paste &>/dev/null; then
    wl-paste --list 2>/dev/null | head -n "$MAX_ITEMS"
  else
    echo "Clipboard history not available"
    echo "Install: cliphist (recommended) or wl-clipboard"
    exit 1
  fi
}

select_and_paste() {
  if command -v cliphist &>/dev/null; then
    local selected
    if command -v fuzzel &>/dev/null; then
      selected=$(cliphist list | fuzzel --dmenu --theme="$HOME/.config/fuzzel/fuzzel.ini" 
          --prompt "Clipboard" --placeholder "Search clipboard history..." 
          --match-mode="fuzzy" --width 400 --height 300)
    elif command -v rofi &>/dev/null; then
      selected=$(cliphist list | rofi -dmenu -p "Clipboard" -theme-str 'window {width: 400px; height: 300px;}')
    elif command -v wofi &>/dev/null; then
      selected=$(cliphist list | wofi --dmenu -p "Clipboard")
    elif command -v fzf &>/dev/null; then
      selected=$(cliphist list | fzf --prompt="Clipboard> ")
    else
      show_history
      exit 0
    fi
    
    if [ -n "$selected" ]; then
      echo "$selected" | cliphist decode | wl-copy
      pass "Copied to clipboard"
    fi
  fi
}

clear_history() {
  if command -v cliphist &>/dev/null; then
    cliphist delete-all
    pass "Clipboard history cleared"
  elif command -v wl-copy &>/dev/null; then
    wl-copy -c
    pass "Clipboard cleared"
  fi
}

copy_text() {
  local text="${*:-}"
  if [ -n "$text" ] && command -v wl-copy &>/dev/null; then
    echo -n "$text" | wl-copy
    pass "Copied: $text"
  fi
}

paste_text() {
  if command -v wl-paste &>/dev/null; then
    wl-paste
  fi
}

case "$MODE" in
  show|list|history)
    show_history
    ;;
  pick|select|rofi)
    select_and_paste
    ;;
  clear|delete)
    clear_history
    ;;
  copy)
    shift
    copy_text "$@"
    ;;
  paste)
    paste_text
    ;;
  help|--help|-h|*)
    echo ""
    echo "Clipboard Manager"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  show       Show clipboard history"
    echo "  pick       Select from history and paste"
    echo "  clear      Clear clipboard history"
    echo "  copy TEXT  Copy text to clipboard"
    echo "  paste      Paste from clipboard"
    echo ""
    ;;
esac
