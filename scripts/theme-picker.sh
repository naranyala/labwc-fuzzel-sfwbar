#!/bin/bash
#
# theme-picker.sh — Interactive visual theme picker for labwc + GTK
#
# Pick and preview predefined themes with color swatches.
# Applies complete desktop theme (labwc + GTK3 + GTK4 + icons + cursors).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILES_DIR="$PROJECT_DIR/dotfiles/gtk/theme-profiles"
CONFIG_DIR="${HOME}/.config/labwc"
GTK3_DIR="${HOME}/.config/gtk-3.0"
GTK4_DIR="${HOME}/.config/gtk-4.0"
CURRENT_THEME_FILE="${HOME}/.config/labwc/current-theme"
BACKUP_DIR="${HOME}/.config/labwc-backups"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

# Color blocks for previews
BLOCK_BG='\033[48;5;'  # Background color escape
BLOCK_FG='\033[38;5;'  # Foreground color escape

pass()  { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
info()  { echo -e "  ${CYAN}→${NC} $1"; }
fail()  { echo -e "  ${RED}✗${NC} $1"; exit 1; }

# ============================================================
# Theme Definitions (name -> colors + metadata)
# ============================================================

declare -A THEME_NAMES
declare -A THEME_DESCS
declare -A THEME_BASE      # base/background
declare -A THEME_SURFACE   # surface/card
declare -A THEME_ACCENT    # accent/highlight
declare -A THEME_TEXT      # text color
declare -A THEME_GTK       # GTK theme name
declare -A THEME_ICONS     # Icon theme
declare -A THEME_CURSOR    # Cursor theme
declare -A THEME_FONTS     # Interface font
declare -A THEME_MONO      # Monospace font

# --- Catppuccin Mocha ---
THEME_NAMES[catppuccin-mocha]="Catppuccin Mocha"
THEME_DESCS[catppuccin-mocha]="Warm dark with pastel colors — cozy & modern"
THEME_BASE[catppuccin-mocha]="236,233,46"
THEME_SURFACE[catppuccin-mocha]="49,50,68"
THEME_ACCENT[catppuccin-mocha]="137,180,250"
THEME_TEXT[catppuccin-mocha]="205,214,244"
THEME_GTK[catppuccin-mocha]="Catppuccin-Mocha-Mauve"
THEME_ICONS[catppuccin-mocha]="Papirus-Dark"
THEME_CURSOR[catppuccin-mocha]="Catppuccin-Mocha-Dark"
THEME_FONTS[catppuccin-mocha]="Noto Sans, 10"
THEME_MONO[catppuccin-mocha]="JetBrains Mono, 10"

# --- Nord ---
THEME_NAMES[nord]="Nord"
THEME_DESCS[nord]="Arctic blue — clean, elegant, eye-friendly"
THEME_BASE[nord]="46,52,64"
THEME_SURFACE[nord]="59,66,82"
THEME_ACCENT[nord]="136,192,208"
THEME_TEXT[nord]="216,222,233"
THEME_GTK[nord]="Nordic"
THEME_ICONS[nord]="Zafiro-Nord-Dark"
THEME_CURSOR[nord]="Nordzy-cursors"
THEME_FONTS[nord]="Cantarell, 11"
THEME_MONO[nord]="Fira Code, 10"

# --- Dracula ---
THEME_NAMES[dracula]="Dracula"
THEME_DESCS[dracula]="Dark with purple accents — stylish & popular"
THEME_BASE[dracula]="40,42,54"
THEME_SURFACE[dracula]="68,71,90"
THEME_ACCENT[dracula]="189,147,249"
THEME_TEXT[dracula]="248,248,242"
THEME_GTK[dracula]="Dracula"
THEME_ICONS[dracula]="Dracula"
THEME_CURSOR[dracula]="Dracula-cursors"
THEME_FONTS[dracula]="Cantarell, 11"
THEME_MONO[dracula]="Fira Code, 10"

# --- Tokyo Night ---
THEME_NAMES[tokyo-night]="Tokyo Night"
THEME_DESCS[tokyo-night]="Neon blue/purple — sleek & futuristic"
THEME_BASE[tokyo-night]="26,27,38"
THEME_SURFACE[tokyo-night]="36,40,59"
THEME_ACCENT[tokyo-night]="122,162,247"
THEME_TEXT[tokyo-night]="192,202,245"
THEME_GTK[tokyo-night]="Tokyonight-Dark-BL"
THEME_ICONS[tokyo-night]="Tela-nordic-dark"
THEME_CURSOR[tokyo-night]="Bibata-Modern-Ice"
THEME_FONTS[tokyo-night]="Noto Sans, 10"
THEME_MONO[tokyo-night]="JetBrains Mono, 10"

# --- Arc Dark ---
THEME_NAMES[arc-dark]="Arc Dark"
THEME_DESCS[arc-dark]="Material design dark — professional & polished"
THEME_BASE[arc-dark]="38,46,56"
THEME_SURFACE[arc-dark]="48,58,69"
THEME_ACCENT[arc-dark]="52,152,219"
THEME_TEXT[arc-dark]="220,224,232"
THEME_GTK[arc-dark]="Arc-Dark"
THEME_ICONS[arc-dark]="Papirus-Dark"
THEME_CURSOR[arc-dark]="Bibata-Modern-Ice"
THEME_FONTS[arc-dark]="Cantarell, 11"
THEME_MONO[arc-dark]="Noto Sans Mono, 10"

# --- Breeze Dark ---
THEME_NAMES[breeze-dark]="Breeze Dark"
THEME_DESCS[breeze-dark]="KDE-style dark — balanced & functional"
THEME_BASE[breeze-dark]="35,38,45"
THEME_SURFACE[breeze-dark]="49,54,64"
THEME_ACCENT[breeze-dark]="61,174,233"
THEME_TEXT[breeze-dark]="230,235,242"
THEME_GTK[breeze-dark]="Breeze-Dark"
THEME_ICONS[breeze-dark]="Breeze"
THEME_CURSOR[breeze-dark]="Breeze"
THEME_FONTS[breeze-dark]="Noto Sans, 10"
THEME_MONO[breeze-dark]="Noto Sans Mono, 10"

# --- Everforest ---
THEME_NAMES[everforest]="Everforest"
THEME_DESCS[everforest]="Green earthy tones — natural & calming"
THEME_BASE[everforest]="47,53,48"
THEME_SURFACE[everforest]="63,72,65"
THEME_ACCENT[everforest]="163,190,140"
THEME_TEXT[everforest]="211,220,210"
THEME_GTK[everforest]="Everforest-Dark"
THEME_ICONS[everforest]="Papirus-Dark"
THEME_CURSOR[everforest]="Catppuccin-Mocha-Dark"
THEME_FONTS[everforest]="Noto Sans, 10"
THEME_MONO[everforest]="JetBrains Mono, 10"

# --- Gruvbox Dark ---
THEME_NAMES[gruvbox]="Gruvbox Dark"
THEME_DESCS[gruvbox]="Retro warm — high contrast & nostalgic"
THEME_BASE[gruvbox]="40,40,40"
THEME_SURFACE[gruvbox]="80,60,50"
THEME_ACCENT[gruvbox]="184,187,106"
THEME_TEXT[gruvbox]="235,219,178"
THEME_GTK[gruvbox]="Gruvbox-Dark"
THEME_ICONS[gruvbox]="Papirus-Dark"
THEME_CURSOR[gruvbox]="Bibata-Modern-Ice"
THEME_FONTS[gruvbox]="Noto Sans, 10"
THEME_MONO[gruvbox]="JetBrains Mono, 10"

# --- Rose Pine ---
THEME_NAMES[rose-pine]="Rose Pine"
THEME_DESCS[rose-pine]="Muted rose & pine — elegant & poetic"
THEME_BASE[rose-pine]="25,23,36"
THEME_SURFACE[rose-pine]="38,35,53"
THEME_ACCENT[rose-pine]="235,188,186"
THEME_TEXT[rose-pine]="224,222,244"
THEME_GTK[rose-pine]="rose-pine-gtk"
THEME_ICONS[rose-pine]="Papirus-Dark"
THEME_CURSOR[rose-pine]="Catppuccin-Mocha-Dark"
THEME_FONTS[rose-pine]="Noto Sans, 10"
THEME_MONO[rose-pine]="JetBrains Mono, 10"

# --- Light (Solarized Light) ---
THEME_NAMES[solarized-light]="Solarized Light"
THEME_DESCS[solarized-light]="Classic light — readable & easy on eyes"
THEME_BASE[solarized-light]="253,246,227"
THEME_SURFACE[solarized-light]="238,232,213"
THEME_ACCENT[solarized-light]="38,139,210"
THEME_TEXT[solarized-light]="0,43,54"
THEME_GTK[solarized-light]="NumixSolarizedLightBlue"
THEME_ICONS[solarized-light]="Papirus-Light"
THEME_CURSOR[solarized-light]="Adwaita"
THEME_FONTS[solarized-light]="Cantarell, 11"
THEME_MONO[solarized-light]="Noto Sans Mono, 10"

# ============================================================
# Color Helpers
# ============================================================

rgb_to_ansi256() {
  local r="$1" g="$2" b="$3"
  # Approximate RGB to 256-color
  local ri=$((r * 5 / 255))
  local gi=$((g * 5 / 255))
  local bi=$((b * 5 / 255))
  echo $((16 + 36 * ri + 6 * gi + bi))
}

color_block() {
  local r="$1" g="$2" b="$3"
  local code
  code=$(rgb_to_ansi256 "$r" "$g" "$b")
  echo -ne "\033[48;5;${code}m    \033[0m"
}

color_text() {
  local r="$1" g="$2" b="$3" text="$4"
  local code
  code=$(rgb_to_ansi256 "$r" "$g" "$b")
  echo -ne "\033[38;5;${code}m${text}\033[0m"
}

# ============================================================
# Display Functions
# ============================================================

show_header() {
  clear
  echo -e "${BOLD}╔════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}║           🎨  Theme Picker  🎨                    ║${NC}"
  echo -e "${BOLD}╚════════════════════════════════════════════════════╝${NC}"
  echo
}

show_current_theme() {
  local current=""
  [[ -f "$CURRENT_THEME_FILE" ]] && current=$(cat "$CURRENT_THEME_FILE")
  [[ -n "$current" ]] && echo -e "  ${DIM}Current theme: ${CYAN}${current}${NC}" || echo -e "  ${DIM}No theme applied yet${NC}"
  echo
}

show_theme_card() {
  local name="$1"
  local idx="$2"
  local display_name="${THEME_NAMES[$name]}"
  local desc="${THEME_DESCS[$name]}"
  local base="${THEME_BASE[$name]}"
  local surface="${THEME_SURFACE[$name]}"
  local accent="${THEME_ACCENT[$name]}"
  local text="${THEME_TEXT[$name]}"

  IFS=',' read -r br bg bb <<< "$base"
  IFS=',' read -r sr sg sb <<< "$surface"
  IFS=',' read -r ar ag ab <<< "$accent"
  IFS=',' read -r tr tg tb <<< "$text"

  echo -e "  ${BOLD}${idx})${NC} ${display_name}"
  echo -e "     ${DIM}${desc}${NC}"
  echo -n "     "
  color_block "$br" "$bg" "$bb"
  color_block "$sr" "$sg" "$sb"
  color_block "$ar" "$ag" "$ab"
  echo -ne "  "
  color_text "$ar" "$ag" "$ab" "████"
  echo -ne "  "
  color_text "$tr" "$tg" "$tb" "text"
  echo
}

show_theme_detail() {
  local name="$1"
  echo
  echo -e "  ${BOLD}═══ ${THEME_NAMES[$name]} ═══${NC}"
  echo
  echo -e "  Color palette:"
  echo -n "    Base:    "
  local base="${THEME_BASE[$name]}"
  IFS=',' read -r r g b <<< "$base"
  color_block "$r" "$g" "$b"
  echo -ne "  rgb($r,$g,$b)"
  echo
  echo -n "    Surface: "
  local surface="${THEME_SURFACE[$name]}"
  IFS=',' read -r r g b <<< "$surface"
  color_block "$r" "$g" "$b"
  echo -ne "  rgb($r,$g,$b)"
  echo
  echo -n "    Accent:  "
  local accent="${THEME_ACCENT[$name]}"
  IFS=',' read -r r g b <<< "$accent"
  color_block "$r" "$g" "$b"
  echo -ne "  rgb($r,$g,$b)"
  echo
  echo -n "    Text:    "
  local text="${THEME_TEXT[$name]}"
  IFS=',' read -r r g b <<< "$text"
  color_block "$r" "$g" "$b"
  echo -ne "  rgb($r,$g,$b)"
  echo
  echo
  echo -e "  Components:"
  echo -e "    GTK Theme:   ${CYAN}${THEME_GTK[$name]}${NC}"
  echo -e "    Icons:       ${CYAN}${THEME_ICONS[$name]}${NC}"
  echo -e "    Cursor:      ${CYAN}${THEME_CURSOR[$name]}${NC}"
  echo -e "    Font:        ${CYAN}${THEME_FONTS[$name]}${NC}"
  echo -e "    Mono Font:   ${CYAN}${THEME_MONO[$name]}${NC}"
  echo
}

# ============================================================
# Apply Theme
# ============================================================

backup_current() {
  local ts=$(date +%Y%m%d-%H%M%S)
  mkdir -p "$BACKUP_DIR"
  tar -czf "$BACKUP_DIR/pre-theme-${ts}.tar.gz" \
    -C "$HOME/.config" \
    labwc/themerc-override \
    labwc/environment \
    gtk-3.0/settings.ini \
    gtk-4.0/settings.ini \
    2>/dev/null || true
}

apply_theme() {
  local name="$1"
  local backup="${2:-true}"

  [[ "$backup" == "true" ]] && backup_current

  # 1. labwc themerc-override
  local base="${THEME_BASE[$name]}"
  local surface="${THEME_SURFACE[$name]}"
  local accent="${THEME_ACCENT[$name]}"
  local text="${THEME_TEXT[$name]}"
  IFS=',' read -r br bg bb <<< "$base"
  IFS=',' read -r sr sg sb <<< "$surface"
  IFS=',' read -r ar ag ab <<< "$accent"
  IFS=',' read -r tr tg tb <<< "$text"

  cat > "$CONFIG_DIR/themerc-override" << EOF
# Theme: ${THEME_NAMES[$name]}
# Applied by theme-picker.sh

activetextfont=sans 10
activebg=$(printf '#%02x%02x%02x' $sr $sg $sb)
activetext=$(printf '#%02x%02x%02x' $tr $tg $tb)

inactivetextfont=sans 10
inactivebg=$(printf '#%02x%02x%02x' $br $bg $bb)
inactivetext=$(printf '#%02x%02x%02x' $((sr/2)) $((sg/2)) $((sb/2)))

border.width=1
border.color=$(printf '#%02x%02x%02x' $sr $sg $sb)
titlebar.height=28
EOF

  # 2. GTK3 settings
  mkdir -p "$GTK3_DIR"
  cat > "$GTK3_DIR/settings.ini" << EOF
[Settings]
gtk-theme-name=${THEME_GTK[$name]}
gtk-icon-theme-name=${THEME_ICONS[$name]}
gtk-font-name=${THEME_FONTS[$name]}
gtk-monospace-font-name=${THEME_MONO[$name]}
gtk-cursor-theme-name=${THEME_CURSOR[$name]}
gtk-cursor-theme-size=24
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=true
gtk-enable-animations=1
EOF

  # 3. GTK4 settings
  mkdir -p "$GTK4_DIR"
  cat > "$GTK4_DIR/settings.ini" << EOF
[Settings]
gtk-theme-name=${THEME_GTK[$name]}
gtk-icon-theme-name=${THEME_ICONS[$name]}
gtk-font-name=${THEME_FONTS[$name]}
gtk-monospace-font-name=${THEME_MONO[$name]}
gtk-cursor-theme-name=${THEME_CURSOR[$name]}
gtk-cursor-theme-size=24
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=true
EOF

  # 4. Environment cursor
  sed -i '/^XCURSOR_THEME=/d' "$CONFIG_DIR/environment" 2>/dev/null || true
  sed -i '/^XCURSOR_SIZE=/d' "$CONFIG_DIR/environment" 2>/dev/null || true
  echo "XCURSOR_THEME=${THEME_CURSOR[$name]}" >> "$CONFIG_DIR/environment"
  echo "XCURSOR_SIZE=24" >> "$CONFIG_DIR/environment"

  # 5. Save current theme
  echo "$name" > "$CURRENT_THEME_FILE"

  # 6. Reload labwc
  if pgrep -x labwc &>/dev/null; then
    labwc --reconfigure 2>/dev/null && pass "labwc reloaded" || true
  fi

  # 7. Apply GTK theme via gsettings if available
  if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "${THEME_GTK[$name]}" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "${THEME_ICONS[$name]}" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "${THEME_CURSOR[$name]}" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name "${THEME_FONTS[$name]}" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface monospace-font-name "${THEME_MONO[$name]}" 2>/dev/null || true
  fi

  pass "Theme '${THEME_NAMES[$name]}' applied"
}

# ============================================================
# Interactive Picker
# ============================================================

main_menu() {
  local theme_list=($(echo "${!THEME_NAMES[@]}" | tr ' ' '\n' | sort))

  while true; do
    show_header
    show_current_theme

    echo -e "  ${BOLD}Available Themes:${NC}"
    echo

    local idx=1
    for name in "${theme_list[@]}"; do
      show_theme_card "$name" "$idx"
      ((idx++))
    done

    echo
    echo -e "  ${BOLD}Options:${NC}"
    echo "  [1-${#theme_list[@]}]  Pick a theme"
    echo "  [p]    Preview a theme"
    echo "  [c]    Show current theme"
    echo "  [r]    Restore previous theme"
    echo "  [0]    Exit"
    echo
    read -rp "  Select: " choice

    case "$choice" in
      0|q|quit|exit)
        echo
        pass "Goodbye"
        exit 0
        ;;
      p|preview)
        echo
        echo "  Available: ${theme_list[*]}"
        echo
        read -rp "  Theme name: " preview_name
        if [[ -n "$preview_name" ]] && [[ -n "${THEME_NAMES[$preview_name]:-}" ]]; then
          show_theme_detail "$preview_name"
          echo
          read -rp "  Apply this theme? [y/N] " ans
          if [[ "$ans" =~ ^[Yy] ]]; then
            apply_theme "$preview_name"
          fi
        else
          warn "Theme not found: $preview_name"
        fi
        echo; read -rp "  Press Enter to continue ... "
        ;;
      c|current)
        local current=""
        [[ -f "$CURRENT_THEME_FILE" ]] && current=$(cat "$CURRENT_THEME_FILE")
        if [[ -n "$current" ]] && [[ -n "${THEME_NAMES[$current]:-}" ]]; then
          show_theme_detail "$current"
        else
          info "No theme applied"
        fi
        echo; read -rp "  Press Enter to continue ... "
        ;;
      r|restore)
        bash "$SCRIPT_DIR/restore.sh" 2>/dev/null
        echo; read -rp "  Press Enter to continue ... "
        ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#theme_list[@]} )); then
          local selected="${theme_list[$((choice-1))]}"
          show_theme_detail "$selected"
          echo
          read -rp "  Apply this theme? [y/N] " ans
          if [[ "$ans" =~ ^[Yy] ]]; then
            apply_theme "$selected"
          fi
        else
          warn "Invalid choice"
        fi
        echo; read -rp "  Press Enter to continue ... "
        ;;
    esac
  done
}

