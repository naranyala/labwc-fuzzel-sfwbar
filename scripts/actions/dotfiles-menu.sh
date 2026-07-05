#!/bin/bash
opts=(
  "Aesthetics & Themes ❯"
  "Hardware & Media ❯"
  "Window Management ❯"
  "System & Power ❯"
  "Quick Tools ❯"
)
choice=$(printf '%s\n' "${opts[@]}" | fuzzel -d -p "Dotfiles ❯ " -w 30 -l 5)
case "$choice" in
  *"Aesthetics & Themes"*) exec ~/.local/bin/actions/menu-aesthetics.sh ;;
  *"Hardware & Media"*)    exec ~/.local/bin/actions/menu-hardware.sh ;;
  *"Window Management"*)   exec ~/.local/bin/actions/menu-windows.sh ;;
  *"System & Power"*)      exec ~/.local/bin/actions/menu-system.sh ;;
  *"Quick Tools"*)         exec ~/.local/bin/actions/menu-tools.sh ;;
esac
