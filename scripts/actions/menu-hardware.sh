#!/bin/bash
ACTIONS="$HOME/.local/bin/actions.sh"
opts=(
  "Increase Volume by 0.5%"
  "Decrease Volume by 0.5%"
  "Toggle Audio Mute"
  "Toggle Mic Mute"
  "Increase Brightness by 0.5%"
  "Decrease Brightness by 0.5%"
  "Toggle WiFi"
  "Toggle Bluetooth"
  "Back"
)
choice=$(printf '%s\n' "${opts[@]}" | fuzzel -d -p "Hardware ❯ " -w 35 -l 9)
case "$choice" in
  *"Increase Volume"*)     "$ACTIONS" audio up-0.5 ;;
  *"Decrease Volume"*)     "$ACTIONS" audio down-0.5 ;;
  *"Toggle Audio Mute")    "$ACTIONS" audio mute ;;
  *"Toggle Mic Mute")      "$ACTIONS" audio mute-input ;;
  *"Increase Brightness"*) "$ACTIONS" brightness up-0.5 ;;
  *"Decrease Brightness"*) "$ACTIONS" brightness down-0.5 ;;
  *"Toggle WiFi")          "$ACTIONS" network wifi-toggle ;;
  *"Toggle Bluetooth")     "$ACTIONS" network bt-toggle ;;
  *"Back")                 exec ~/.local/bin/actions/dotfiles-menu.sh ;;
esac
