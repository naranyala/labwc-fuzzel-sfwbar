#!/bin/bash
opts=(
  "Randomize Wallpaper"
  "Change Global Theme"
  "Toggle Dark Mode"
  "Toggle Night Light"
  "Back"
)
choice=$(printf '%s\n' "${opts[@]}" | fuzzel -d -p "Aesthetics ❯ " -w 35 -l 5)
case "$choice" in
  *"Randomize Wallpaper")
    wallpaper random
    notify-send -a "Wallpaper" -i preferences-desktop-wallpaper "Wallpaper Randomized" "A new wallpaper has been applied." -t 2000 ;;
  *"Change Global Theme")
    theme_choice=$(ls /media/naranyala/Data/projects-remote/labwc-fuzzel-sfwbar/themes/*.ini 2>/dev/null | xargs -n 1 basename -s .ini | fuzzel -d -p "Theme ❯ " -w 30 -l 12)
    if [[ -n "$theme_choice" ]]; then
      ~/.local/bin/theme "$theme_choice"
      notify-send -a "Theme" -i applications-graphics "Theme Applied" "Global theme changed to $theme_choice." -t 2000
    fi ;;
  *"Toggle Dark Mode")
    ~/.local/bin/actions.sh settings dark-mode 2>/dev/null || true
    notify-send -a "Theme" -i weather-clear-night "Dark Mode Toggled" "System dark mode state has been changed." -t 2000 ;;
  *"Toggle Night Light")
    ~/.local/bin/actions.sh settings night-mode 2>/dev/null || true
    notify-send -a "Display" -i weather-clear-night "Night Light Toggled" "Blue light filter state has been changed." -t 2000 ;;
  *"Back")
    exec ~/.local/bin/actions/dotfiles-menu.sh ;;
esac
