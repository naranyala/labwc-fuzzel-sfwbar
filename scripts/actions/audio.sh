#!/bin/bash
#
# audio.sh — Audio control (volume, mute, sink switch)
#
# Modes: up, down, up-0.5, down-0.5, mute, mute-input, sink-list, sink-switch, mic-toggle

set -euo pipefail

MODE="${1:-up}"
STEP="${2:-5%}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }

get_volume() {
  wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -oP '[\d.]+(?= \[)' || echo "0"
}

is_muted() {
  wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q '\[MUTED\]'
}

notify() {
  local msg="$1"
  local vol="$2"
  if command -v notify-send &>/dev/null; then
    notify-send -a "Audio" -t 2000 -h int:value:"$vol" "$msg"
  fi
}

case "$MODE" in
  up|raise|volume-up)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "$STEP"+ 2>/dev/null
    vol=$(get_volume)
    notify "Volume: ${vol}%" "$vol"
    ;;

  down|lower|volume-down)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "$STEP"- 2>/dev/null
    vol=$(get_volume)
    notify "Volume: ${vol}%" "$vol"
    ;;

  up-0.5|volume-up-0.5|volume-up-half|volume-up-half-percent|vol-up-0.5|vol-up-half|inc-0.5)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "0.5%+" 2>/dev/null
    vol=$(get_volume)
    notify "Volume: ${vol}%" "$vol"
    pass "Volume up by 0.5%"
    ;;

  down-0.5|volume-down-0.5|volume-down-half|volume-down-half-percent|vol-down-0.5|vol-down-half|dec-0.5)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "0.5%-" 2>/dev/null
    vol=$(get_volume)
    notify "Volume: ${vol}%" "$vol"
    pass "Volume down by 0.5%"
    ;;

  mute|toggle-mute)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null
    if is_muted; then
      notify "Muted" "0"
    else
      vol=$(get_volume)
      notify "Unmuted: ${vol}%" "$vol"
    fi
    ;;

  mute-input|mic)
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle 2>/dev/null
    pass "Microphone toggled"
    ;;

  sink-list|list-sinks)
    wpctl status 2>/dev/null
    ;;

  sink-switch|switch-sink)
    local_sinks=$(wpctl status 2>/dev/null | grep -A 100 "Sinks:" | grep -oP '^\s+\*\s+\d+\.\s+.*' | head -1)
    echo "Current sink: $local_sinks"
    echo ""
    echo "Use 'wpctl set-default <id>' to switch"
    wpctl status 2>/dev/null | grep -A 20 "Sinks:"
    ;;

  set-sink)
    local_sink_id="${2:-}"
    if [ -z "$local_sink_id" ]; then
      fail "Usage: $0 set-sink <sink-id>"
    fi
    wpctl set-default "$local_sink_id" 2>/dev/null
    pass "Default sink set to $local_sink_id"
    ;;

  status)
    vol=$(get_volume)
    muted=$(is_muted && echo "muted" || echo "unmuted")
    echo "Volume: ${vol}% (${muted})"
    ;;

  help|--help|-h|*)
    echo ""
    echo "Audio Control"
    echo ""
    echo "Usage: $0 <command> [step]"
    echo ""
    echo "Commands:"
    echo "  up [step]       Volume up (default: 5%)"
    echo "  down [step]     Volume down (default: 5%)"
    echo "  mute            Toggle mute"
    echo "  mute-input      Toggle microphone"
    echo "  sink-list       List audio sinks"
    echo "  sink-switch     Show current sink"
    echo "  set-sink ID     Set default sink"
    echo "  status          Show volume status"
    echo ""
    ;;
esac
