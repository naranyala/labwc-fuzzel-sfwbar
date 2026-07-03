#!/bin/bash
#
# download-themes.sh — Download lightweight GTK/icon/cursor/font themes
#
# Installs to ~/.local/share/themes and ~/.local/share/icons (XDG spec)
# with ~/.themes and ~/.icons as fallback.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# XDG paths (preferred)
THEMES_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/themes"
ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
FONTS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
# Legacy fallbacks
LEGACY_THEMES="${HOME}/.themes"
LEGACY_ICONS="${HOME}/.icons"
CACHE_DIR="/tmp/theme-downloads"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

pass()  { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
info()  { echo -e "  ${CYAN}→${NC} $1"; }
fail()  { echo -e "  ${RED}✗${NC} $1"; exit 1; }
section() { echo -e "\n${BOLD}[$1]${NC}"; }

mkdir -p "$THEMES_DIR" "$ICONS_DIR" "$FONTS_DIR" "$CACHE_DIR"

# Legacy symlinks so apps that still look in ~/.themes find them
ensure_legacy_links() {
  if [[ "$THEMES_DIR" != "$LEGACY_THEMES" && ! -L "$LEGACY_THEMES" ]]; then
    [[ -d "$LEGACY_THEMES" ]] && return 0
    ln -sf "$THEMES_DIR" "$LEGACY_THEMES" 2>/dev/null || true
  fi
  if [[ "$ICONS_DIR" != "$LEGACY_ICONS" && ! -L "$LEGACY_ICONS" ]]; then
    [[ -d "$LEGACY_ICONS" ]] && return 0
    ln -sf "$ICONS_DIR" "$LEGACY_ICONS" 2>/dev/null || true
  fi
}

ensure_legacy_links

# ============================================================
# Theme Definitions — lightweight, verified URLs
# ============================================================

# GTK Themes (look for gtk-3.0/ or gtk-4.0/ subdir inside archive)
declare -A GTK_THEMES=(
  ["Nordic"]="https://github.com/EliverLara/Nordic/archive/refs/heads/master.tar.gz"
  ["Nordic-darker"]="https://github.com/EliverLara/Nordic/archive/refs/heads/darker.tar.gz"
  ["Nordic-bluish"]="https://github.com/EliverLara/Nordic/archive/refs/heads/bluish-accent.tar.gz"
  ["Catppuccin-Mocha-Mauve"]="https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-mauve-standard%2Bdefault.zip"
  ["Catppuccin-Macchiato-Mauve"]="https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-macchiato-mauve-standard%2Bdefault.zip"
)

# Icon Themes (look for index.theme inside archive)
declare -A ICON_THEMES=(
  ["Papirus-Dark"]="https://github.com/PapirusDevelopmentTeam/papirus-icon-theme/archive/refs/heads/master.tar.gz"
)

# Cursor Themes (look for cursors/ subdir inside archive)
declare -A CURSOR_THEMES=(
  ["Bibata-Modern-Ice"]="https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz"
  ["Catppuccin-Mocha-Dark"]="https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-mocha-dark-cursors.zip"
  ["Catppuccin-Macchiato-Dark"]="https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-macchiato-dark-cursors.zip"
)

# UI/Interface Fonts
declare -A UI_FONTS=(
  ["Inter"]="https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip"
  ["Noto-Sans"]="https://github.com/googlefonts/noto-fonts/raw/main/hinted/ttf/NotoSans/NotoSans%5Bwdth%2Cwght%5D.ttf"
  ["LXGW-WenKai"]="https://github.com/lxgw/LxgwWenKai/releases/download/v1.330/LXGWWenKai-Regular.ttf"
  ["Atkinson-Hyperlegible"]="https://github.com/brailleservices/Atkinson-Hyperlegible/releases/download/2022-01-27/Atkinson-Hyperlegible-Regular.ttf"
)

# Monospace/Code Fonts
declare -A MONO_FONTS=(
  ["JetBrainsMono"]="https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip"
  ["CascadiaCode"]="https://github.com/microsoft/cascadia-code/releases/download/v2404.23224.1142/CascadiaCode-2404.23224.1142.zip"
  ["FiraCode"]="https://github.com/tonsky/FiraCode/releases/download/6.2/Fira_Code_v6.2.zip"
  ["VictorMono"]="https://github.com/rubjo/victor-mono/releases/download/v1.5.5/VictorMonoAll.zip"
  ["Hack"]="https://github.com/chrissimpkins/Hack/releases/download/v3.003/Hack-v3.003-ttf.zip"
  ["SourceCodePro"]="https://github.com/adobe-fonts/source-code-pro/releases/download/2.042R%2F1.062R%2F2.032R%2F1.072R%2FVar.zip"
  ["GeistMono"]="https://github.com/vercel/geist-font/releases/download/1.4.1/geist-mono-1.4.1.zip"
  ["MapleMono"]="https://github.com/subframe7534/maple-font/releases/download/v7.0/MapleMono-NF.zip"
)

# CJK Fonts
declare -A CJK_FONTS=(
  ["Noto-Sans-CJK"]="https://github.com/googlefonts/noto-cjk/releases/download/Sans2.004/03_NotoSansCJKsc.zip"
  ["Noto-Serif-CJK"]="https://github.com/googlefonts/noto-cjk/releases/download/Serif2.004/03_NotoSerifCJKsc.zip"
)

# Nerd Fonts (with icon glyphs)
declare -A NERD_FONTS=(
  ["NerdFonts-JetBrains"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/JetBrainsMono.zip"
  ["NerdFonts-FiraCode"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/FiraCode.zip"
  ["NerdFonts-Hack"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip"
  ["NerdFonts-Cascadia"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/CascadiaCode.zip"
  ["NerdFonts-Mono"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Mono.zip"
)

# Font profiles (quick install combos)
declare -A FONT_PROFILES=(
  ["minimal"]="Inter JetBrainsMono"
  ["dev"]="JetBrainsMono NerdFonts-JetBrains Noto-Sans-CJK"
  ["ui"]="Inter Noto-Sans"
  ["cjk"]="Noto-Sans-CJK Noto-Serif-CJK"
  ["nerdy"]="NerdFonts-JetBrains NerdFonts-FiraCode"
  ["beautiful"]="LXGW-WenKai MapleMono GeistMono"
  ["all-ui"]="Inter Noto-Sans LXGW-WenKai Atkinson-Hyperlegible"
  ["all-mono"]="JetBrainsMono FiraCode CascadiaCode VictorMono Hack GeistMono MapleMono"
)

# ============================================================
# Download & Extract
# ============================================================

download() {
  local url="$1" dest="$2"
  if [[ -f "$dest" ]]; then
    info "Already cached: $(basename "$dest")"
    return 0
  fi
  info "Downloading: $(basename "$dest")"
  if command -v curl &>/dev/null; then
    curl -fLsS -o "$dest" "$url" 2>/dev/null
  elif command -v wget &>/dev/null; then
    wget -q -O "$dest" "$url" 2>/dev/null
  else
    fail "Need curl or wget"
  fi
}

extract_flat() {
  local archive="$1" dest="$2"
  mkdir -p "$dest"
  case "$archive" in
    *.tar.gz|*.tgz) tar -xzf "$archive" -C "$dest" --strip-components=1 2>/dev/null ;;
    *.tar.xz)       tar -xf "$archive" -C "$dest" --strip-components=1 2>/dev/null ;;
    *.zip)          unzip -qo "$archive" -d "$dest" 2>/dev/null ;;
    *)              warn "Unknown format: $archive"; return 1 ;;
  esac
}

find_subdir_in_extract() {
  local extract_dir="$1" markers=("${@:2}")
  for marker in "${markers[@]}"; do
    local found
    found=$(find "$extract_dir" -type d -name "$marker" 2>/dev/null | head -1)
    [[ -n "$found" ]] && { dirname "$found"; return 0; }
  done
  echo "$extract_dir"
}

# ============================================================
# Installers
# ============================================================

install_gtk_theme() {
  local name="$1" url="$2"
  local archive="$CACHE_DIR/gtk-${name}.tar.gz"
  local extract_dir="$CACHE_DIR/gtk-${name}-extract"

  download "$url" "$archive"
  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"

  if ! extract_flat "$archive" "$extract_dir"; then
    rm -rf "$extract_dir"
    return 1
  fi

  local theme_root
  theme_root=$(find_subdir_in_extract "$extract_dir" "gtk-3.0" "gtk-4.0")
  [[ "$theme_root" = "$extract_dir" ]] && {
    # No gtk-3.0/4.0 found — try the repo root directly
    theme_root=$(find "$extract_dir" -maxdepth 3 -type f -name "index.theme" 2>/dev/null | head -1 | xargs dirname)
  }
  [[ -z "$theme_root" || ! -d "$theme_root" ]] && { warn "No GTK theme dir in $name"; rm -rf "$extract_dir"; return 1; }

  rm -rf "$THEMES_DIR/$name"
  cp -r "$theme_root" "$THEMES_DIR/$name"
  pass "GTK theme: $name"
  rm -rf "$extract_dir"
}

install_icon_theme() {
  local name="$1" url="$2"
  local archive="$CACHE_DIR/icon-${name}.tar.gz"
  local extract_dir="$CACHE_DIR/icon-${name}-extract"

  download "$url" "$archive"
  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"

  if ! extract_flat "$archive" "$extract_dir"; then
    rm -rf "$extract_dir"
    return 1
  fi

  local theme_root
  theme_root=$(find "$extract_dir" -type f -name "index.theme" 2>/dev/null | head -1 | xargs dirname)
  [[ -z "$theme_root" || ! -d "$theme_root" ]] && { warn "No index.theme in $name"; rm -rf "$extract_dir"; return 1; }

  rm -rf "$ICONS_DIR/$name"
  cp -r "$theme_root" "$ICONS_DIR/$name"
  pass "Icon theme: $name"
  rm -rf "$extract_dir"
}

install_cursor_theme() {
  local name="$1" url="$2"
  local ext="${url##*.}"
  [[ "$url" == *.tar.* ]] && ext="${url#*.tar.}" && ext="tar.${ext}"
  local archive="$CACHE_DIR/cursor-${name}.${ext}"
  local extract_dir="$CACHE_DIR/cursor-${name}-extract"

  download "$url" "$archive"
  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"

  if ! extract_flat "$archive" "$extract_dir"; then
    rm -rf "$extract_dir"
    return 1
  fi

  # Find directory containing cursors/ subdir
  local theme_root
  local cursor_dir
  cursor_dir=$(find "$extract_dir" -type d -name "cursors" 2>/dev/null | head -1)
  if [[ -n "$cursor_dir" ]]; then
    theme_root=$(dirname "$cursor_dir")
  else
    # Maybe it's at the root with cursors directly inside the extract dir
    [[ -d "$extract_dir/cursors" ]] && theme_root="$extract_dir"
  fi
  [[ -z "$theme_root" || ! -d "$theme_root" ]] && { warn "No cursors/ in $name"; rm -rf "$extract_dir"; return 1; }

  rm -rf "$ICONS_DIR/$name"
  cp -r "$theme_root" "$ICONS_DIR/$name"
  pass "Cursor theme: $name"
  rm -rf "$extract_dir"
}

install_font() {
  local name="$1" url="$2"
  local ext="${url##*.}"
  [[ "$url" == *.tar.* ]] && ext="${url#*.tar.}" && ext="tar.${ext}"
  local archive="$CACHE_DIR/font-${name}.${ext}"
  local extract_dir="$CACHE_DIR/font-${name}-extract"

  download "$url" "$archive"
  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"

  if ! extract_flat "$archive" "$extract_dir"; then
    rm -rf "$extract_dir"
    return 1
  fi

  local count=0
  while IFS= read -r f; do
    cp "$f" "$FONTS_DIR/" 2>/dev/null && count=$((count + 1))
  done < <(find "$extract_dir" -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.woff2" \) 2>/dev/null)

  if [[ "$count" -gt 0 ]]; then
    pass "Fonts installed: $name ($count files)"
  else
    warn "No font files in $name"
  fi
  rm -rf "$extract_dir"
}

# ============================================================
# Commands
# ============================================================

cmd_all() {
  cmd_gtk
  cmd_icons
  cmd_cursors
  cmd_fonts
  echo
  section "Summary"
  pass "All theme resources downloaded"
  echo
  info "Apply with: themes.sh profile apply <name>"
}

cmd_gtk() {
  section "GTK Themes"
  for name in "${!GTK_THEMES[@]}"; do
    install_gtk_theme "$name" "${GTK_THEMES[$name]}"
  done
}

cmd_icons() {
  section "Icon Themes"
  for name in "${!ICON_THEMES[@]}"; do
    install_icon_theme "$name" "${ICON_THEMES[$name]}"
  done
}

cmd_cursors() {
  section "Cursor Themes"
  for name in "${!CURSOR_THEMES[@]}"; do
    install_cursor_theme "$name" "${CURSOR_THEMES[$name]}"
  done
}

cmd_fonts() {
  section "UI Fonts"
  for name in "${!UI_FONTS[@]}"; do
    install_font "$name" "${UI_FONTS[$name]}"
  done
  
  section "Monospace Fonts"
  for name in "${!MONO_FONTS[@]}"; do
    install_font "$name" "${MONO_FONTS[$name]}"
  done
  
  section "CJK Fonts"
  for name in "${!CJK_FONTS[@]}"; do
    install_font "$name" "${CJK_FONTS[$name]}"
  done
  
  section "Nerd Fonts"
  for name in "${!NERD_FONTS[@]}"; do
    install_font "$name" "${NERD_FONTS[$name]}"
  done
  
  section "Updating Font Cache"
  if command -v fc-cache &>/dev/null; then
    fc-cache -f 2>/dev/null && pass "Font cache updated"
  fi
}

cmd_ui_fonts() {
  section "UI Fonts"
  for name in "${!UI_FONTS[@]}"; do
    install_font "$name" "${UI_FONTS[$name]}"
  done
  if command -v fc-cache &>/dev/null; then
    fc-cache -f 2>/dev/null && pass "Font cache updated"
  fi
}

cmd_mono_fonts() {
  section "Monospace Fonts"
  for name in "${!MONO_FONTS[@]}"; do
    install_font "$name" "${MONO_FONTS[$name]}"
  done
  if command -v fc-cache &>/dev/null; then
    fc-cache -f 2>/dev/null && pass "Font cache updated"
  fi
}

cmd_cjk_fonts() {
  section "CJK Fonts"
  for name in "${!CJK_FONTS[@]}"; do
    install_font "$name" "${CJK_FONTS[$name]}"
  done
  if command -v fc-cache &>/dev/null; then
    fc-cache -f 2>/dev/null && pass "Font cache updated"
  fi
}

cmd_nerd_fonts() {
  section "Nerd Fonts"
  for name in "${!NERD_FONTS[@]}"; do
    install_font "$name" "${NERD_FONTS[$name]}"
  done
  if command -v fc-cache &>/dev/null; then
    fc-cache -f 2>/dev/null && pass "Font cache updated"
  fi
}

cmd_font_profile() {
  local profile="${1:-}"
  [[ -z "$profile" ]] && fail "Usage: $0 font-profile <name>"
  
  local font_list="${FONT_PROFILES[$profile]:-}"
  [[ -z "$font_list" ]] && fail "Unknown profile: $profile"
  
  section "Font Profile: $profile"
  
  for font_name in $font_list; do
    local url=""
    [[ -n "${UI_FONTS[$font_name]:-}" ]] && url="${UI_FONTS[$font_name]}"
    [[ -z "$url" && -n "${MONO_FONTS[$font_name]:-}" ]] && url="${MONO_FONTS[$font_name]}"
    [[ -z "$url" && -n "${CJK_FONTS[$font_name]:-}" ]] && url="${CJK_FONTS[$font_name]}"
    [[ -z "$url" && -n "${NERD_FONTS[$font_name]:-}" ]] && url="${NERD_FONTS[$font_name]}"
    
    if [[ -n "$url" ]]; then
      install_font "$font_name" "$url"
    else
      warn "Font not found: $font_name"
    fi
  done
  
  if command -v fc-cache &>/dev/null; then
    fc-cache -f 2>/dev/null && pass "Font cache updated"
  fi
}

cmd_list() {
  echo
  echo "== Available Theme Resources =="
  echo
  echo "GTK Themes:"
  for name in "${!GTK_THEMES[@]}"; do echo "  - $name"; done
  echo
  echo "Icon Themes:"
  for name in "${!ICON_THEMES[@]}"; do echo "  - $name"; done
  echo
  echo "Cursor Themes:"
  for name in "${!CURSOR_THEMES[@]}"; do echo "  - $name"; done
  echo
  echo "UI Fonts:"
  for name in "${!UI_FONTS[@]}"; do echo "  - $name"; done
  echo
  echo "Monospace Fonts:"
  for name in "${!MONO_FONTS[@]}"; do echo "  - $name"; done
  echo
  echo "CJK Fonts:"
  for name in "${!CJK_FONTS[@]}"; do echo "  - $name"; done
  echo
  echo "Nerd Fonts (with icons):"
  for name in "${!NERD_FONTS[@]}"; do echo "  - $name"; done
  echo
  echo "Font Profiles:"
  for name in "${!FONT_PROFILES[@]}"; do
    echo "  - $name: ${FONT_PROFILES[$name]}"
  done
  echo
}

cmd_installed() {
  echo
  echo "== Installed Themes =="
  echo
  echo "GTK themes ($THEMES_DIR):"
  for d in "$THEMES_DIR"/*/; do [[ -d "$d" ]] && echo "  - $(basename "$d")"; done
  echo
  echo "Icons/cursors ($ICONS_DIR):"
  for d in "$ICONS_DIR"/*/; do [[ -d "$d" ]] && echo "  - $(basename "$d")"; done
  echo
  local fc
  fc=$(find "$FONTS_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | wc -l)
  echo "Fonts: $fc files in $FONTS_DIR"
  echo
}

cmd_clean() {
  rm -rf "$CACHE_DIR"
  pass "Cache cleaned"
}

# ============================================================
# CLI
# ============================================================

ACTION="${1:-help}"; shift || true

case "$ACTION" in
  all|install)     cmd_all ;;
  gtk)             cmd_gtk ;;
  icons)           cmd_icons ;;
  cursors)         cmd_cursors ;;
  fonts)           cmd_fonts ;;
  ui|ui-fonts)     cmd_ui_fonts ;;
  mono|mono-fonts) cmd_mono_fonts ;;
  cjk|cjk-fonts)   cmd_cjk_fonts ;;
  nerd|nerd-fonts) cmd_nerd_fonts ;;
  font-profile)    cmd_font_profile "${1:-}" ;;
  list)            cmd_list ;;
  installed)       cmd_installed ;;
  clean)           cmd_clean ;;
  help|--help|-h|*)
    echo
    echo "== Theme Downloader =="
    echo
    echo "Usage: $0 <command>"
    echo
    echo "Commands:"
    echo "  all               Download all theme resources"
    echo "  gtk               GTK themes only"
    echo "  icons             Icon themes only"
    echo "  cursors           Cursor themes only"
    echo "  fonts             All fonts (UI + Mono + CJK + Nerd)"
    echo "  ui                UI fonts only (Inter, Noto, etc.)"
    echo "  mono              Monospace fonts only"
    echo "  cjk               CJK fonts only"
    echo "  nerd              Nerd Fonts (with icon glyphs)"
    echo "  font-profile <n>  Install a font profile"
    echo "  list              List available resources"
    echo "  installed         List installed"
    echo "  clean             Clear download cache"
    echo
    echo "Font Profiles:"
    for name in "${!FONT_PROFILES[@]}"; do
      echo "  - $name: ${FONT_PROFILES[$name]}"
    done
    echo
    echo "Examples:"
    echo "  $0 fonts                 # Install all fonts"
    echo "  $0 mono                  # Just monospace fonts"
    echo "  $0 nerd                  # Just Nerd Fonts"
    echo "  $0 font-profile dev      # Dev font combo"
    echo "  $0 font-profile cjk      # CJK fonts only"
    echo
    ;;
esac
