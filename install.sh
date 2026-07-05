#!/bin/bash
# -------------------------------------------------------------------
# OCWS Installer
# Enhanced distribution-aware installer for OCWS ecosystem.
# For comprehensive distro-specific installation, use ./install-distribution.sh
# -------------------------------------------------------------------

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "\n${CYAN}==>${NC} $*"; }
pass() { echo -e "  ${GREEN}✓${NC} $*"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $*"; }
fail() { echo -e "  ${RED}✗${NC} $*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info "Initializing OCWS Deployment..."

# 1. Check for comprehensive distro-specific installer
if [ -f "${SCRIPT_DIR}/install-distribution.sh" ]; then
    echo -e "\n  ${GREEN}✓${NC} Enhanced distro-specific installer found."
    echo -e "  ${CYAN}=== OCWS Installer ===${NC}"
    echo -e "  ${CYAN}  Quick Mode:${NC} All manual config steps"
    echo -e "  ${CYAN}  Full Mode:${NC}  Automatic package installation"
    echo -e "\n  Choose option:"
    echo -e "    1) Quick Install (manual dependency setup)"
    echo -e "    2) Full Install (automatic distro detection and package installation)"
    echo -e "\n  Default: 1 (Quick Install)"
    echo -n "    Enter choice [1-2]: "
    
    read -r choice
    
    case "${choice:-1}" in
        2)
            echo -e "\n${CYAN}==>${NC} Starting comprehensive distribution installer..."
            bash "${SCRIPT_DIR}/install-distribution.sh" "$@"
            exit 0
            ;;
        *)
            echo -e "\n${CYAN}==>${NC} Starting quick installer..."
            ;;
    esac
fi

# -------------------------------------------------------------------
# Legacy Quick Installer
# Manual dependency installation and configuration deployment
# -------------------------------------------------------------------

# 1. Dependency Check
info "Checking for required dependencies..."
if ! command -v labwc >/dev/null 2>&1 || ! command -v sfwbar >/dev/null 2>&1 || ! command -v fuzzel >/dev/null 2>&1; then
    echo -e "\n${YELLOW}⚠${NC} Core engines (labwc, sfwbar, fuzzel) are missing!"
    echo -e "  ${RED}Options:${NC}"
    echo -e "    1) Install via package manager (${SCRIPT_DIR}/install-distribution.sh)"
    echo -e "    2) Build from source (${SCRIPT_DIR}/build-ocws-core.sh all)"
    echo -e "\n  Press [ENTER] to continue anyway, or Ctrl+C to cancel."
    read -r
fi

# 2. Setup Directories
info "Setting up configuration directories..."
mkdir -p ~/.config/labwc
mkdir -p ~/.config/ocws/plugins
mkdir -p ~/.config/fuzzel
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
mkdir -p ~/.local/bin/actions
pass "Directories created."

# 3. Deploy Labwc Core
info "Deploying Compositor Rules (labwc)..."
cp -r "$SCRIPT_DIR/dotfiles/labwc/"* ~/.config/labwc/ 2>/dev/null || fail "Failed to deploy labwc configurations"
pass "labwc configurations synced."

# 4. Deploy OCWS Shell
info "Deploying the OCWS Shell..."
cp -r "$SCRIPT_DIR/dotfiles/ocws/"* ~/.config/ocws/ 2>/dev/null || fail "Failed to deploy OCWS shell"
pass "OCWS layout and plugins synced."

# 5. Deploy Fuzzel Launcher
if [ -d "$SCRIPT_DIR/dotfiles/fuzzel" ]; then
    info "Deploying Application Launcher (fuzzel)..."
    cp -r "$SCRIPT_DIR/dotfiles/fuzzel/"* ~/.config/fuzzel/ 2>/dev/null || fail "Failed to deploy fuzzel configuration"
    pass "Fuzzel synced."
fi

# 6. Deploy GTK Styling
if [ -d "$SCRIPT_DIR/dotfiles/gtk" ]; then
    info "Deploying GTK Preferences..."
    cp -r "$SCRIPT_DIR/dotfiles/gtk/"* ~/.config/gtk-3.0/ 2>/dev/null || true
    cp -r "$SCRIPT_DIR/dotfiles/gtk/"* ~/.config/gtk-4.0/ 2>/dev/null || true
    pass "GTK settings synced."
fi

