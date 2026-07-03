#!/bin/bash
#
# quick.sh — Quick launch common operations
#
# Shortcuts for frequent tasks.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

ACTION="${1:-help}"

case "$ACTION" in

  # --- Config Management ---
  config|cfg)
    ${EDITOR:-nano} "$HOME/.config/labwc/rc.xml"
    labwc --reconfigure 2>/dev/null && echo -e "${GREEN}✓${NC} Config reloaded" || echo -e "${YELLOW}⚠${NC} Could not reload"
    ;;

  autostart)
    ${EDITOR:-nano} "$HOME/.config/labwc/autostart"
    ;;

  theme)
    ${EDITOR:-nano} "$HOME/.config/labwc/themerc-override"
    labwc --reconfigure 2>/dev/null
    ;;

  theme-picker|pick)
    "$SCRIPT_DIR/theme-picker.sh" pick
    ;;

  theme-apply)
    "$SCRIPT_DIR/theme-picker.sh" apply "${2:-}"
    ;;

  theme-list)
    "$SCRIPT_DIR/theme-picker.sh" list
    ;;

  theme-current)
    "$SCRIPT_DIR/theme-picker.sh" current
    ;;

  theme-preview)
    "$SCRIPT_DIR/theme-picker.sh" preview "${2:-}"
    ;;

  theme-download)
    "$SCRIPT_DIR/download-themes.sh" "${2:-all}"
    ;;

  menu)
    ${EDITOR:-nano} "$HOME/.config/labwc/menu.xml"
    labwc --reconfigure 2>/dev/null
    ;;

  # --- Quick Actions ---
  reload)
    labwc --reconfigure 2>/dev/null && echo -e "${GREEN}✓${NC} Reloaded" || echo -e "${RED}✗${NC} Failed"
    ;;

  # --- Actions (delegate to actions.sh) ---
  power|power-menu|shutdown|reboot|logout|suspend)
    "$SCRIPT_DIR/actions.sh" "$ACTION" "$@"
    ;;
  screenshot|scrot|screen)
    "$SCRIPT_DIR/actions.sh" screenshot "$@"
    ;;
  clipboard|clip)
    "$SCRIPT_DIR/actions.sh" clipboard "$@"
    ;;
  audio|volume|sound)
    "$SCRIPT_DIR/actions.sh" audio "$@"
    ;;
  brightness|bright)
    "$SCRIPT_DIR/actions.sh" brightness "$@"
    ;;
  network|wifi|bt)
    "$SCRIPT_DIR/actions.sh" network "$@"
    ;;
  window|wm)
    "$SCRIPT_DIR/actions.sh" window "$@"
    ;;
  workspace|ws)
    "$SCRIPT_DIR/actions.sh" workspace "$@"
    ;;
  launcher|launch|apps)
    "$SCRIPT_DIR/actions.sh" launcher "$@"
    ;;
  settings|setting)
    "$SCRIPT_DIR/actions.sh" settings "$@"
    ;;

  restart)
    pkill -x labwc 2>/dev/null
    echo -e "${YELLOW}⚠${NC} labwc closed. Log in again from TTY."
    ;;

  # --- Widget Management ---
  widgets)
    "$SCRIPT_DIR/widget-manager.sh" list
    ;;

  widget-install)
    "$SCRIPT_DIR/widget-manager.sh" install "${2:-}"
    ;;

  widget-enable)
    "$SCRIPT_DIR/widget-manager.sh" enable "${2:-}"
    ;;

  # --- Wallpaper ---
  wallpaper)
    wallpaper "${2:-random}" 2>/dev/null || echo -e "${RED}✗${NC} wallpaper command not found"
    ;;

  wallpaper-sync)
    wallpaper sync 2>/dev/null || echo -e "${RED}✗${NC} wallpaper sync failed"
    ;;

  # --- Screen Protection ---
  night-on)
    if command -v gammastep &>/dev/null; then
      gammastep -m randr -t 6500:3500 -g 1.0 -r &
      echo -e "${GREEN}✓${NC} gammastep started (night mode)"
    elif command -v redshift &>/dev/null; then
      redshift -m randr -t 6500:3500 -g 1.0 -r &
      echo -e "${GREEN}✓${NC} redshift started (night mode)"
    else
      echo -e "${RED}✗${NC} No screen protection tool found"
    fi
    ;;

  night-off)
    pkill -x gammastep 2>/dev/null && echo -e "${GREEN}✓${NC} gammastep stopped" || true
    pkill -x redshift 2>/dev/null && echo -e "${GREEN}✓${NC} redshift stopped" || true
    ;;

  # --- Input ---
  scroll)
    "$SCRIPT_DIR/toggle-natural-scroll.sh"
    ;;

  # --- Diagnostics ---
  validate)
    "$SCRIPT_DIR/validate.sh"
    ;;

  fix)
    "$SCRIPT_DIR/fix.sh"
    ;;

  status)
    "$SCRIPT_DIR/status.sh"
    ;;

  diag)
    "$SCRIPT_DIR/diagnostics.sh"
    ;;

  # --- Backup ---
  backup)
    "$SCRIPT_DIR/backup.sh"
    ;;

  restore)
    "$SCRIPT_DIR/restore.sh" "${2:-}"
    ;;

  # --- Sync ---
  sync)
    "$SCRIPT_DIR/dotfiles-sync.sh" "${2:-diff}" "${3:---all}"
    ;;

  sync-push)
    "$SCRIPT_DIR/dotfiles-sync.sh" push --all
    ;;

  sync-pull)
    "$SCRIPT_DIR/dotfiles-sync.sh" pull --all
    ;;

  # --- Themes ---
  theme)
    "$SCRIPT_DIR/themes.sh" override
    ;;

  theme-list)
    "$SCRIPT_DIR/themes.sh" list
    ;;

  theme-set)
    "$SCRIPT_DIR/themes.sh" set "${2:-}"
    ;;

  theme-preview)
    "$SCRIPT_DIR/themes.sh" preview
    ;;

  # --- Keybind Presets ---
  binds)
    "$SCRIPT_DIR/keybind-presets.sh" current
    ;;

  binds-list)
    "$SCRIPT_DIR/keybind-presets.sh" list
    ;;

  binds-apply)
    "$SCRIPT_DIR/keybind-presets.sh" apply "${2:-}"
    ;;

  # --- Widget Actions ---
  action)
    shift
    "$SCRIPT_DIR/widget-actions.sh" "$@"
    ;;

  # --- Update ---
  update)
    "$SCRIPT_DIR/update.sh" "${2:---labwc-only}"
    ;;

  # --- Process Control ---
  kill-panel)
    pkill -x crystal-dock 2>/dev/null && echo -e "${GREEN}✓${NC} crystal-dock stopped"
    pkill -x zebar 2>/dev/null && echo -e "${GREEN}✓${NC} zebar stopped"
    ;;

  start-panel)
    crystal-dock --start --overlay &
    zebar startup &
    echo -e "${GREEN}✓${NC} Panels started"
    ;;

  # --- Reconfigure ---
  reconfigure|reconfig|interactive)
    "$SCRIPT_DIR/reconfigure.sh"
    ;;

  # --- Help ---
  help|--help|-h|*)
    echo ""
    echo -e "${BOLD}== Quick Actions ==${NC}"
    echo ""
    echo -e "${CYAN}Config:${NC}"
    echo "  config          Edit rc.xml and reload"
    echo "  autostart       Edit autostart"
    echo "  theme           Edit theme overrides"
    echo "  menu            Edit root menu"
    echo ""
    echo -e "${CYAN}Actions:${NC}"
    echo "  reload          Reload labwc config"
    echo "  restart         Close labwc (re-login to restart)"
    echo ""
    echo -e "${CYAN}Widgets:${NC}"
    echo "  widgets         List available widgets"
    echo "  widget-install  Install a widget"
    echo "  widget-enable   Set widget as main bar"
    echo ""
    echo -e "${CYAN}Wallpaper:${NC}"
    echo "  wallpaper       Set random wallpaper"
    echo "  wallpaper-sync  Download wallpapers"
    echo ""
    echo -e "${CYAN}Screen:${NC}"
    echo "  night-on        Enable night mode"
    echo "  night-off       Disable night mode"
    echo "  scroll          Toggle natural scroll"
    echo ""
    echo -e "${CYAN}System:${NC}"
    echo "  reconfigure     Interactive reinstall/reconfigure CLI"
    echo "  validate        Validate setup"
    echo "  fix             Auto-fix issues"
    echo "  status          Show system status"
    echo "  diag            Run diagnostics"
    echo "  backup          Backup config"
    echo "  restore [N]     Restore from backup"
    echo "  update          Update labwc"
    echo ""
    echo -e "${CYAN}Sync & Config:${NC}"
    echo "  sync [diff|push|pull]  Sync dotfiles with project"
    echo "  sync-push       Push project → ~/.config"
    echo "  sync-pull       Pull ~/.config → project"
    echo "  theme-picker    Interactive visual theme picker"
    echo "  theme-apply <n> Quick apply a theme"
    echo "  theme-list      List available themes"
    echo "  theme-current   Show current theme"
    echo "  theme-preview   Preview a theme"
    echo "  binds           Show current keybindings"
    echo "  binds-list      List available presets"
    echo "  binds-apply <n> Apply keybinding preset"
    echo ""
    echo -e "${CYAN}Widget Actions:${NC}"
    echo "  action <cmd>    Run widget action (volume-up, media-play, etc)"
    echo "  action help     List all available actions"
    echo ""
    echo -e "${CYAN}Panels:${NC}"
    echo "  kill-panel      Stop crystal-dock and zebar"
    echo "  start-panel     Start crystal-dock and zebar"
    echo ""
    ;;
esac
