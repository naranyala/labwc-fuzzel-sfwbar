#!/bin/bash
# Shell Switcher for OCWS
# Default: noctalia

set -euo pipefail

MODE_FILE="$HOME/.config/ocws/shell_mode"
mkdir -p "$HOME/.config/ocws"

# If no argument, read current or default to noctalia
if [ -z "${1:-}" ]; then
    if [ -f "$MODE_FILE" ]; then
        MODE=$(cat "$MODE_FILE")
    else
        MODE="noctalia"
    fi
else
    MODE="$1"
    echo "$MODE" > "$MODE_FILE"
fi

echo "Shell mode: $MODE"

# Generate ocws-top.config if missing (for crystal_dock mode)
if [ ! -f "$HOME/.config/ocws/ocws-top.config" ] && [ -f "$HOME/.config/ocws/ocws.config" ]; then
    sed -e '39,75d' "$HOME/.config/ocws/ocws.config" > "$HOME/.config/ocws/ocws-top.config"
fi

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
    double_panel)
        if command -v sfwbar >/dev/null 2>&1; then
            nohup sfwbar -f "$HOME/.config/ocws/ocws.config" > /dev/null 2>&1 &
            echo "Started sfwbar (double panel)"
        else
            echo "error: sfwbar not installed"
            exit 1
        fi
        ;;
    crystal_dock)
        if command -v crystal-dock >/dev/null 2>&1 && command -v sfwbar >/dev/null 2>&1; then
            nohup sfwbar -f "$HOME/.config/ocws/ocws-top.config" > /dev/null 2>&1 &
            nohup crystal-dock --start --overlay > /dev/null 2>&1 &
            echo "Started sfwbar + crystal-dock"
        else
            echo "error: crystal-dock or sfwbar not installed"
            exit 1
        fi
        ;;
    *)
        echo "error: unknown mode '$MODE'. Valid: noctalia, double_panel, crystal_dock"
        exit 1
        ;;
esac
