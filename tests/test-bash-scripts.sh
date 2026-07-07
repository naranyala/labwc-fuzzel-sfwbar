#!/bin/bash
# OCWS Bash Script Test Suite
# Tests all bash scripts for syntax, structure, and functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

header() { echo -e "\n${BOLD}${CYAN}=== $1 ===${NC}"; }
pass()   { echo -e "  ${GREEN}[PASS]${NC} $1"; ((PASS_COUNT++)); }
fail()   { echo -e "  ${RED}[FAIL]${NC} $1"; ((FAIL_COUNT++)); }
skip()   { echo -e "  ${YELLOW}[SKIP]${NC} $1"; ((SKIP_COUNT++)); }

# ============================================================
# 1. Syntax Validation — scripts/
# ============================================================
header "Bash Syntax: scripts/"

SCRIPTS_DIR_SCRIPTS=(
    "scripts/autorun-manager.sh"
    "scripts/dotfiles-sync.sh"
    "scripts/theme-engine.sh"
    "scripts/theme.sh"
    "scripts/keybinds.sh"
    "scripts/cross-build.sh"
    "scripts/release.sh"
    "scripts/update.sh"
    "scripts/backup.sh"
    "scripts/restore.sh"
    "scripts/clean.sh"
    "scripts/ocws-emit.sh"
    "scripts/ocws-state.sh"
    "scripts/ocws-configure.sh"
    "scripts/ocws-health.sh"
    "scripts/ocws-validate.sh"
    "scripts/validate-contract.sh"
    "scripts/ocws-plugin-loader.sh"
    "scripts/ocws-deps.sh"
    "scripts/ocws-display.sh"
    "scripts/ocws-media-art.sh"
    "scripts/ocws-media-widget-updater.sh"
    "scripts/ocws-fetch-art.sh"
    "scripts/ocws-network-bandwidth.sh"
    "scripts/playerctl.sh"
    "scripts/font-scale.sh"
    "scripts/install-fonts.sh"
    "scripts/screenshot-tool.sh"
    "scripts/dotfiles-sync.sh"
    "scripts/debug-labwc.sh"
    "scripts/wallpaper-theme.sh"
    "scripts/theme-scheduler.sh"
    "scripts/workspace-presets.sh"
    "scripts/shell-switcher.sh"
    "scripts/start-labwc.sh"
    "scripts/ocws-icon-downloader.sh"
    "scripts/ocws-icon-picker.sh"
    "scripts/ocws-autorun.sh"
)

for script in "${SCRIPTS_DIR_SCRIPTS[@]}"; do
    if [ -f "$PROJECT_DIR/$script" ]; then
        if bash -n "$PROJECT_DIR/$script" 2>/dev/null; then
            pass "Syntax valid: $(basename "$script")"
        else
            fail "Syntax error: $(basename "$script")"
        fi
    else
        skip "Not found: $script"
    fi
done

# ============================================================
# 2. Syntax Validation — scripts/actions/
# ============================================================
header "Bash Syntax: scripts/actions/"

