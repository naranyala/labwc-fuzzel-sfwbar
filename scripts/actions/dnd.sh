#!/bin/bash

# Centralized error handling + desktop notifications (ocws-notify / mako / dunst)
source "$(dirname "${BASH_SOURCE[0]}")/../lib/ocws-err.sh"
ocws_enable_strict

#
# dnd.sh — Do Not Disturb toggle with Event Bus IPC
#
# Modes: toggle, on, off, status

set -euo pipefail

MODE="${1:-toggle}"

notify() {
  local msg="$1"
  if command -v notify-send &>/dev/null; then
    notify-send -a "DND" -t 2000 "$msg"
  fi
}

emit_dnd() {
  local state="$1"
  if command -v ocws-emit.sh &>/dev/null; then
    ocws-emit.sh System.DND "$state"
  fi
}

set_dnd_on() {
  if command -v makoctl &>/dev/null; then
    makoctl set-mode do-not-disturb 2>/dev/null || makoctl mode -a do-not-disturb 2>/dev/null
  fi
  if command -v dunstctl &>/dev/null; then
    dunstctl set-paused true 2>/dev/null
  fi
  if command -v notify-send &>/dev/null; then
    pkill -x notify-send 2>/dev/null || true
  fi
  emit_dnd 1
  notify "Do Not Disturb: ON"
}

set_dnd_off() {
  if command -v makoctl &>/dev/null; then
    makoctl set-mode default 2>/dev/null || makoctl mode -r do-not-disturb 2>/dev/null
  fi
  if command -v dunstctl &>/dev/null; then
    dunstctl set-paused false 2>/dev/null
  fi
  emit_dnd 0
  notify "Do Not Disturb: OFF"
}

is_dnd() {
  if command -v dunstctl &>/dev/null; then
    dunstctl is-paused 2>/dev/null | grep -q "true" && return 0 || return 1
  fi
  if command -v makoctl &>/dev/null; then
    makoctl mode 2>/dev/null | grep -q "do-not-disturb" && return 0 || return 1
  fi
  return 1
}

case "$MODE" in
  toggle)
    if is_dnd; then
      set_dnd_off
    else
      set_dnd_on
    fi
    ;;

  on|enable)
    set_dnd_on
    ;;

  off|disable)
    set_dnd_off
    ;;

  status|get)
    if is_dnd; then
      echo "DND: on"
    else
      echo "DND: off"
    fi
    ;;

  help|--help|-h|*)
    echo ""
    echo "Do Not Disturb"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  toggle        Toggle DND on/off"
    echo "  on            Enable DND"
    echo "  off           Disable DND"
    echo "  status        Show DND state"
    echo ""
    ;;
esac