# ============================================================
# Quick Apply (non-interactive)
# ============================================================

quick_apply() {
  local name="${1:-}"
  [[ -z "$name" ]] && fail "Usage: theme-picker.sh apply <theme-name>"
  [[ -z "${THEME_NAMES[$name]:-}" ]] && fail "Unknown theme: $name"

  echo -e "Applying theme: ${BOLD}${THEME_NAMES[$name]}${NC}"
  apply_theme "$name"
}

quick_list() {
  echo
  echo "Available themes:"
  for name in $(echo "${!THEME_NAMES[@]}" | tr ' ' '\n' | sort); do
    echo "  - $name  (${THEME_NAMES[$name]})"
  done
  echo
}

# ============================================================
# CLI
# ============================================================

ACTION="${1:-help}"; shift || true

case "$ACTION" in
  pick|interactive)  main_menu ;;
  apply)             quick_apply "${1:-}" ;;
  list)              quick_list ;;
  preview)
    [[ -z "${1:-}" ]] && fail "Usage: theme-picker.sh preview <theme-name>"
    [[ -z "${THEME_NAMES[$1]:-}" ]] && fail "Unknown theme: $1"
    show_theme_detail "$1"
    ;;
  current)
    local current=""
    [[ -f "$CURRENT_THEME_FILE" ]] && current=$(cat "$CURRENT_THEME_FILE")
    [[ -n "$current" ]] && show_theme_detail "$current" || echo "No theme applied"
    ;;
  help|--help|-h|*)
    echo
    echo -e "${BOLD}== Theme Picker ==${NC}"
    echo
    echo "Usage: $0 <command> [args]"
    echo
    echo "Commands:"
    echo "  pick              Interactive visual picker (default)"
    echo "  apply <name>      Quick apply a theme"
    echo "  list              List all available themes"
    echo "  preview <name>    Preview theme colors & components"
    echo "  current           Show currently applied theme"
    echo
    echo "Themes: catppuccin-mocha, nord, dracula, tokyo-night,"
    echo "        arc-dark, breeze-dark, everforest, gruvbox,"
    echo "        rose-pine, solarized-light"
    echo
    echo "Examples:"
    echo "  $0 pick                  # Interactive picker"
    echo "  $0 apply catppuccin-mocha  # Quick apply"
    echo "  $0 preview nord           # Preview colors"
    echo
    ;;
esac