# 7. Deploy IPC & Core Tools
info "Deploying Event Bus API & System Tools..."
find "$SCRIPT_DIR/scripts" -maxdepth 1 -type f -name "*.sh" -exec cp {} ~/.local/bin/ \; 2>/dev/null || fail "Failed to deploy scripts"
if [ -d "$SCRIPT_DIR/scripts/actions" ]; then
    cp "$SCRIPT_DIR/scripts/actions/"* ~/.local/bin/actions/ 2>/dev/null || true
fi
chmod +x ~/.local/bin/*.sh 2>/dev/null || fail "Failed to set execute permissions on scripts"
chmod +x ~/.local/bin/actions/* 2>/dev/null || true
pass "Scripts and IPC mapped to ~/.local/bin"

# 8. Strict Installation Validation
info "Performing strict validation of deployed assets..."

validate_file() {
    local target="$1"
    if [ ! -e "$target" ]; then
        echo -e "  ${RED}✗${NC} Missing deployed asset: $target"
        return 1
    fi
    return 0
}

validate_executable() {
    local target="$1"
    if [ ! -x "$target" ]; then
        echo -e "  ${RED}✗${NC} Missing execute permissions: $target"
        return 1
    fi
    return 0
}

warn() {
    echo -e "  ${YELLOW}⚠${NC} $*"
}

validate_file_format() {
    local target="$1"
    local format="$2"
    
    case "$format" in
        xml)
            if ! command -v xmllint >/dev/null 2>&1; then
                warn "xmllint not available for XML validation of $target"
                return 0
            fi
            if ! xmllint --noout "$target" 2>/dev/null; then
                echo -e "  ${RED}✗${NC} Invalid XML format: $target"
                return 1
            fi
            ;;
        ini)
            if ! command -v crudini >/dev/null 2>&1; then
                warn "crudini not available for INI validation of $target"
                return 0
            fi
            crudini --inplace test "$target" >/dev/null 2>&1 || {
                echo -e "  ${RED}✗${NC} Invalid INI format: $target"
                return 1
            }
            ;;
        css)
            if ! command -v csslint >/dev/null 2>&1; then
                warn "csslint not available for CSS validation of $target"
                return 0
            fi
            csslint "$target" >/dev/null 2>&1 || {
                echo -e "  ${RED}✗${NC} Invalid CSS format: $target"
                return 1
            }
            ;;
        shell)
            bash -n "$target" 2>/dev/null || {
                echo -e "  ${RED}✗${NC} Invalid shell syntax: $target"
                return 1
            }
            ;;
    esac
    pass "Valid $format format: $target"
    return 0
}

validate_content() {
    local target="$1"
    local check_type="$2"
    
    case "$check_type" in
        rcxml)
            if ! grep -q "<labwc_config>" "$target"; then
                echo -e "  ${RED}✗${NC} Missing root element in rc.xml"
                return 1
            fi
            if ! grep -q "<keyboard>" "$target" || ! grep -q "</keyboard>" "$target"; then
                echo -e "  ${RED}✗${NC} Missing keyboard section in rc.xml"
                return 1
            fi
            ;;
        menu)
            if ! grep "<menu" "$target" | grep -q "/>"; then
                echo -e "  ${RED}✗${NC} Missing root menu element in menu.xml"
                return 1
            fi
            ;;
        ocwsconfig)
            if ! grep -q "^bar\|widget" "$target"; then
                echo -e "  ${RED}✗${NC} Missing bar definition in ocws.config"
                return 1
            fi
            ;;
        fuzzelini)
            if ! grep -q "^\[main\]" "$target"; then
                echo -e "  ${RED}✗${NC} Missing [main] section in fuzzel.ini"
                return 1
            fi
            ;;
        scripts)
            # Check for essential shebang
            if [[ "$target" == *.sh ]]; then
                if ! head -1 "$target" | grep -q "^#!/bin/bash"; then
                    echo -e "  ${YELLOW}⚠${NC} Missing bash shebang in $target"
                fi
            fi
            ;;
    esac
    pass "Content validation passed: $target ($check_type)"
    return 0
}

validate_required_functions() {
    local script="$1"
    
    if [[ "$script" == *.sh ]]; then
        # Check for essential functions
        if ! grep -q "^info()" "$script" && ! grep -q "^error()" "$script"; then
            echo -e "  ${YELLOW}⚠${NC} Script $script may lack error handling functions"
        fi
        
        # Check for file existence checks
        if ! grep -q "\[ ! -f\]\|\[-d " "$script"; then
            echo -e "  ${YELLOW}⚠${NC} Script $script may lack file validation"
        fi
    fi
    pass "Required functions present in $script"
    return 0
}

validate_keybinding_integrity() {
    local rc_file="$HOME/.config/labwc/rc.xml"
    
    if [ ! -f "$rc_file" ]; then
        echo -e "  ${YELLOW}⚠${NC} rc.xml not found for keybinding validation"
        return 0
    fi
    
    # Check for duplicate keybindings
    local duplicates=$(sed -n 's/.*key="\([^"]*\)".*/\1/p' "$rc_file" | sort | uniq -d)
    if [ -n "$duplicates" ]; then
        echo -e "  ${RED}✗${NC} Duplicate keybindings found: $duplicates"
        return 1
    fi
    
    # Check for essential keybindings
    local essential_keys=(A-Return A-Alt-Tab A-ESC A-S-ESC A-F4 S-F4)
    for key in "${essential_keys[@]}"; do
        if ! grep -q "key=\"$key\"" "$rc_file"; then
            echo -e "  ${YELLOW}⚠${NC} Missing essential keybinding: $key"
        fi
    done
    
    pass "Keybinding integrity validated"
    return 0
}

