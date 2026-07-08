#!/bin/bash
# ocws-menu.sh — Shared menu launcher (fuzzel → rofi → wofi → stdin fallback)
# Source this file: source "$(dirname "$0")/../lib/ocws-menu.sh"

# Use the canonical notification helper instead of a local copy.
source "$(dirname "${BASH_SOURCE[0]}")/ocws-notify.sh"

ocws_menu() {
    local prompt="${1:-Select}"
    local items="${2:-}"
    local width="${3:-40}"
    local lines="${4:-15}"

    if command -v fuzzel &>/dev/null; then
        echo "$items" | fuzzel --dmenu -p "$prompt" -w "$width" -l "$lines" 2>/dev/null
    elif command -v rofi &>/dev/null; then
        echo "$items" | rofi -dmenu -p "$prompt" -theme-str "window {width: 300px;}" 2>/dev/null
    elif command -v wofi &>/dev/null; then
        echo "$items" | wofi --dmenu -p "$prompt" 2>/dev/null
    else
        echo "$items" | head -1
    fi
}

ocws_check_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        ocws_fail "Required command not found: $cmd"
    fi
}
