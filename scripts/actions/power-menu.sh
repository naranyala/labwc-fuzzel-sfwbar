#!/bin/bash
#
# power-menu.sh — Power menu (shutdown, reboot, logout, lock, suspend)
#
# Shows a menu via rofi or wofi, or acts directly with flags.

set -euo pipefail

ACTION="${1:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

show_menu() {
  local opts=(
    "  Logout"
    "  Suspend"
    "  Hibernate"
    "  Reboot"
    "  Shutdown"
    "  Cancel"
  )

  if command -v rofi &>/dev/null; then
    choice=$(printf '%s\n' "${opts[@]}" | rofi -dmenu -p "Power" -theme-str 'window {width: 200px;}')
  elif command -v wofi &>/dev/null; then
    choice=$(printf '%s\n' "${opts[@]}" | wofi --dmenu -p "Power")
  else
    echo "Select action:"
    select choice in "${opts[@]}"; do
      break
    done
  fi

  case "$choice" in
    *Logout)    do_action logout ;;
    *Suspend)   do_action suspend ;;
    *Hibernate) do_action hibernate ;;
    *Reboot)    do_action reboot ;;
    *Shutdown)  do_action shutdown ;;
    *)          exit 0 ;;
  esac
}

do_action() {
  local action="$1"
  case "$action" in
    logout)
      if command -v labwc &>/dev/null; then
        labwc --exit
      elif command -v swaymsg &>/dev/null; then
        swaymsg exit
      else
        loginctl terminate-user "$USER"
      fi
      ;;
    suspend)
      systemctl suspend
      ;;
    hibernate)
      systemctl hibernate
      ;;
    reboot)
      systemctl reboot
      ;;
    shutdown)
      systemctl poweroff
      ;;
  esac
}

if [ -n "$ACTION" ]; then
  do_action "$ACTION"
else
  show_menu
fi
