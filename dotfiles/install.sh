#!/bin/bash

# labwc + sfwbar + crystal-dock Dotfiles Installation Script
# Complete installation with all scripts and configurations

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GTK3_DIR="${HOME}/.config/gtk-3.0"
GTK4_DIR="${HOME}/.config/gtk-4.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

pass()  { echo -e "  ${GREEN}✓${NC} $1"; }
fail()  { echo -e "  ${RED}✗${NC} $1"; exit 1; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
info()  { echo -e "  ${CYAN}→${NC} $1"; }
section() { echo -e "\n${BOLD}[$1]${NC}"; }

echo ""
echo -e "${BOLD}== labwc Dotfiles Installer ==${NC}"
echo ""

# ============================================================
section "1. Pre-flight Checks"
# ============================================================

# Check labwc
LABWC_BIN="$(command -v labwc 2>/dev/null || true)"
if [[ -z "$LABWC_BIN" ]]; then
  fail "labwc not found. Run: ./download-labwc.sh --install"
fi
pass "labwc: $LABWC_BIN"

# Check sfwbar
if command -v sfwbar &>/dev/null; then
  pass "sfwbar: $(command -v sfwbar)"
else
  warn "sfwbar not found (statusbar will need manual launch)"
fi

# Check crystal-dock
if command -v crystal-dock &>/dev/null; then
  pass "crystal-dock: $(command -v crystal-dock)"
else
  warn "crystal-dock not found (dock will be skipped)"
fi

# ============================================================
section "2. Create Directories"
# ============================================================

DIRS=(
  "$HOME/.config/labwc"
  "$HOME/.config/labwc-widgets"
  "$HOME/.config/sfwbar"
  "$HOME/.local/bin"
  "$HOME/Pictures/screenshots"
)

for dir in "${DIRS[@]}"; do
  mkdir -p "$dir"
  pass "$dir"
done

# ============================================================
section "3. Install labwc Config"
# ============================================================

LABWC_SRC="$PROJECT_DIR/dotfiles/labwc"
LABWC_DST="$HOME/.config/labwc"

# Pre-validate rc.xml — abort if source has broken Client context
if [[ -f "$LABWC_SRC/rc.xml" ]]; then
  CLIENT_CTX=$(sed -n '/<context name="Client">/,/<\/context>/p' "$LABWC_SRC/rc.xml")
  if echo "$CLIENT_CTX" | grep -q 'button="Left" action="Press"'; then
    fail "SOURCE rc.xml has broken Client context (Left Press). Fix dotfiles/labwc/rc.xml first."
  fi
fi

for cfg in rc.xml autostart environment menu.xml themerc-override startup-wallpaper.sh; do
  if [[ -f "$LABWC_SRC/$cfg" ]]; then
    cp "$LABWC_SRC/$cfg" "$LABWC_DST/$cfg"
    pass "$cfg"
  fi
done

chmod +x "$LABWC_DST/autostart" 2>/dev/null || true
chmod +x "$LABWC_DST/startup-wallpaper.sh" 2>/dev/null || true

# ============================================================
section "4. Install Scripts"
# ============================================================

SCRIPTS_DST="$HOME/.local/bin"
mkdir -p "$SCRIPTS_DST/actions"

# Install scripts from dotfiles/ (including subdirectories)
find "$SCRIPT_DIR" -name "*.sh" -type f | while read -r script; do
  name=$(basename "$script")
  [[ "$name" == "install.sh" ]] || continue
  cp "$script" "$SCRIPTS_DST/$name"
  chmod +x "$SCRIPTS_DST/$name"
  pass "$name"
done

# Install main tool scripts from scripts/
SCRIPTS_SRC="$PROJECT_DIR/scripts"
find "$SCRIPTS_SRC" -name "*.sh" -type f | while read -r script; do
  if [[ -f "$script" ]]; then
    name=$(basename "$script")
    cp "$script" "$SCRIPTS_DST/$name"
    chmod +x "$SCRIPTS_DST/$name"
    pass "$name"
  fi
done

# Install action scripts
if [[ -d "$SCRIPTS_SRC/actions" ]]; then
  for script in "$SCRIPTS_SRC/actions"/*.sh; do
    if [[ -f "$script" ]]; then
      name=$(basename "$script")
      cp "$script" "$SCRIPTS_DST/actions/$name"
      chmod +x "$SCRIPTS_DST/actions/$name"
      pass "actions/$name"
    fi
  done
fi

# ============================================================
section "5. Install SFWBar Configuration"
# ============================================================

SFWBAR_SRC="$PROJECT_DIR/dotfiles/sfwbar"
SFWBAR_DST="$HOME/.config/sfwbar"

# Install sfwbar config and widget files
mkdir -p "$SFWBAR_DST"
if [[ -d "$SFWBAR_SRC" ]]; then
  for cfg in sfwbar.config catppuccin-mocha.css *.widget *.source; do
    for f in "$SFWBAR_SRC/$cfg"; do
      if [[ -f "$f" ]]; then
        cp "$f" "$SFWBAR_DST/"
        pass "$(basename "$f")"
      fi
    done
  done
fi

# Copy widget files from installed sfwbar if not already present
if [[ -d "$HOME/.local/share/sfwbar" ]]; then
  for f in "$HOME/.local/share/sfwbar"/*.widget "$HOME/.local/share/sfwbar"/*.source; do
    if [[ -f "$f" ]]; then
      name=$(basename "$f")
      if [[ ! -f "$SFWBAR_DST/$name" ]]; then
        cp "$f" "$SFWBAR_DST/$name"
        pass "$name"
      fi
    fi
  done
fi

# ============================================================
section "6. Install GTK Theme Config"
# ============================================================

GTK_SRC="$PROJECT_DIR/dotfiles/gtk"

mkdir -p "$GTK3_DIR" "$GTK4_DIR"

# GTK3 settings
if [[ -f "$GTK_SRC/gtk3-settings.ini" ]]; then
  cp "$GTK_SRC/gtk3-settings.ini" "$GTK3_DIR/settings.ini"
  pass "GTK3 settings.ini"
fi

# GTK4 settings
if [[ -f "$GTK_SRC/gtk4-settings.ini" ]]; then
  cp "$GTK_SRC/gtk4-settings.ini" "$GTK4_DIR/settings.ini"
  pass "GTK4 settings.ini"
fi

# GTK CSS overrides
if [[ -f "$GTK_SRC/gtk.css" ]]; then
  cp "$GTK_SRC/gtk.css" "$GTK3_DIR/gtk.css"
  cp "$GTK_SRC/gtk.css" "$GTK4_DIR/gtk.css"
  pass "gtk.css (GTK3 + GTK4)"
fi

# ============================================================
section "7. Install Wallpaper"
# ============================================================

WALLPAPER_SRC="$PROJECT_DIR/dotfiles/wallpaper"
WALLPAPER_DST="$HOME/.local/bin/wallpaper"

if [[ -f "$WALLPAPER_SRC" ]]; then
  cp "$WALLPAPER_SRC" "$WALLPAPER_DST"
  chmod +x "$WALLPAPER_DST"
  pass "wallpaper script"
fi

cp "$PROJECT_DIR/dotfiles/wallpaper-sources.txt" "$HOME/.local/bin/wallpaper-sources.txt" 2>/dev/null || true

# ============================================================
section "8. Create Session File"
# ============================================================

SESSION_DIR="/usr/share/wayland-sessions"
SESSION_FILE="$SESSION_DIR/labwc.desktop"

if [[ -d "$SESSION_DIR" ]]; then
  cat > /tmp/labwc.desktop << EOF
[Desktop Entry]
Name=labwc
Comment=Lab Wayland Compositor
Exec=labwc
TryExec=labwc
Type=Application
DesktopNames=labwc;
Keywords=wayland;compositor;labwc;
X-GDM-SessionRegisters=true
X-GDM-CanRunHeadless=true
EOF
  sudo cp /tmp/labwc.desktop "$SESSION_FILE" 2>/dev/null && \
    sudo chmod 644 "$SESSION_FILE" && \
    pass "labwc.desktop" || warn "Could not create session file (need sudo)"
  rm -f /tmp/labwc.desktop
else
  warn "Session directory not found"
fi

# ============================================================
section "9. Update PATH"
# ============================================================

PROFILE=""
for f in "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc"; do
  if [[ -f "$f" ]]; then
    PROFILE="$f"
    break
  fi
done

if [[ -n "$PROFILE" ]]; then
  if ! grep -q '\.local/bin' "$PROFILE" 2>/dev/null; then
    echo '' >> "$PROFILE"
    echo '# labwc - add local bin to PATH' >> "$PROFILE"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$PROFILE"
    pass "PATH updated in $PROFILE"
  else
    pass "PATH already configured"
  fi
fi

# ============================================================
section "10. Validate"
# ============================================================

ERRORS=0

# Check autostart
if [[ -f "$LABWC_DST/autostart" ]]; then
  grep -q "crystal-dock" "$LABWC_DST/autostart" && pass "autostart: crystal-dock" || warn "autostart: missing crystal-dock"
  grep -q "sfwbar" "$LABWC_DST/autostart" && pass "autostart: sfwbar" || warn "autostart: missing sfwbar"
  grep -q "gammastep\|redshift" "$LABWC_DST/autostart" && pass "autostart: screen protection" || warn "autostart: no screen protection"
fi

# Check scripts
for script in validate.sh fix.sh clean.sh dotfiles-sync.sh keybind-presets.sh themes.sh widget-actions.sh quick.sh setup.sh update.sh status.sh backup.sh diagnostics.sh start-labwc.sh widget-manager.sh keybinds.sh relaunch-status-bars.sh reset.sh; do
  if [[ -f "$SCRIPTS_DST/$script" ]]; then
    pass "script: $script"
  else
    warn "missing script: $script"
    ((ERRORS++))
  fi
done

# Check actions
for script in audio.sh brightness.sh clipboard.sh launcher.sh network.sh power-menu.sh quick-settings.sh screenshot.sh window.sh workspace.sh; do
  if [[ -f "$SCRIPTS_DST/actions/$script" ]]; then
    pass "actions/$script"
  else
    warn "missing action: $script"
    ((ERRORS++))
  fi
done

# Check sfwbar config
if [[ -f "$HOME/.config/sfwbar/sfwbar.config" ]]; then
  pass "sfwbar config: installed"
else
  warn "sfwbar config: missing"
  ((ERRORS++))
fi

# Check GTK config
if [[ -f "$GTK3_DIR/settings.ini" ]]; then
  pass "GTK3 settings: installed"
else
  warn "GTK3 settings: missing"
  ((ERRORS++))
fi
if [[ -f "$GTK4_DIR/settings.ini" ]]; then
  pass "GTK4 settings: installed"
else
  warn "GTK4 settings: missing"
  ((ERRORS++))
fi
if [[ -f "$GTK3_DIR/gtk.css" ]]; then
  pass "GTK3 CSS: installed"
else
  warn "GTK3 CSS: missing"
  ((ERRORS++))
fi
if [[ -f "$GTK4_DIR/gtk.css" ]]; then
  pass "GTK4 CSS: installed"
else
  warn "GTK4 CSS: missing"
  ((ERRORS++))
fi

# ============================================================
section "11. Summary"
# ============================================================

echo ""
echo -e "${GREEN}${BOLD}Installation Complete!${NC}"
echo ""
echo "Components installed:"
echo "  • labwc config    → ~/.config/labwc/"
echo "  • SFWBar config   → ~/.config/sfwbar/"
echo "  • GTK3 config     → ~/.config/gtk-3.0/"
echo "  • GTK4 config     → ~/.config/gtk-4.0/"
echo "  • Scripts         → ~/.local/bin/"
echo "  • Actions         → ~/.local/bin/actions/"
echo "  • Wallpaper       → ~/.local/bin/wallpaper"
echo ""
echo "Available commands:"
echo "  relaunch-status-bars.sh    Restart sfwbar + crystal-dock"
echo "  reset.sh                   Full reset with defaults (non-interactive)"
echo "  quick.sh                   Hub for all operations"
echo "  setup.sh                   Full install chain"
echo "  validate.sh                Check setup"
echo "  fix.sh                     Auto-fix issues"
echo ""
echo "Launch from TTY:"
echo "  $PROJECT_DIR/scripts/start-labwc.sh"
echo ""