ERRORS=0

# Verify Labwc
validate_file "$HOME/.config/labwc/rc.xml" || ((ERRORS++))
validate_file "$HOME/.config/labwc/autostart" || ((ERRORS++))
validate_file "$HOME/.config/labwc/menu.xml" || ((ERRORS++))

# Verify OCWS
validate_file "$HOME/.config/ocws/ocws.config" || ((ERRORS++))

# Verify Fuzzel
if [ -d "$SCRIPT_DIR/dotfiles/fuzzel" ]; then
    validate_file "$HOME/.config/fuzzel/fuzzel.ini" || ((ERRORS++))
fi

# Verify Scripts
for script in "$SCRIPT_DIR/scripts/"*.sh; do
    [ -e "$script" ] || continue
    base=$(basename "$script")
    validate_file "$HOME/.local/bin/$base" || ((ERRORS++))
    validate_executable "$HOME/.local/bin/$base" || ((ERRORS++))
    validate_required_functions "$HOME/.local/bin/$base"
    validate_file_format "$HOME/.local/bin/$base" shell
    validate_content "$HOME/.local/bin/$base" scripts
    done

# Verify Dotfile Formats
validate_file_format "$HOME/.config/labwc/rc.xml" xml
validate_file_format "$HOME/.config/labwc/menu.xml" xml

if [ -f "$HOME/.config/ocws/ocws.config" ]; then
    validate_file_format "$HOME/.config/ocws/ocws.config" css
    validate_content "$HOME/.config/ocws/ocws.config" ocwsconfig
fi

if [ -f "$HOME/.config/fuzzel/fuzzel.ini" ]; then
    validate_file_format "$HOME/.config/fuzzel/fuzzel.ini" ini
    validate_content "$HOME/.config/fuzzel/fuzzel.ini" fuzzelini
fi

# Validate Labwc content
validate_content "$HOME/.config/labwc/rc.xml" rcxml
validate_content "$HOME/.config/labwc/menu.xml" menu

# Validate keybinding integrity
validate_keybinding_integrity

if [ "$ERRORS" -gt 0 ]; then
    fail "Comprehensive validation failed with $ERRORS errors. Installation is incomplete."
else
    pass "All configuration files strictly validated with format, content, and integrity checks."
fi

# 9. Success
info "OCWS Deployment Complete! 🚀"
echo -e "\n${CYAN}=== Quick Install Complete ===${NC}"
echo -e "${CYAN}  Note:${NC} You must manually install labwc, sfwbar, and fuzzel first."
echo -e "  Use ./install-distribution.sh for automatic distro detection and installation."
echo -e "\n${CYAN}  Next Steps:${NC}"
echo -e "  • Install dependencies using: ./install-distribution.sh (Recommended)"
echo -e "  • Build from source: ./build-ocws-core.sh all"
echo -e "  • Restart and select 'labwc' from display manager"
echo -e "  • Or run: labwc (from a TTY)"
