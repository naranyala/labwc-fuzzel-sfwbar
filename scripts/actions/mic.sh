#!/bin/bash
#
# mic.sh — Microphone control (mute toggle, volume, list sources)
#
# Modes: toggle, mute, unmute, status, list

set -euo pipefail

MODE="${1:-toggle}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}ok${NC} $1"; }
fail() { echo -e "${RED}fail${NC} $1"; exit 1; }

notify() {
  local msg="$1"
  if command -v notify-send &>/dev/null; then
    notify-send -a "Microphone" -t 2000 "$msg"
  fi
}

get_mic_volume() {
  wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -oP '[\d.]+' | head -1
}

is_mic_muted() {
  wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q '\[MUTED\]'
}

case "$MODE" in
  toggle)
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle 2>/dev/null
    if is_mic_muted; then
      notify "Microphone muted"
      pass "Mic muted"
    else
      notify "Microphone unmuted"
      pass "Mic unmuted"
    fi
    ;;

  mute|mute-input)
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1 2>/dev/null
    notify "Microphone muted"
    pass "Mic muted"
    ;;

  unmute)
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 2>/dev/null
    notify "Microphone unmuted"
    pass "Mic unmuted"
    ;;

  status)
    if is_mic_muted; then
      echo "Microphone: muted"
    else
      vol=$(get_mic_volume)
      echo "Microphone: active (${vol}%)"
    fi
    ;;

  list)
    echo "Audio Sources:"
    wpctl status 2>/dev/null | grep -A 50 "Sources:" | grep -v "Sinks:"
    ;;

  help|--help|-h|*)
    echo ""
    echo "Microphone Control"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  toggle        Toggle microphone mute"
    echo "  mute          Mute microphone"
    echo "  unmute        Unmute microphone"
    echo "  status        Show microphone status"
    echo "  list          List audio sources"
    echo ""
    ;;
esac
