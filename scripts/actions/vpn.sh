#!/bin/bash
#
# vpn.sh — VPN status and control
#
# Modes: status, toggle, connect, disconnect, list
# Supports: NetworkManager, wg-quick, OpenVPN, systemd-resolved

set -euo pipefail

MODE="${1:-status}"

notify() {
  local msg="$1"
  if command -v notify-send &>/dev/null; then
    notify-send -a "VPN" -t 3000 "$msg"
  fi
}

get_nm_vpns() {
  nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -E 'vpn|wireguard' | cut -d: -f1 || true
}

get_active_vpn() {
  local nm_vpns
  nm_vpns=$(get_nm_vpns)
  if [ -n "$nm_vpns" ]; then
    echo "$nm_vpns" | head -1
    return
  fi
  if command -v wg show &>/dev/null && wg show 2>/dev/null | grep -q "interface"; then
    wg show 2>/dev/null | grep "interface" | head -1 | awk '{print $2}'
    return
  fi
}

is_vpn_active() {
  local active
  active=$(get_active_vpn)
  [ -n "$active" ]
}

case "$MODE" in
  status)
    if is_vpn_active; then
      local vpn_name
      vpn_name=$(get_active_vpn)
      echo "VPN: connected ($vpn_name)"
    else
      echo "VPN: disconnected"
    fi
    ;;

  toggle)
    if is_vpn_active; then
      local vpn_name
      vpn_name=$(get_active_vpn)
      nmcli connection down "$vpn_name" 2>/dev/null || true
      notify "VPN disconnected: $vpn_name"
    else
      local available
      available=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep -E ':vpn|:wireguard' | cut -d: -f1 | head -1 || true)
      if [ -z "$available" ]; then
        echo "No VPN connections configured"
        echo ""
        echo "Configure one with: nmcli connection import type openvpn <file.ovpn>"
        exit 1
      fi
      nmcli connection up "$available" 2>/dev/null || {
        echo "Failed to connect to $available"
        exit 1
      }
      notify "VPN connected: $available"
    fi
    ;;

  connect)
    local name="${2:-}"
    if [ -z "$name" ]; then
      local available
      available=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep -E ':vpn|:wireguard' | cut -d: -f1)
      if [ -z "$available" ]; then
        echo "No VPN connections configured"
        exit 1
      fi
      name=$(echo "$available" | fuzzel -d -p "VPN > " -w 40 -l 10 2>/dev/null || echo "$available" | head -1)
    fi
    [ -z "$name" ] && exit 0
    nmcli connection up "$name" 2>/dev/null && notify "VPN connected: $name"
    ;;

  disconnect)
    local vpn_name
    vpn_name=$(get_active_vpn)
    if [ -n "$vpn_name" ]; then
      nmcli connection down "$vpn_name" 2>/dev/null || true
      notify "VPN disconnected: $vpn_name"
    else
      echo "No active VPN"
    fi
    ;;

  list)
    local available
    available=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | grep -E ':vpn|:wireguard' | cut -d: -f1 || true)
    if [ -n "$available" ]; then
      echo "Available VPNs:"
      echo "$available" | while IFS= read -r line; do
        if is_vpn_active && [ "$line" = "$(get_active_vpn)" ]; then
          echo "  * $line (active)"
        else
          echo "    $line"
        fi
      done
    else
      echo "No VPN connections configured"
      echo ""
      echo "Import a VPN profile: nmcli connection import type openvpn <file.ovpn>"
    fi
    ;;

  help|--help|-h|*)
    echo ""
    echo "VPN Control"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  status            Show VPN status"
    echo "  toggle            Toggle VPN on/off"
    echo "  connect [name]    Connect to VPN"
    echo "  disconnect        Disconnect VPN"
    echo "  list              List available VPNs"
    echo ""
    ;;
esac
