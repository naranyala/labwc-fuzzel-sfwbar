#!/bin/bash
#
# network.sh — Network control (wifi, bluetooth, status)
#
# Modes: wifi-toggle, wifi-list, wifi-connect, bt-toggle, bt-list, status

set -euo pipefail

MODE="${1:-status}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

notify() {
  local msg="$1"
  if command -v notify-send &>/dev/null; then
    notify-send -a "Network" -t 3000 "$msg"
  fi
}

# --- WiFi ---
wifi_toggle() {
  if command -v nmcli &>/dev/null; then
    local state=$(nmcli -t -f WIFI general 2>/dev/null)
    if [ "$state" = "enabled" ]; then
      nmcli radio wifi off 2>/dev/null
      notify "WiFi disabled"
      pass "WiFi off"
    else
      nmcli radio wifi on 2>/dev/null
      notify "WiFi enabled"
      pass "WiFi on"
    fi
  elif command -v ip &>/dev/null; then
    local iface=$(ip link show | grep -oP 'wl\w+' | head -1)
    if [ -n "$iface" ]; then
      if ip link show "$iface" | grep -q "UP"; then
        sudo ip link set "$iface" down
        notify "WiFi disabled"
      else
        sudo ip link set "$iface" up
        notify "WiFi enabled"
      fi
    fi
  else
    fail "No network tool found"
  fi
}

wifi_list() {
  if command -v nmcli &>/dev/null; then
    echo "Available WiFi networks:"
    echo ""
    nmcli device wifi list 2>/dev/null
  else
    fail "nmcli not found"
  fi
}

wifi_connect() {
  local ssid="${1:-}"
  local pass_input="${2:-}"
  
  if [ -z "$ssid" ]; then
    if command -v rofi &>/dev/null; then
      ssid=$(nmcli -t -f SSID device wifi list 2>/dev/null | rofi -dmenu -p "WiFi Network")
    else
      fail "Usage: $0 wifi-connect <ssid> [password]"
    fi
  fi
  
  if [ -z "$ssid" ]; then
    exit 0
  fi
  
  if [ -n "$pass_input" ]; then
    nmcli device wifi connect "$ssid" password "$pass_input" 2>/dev/null
  else
    nmcli device wifi connect "$ssid" 2>/dev/null
  fi
  
  if [ $? -eq 0 ]; then
    notify "Connected to $ssid"
    pass "Connected to $ssid"
  else
    warn "Failed to connect to $ssid"
  fi
}

# --- Bluetooth ---
bt_toggle() {
  if command -v bluetoothctl &>/dev/null; then
    local state=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')
    if [ "$state" = "yes" ]; then
      bluetoothctl power off 2>/dev/null
      notify "Bluetooth disabled"
      pass "Bluetooth off"
    else
      bluetoothctl power on 2>/dev/null
      notify "Bluetooth enabled"
      pass "Bluetooth on"
    fi
  else
    fail "bluetoothctl not found"
  fi
}

bt_list() {
  if command -v bluetoothctl &>/dev/null; then
    echo "Bluetooth devices:"
    echo ""
    bluetoothctl devices 2>/dev/null
    echo ""
    echo "Trusted:"
    bluetoothctl devices Trusted 2>/dev/null
  fi
}

bt_connect() {
  local mac="${1:-}"
  if [ -z "$mac" ]; then
    bt_list
    exit 0
  fi
  bluetoothctl connect "$mac" 2>/dev/null && pass "Connected to $mac"
}

# --- Status ---
show_status() {
  echo ""
  echo "== Network Status =="
  echo ""
  
  # WiFi
  if command -v nmcli &>/dev/null; then
    local wifi_state=$(nmcli -t -f WIFI general 2>/dev/null)
    local wifi_conn=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep wireless | head -1 | cut -d: -f1)
    
    if [ "$wifi_state" = "enabled" ]; then
      if [ -n "$wifi_conn" ]; then
        echo -e "  WiFi: ${GREEN}●${NC} Connected to ${CYAN}$wifi_conn${NC}"
      else
        echo -e "  WiFi: ${YELLOW}●${NC} Enabled, not connected"
      fi
    else
      echo -e "  WiFi: ${RED}○${NC} Disabled"
    fi
  fi
  
  # IP
  local ip=$(ip -4 addr show 2>/dev/null | grep -oP 'inet \K[\d.]+' | grep -v '127.0.0.1' | head -1)
  if [ -n "$ip" ]; then
    echo -e "  IP:   ${CYAN}$ip${NC}"
  fi
  
  # Bluetooth
  if command -v bluetoothctl &>/dev/null; then
    local bt_state=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
    if [ "$bt_state" = "yes" ]; then
      echo -e "  BT:   ${GREEN}●${NC} On"
    else
      echo -e "  BT:   ${RED}○${NC} Off"
    fi
  fi
  
  # Internet
  if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    echo -e "  Net:  ${GREEN}●${NC} Connected"
  else
    echo -e "  Net:  ${RED}○${NC} No internet"
  fi
  echo ""
}

case "$MODE" in
  wifi-toggle|wifi)     wifi_toggle ;;
  wifi-list|wifi-scan)  wifi_list ;;
  wifi-connect)         wifi_connect "${@:2}" ;;
  bt-toggle|bluetooth|bt) bt_toggle ;;
  bt-list|bt-scan)      bt_list ;;
  bt-connect)           bt_connect "${@:2}" ;;
  status|info)          show_status ;;
  help|--help|-h|*)
    echo ""
    echo "Network Control"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "WiFi:"
    echo "  wifi-toggle      Toggle WiFi on/off"
    echo "  wifi-list        List available networks"
    echo "  wifi-connect     Connect to network"
    echo ""
    echo "Bluetooth:"
    echo "  bt-toggle        Toggle Bluetooth"
    echo "  bt-list          List devices"
    echo "  bt-connect       Connect to device"
    echo ""
    echo "Status:"
    echo "  status           Show network status"
    echo ""
    ;;
esac