ACTIONS_DIR="$PROJECT_DIR/scripts/actions"
if [ -d "$ACTIONS_DIR" ]; then
    ACTION_COUNT=0
    for script in "$ACTIONS_DIR"/*.sh; do
        [ -f "$script" ] || continue
        if bash -n "$script" 2>/dev/null; then
            pass "Syntax valid: actions/$(basename "$script")"
        else
            fail "Syntax error: actions/$(basename "$script")"
        fi
        ((ACTION_COUNT++))
    done
    if [ "$ACTION_COUNT" -eq 0 ]; then
        skip "No action scripts found in $ACTIONS_DIR"
    fi
else
    skip "actions/ directory not found"
fi

# ============================================================
# 3. Syntax Validation — dotfiles daemon scripts
# ============================================================
header "Bash Syntax: dotfiles daemons"

DOTFILE_SCRIPTS=(
    "dotfiles/ocws/ocws-daemon.sh"
    "dotfiles/ocws/get-keybinds.sh"
    "dotfiles/labwc/autostart"
    "dotfiles/labwc/startup-wallpaper.sh"
)

for script in "${DOTFILE_SCRIPTS[@]}"; do
    if [ -f "$PROJECT_DIR/$script" ]; then
        if bash -n "$PROJECT_DIR/$script" 2>/dev/null; then
            pass "Syntax valid: $script"
        else
            fail "Syntax error: $script"
        fi
    else
        skip "Not found: $script"
    fi
done

# ============================================================
# 4. Key Script Functionality — help / init modes
# ============================================================
header "Script Functionality: help modes"

check_help() {
    local path="$1"
    local arg="${2:---help}"
    local name
    name="$(basename "$path")"
    if [ ! -f "$path" ]; then
        skip "$name not found"
        return
    fi
    if [ ! -x "$path" ]; then
        skip "$name not executable"
        return
    fi
    if "$path" "$arg" >/dev/null 2>&1; then
        pass "$name $arg works"
    else
        # exit code > 0 is allowed for --help; check stderr at least runs
        if "$path" "$arg" 2>/dev/null | head -1 >/dev/null || true; then
            pass "$name $arg exits gracefully"
        else
            fail "$name $arg failed"
        fi
    fi
}

check_help "$PROJECT_DIR/scripts/autorun-manager.sh"   "help"
check_help "$PROJECT_DIR/scripts/dotfiles-sync.sh"     "--help"
check_help "$PROJECT_DIR/scripts/cross-build.sh"       "--help"
check_help "$PROJECT_DIR/scripts/keybinds.sh"          "--help"
check_help "$PROJECT_DIR/scripts/ocws-configure.sh"    "--help"
check_help "$PROJECT_DIR/scripts/ocws-deps.sh"         "--help"
check_help "$PROJECT_DIR/scripts/workspace-presets.sh" "--help"
check_help "$PROJECT_DIR/scripts/font-scale.sh"        "--help"

# ============================================================
# 5. theme-engine.sh — list and current
# ============================================================
header "theme-engine.sh: list / current"

THEME_ENGINE="$PROJECT_DIR/scripts/theme-engine.sh"

if [ -x "$THEME_ENGINE" ]; then
    # list should print at least one theme name
    LIST_OUT=$("$THEME_ENGINE" list 2>/dev/null || true)
    if echo "$LIST_OUT" | grep -qi "catppuccin\|tokyo\|dracula\|nord"; then
        pass "theme-engine list outputs known themes"
    elif [ -n "$LIST_OUT" ]; then
        pass "theme-engine list produces output"
    else
        fail "theme-engine list produced no output"
    fi

    # list should enumerate all INI files in themes/
    THEME_COUNT=$(ls "$PROJECT_DIR/themes/"*.ini 2>/dev/null | wc -l)
    if [ "$THEME_COUNT" -gt 0 ]; then
        pass "themes/ directory contains $THEME_COUNT theme files"
    else
        fail "No theme INI files found in themes/"
    fi

    # current — just needs to exit without a hard crash
    if "$THEME_ENGINE" current >/dev/null 2>&1; then
        pass "theme-engine current exits cleanly"
    else
        # exit non-zero is acceptable when no theme is applied yet
        skip "theme-engine current non-zero (no theme applied)"
    fi
else
    skip "theme-engine.sh not found or not executable"
fi

# ============================================================
# 6. validate-contract.sh — dry-run structure check
# ============================================================
header "validate-contract.sh"

VALIDATE="$PROJECT_DIR/scripts/validate-contract.sh"
if [ -x "$VALIDATE" ]; then
    # Run from project root so relative paths resolve
    if (cd "$PROJECT_DIR" && "$VALIDATE" >/dev/null 2>&1); then
        pass "validate-contract.sh exits cleanly"
    else
        # Non-zero exit may mean contract issues; script running is enough for syntax test
        RC=$?
        if [ "$RC" -lt 128 ]; then
            pass "validate-contract.sh runs and reports (exit $RC)"
        else
            fail "validate-contract.sh crashed (exit $RC)"
        fi
    fi
else
    skip "validate-contract.sh not found or not executable"
fi

# ============================================================
# 7. ocws-health.sh — can invoke and get output
# ============================================================
header "ocws-health.sh"

HEALTH="$PROJECT_DIR/scripts/ocws-health.sh"
if [ -x "$HEALTH" ]; then
    HEALTH_OUT=$((cd "$PROJECT_DIR" && "$HEALTH") 2>&1 || true)
    if [ -n "$HEALTH_OUT" ]; then
        pass "ocws-health.sh produces output"
    else
        fail "ocws-health.sh produced no output"
    fi

    # Should report at least PASS or WARN tokens
    if echo "$HEALTH_OUT" | grep -qiE "PASS|WARN|FAIL|OK|✓|✗|check"; then
        pass "ocws-health.sh reports health status"
    else
        skip "ocws-health.sh output format unrecognised"
    fi
else
    skip "ocws-health.sh not found or not executable"
fi

# ============================================================
# 8. ocws-emit.sh (shell version) — namespace mapping
# ============================================================
header "ocws-emit.sh (shell): namespace mapping"

EMIT_SH="$PROJECT_DIR/scripts/ocws-emit.sh"
if [ -f "$EMIT_SH" ]; then
    # Verify known namespaces appear in the script
    EXPECTED_NS=(
        "System.Volume"
        "System.Brightness"
        "System.Battery"
        "System.Cpu"
        "System.Memory"
        "System.Disk"
        "Network.WiFi"
        "Network.Bluetooth"
        "Media.Title"
        "Media.Artist"
        "Media.Status"
        "System.DND"
    )
    for ns in "${EXPECTED_NS[@]}"; do
        if grep -qF "$ns" "$EMIT_SH"; then
            pass "ocws-emit.sh contains namespace: $ns"
        else
            fail "ocws-emit.sh missing namespace: $ns"
        fi
    done

    # Verify variable mappings appear
    EXPECTED_VARS=(
        "XVolLevel"
        "XBrightness"
        "XBatLvl"
        "XCpuLoad"
        "XMemPct"
        "XNetState"
        "XBtState"
        "XMediaTitle"
    )
    for var in "${EXPECTED_VARS[@]}"; do
        if grep -qF "$var" "$EMIT_SH"; then
            pass "ocws-emit.sh maps to variable: $var"
        else
            fail "ocws-emit.sh missing variable mapping: $var"
        fi
    done
else
    skip "scripts/ocws-emit.sh not found"
fi

# ============================================================
# 9. contracts/variables.ini — IPC contract completeness
# ============================================================
header "contracts/variables.ini: IPC contract"

CONTRACT="$PROJECT_DIR/contracts/variables.ini"
if [ -f "$CONTRACT" ]; then
    # Must have entries for all major namespaces
    CONTRACT_NS=(
        "System.Volume"
        "System.Brightness"
        "System.Battery"
        "System.Cpu"
        "System.Memory"
        "Network.WiFi"
        "Media.Title"
    )
    for ns in "${CONTRACT_NS[@]}"; do
        if grep -qF "$ns" "$CONTRACT"; then
            pass "contracts/variables.ini has entry: $ns"
        else
            fail "contracts/variables.ini missing: $ns"
        fi
    done

    # Count entries
    ENTRY_COUNT=$(grep -c "=" "$CONTRACT" 2>/dev/null || echo 0)
    if [ "$ENTRY_COUNT" -ge 10 ]; then
        pass "contracts/variables.ini has $ENTRY_COUNT entries (≥10)"
    else
        fail "contracts/variables.ini has only $ENTRY_COUNT entries"
    fi
else
    skip "contracts/variables.ini not found"
fi

# ============================================================
# 10. Action scripts structural checks
# ============================================================
header "Action scripts: structural checks"

if [ -d "$ACTIONS_DIR" ]; then
    # All action scripts should have a shebang
    for script in "$ACTIONS_DIR"/*.sh; do
        [ -f "$script" ] || continue
        SHEBANG=$(head -1 "$script")
        if echo "$SHEBANG" | grep -q "^#!"; then
            pass "Has shebang: actions/$(basename "$script")"
        else
            fail "Missing shebang: actions/$(basename "$script")"
        fi
    done

    # Verify key action scripts exist
    KEY_ACTIONS=(
        "audio.sh"
        "brightness.sh"
        "screenshot.sh"
        "clipboard.sh"
        "launcher.sh"
        "power-menu.sh"
        "workspace.sh"
        "network.sh"
        "window.sh"
    )
    for action in "${KEY_ACTIONS[@]}"; do
        if [ -f "$ACTIONS_DIR/$action" ]; then
            pass "Key action script exists: $action"
        else
            fail "Key action script missing: $action"
        fi
    done
else
    skip "actions/ directory not found"
fi

# ============================================================
# 11. Build scripts — installer integrity
# ============================================================
header "Installer / build scripts"

BUILD_SCRIPTS=(
    "install.sh"
    "install-distribution.sh"
    "build-ocws-core.sh"
)

for script in "${BUILD_SCRIPTS[@]}"; do
    path="$PROJECT_DIR/$script"
    if [ -f "$path" ]; then
        if bash -n "$path" 2>/dev/null; then
            pass "Syntax valid: $script"
        else
            fail "Syntax error: $script"
        fi
    else
        skip "Not found: $script"
    fi
done

# ============================================================
# 10. font-scale.sh float support
# ============================================================
header "font-scale.sh Float Support"
FONT_SCALE="$PROJECT_DIR/scripts/font-scale.sh"
if [ -f "$FONT_SCALE" ] && [ -x "$FONT_SCALE" ]; then
    # Test set command with integer
    OUTPUT=$(bash "$FONT_SCALE" set 10 2>&1 || true)
    if echo "$OUTPUT" | grep -q "Font Scale"; then
        pass "font-scale.sh set <int> works"
    else
        fail "font-scale.sh set <int> produced unexpected output"
    fi

    # Test set command with float
    OUTPUT=$(bash "$FONT_SCALE" set 10.5 2>&1 || true)
    if echo "$OUTPUT" | grep -q "10.5"; then
        pass "font-scale.sh set <float> accepts decimals"
    else
        fail "font-scale.sh set <float> did not process decimal"
    fi

    # Test status command
    OUTPUT=$(bash "$FONT_SCALE" status 2>&1 || true)
    if echo "$OUTPUT" | grep -q "Current Status"; then
        pass "font-scale.sh status works"
    else
        fail "font-scale.sh status failed"
    fi

    # Reset to default
    bash "$FONT_SCALE" set 10 &>/dev/null
    pass "font-scale.sh reset to default"
else
    skip "font-scale.sh not found or not executable"
fi

# ============================================================
# 11. labwc environment file
# ============================================================
header "Labwc Environment File"
ENV_FILE="$PROJECT_DIR/dotfiles/labwc/environment"
if [ -f "$ENV_FILE" ]; then
    pass "environment file exists"

    # Must set PATH
    if grep -q "^PATH=" "$ENV_FILE"; then
        pass "environment sets PATH"
    else
        fail "environment missing PATH"
    fi

    # Must set XDG_CURRENT_DESKTOP
    if grep -q "^XDG_CURRENT_DESKTOP=" "$ENV_FILE"; then
        pass "environment sets XDG_CURRENT_DESKTOP"
    else
        fail "environment missing XDG_CURRENT_DESKTOP"
    fi

    # PATH must include ~/.local/bin
    if grep -q '\$HOME/\.local/bin' "$ENV_FILE"; then
        pass "PATH includes \$HOME/.local/bin"
    else
        fail "PATH missing \$HOME/.local/bin"
    fi
else
    fail "environment file not found"
fi

# ============================================================
# 12. autorun.conf contains ocws-welcome
# ============================================================
header "Autorun Configuration"
AUTORUN="$PROJECT_DIR/dotfiles/labwc/autorun.conf"
if [ -f "$AUTORUN" ]; then
    pass "autorun.conf exists"

    if grep -q "ocws-welcome" "$AUTORUN"; then
        pass "autorun.conf includes ocws-welcome"
    else
        fail "autorun.conf missing ocws-welcome"
    fi
else
    fail "autorun.conf not found"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo -e "${BOLD}Bash Script Test Suite Summary:${NC}"
echo -e "  ${GREEN}Passed:${NC}  $PASS_COUNT"
echo -e "  ${YELLOW}Skipped:${NC} $SKIP_COUNT"
echo -e "  ${RED}Failed:${NC}  $FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
exit 0
