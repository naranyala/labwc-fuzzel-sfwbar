#!/bin/bash
#
# display.sh — Display management (wlr-randr)
#
# Modes: list, layout, single, mirror, reset

set -euo pipefail

MODE="${1:-list}"
LAYOUT="${2:-}"

notify() {
  local msg="$1"
  if command -v notify-send &>/dev/null; then
    notify-send -a "Display" -t 3000 "$msg"
  fi
}

list_displays() {
  if ! command -v wlr-randr &>/dev/null; then
    echo "wlr-randr not found"
    return 1
  fi
  wlr-randr 2>/dev/null
}

get_outputs() {
  wlr-randr 2>/dev/null | grep -E '^\S' | awk '{print $1}'
}

case "$MODE" in
  list|status)
    list_displays
    ;;

  layout|apply)
    if [ -z "$LAYOUT" ]; then
      echo "Usage: $0 layout <layout-name>"
      echo ""
      echo "Available layouts:"
      ls ~/.config/labwc/presets/ 2>/dev/null || echo "  (no presets found in ~/.config/labwc/presets/)"
      echo ""
      echo "Create presets: $0 save <name>"
      exit 0
    fi
    local layout_file="$HOME/.config/labwc/presets/$LAYOUT"
    if [ -f "$layout_file" ]; then
      bash "$layout_file" 2>/dev/null && notify "Applied layout: $LAYOUT"
    else
      echo "Layout not found: $layout_file"
      exit 1
    fi
    ;;

  save)
    if [ -z "$LAYOUT" ]; then
      echo "Usage: $0 save <layout-name>"
      exit 1
    fi
    mkdir -p "$HOME/.config/labwc/presets"
    wlr-randr 2>/dev/null > "$HOME/.config/labwc/presets/$LAYOUT"
    notify "Saved layout: $LAYOUT"
    ;;

  single)
    local output="${2:-}"
    if [ -z "$output" ]; then
      echo "Usage: $0 single <output-name>"
      echo ""
      echo "Available outputs:"
      get_outputs
      exit 0
    fi
    for out in $(get_outputs); do
      if [ "$out" = "$output" ]; then
        wlr-randr --output "$out" --on --preferred 2>/dev/null
      else
        wlr-randr --output "$out" --off 2>/dev/null
      fi
    done
    notify "Single display: $output"
    ;;

  mirror)
    local primary="${2:-}"
    if [ -z "$primary" ]; then
      primary=$(get_outputs | head -1)
    fi
    local others=""
    for out in $(get_outputs); do
      if [ "$out" != "$primary" ]; then
        others="$out"
      fi
    done
    if [ -n "$others" ]; then
      wlr-randr --output "$others" --on --pos 0x0 --mode $(wlr-randr 2>/dev/null | grep -A 10 "^$primary" | grep -oP '[\d]+x[\d]+' | head -1) 2>/dev/null
      notify "Mirroring to $others"
    else
      echo "No secondary display found"
    fi
    ;;

  reset)
    for out in $(get_outputs); do
      wlr-randr --output "$out" --on --preferred 2>/dev/null
    done
    notify "Display layout reset"
    ;;

  help|--help|-h|*)
    echo ""
    echo "Display Management"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  list              Show display status"
    echo "  layout <name>     Apply saved layout"
    echo "  save <name>       Save current layout"
    echo "  single <output>   Use single display"
    echo "  mirror [primary]  Mirror displays"
    echo "  reset             Reset all displays"
    echo ""
    ;;
esac
