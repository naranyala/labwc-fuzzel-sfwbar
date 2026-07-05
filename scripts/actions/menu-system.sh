#!/bin/bash
ACTIONS="$HOME/.local/bin/actions.sh"
opts=(
  "Screenshot Options"
  "Toggle Do Not Disturb"
  "Reload Configuration"
  "System Maintenance"
  "Power Menu"
  "Back"
)
choice=$(printf '%s\n' "${opts[@]}" | fuzzel -d -p "System ❯ " -w 35 -l 6)
case "$choice" in
  *"Screenshot Options") "$ACTIONS" screenshot ;;
  *"Toggle Do Not Disturb") "$ACTIONS" settings dnd ;;
  *"Reload Configuration") 
    killall -s SIGHUP labwc
    notify-send -a "System" -i view-refresh "Configuration Reloaded" "Labwc configuration reloaded successfully." -t 2000 ;;
  *"System Maintenance")
    "$ACTIONS" maintenance 2>/dev/null || true
    notify-send -a "System" -i system-run "Maintenance Started" "Running system maintenance scripts." -t 2000 ;;
  *"Power Menu") "$ACTIONS" power-menu ;;
  *"Back") exec ~/.local/bin/actions/dotfiles-menu.sh ;;
esac
