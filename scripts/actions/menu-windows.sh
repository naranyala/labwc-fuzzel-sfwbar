#!/bin/bash
ACTIONS="$HOME/.local/bin/actions.sh"
opts=(
  "Show Desktop"
  "Toggle Fullscreen"
  "Toggle Floating Window"
  "Back"
)
choice=$(printf '%s\n' "${opts[@]}" | fuzzel -d -p "Windows ❯ " -w 35 -l 4)
case "$choice" in
  *"Show Desktop") wtype -M win -k d -m win 2>/dev/null || xdotool key super+d 2>/dev/null ;;
  *"Toggle Fullscreen") "$ACTIONS" window fullscreen ;;
  *"Toggle Floating"*) "$ACTIONS" window floating ;;
  *"Back") exec ~/.local/bin/actions/dotfiles-menu.sh ;;
esac
