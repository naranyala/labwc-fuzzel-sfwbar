#!/bin/bash
# shell-switcher.sh — Switch between shell modes
# Used by autostart and can be called manually
# Config: ~/.config/labwc-widgets/shell-mode

set -euo pipefail

CFG="$HOME/.config/labwc-widgets/shell-mode"
mkdir -p "$(dirname "$CFG")"

# If no argument, read current or default to noctalia
if [ -z "${1:-}" ]; then
    if [ -f "$CFG" ]; then
        MODE=$(cat "$CFG")
    else
        MODE="noctalia"
    fi
else
    MODE="$1"
    echo "$MODE" > "$CFG"
fi

echo "Shell mode: $MODE"

# Kill all existing shells
pkill -x sfwbar 2>/dev/null || true
pkill -9 -x crystal-dock 2>/dev/null || true
pkill -9 -x noctalia 2>/dev/null || true
sleep 0.5

# Start selected shell
case "$MODE" in
    noctalia)
        if command -v noctalia >/dev/null 2>&1; then
            nohup noctalia > /dev/null 2>&1 &
            echo "Started noctalia"
        else
            echo "error: noctalia not installed"
            exit 1
        fi
        ;;
    crystal)
        if command -v crystal-dock >/dev/null 2>&1; then
            nohup crystal-dock --start --overlay > /dev/null 2>&1 &
            echo "Started crystal-dock"
        else
            echo "error: crystal-dock not installed"
            exit 1
        fi
        
        # SFWBar Top Panel Only
        if command -v sfwbar >/dev/null 2>&1; then
            # Strip bottom bar configuration for this mode
            sed '/bar "bottombar:bottom"/,/}/d' "$HOME/.config/ocws/ocws.config" > "$HOME/.config/ocws/ocws-top.config"
            nohup sfwbar -f "$HOME/.config/ocws/ocws-top.config" > /dev/null 2>&1 &
            echo "Started OCWS Top Panel (sfwbar)"
        fi
        ;;
    both|double_panel)
        if command -v sfwbar >/dev/null 2>&1; then
            nohup sfwbar -f "$HOME/.config/ocws/ocws.config" > /dev/null 2>&1 &
            echo "Started OCWS Dual Panel (sfwbar)"
        else
            echo "error: sfwbar not installed"
            exit 1
        fi
        ;;
    *)
        echo "error: unknown mode '$MODE'. Valid: noctalia, crystal, both"
        echo "Usage: $0 <mode>"
        exit 1
        ;;
esac
