#!/bin/bash
#
# workspace.sh — Workspace/desktop actions
#
# Modes: switch, move, list, next, prev

set -euo pipefail

MODE="${1:-list}"
TARGET="${2:-}"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }

switch_workspace() {
  local ws="${1:-1}"
  # Alt+1-9 switches workspace in labwc
  xdotool key --clearmodifiers alt+"$ws" 2>/dev/null || true
  pass "Switched to workspace $ws"
}

move_to_workspace() {
  local ws="${1:-1}"
  # Super+Shift+1-9 moves window
  xdotool key --clearmodifiers super+shift+"$ws" 2>/dev/null || true
  pass "Moved window to workspace $ws"
}

next_workspace() {
  # Alt+Tab or similar for next workspace
  xdotool key --clearmodifiers alt+Right 2>/dev/null || true
  pass "Next workspace"
}

prev_workspace() {
  xdotool key --clearmodifiers alt+Left 2>/dev/null || true
  pass "Previous workspace"
}

list_workspaces() {
  echo ""
  echo "Workspaces: 1-9"
  echo ""
  echo "Switch: Alt + [1-9]"
  echo "Move window: Super + Shift + [1-9]"
  echo ""
}

case "$MODE" in
  switch|goto|go)
    if [ -n "$TARGET" ]; then
      switch_workspace "$TARGET"
    else
      list_workspaces
    fi
    ;;
  move|send)
    if [ -n "$TARGET" ]; then
      move_to_workspace "$TARGET"
    else
      list_workspaces
    fi
    ;;
  next)
    next_workspace
    ;;
  prev|previous)
    prev_workspace
    ;;
  list|ls)
    list_workspaces
    ;;
  help|--help|-h|*)
    echo ""
    echo "Workspace Management"
    echo ""
    echo "Usage: $0 <command> [target]"
    echo ""
    echo "Commands:"
    echo "  switch <N>     Switch to workspace N"
    echo "  move <N>       Move window to workspace N"
    echo "  next           Next workspace"
    echo "  prev           Previous workspace"
    echo "  list           List workspaces"
    echo ""
    ;;
esac
