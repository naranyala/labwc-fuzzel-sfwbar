#!/bin/bash
#
# ocws-display.sh — Display layout management with Event Bus IPC
#
# Manages multi-monitor layouts using wlr-randr.
# Supports saving/restoring layouts, single/mirror modes.

set -euo pipefail

LAYOUT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/labwc/presets"
mkdir -p "$LAYOUT_DIR"

get_outputs() {
  wlr-randr 2>/dev/null | grep -E '^\S' | awk '{print $1}'
}

apply_layout() {
  local file="$1"
  if [ -f "$file" ]; then
    bash "$file" 2>/dev/null
  fi
}

case "${1:-list}" in
  list)
    echo "Connected outputs:"
    wlr-randr 2>/dev/null
    echo ""
    echo "Saved layouts:"
    ls "$LAYOUT_DIR" 2>/dev/null || echo "  (none)"
    ;;

  save)
    local name="${2:-default}"
    wlr-randr 2>/dev/null > "$LAYOUT_DIR/$name"
    echo "Saved layout: $name"
    ;;

  load|restore)
    local name="${2:-default}"
    local file="$LAYOUT_DIR/$name"
    if [ -f "$file" ]; then
      apply_layout "$file"
      echo "Restored layout: $name"
      if command -v ocws-emit.sh &>/dev/null; then
        ocws-emit.sh System.DisplayLayout "$name"
      fi
    else
      echo "Layout not found: $name"
      echo "Available layouts:"
      ls "$LAYOUT_DIR" 2>/dev/null || echo "  (none)"
      exit 1
    fi
    ;;

  single)
    local output="${2:-}"
    if [ -z "$output" ]; then
      echo "Usage: $0 single <output>"
      echo "Outputs:"
      get_outputs
      exit 1
    fi
    for out in $(get_outputs); do
      if [ "$out" = "$output" ]; then
        wlr-randr --output "$out" --on --preferred 2>/dev/null
      else
        wlr-randr --output "$out" --off 2>/dev/null
      fi
    done
    ;;

  mirror)
    local primary="${2:-$(get_outputs | head -1)}"
    for out in $(get_outputs); do
      if [ "$out" != "$primary" ]; then
        wlr-randr --output "$out" --on --same-as "$primary" 2>/dev/null || \
        wlr-randr --output "$out" --on --pos 0x0 2>/dev/null
      fi
    done
    ;;

  help|--help|-h|*)
    echo ""
    echo "OCWS Display Manager"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  list              Show outputs and saved layouts"
    echo "  save [name]       Save current layout"
    echo "  load [name]       Restore saved layout"
    echo "  single <output>   Use single display"
    echo "  mirror [primary]  Mirror displays"
    echo ""
    ;;
esac
