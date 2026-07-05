#!/bin/bash
set -euo pipefail

# ocws-validate.sh — Post-install validation for OCWS
# Checks that all required files, binaries, and configurations are in place.

OCWS_DIR="${OCWS_DIR:-$HOME/.config/ocws}"
LABWC_DIR="${LABWC_DIR:-$HOME/.config/labwc}"
LOCAL_BIN="${HOME}/.local/bin"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
WARN=0
FAIL=0

pass() { echo -e "  ${GREEN}PASS${NC} $1"; PASS=$((PASS+1)); }
warn() { echo -e "  ${YELLOW}WARN${NC} $1"; WARN=$((WARN+1)); }
fail() { echo -e "  ${RED}FAIL${NC} $1"; FAIL=$((FAIL+1)); }

echo "=== OCWS Validation ==="
echo ""

# --- 1. Core Binaries ---
echo "[1/8] Core Binaries"
for bin in labwc sfwbar fuzzel foot; do
    if command -v "$bin" &>/dev/null; then
        pass "$bin found: $(which $bin)"
    else
        fail "$bin not found in PATH"
    fi
done

for bin in ocws-sysmon ocws-clip ocws-shot ocws-lock ocws-kv ocws-brightness ocws-volume ocws-notify ocws-wallpaper ocws-color; do
    if [[ -x "$LOCAL_BIN/$bin" ]]; then
        pass "$bin installed"
    else
        fail "$bin not found at $LOCAL_BIN/$bin"
    fi
done
echo ""

# --- 2. Config Directories ---
echo "[2/8] Config Directories"
for dir in "$OCWS_DIR" "$LABWC_DIR" "$OCWS_DIR/plugins"; do
    if [[ -d "$dir" ]]; then
        pass "Directory exists: $dir"
    else
        fail "Directory missing: $dir"
    fi
done
echo ""

# --- 3. Core Config Files ---
echo "[3/8] Core Config Files"
for file in "$OCWS_DIR/ocws.config" "$LABWC_DIR/rc.xml" "$LABWC_DIR/autostart" "$LABWC_DIR/environment"; do
    if [[ -f "$file" ]]; then
        pass "Config exists: $(basename $file)"
    else
        fail "Config missing: $file"
    fi
done
echo ""

# --- 4. Widget Files ---
echo "[4/8] Widget Files"
WIDGET_COUNT=$(find "$OCWS_DIR" -name "*.widget" 2>/dev/null | wc -l)
if [[ "$WIDGET_COUNT" -ge 20 ]]; then
    pass "Widget files: $WIDGET_COUNT found"
else
    warn "Widget files: only $WIDGET_COUNT found (expected 20+)"
fi

for widget in launcher.widget workspaces.widget clock.widget volume-text.widget battery-text.widget tray.widget; do
    if [[ -f "$OCWS_DIR/$widget" ]]; then
        pass "Widget exists: $widget"
    else
        fail "Widget missing: $widget"
    fi
done
echo ""

# --- 5. CSS Files ---
echo "[5/8] CSS Files"
for css in ocws.css theme.css; do
    if [[ -f "$OCWS_DIR/$css" ]]; then
        # Check for invalid GTK3 CSS
        INVALID=$(grep -c "linear-gradient\|backdrop-filter\|:root\|--blur\|var(\|@keyframes" "$OCWS_DIR/$css" 2>/dev/null || true)
        if [[ "$INVALID" -eq 0 ]]; then
            pass "CSS valid: $css"
        else
            warn "CSS has $INVALID invalid GTK3 features: $css"
        fi
    else
        fail "CSS missing: $css"
    fi
done
echo ""

# --- 6. Source Files ---
echo "[6/8] Data Source Files"
for source in ocws-sysmon.source cpu.source memory.source battery.source; do
    if [[ -f "$OCWS_DIR/$source" ]]; then
        pass "Source exists: $source"
    else
        fail "Source missing: $source"
    fi
done
echo ""

# --- 7. Scripts ---
echo "[7/8] Scripts"
for script in ocws-emit.sh ocws-daemon.sh ocws-plugin-loader.sh theme-engine.sh; do
    if [[ -x "$LOCAL_BIN/$script" ]] || [[ -x "$LOCAL_BIN/actions/$script" ]]; then
        pass "Script installed: $script"
    else
        # Check in project scripts dir
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [[ -x "$SCRIPT_DIR/$script" ]]; then
            pass "Script found: $script (not linked)"
        else
            fail "Script missing: $script"
        fi
    fi
done
echo ""

# --- 8. Running Services ---
echo "[8/8] Running Services"
if pgrep -x sfwbar &>/dev/null; then
    pass "sfwbar is running (PID: $(pgrep -x sfwbar))"
else
    warn "sfwbar is not running"
fi

if pgrep -f "ocws-daemon" &>/dev/null; then
    pass "ocws-daemon is running"
else
    warn "ocws-daemon is not running"
fi

if pgrep -x labwc &>/dev/null; then
    pass "labwc is running"
else
    warn "labwc is not running (expected if not in labwc session)"
fi
echo ""

# --- Summary ---
echo "=== Validation Complete ==="
echo -e "  ${GREEN}PASS: $PASS${NC}"
echo -e "  ${YELLOW}WARN: $WARN${NC}"
echo -e "  ${RED}FAIL: $FAIL${NC}"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
    echo -e "${RED}Some checks failed. Run './install.sh' to fix missing files.${NC}"
    exit 1
elif [[ "$WARN" -gt 0 ]]; then
    echo -e "${YELLOW}Some warnings. OCWS may work but some features could be limited.${NC}"
    exit 0
else
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
fi
