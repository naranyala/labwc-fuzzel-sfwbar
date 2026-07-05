#!/bin/bash
set -euo pipefail

# ocws-health.sh — System health diagnostics for OCWS
# Checks system resources, service status, and potential issues.

OCWS_DIR="${OCWS_DIR:-$HOME/.config/ocws}"
STATE_DIR="$OCWS_DIR/state"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=== OCWS Health Check ==="
echo ""

# --- 1. System Resources ---
echo -e "${CYAN}[1/6] System Resources${NC}"

# Memory
MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_AVAIL=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
MEM_USED=$((MEM_TOTAL - MEM_AVAIL))
MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))

if [[ "$MEM_PCT" -lt 80 ]]; then
    echo -e "  ${GREEN}PASS${NC} Memory: ${MEM_PCT}% used ($((MEM_USED/1024))MB / $((MEM_TOTAL/1024))MB)"
elif [[ "$MEM_PCT" -lt 90 ]]; then
    echo -e "  ${YELLOW}WARN${NC} Memory: ${MEM_PCT}% used ($((MEM_USED/1024))MB / $((MEM_TOTAL/1024))MB)"
else
    echo -e "  ${RED}FAIL${NC} Memory: ${MEM_PCT}% used ($((MEM_USED/1024))MB / $((MEM_TOTAL/1024))MB)"
fi

# CPU Load
LOAD_1=$(cat /proc/loadavg | awk '{print $1}')
LOAD_5=$(cat /proc/loadavg | awk '{print $2}')
CORES=$(nproc)
LOAD_PCT=$(echo "$LOAD_1 $CORES" | awk '{printf "%.0f", ($1/$2)*100}')

if [[ "$LOAD_PCT" -lt 80 ]]; then
    echo -e "  ${GREEN}PASS${NC} CPU Load: ${LOAD_PCT}% (${LOAD_1} avg, ${CORES} cores)"
elif [[ "$LOAD_PCT" -lt 100 ]]; then
    echo -e "  ${YELLOW}WARN${NC} CPU Load: ${LOAD_PCT}% (${LOAD_1} avg, ${CORES} cores)"
else
    echo -e "  ${RED}FAIL${NC} CPU Load: ${LOAD_PCT}% (${LOAD_1} avg, ${CORES} cores)"
fi

# Disk
DISK_PCT=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
if [[ "$DISK_PCT" -lt 80 ]]; then
    echo -e "  ${GREEN}PASS${NC} Disk: ${DISK_PCT}% used"
elif [[ "$DISK_PCT" -lt 90 ]]; then
    echo -e "  ${YELLOW}WARN${NC} Disk: ${DISK_PCT}% used"
else
    echo -e "  ${RED}FAIL${NC} Disk: ${DISK_PCT}% used"
fi
echo ""

# --- 2. OCWS Services ---
echo -e "${CYAN}[2/6] OCWS Services${NC}"

# sfwbar
if pgrep -x sfwbar &>/dev/null; then
    SFWPID=$(pgrep -x sfwbar)
    SFWMEM=$(ps -o rss= -p "$SFWPID" 2>/dev/null | awk '{printf "%.1f", $1/1024}')
    echo -e "  ${GREEN}PASS${NC} sfwbar running (PID: $SFWPID, RSS: ${SFWMEM}MB)"
else
    echo -e "  ${RED}FAIL${NC} sfwbar not running"
fi

# ocws-daemon
if pgrep -f "ocws-daemon" &>/dev/null; then
    echo -e "  ${GREEN}PASS${NC} ocws-daemon running"
else
    echo -e "  ${YELLOW}WARN${NC} ocws-daemon not running"
fi

# labwc
if pgrep -x labwc &>/dev/null; then
    echo -e "  ${GREEN}PASS${NC} labwc running"
else
    echo -e "  ${YELLOW}WARN${NC} labwc not running"
fi

# wl-paste (clipboard)
if pgrep -f "wl-paste.*cliphist" &>/dev/null; then
    echo -e "  ${GREEN}PASS${NC} Clipboard daemon running"
else
    echo -e "  ${YELLOW}WARN${NC} Clipboard daemon not running"
fi
echo ""

# --- 3. Audio ---
echo -e "${CYAN}[3/6] Audio${NC}"

if command -v wpctl &>/dev/null; then
    VOL=$(wpctl get-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '[\d.]+' || echo "N")
    if [[ "$VOL" != "N" ]]; then
        echo -e "  ${GREEN}PASS${NC} PipeWire volume: ${VOL}"
    else
        echo -e "  ${YELLOW}WARN${NC} Could not read volume"
    fi
else
    echo -e "  ${YELLOW}WARN${NC} wpctl not found"
fi

if command -v playerctl &>/dev/null; then
    STATUS=$(playerctl status 2>/dev/null || echo "No player")
    echo -e "  ${GREEN}PASS${NC} Playerctl: $STATUS"
else
    echo -e "  ${YELLOW}WARN${NC} playerctl not found"
fi
echo ""

# --- 4. Display ---
echo -e "${CYAN}[4/6] Display${NC}"

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    echo -e "  ${GREEN}PASS${NC} Wayland session: $WAYLAND_DISPLAY"
else
    echo -e "  ${YELLOW}WARN${NC} WAYLAND_DISPLAY not set"
fi

if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
    echo -e "  ${GREEN}PASS${NC} Desktop: $XDG_CURRENT_DESKTOP"
else
    echo -e "  ${YELLOW}WARN${NC} XDG_CURRENT_DESKTOP not set"
fi
echo ""

# --- 5. State Files ---
echo -e "${CYAN}[5/6] State Files${NC}"

if [[ -d "$STATE_DIR" ]]; then
    STATE_COUNT=$(find "$STATE_DIR" -type f 2>/dev/null | wc -l)
    echo -e "  ${GREEN}PASS${NC} State directory: $STATE_COUNT files"
    
    # Check for corrupted JSON
    for f in "$STATE_DIR"/*.json; do
        if [[ -f "$f" ]]; then
            if ! jq . "$f" &>/dev/null; then
                echo -e "  ${RED}FAIL${NC} Corrupted JSON: $(basename $f)"
            fi
        fi
    done
else
    echo -e "  ${YELLOW}WARN${NC} State directory not found"
fi
echo ""

# --- 6. Potential Issues ---
echo -e "${CYAN}[6/6] Potential Issues${NC}"

# Check for stale lock files
if [[ -f /tmp/ocws-*.lock ]]; then
    echo -e "  ${YELLOW}WARN${NC} Stale lock files found in /tmp"
fi

# Check for zombie processes
ZOMBIES=$(ps aux | grep -c '[Z]' || true)
if [[ "$ZOMBIES" -gt 0 ]]; then
    echo -e "  ${YELLOW}WARN${NC} $ZOMBIES zombie processes found"
fi

# Check disk space for config
CONFIG_SIZE=$(du -sh "$OCWS_DIR" 2>/dev/null | awk '{print $1}')
echo -e "  ${GREEN}PASS${NC} Config size: $CONFIG_SIZE"

echo ""
echo "=== Health Check Complete ==="
