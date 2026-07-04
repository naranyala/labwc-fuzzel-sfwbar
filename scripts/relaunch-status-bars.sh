#!/bin/bash
#
# relaunch-status-bars.sh — Restart sfwbar and crystal-dock
#
# Usage: relaunch-status-bars.sh [sfwbar|dock|all]
#   No args or "all" → restart both
#   "sfwbar"         → restart sfwbar only
#   "dock"           → restart crystal-dock only

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

pass()  { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail()  { echo -e "  ${RED}✗${NC} $1"; exit 1; }
info()  { echo -e "  ${CYAN}→${NC} $1"; }
section() { echo -e "\n${BOLD}[$1]${NC}"; }

TARGET="${1:-all}"

# ---- Stop ----
section "Stopping"

stop_sfwbar() {
  if pgrep -x sfwbar >/dev/null 2>&1; then
    pkill -9 -x sfwbar
    sleep 0.3
    pass "sfwbar stopped"
  else
    info "sfwbar not running"
  fi
}

stop_dock() {
  if pgrep -x crystal-dock >/dev/null 2>&1; then
    pkill -9 -x crystal-dock
    sleep 0.3
    pass "crystal-dock stopped"
  else
    info "crystal-dock not running"
  fi
}

case "$TARGET" in
  sfwbar) stop_sfwbar ;;
  dock)   stop_dock ;;
  all)    stop_sfwbar; stop_dock ;;
  *)      fail "Unknown target: $TARGET (use sfwbar, dock, or all)" ;;
esac

# ---- Start ----
section "Starting"

CSS_FILE="$HOME/.config/sfwbar/catppuccin-mocha.css"
CONFIG_FILE="$HOME/.config/sfwbar/sfwbar.config"
CSS_ARG=""
CONFIG_ARG=""
[ -f "$CSS_FILE" ] && CSS_ARG="-c $CSS_FILE"
[ -f "$CONFIG_FILE" ] && CONFIG_ARG="-f $CONFIG_FILE"

start_sfwbar() {
  if ! command -v sfwbar >/dev/null 2>&1; then
    warn "sfwbar binary not found, skipping"
    return
  fi
  nohup sfwbar $CONFIG_ARG $CSS_ARG > /dev/null 2>&1 &
  sleep 1
  if pgrep -x sfwbar >/dev/null 2>&1; then
    pass "sfwbar started (PID: $(pgrep -x sfwbar))"
  else
    warn "sfwbar failed to start"
  fi
}

start_dock() {
  if ! command -v crystal-dock >/dev/null 2>&1; then
    warn "crystal-dock binary not found, skipping"
    return
  fi
  nohup crystal-dock --start --overlay > /dev/null 2>&1 &
  sleep 1
  if pgrep -x crystal-dock >/dev/null 2>&1; then
    pass "crystal-dock started (PID: $(pgrep -x crystal-dock))"
  else
    warn "crystal-dock failed to start"
  fi
}

case "$TARGET" in
  sfwbar) start_sfwbar ;;
  dock)   start_dock ;;
  all)    start_sfwbar; start_dock ;;
esac

section "Status"
pgrep -x sfwbar >/dev/null 2>&1 && pass "sfwbar: running" || warn "sfwbar: not running"
pgrep -x crystal-dock >/dev/null 2>&1 && pass "crystal-dock: running" || warn "crystal-dock: not running"
