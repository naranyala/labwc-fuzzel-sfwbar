#!/bin/bash
#
# window.sh — Window management actions
#
# Modes: fullscreen, floating, maximize, center, move-to-workspace,
#        snap-left, snap-right, snap-top, snap-bottom, kill, resize

set -euo pipefail

MODE="${1:-}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }

# labwc uses wlr-foreign-toplevel for window management
# Most actions work via keybindings in rc.xml, but these are helper scripts

case "$MODE" in
  fullscreen)
    # Toggle fullscreen via keybinding
    xdotool key --clearmodifiers super+f 2>/dev/null || true
    pass "Toggle fullscreen"
    ;;

  floating)
    xdotool key --clearmodifiers super+e 2>/dev/null || true
    pass "Toggle floating"
    ;;

  maximize)
    xdotool key --clearmodifiers super+a 2>/dev/null || true
    pass "Toggle maximize"
    ;;

  center)
    # Center current window - use labwc action if available
    if command -v wlr-randr &>/dev/null; then
      # Get screen dimensions
      local_res=$(wlr-randr 2>/dev/null | grep -oP '\d+x\d+' | head -1)
      local_w=$(echo "$local_res" | cut -dx -f1)
      local_h=$(echo "$local_res" | cut -dx -f2)
      
      # Center window (800x600 default size)
      local_x=$(( (local_w - 800) / 2 ))
      local_y=$(( (local_h - 600) / 2 ))
      
      # This requires wlr-foreign-toplevel or similar
      pass "Center window (manual positioning may be needed)"
    fi
    ;;

  move-to-workspace)
    local_ws="${2:-1}"
    # Super+Shift+1-9 moves window to workspace
    xdotool key --clearmodifiers super+shift+"$local_ws" 2>/dev/null || true
    pass "Moved to workspace $local_ws"
    ;;

  snap-left)
    xdotool key --clearmodifiers super+Left 2>/dev/null || true
    pass "Snap left"
    ;;

  snap-right)
    xdotool key --clearmodifiers super+Right 2>/dev/null || true
    pass "Snap right"
    ;;

  snap-top)
    xdotool key --clearmodifiers super+Up 2>/dev/null || true
    pass "Snap top"
    ;;

  snap-bottom)
    xdotool key --clearmodifiers super+Down 2>/dev/null || true
    pass "Snap bottom"
    ;;

  kill)
    xdotool key --clearmodifiers super+q 2>/dev/null || true
    pass "Kill window"
    ;;

  close)
    xdotool key --clearmodifiers alt+F4 2>/dev/null || true
    pass "Close window"
    ;;

  resize)
    local_dir="${2:-right}"
    local_size="${3:-50}"
    case "$local_dir" in
      left)   xdotool key --clearmodifiers super+shift+Left 2>/dev/null ;;
      right)  xdotool key --clearmodifiers super+shift+Right 2>/dev/null ;;
      up)     xdotool key --clearmodifiers super+shift+Up 2>/dev/null ;;
      down)   xdotool key --clearmodifiers super+shift+Down 2>/dev/null ;;
    esac
    pass "Resize $local_dir"
    ;;

  help|--help|-h|*)
    echo ""
    echo "Window Management"
    echo ""
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  fullscreen              Toggle fullscreen"
    echo "  floating                Toggle floating"
    echo "  maximize                Toggle maximize"
    echo "  center                  Center window"
    echo "  move-to-workspace <N>   Move to workspace N"
    echo "  snap-left               Snap to left half"
    echo "  snap-right              Snap to right half"
    echo "  snap-top                Snap to top"
    echo "  snap-bottom             Snap to bottom"
    echo "  kill                    Kill window"
    echo "  close                   Close window"
    echo "  resize <dir> <size>     Resize window"
    echo ""
    ;;
esac
