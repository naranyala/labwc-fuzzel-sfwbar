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
    # Find themes dir: installed location, then fall back to script-relative repo path
    _script_dir="$(cd "$(dirname "$0")" && pwd)"
    _themes_dir=""
    for _candidate in \
        "$HOME/.local/share/ocws/themes" \
        "$HOME/.config/ocws/themes" \
        "$_script_dir/../../themes" \
        "$_script_dir/../../../themes"
    do
        if [[ -d "$_candidate" ]]; then
            _themes_dir="$_candidate"
            break
        fi
    done

    if [[ -z "$_themes_dir" ]]; then
      notify-send -a "Theme" -i dialog-error "Themes Not Found" "Could not locate a themes directory." -t 3000
    else
      theme_choice=$(ls "$_themes_dir"/*.ini 2>/dev/null | xargs -n 1 basename -s .ini | fuzzel -d -p "Theme ❯ " -w 30 -l 12)
      if [[ -n "$theme_choice" ]]; then
        ~/.local/bin/theme "$theme_choice"
        notify-send -a "Theme" -i applications-graphics "Theme Applied" "Global theme changed to $theme_choice." -t 2000
      fi
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
