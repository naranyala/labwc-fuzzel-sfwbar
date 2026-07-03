#!/bin/bash
#
# themes.sh — Unified theme manager for labwc + GTK3 + GTK4
#
# Manages Openbox themes, GTK themes/icons/cursors/fonts,
# GTK CSS overrides, and full theme profiles.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="${HOME}/.config/labwc"
THEMERC="$CONFIG_DIR/themerc-override"
RC_XML="$CONFIG_DIR/rc.xml"
GTK3_DIR="${HOME}/.config/gtk-3.0"
GTK4_DIR="${HOME}/.config/gtk-4.0"
GTK3_INI="$GTK3_DIR/settings.ini"
GTK4_INI="$GTK4_DIR/settings.ini"
GTK_CSS_SRC="$PROJECT_DIR/dotfiles/gtk/gtk.css"
PROFILES_DIR="$PROJECT_DIR/dotfiles/gtk/theme-profiles"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

pass()  { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
info()  { echo -e "  ${CYAN}→${NC} $1"; }
fail()  { echo -e "  ${RED}✗${NC} $1"; exit 1; }
header() { echo -e "\n${BOLD}[$1]${NC}"; }

ACTION="${1:-help}"; shift || true

# ---- Helpers ----

reload_labwc() {
  if pgrep -x labwc &>/dev/null; then
    labwc --reconfigure 2>/dev/null && pass "labwc reloaded" || warn "labwc reload failed"
  fi
}

set_gtk3_key() {
  local key="$1" val="$2"
  mkdir -p "$GTK3_DIR"
  if [[ -f "$GTK3_INI" ]]; then
    if grep -q "^$key\s*=" "$GTK3_INI"; then
      sed -i "s|^$key\s*=.*|${key}=${val}|" "$GTK3_INI"
    else
      sed -i "/^\[Settings\]/a ${key}=${val}" "$GTK3_INI"
    fi
  else
    echo -e "[Settings]\n${key}=${val}" > "$GTK3_INI"
  fi
}

set_gtk4_key() {
  local key="$1" val="$2"
  mkdir -p "$GTK4_DIR"
  if [[ -f "$GTK4_INI" ]]; then
    if grep -q "^$key\s*=" "$GTK4_INI"; then
      sed -i "s|^$key\s*=.*|${key}=${val}|" "$GTK4_INI"
    else
      sed -i "/^\[Settings\]/a ${key}=${val}" "$GTK4_INI"
    fi
  else
    echo -e "[Settings]\n${key}=${val}" > "$GTK4_INI"
  fi
}

gsettings_if_exists() {
  local schema="$1" key="$2" val="$3"
  if gsettings list-schemas 2>/dev/null | grep -qx "$schema"; then
    gsettings set "$schema" "$key" "$val" 2>/dev/null || true
  fi
}

sync_gsettings() {
  local theme="${1:-}" icon="${2:-}" cursor="${3:-}" font="${4:-}" dark="${5:-}"
  [[ -n "$theme" ]] && gsettings_if_exists org.gnome.desktop.interface gtk-theme "$theme"
  [[ -n "$icon" ]]  && gsettings_if_exists org.gnome.desktop.interface icon-theme "$icon"
  [[ -n "$cursor" ]] && gsettings_if_exists org.gnome.desktop.interface cursor-theme "$cursor"
  [[ -n "$font" ]]  && gsettings_if_exists org.gnome.desktop.interface font-name "$font"
  [[ -n "$dark" ]]  && gsettings_if_exists org.gnome.desktop.interface color-scheme "$([ "$dark" = true ] && echo prefer-dark || echo default)"
}

find_system_fonts() {
  fc-list 2>/dev/null | awk -F: '{print $2}' | sort -u | sed 's/^ *//'
}

find_system_fonts_by_category() {
  local category="${1:-}"
  case "$category" in
    mono|monospace)
      fc-list 2>/dev/null | grep -i "mono" | awk -F: '{print $2}' | sort -u | sed 's/^ *//'
      ;;
    sans|sans-serif)
      fc-list 2>/dev/null | grep -iv "mono" | awk -F: '{print $2}' | sort -u | sed 's/^ *//'
      ;;
    nerd)
      fc-list 2>/dev/null | grep -i "nerd" | awk -F: '{print $2}' | sort -u | sed 's/^ *//'
      ;;
    *)
      find_system_fonts
      ;;
  esac
}

find_themes_labwc() {
  local dirs=()
  for base in "$HOME/.local/share/themes" "/usr/share/themes"; do
    [[ -d "$base" ]] && dirs+=("$base"/*/labwc)
  done
  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] && basename "$(dirname "$d")"
  done | sort -u
}

find_themes_gtk() {
  local dirs=()
  for base in "$HOME/.local/share/themes" "/usr/share/themes"; do
    [[ -d "$base" ]] && dirs+=("$base"/*/gtk-3.0)
  done
  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] && basename "$(dirname "$d")"
  done | sort -u
}

find_icon_themes() {
  for base in "$HOME/.local/share/icons" "/usr/share/icons"; do
    [[ -d "$base" ]] && ls "$base" 2>/dev/null
  done | sort -u
}

find_cursor_themes() {
  for base in "$HOME/.local/share/icons" "/usr/share/icons"; do
    if [[ -d "$base" ]]; then
      for d in "$base"/*; do
        [[ -f "$d/cursor.theme" || -d "$d/cursors" ]] && basename "$d"
      done 2>/dev/null
    fi
  done | sort -u
}

current_gtk3_theme() {
  grep -oP '(?<=^gtk-theme-name=).*' "$GTK3_INI" 2>/dev/null | head -1
}

current_gtk4_theme() {
  grep -oP '(?<=^gtk-theme-name=).*' "$GTK4_INI" 2>/dev/null | head -1
}

read_profile() {
  local file="$1"
  [[ ! -f "$file" ]] && return 1
  local k v
  while IFS='=' read -r k v; do
    [[ "$k" =~ ^#.*$ || -z "$k" ]] && continue
    case "$k" in
      labwc_theme) labwc_theme="$v" ;;
      gtk3_theme)  gtk3_theme="$v" ;;
      gtk4_theme)  gtk4_theme="$v" ;;
      icon_theme)  icon_theme="$v" ;;
      cursor_theme) cursor_theme="$v" ;;
      cursor_size) cursor_size="$v" ;;
      font)        font="$v" ;;
      font_mono)   font_mono="$v" ;;
      font_profile) font_profile="$v" ;;
      prefer_dark) prefer_dark="$v" ;;
    esac
  done < "$file"
}

# ---- Commands ----

cmd_list() {
  header "labwc Themes"
  local current=$(grep -oP '(?<=<name>).*(?=</name>)' "$RC_XML" 2>/dev/null | head -1 || echo "default")
  echo -e "  Current: ${CYAN}${current}${NC}"
  echo "  Installed:"
  local found=0
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    echo -e "    ${GREEN}●${NC} $t"
    ((found++))
  done < <(find_themes_labwc)
  [[ "$found" -eq 0 ]] && echo "    (none)"
  echo

  header "GTK3 Themes"
  echo -e "  Current: ${CYAN}$(current_gtk3_theme)${NC}"
  echo "  Installed:"
  found=0
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    echo -e "    ${GREEN}●${NC} $t"
    ((found++))
  done < <(find_themes_gtk)
  [[ "$found" -eq 0 ]] && echo "    (none)"
  echo

  header "GTK4 Themes"
  echo -e "  Current: ${CYAN}$(current_gtk4_theme)${NC}"
  echo

  header "Icon Themes"
  echo -e "  Current: ${CYAN}$(grep -oP '(?<=^gtk-icon-theme-name=).*' "$GTK3_INI" 2>/dev/null)${NC}"
  echo "  Installed:"
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    echo -e "    ${GREEN}●${NC} $t"
  done < <(find_icon_themes)
  echo

  header "Cursor Themes"
  echo -e "  Current: ${CYAN}$(grep -oP '(?<=^gtk-cursor-theme-name=).*' "$GTK3_INI" 2>/dev/null)${NC}"
  echo "  Installed:"
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    echo -e "    ${GREEN}●${NC} $t"
  done < <(find_cursor_themes)
  echo

  header "GTK CSS"
  echo -e "  ${DIM}${GTK3_DIR}/gtk.css:${NC} $(wc -c < "$GTK3_DIR/gtk.css" 2>/dev/null || echo 0) bytes"
  echo -e "  ${DIM}${GTK4_DIR}/gtk.css:${NC} $(wc -c < "$GTK4_DIR/gtk.css" 2>/dev/null || echo 0) bytes"
  echo

  header "Font"
  echo -e "  ${DIM}GTK:${NC} $(grep -oP '(?<=^gtk-font-name=).*' "$GTK3_INI" 2>/dev/null || echo "default")"
  echo -e "  ${DIM}labwc:${NC} $(grep -oP '(?<=<name>).*(?=</name>)' "$RC_XML" 2>/dev/null | head -1 || echo "default")"
  echo

  info "Commands:"
  echo "  themes.sh set <theme>           Set labwc Openbox theme"
  echo "  themes.sh override              Edit themerc-override"
  echo "  themes.sh gtk-set <theme>       Set GTK3 + GTK4 theme"
  echo "  themes.sh gtk-css               Edit GTK CSS overrides"
  echo "  themes.sh gtk-css-install       Copy gtk.css to GTK dirs"
  echo "  themes.sh icon-set <name>       Set icon theme"
  echo "  themes.sh cursor-set <name>     Set cursor theme"
  echo "  themes.sh font-set <font>       Set system font"
  echo "  themes.sh profile list          List theme profiles"
  echo "  themes.sh profile apply <name>  Apply a full theme profile"
  echo "  themes.sh profile create <name> Create profile from current state"
}

cmd_set() {
  local name="${1:-}"
  [[ -z "$name" ]] && fail "Usage: themes.sh set <theme-name>"

  local found=false
  while IFS= read -r t; do
    [[ "$t" = "$name" ]] && found=true && break
  done < <(find_themes_labwc)
  $found || warn "Theme '$name' not found (labwc will fall back)"

  [[ -f "$RC_XML" ]] && cp "$RC_XML" "${RC_XML}.theme-backup"
  if grep -q '<name>' "$RC_XML" 2>/dev/null; then
    sed -i "s|<name>.*</name>|<name>${name}</name>|" "$RC_XML"
  else
    sed -i "/<theme>/a\\    <name>${name}</name>" "$RC_XML"
  fi
  pass "labwc theme: $name"
  reload_labwc
}

cmd_override() {
  mkdir -p "$CONFIG_DIR"
  if [[ ! -f "$THEMERC" ]]; then
    cat > "$THEMERC" << 'EOF'
# labwc theme overrides
activetextfont=sans 10
activebg=#2d2d2d
activetext=#d4d4d4
inactivetextfont=sans 10
inactivebg=#1e1e1e
inactivetext=#808080
border.width=1
border.color=#3c3c3c
titlebar.height=28
EOF
    pass "Created default themerc-override"
  fi
  ${EDITOR:-nano} "$THEMERC"
  pass "themerc-override saved"
  reload_labwc
}

cmd_gtk_set() {
  local name="${1:-}"
  [[ -z "$name" ]] && fail "Usage: themes.sh gtk-set <theme-name>"

  set_gtk3_key gtk-theme-name "$name"
  set_gtk4_key gtk-theme-name "$name"
  gsettings_if_exists org.gnome.desktop.interface gtk-theme "$name"
  pass "GTK3 + GTK4 theme: $name"
}

cmd_gtk_css() {
  mkdir -p "$GTK3_DIR" "$GTK4_DIR"
  local css_src="$GTK_CSS_SRC"
  if [[ ! -f "$css_src" ]]; then
    fail "gtk.css source not found: $css_src"
  fi
  cp "$css_src" "$GTK3_DIR/gtk.css"
  cp "$css_src" "$GTK4_DIR/gtk.css"
  pass "gtk.css installed to GTK3 + GTK4 dirs"
  ${EDITOR:-nano} "$GTK3_DIR/gtk.css"
  pass "gtk.css saved"
  cp "$GTK3_DIR/gtk.css" "$GTK4_DIR/gtk.css"
  pass "GTK4 gtk.css synced"
}

cmd_icon_set() {
  local name="${1:-}"
  [[ -z "$name" ]] && fail "Usage: themes.sh icon-set <name>"

  set_gtk3_key gtk-icon-theme-name "$name"
  set_gtk4_key gtk-icon-theme-name "$name"
  gsettings_if_exists org.gnome.desktop.interface icon-theme "$name"
  pass "Icon theme: $name"
}

cmd_cursor_set() {
  local name="${1:-}" size="${2:-24}"
  [[ -z "$name" ]] && fail "Usage: themes.sh cursor-set <name> [size]"

  set_gtk3_key gtk-cursor-theme-name "$name"
  set_gtk4_key gtk-cursor-theme-name "$name"
  set_gtk3_key gtk-cursor-theme-size "$size"
  set_gtk4_key gtk-cursor-theme-size "$size"
  gsettings_if_exists org.gnome.desktop.interface cursor-theme "$name"
  gsettings_if_exists org.gnome.desktop.interface cursor-size "$size"
  pass "Cursor theme: $name ($size px)"
}

cmd_font_set() {
  local font="${1:-}" mono="${2:-}"
  [[ -z "$font" ]] && fail "Usage: themes.sh font-set \"<font>, <size>\" [\"<mono-font>, <size>\"]"

  set_gtk3_key gtk-font-name "$font"
  set_gtk4_key gtk-font-name "$font"
  gsettings_if_exists org.gnome.desktop.interface font-name "$font"

  if [[ -n "$mono" ]]; then
    set_gtk4_key gtk-monospace-font-name "$mono"
    gsettings_if_exists org.gnome.desktop.interface monospace-font-name "$mono"
  fi
  pass "Font: $font"
}

cmd_font_list() {
  local filter="${1:-}"
  header "System Fonts"
  if [[ -n "$filter" ]]; then
    echo -e "  Filter: ${CYAN}${filter}${NC}"
    echo
    while IFS= read -r f; do
      echo -e "  ${GREEN}●${NC} $f"
    done < <(find_system_fonts_by_category "$filter")
  else
    while IFS= read -r f; do
      echo -e "  ${GREEN}●${NC} $f"
    done < <(find_system_fonts)
  fi
  echo
  info "Usage: themes.sh font list [mono|sans|nerd]"
  echo
}

cmd_font_preview() {
  local font_name="${1:-}"
  [[ -z "$font_name" ]] && fail "Usage: themes.sh font preview \"<font-name>\""

  echo
  echo "== Font Preview: $font_name =="
  echo
  echo -e "  ${BOLD}Regular:${NC}"
  echo -e "  ${font_name} — The quick brown fox jumps over the lazy dog. 0123456789"
  echo
  echo -e "  ${BOLD}Bold:${NC}"
  echo -e "  \033[1m${font_name} — The quick brown fox jumps over the lazy dog. 0123456789\033[0m"
  echo
  echo -e "  ${BOLD}Italic:${NC}"
  echo -e "  \033[3m${font_name} — The quick brown fox jumps over the lazy dog. 0123456789\033[0m"
  echo
  echo -e "  ${BOLD}Special chars:${NC}"
  echo -e "  !@#\$%^&*() _+-=[]{}|;':\",./<>?~"
  echo
  echo -e "  ${BOLD}Code sample:${NC}"
  echo -e "  fn main() { println!(\"Hello, World!\"); }"
  echo
}

cmd_profile() {
  local sub="${1:-help}"; shift || true

  case "$sub" in
    list|ls)
      header "Theme Profiles"
      if [[ -d "$PROFILES_DIR" ]]; then
        for f in "$PROFILES_DIR"/*; do
          [[ ! -f "$f" ]] && continue
          local name=$(basename "$f")
          local desc=$(head -1 "$f" 2>/dev/null | sed 's/^# //')
          echo -e "  ${GREEN}●${NC} ${BOLD}${name}${NC}"
          echo -e "    ${DIM}${desc:-}${NC}"
          while IFS='=' read -r k v; do
            [[ "$k" =~ ^#.*$ || -z "$k" ]] && continue
            printf "    %-20s %s\n" "$k" "$v"
          done < "$f"
          echo
        done
      else
        echo "  (no profiles directory)"
      fi
      echo

      info "Apply: themes.sh profile apply <name>"
      info "Create: themes.sh profile create <name>"
      ;;

    apply)
      local name="${1:-}"
      [[ -z "$name" ]] && fail "Usage: themes.sh profile apply <name>"
      local file="$PROFILES_DIR/$name"
      [[ ! -f "$file" ]] && fail "Profile not found: $name (check 'profile list')"

      local labwc_theme="" gtk3_theme="" gtk4_theme=""
      local icon_theme="" cursor_theme="" cursor_size="24"
      local font="" font_mono="" font_profile="" prefer_dark=""
      read_profile "$file"

      header "Applying profile: $name"

      [[ -n "$labwc_theme" ]] && cmd_set "$labwc_theme"
      [[ -n "$gtk3_theme" ]]  && cmd_gtk_set "$gtk3_theme"
      [[ -n "$gtk4_theme" && -z "$gtk3_theme" ]] && cmd_gtk_set "$gtk4_theme"
      [[ -n "$icon_theme" ]]  && cmd_icon_set "$icon_theme"
      [[ -n "$cursor_theme" ]] && cmd_cursor_set "$cursor_theme" "$cursor_size"
      if [[ -n "$font" ]]; then
        cmd_font_set "$font" "$font_mono"
      fi
      if [[ -n "$font_profile" ]]; then
        info "Font profile: $font_profile"
        "$SCRIPT_DIR/download-themes.sh" font-profile "$font_profile"
      fi
      if [[ "$prefer_dark" = "true" ]]; then
        set_gtk3_key gtk-application-prefer-dark-theme 1
        set_gtk4_key gtk-application-prefer-dark-theme true
        gsettings_if_exists org.gnome.desktop.interface color-scheme prefer-dark
      fi

      header "Done"
      pass "Profile '$name' applied"
      echo
      info "Reload GTK apps to see changes (or logout/login)"
      ;;

    create)
      local name="${1:-}"
      [[ -z "$name" ]] && fail "Usage: themes.sh profile create <name>"
      local file="$PROFILES_DIR/$name"
      [[ -f "$file" ]] && warn "Overwriting existing profile: $name"

      local ltheme=$(grep -oP '(?<=<name>).*(?=</name>)' "$RC_XML" 2>/dev/null | head -1 || echo "")
      local g3theme=$(current_gtk3_theme)
      local g4theme=$(current_gtk4_theme)
      local itheme=$(grep -oP '(?<=^gtk-icon-theme-name=).*' "$GTK3_INI" 2>/dev/null || echo "")
      local ctheme=$(grep -oP '(?<=^gtk-cursor-theme-name=).*' "$GTK3_INI" 2>/dev/null || echo "")
      local csize=$(grep -oP '(?<=^gtk-cursor-theme-size=).*' "$GTK3_INI" 2>/dev/null || echo "24")
      local ffont=$(grep -oP '(?<=^gtk-font-name=).*' "$GTK3_INI" 2>/dev/null || echo "")
      local fmono=$(grep -oP '(?<=^gtk-monospace-font-name=).*' "$GTK4_INI" 2>/dev/null || echo "")
      local dark=$(grep -oP '(?<=^gtk-application-prefer-dark-theme=).*' "$GTK4_INI" 2>/dev/null || echo "false")

      cat > "$file" << PROFILE
# Theme profile: $name (saved $(date +%Y-%m-%d))
labwc_theme=${ltheme}
gtk3_theme=${g3theme}
gtk4_theme=${g4theme}
icon_theme=${itheme}
cursor_theme=${ctheme}
cursor_size=${csize}
font=${ffont}
font_mono=${fmono}
prefer_dark=${dark}
PROFILE
      pass "Profile created: $name"
      ;;

    pick|select)
      local profiles=()
      while IFS= read -r f; do
        [[ -f "$f" ]] && profiles+=("$f")
      done < <(find "$PROFILES_DIR" -maxdepth 1 -type f | sort)

      [[ ${#profiles[@]} -eq 0 ]] && fail "No profiles found in $PROFILES_DIR"

      echo
      echo "  Available profiles:"
      echo
      for i in "${!profiles[@]}"; do
        local pfile="${profiles[$i]}"
        local pname=$(basename "$pfile")
        local pdesc=$(head -1 "$pfile" 2>/dev/null | sed 's/^# //')
        printf "  %2d)  ${BOLD}%-25s${NC} ${DIM}%s${NC}\n" $((i+1)) "$pname" "${pdesc:-}"
      done
      echo
      echo "  0)   Cancel"
      echo
      read -rp "  Pick profile [1-${#profiles[@]}]: " pick
      [[ -z "$pick" || "$pick" == "0" ]] && { info "Cancelled"; return; }
      [[ "$pick" -ge 1 && "$pick" -le "${#profiles[@]}" ]] || { warn "Invalid: $pick"; return; }

      local chosen=$(basename "${profiles[$((pick-1))]}")
      echo
      info "Selected: $chosen"
      echo "  Changes:"

      local labwc_theme="" gtk3_theme="" gtk4_theme=""
      local icon_theme="" cursor_theme="" cursor_size="24"
      local font="" font_mono="" font_profile="" prefer_dark=""
      read_profile "${profiles[$((pick-1))]}"

      [[ -n "$labwc_theme" ]] && echo "    labwc:    $(grep -oP '(?<=<name>).*(?=</name>)' "$RC_XML" 2>/dev/null | head -1 || echo '?') → ${labwc_theme}"
      [[ -n "$gtk3_theme" ]] && echo "    GTK3:     $(current_gtk3_theme) → ${gtk3_theme}"
      [[ -n "$gtk4_theme" ]] && echo "    GTK4:     $(current_gtk4_theme) → ${gtk4_theme}"
      [[ -n "$icon_theme" ]] && echo "    Icons:    $(grep -oP '(?<=^gtk-icon-theme-name=).*' "$GTK3_INI" 2>/dev/null || echo '?') → ${icon_theme}"
      [[ -n "$cursor_theme" ]] && echo "    Cursor:   $(grep -oP '(?<=^gtk-cursor-theme-name=).*' "$GTK3_INI" 2>/dev/null || echo '?') → ${cursor_theme}"
      [[ -n "$font" ]] && echo "    Font:     $font"
      [[ "$prefer_dark" = "true" ]] && echo "    Dark mode"
      echo
      read -rp "  Apply profile '$chosen'? [y/N] " confirm
      [[ ! "$confirm" =~ ^[Yy] ]] && { info "Cancelled"; return; }

      cmd_profile apply "$chosen"
      ;;

    *)
      echo "Usage: themes.sh profile <subcommand>"
      echo
      echo "Subcommands:"
      echo "  list              List available profiles"
      echo "  pick              Interactive profile picker"
      echo "  apply <name>      Apply a theme profile"
      echo "  create <name>     Save current theme as profile"
      ;;
  esac
}

cmd_pick() {
  while true; do
    echo
    echo "  Pick what to configure:"
    echo
    echo "  1)  Theme profile        (set everything at once)"
    echo "  2)  labwc theme          (window borders + titlebars)"
    echo "  3)  GTK3 + GTK4 theme    (appearance of GTK apps)"
    echo "  4)  Icon theme"
    echo "  5)  Cursor theme"
    echo "  6)  System font"
    echo "  0)  Back"
    echo
    read -rp "  Select [0-6]: " pick

    case "$pick" in
      1)
        cmd_profile pick
        ;;
      2)
        local arr=()
        while IFS= read -r t; do arr+=("$t"); done < <(find_themes_labwc)
        [[ ${#arr[@]} -eq 0 ]] && { warn "No labwc themes found"; sleep 1; continue; }
        echo
        echo "  Available labwc themes:"
        for i in "${!arr[@]}"; do
          local m=""
          [[ "${arr[$i]}" == "$(grep -oP '(?<=<name>).*(?=</name>)' "$RC_XML" 2>/dev/null | head -1)" ]] && m=" ${GREEN}← current${NC}"
          echo "  $((i+1)))  ${arr[$i]}${m}"
        done
        echo
        read -rp "  Pick [1-${#arr[@]}] or 0 to cancel: " p
        [[ -z "$p" || "$p" == "0" ]] && continue
        [[ "$p" -ge 1 && "$p" -le "${#arr[@]}" ]] && cmd_set "${arr[$((p-1))]}" || warn "Invalid"
        ;;
      3)
        local arr=()
        while IFS= read -r t; do arr+=("$t"); done < <(find_themes_gtk)
        [[ ${#arr[@]} -eq 0 ]] && { warn "No GTK themes found"; sleep 1; continue; }
        echo
        echo "  Available GTK themes:"
        for i in "${!arr[@]}"; do
          local m=""
          [[ "${arr[$i]}" == "$(current_gtk3_theme)" ]] && m=" ${GREEN}← current${NC}"
          echo "  $((i+1)))  ${arr[$i]}${m}"
        done
        echo
        read -rp "  Pick [1-${#arr[@]}] or 0 to cancel: " p
        [[ -z "$p" || "$p" == "0" ]] && continue
        [[ "$p" -ge 1 && "$p" -le "${#arr[@]}" ]] && cmd_gtk_set "${arr[$((p-1))]}" || warn "Invalid"
        ;;
      4)
        local arr=()
        while IFS= read -r t; do arr+=("$t"); done < <(find_icon_themes)
        [[ ${#arr[@]} -eq 0 ]] && { warn "No icon themes found"; sleep 1; continue; }
        echo
        echo "  Available icon themes:"
        for i in "${!arr[@]}"; do
          local m=""
          [[ "${arr[$i]}" == "$(grep -oP '(?<=^gtk-icon-theme-name=).*' "$GTK3_INI" 2>/dev/null || true)" ]] && m=" ${GREEN}← current${NC}"
          echo "  $((i+1)))  ${arr[$i]}${m}"
        done
        echo
        read -rp "  Pick [1-${#arr[@]}] or 0 to cancel: " p
        [[ -z "$p" || "$p" == "0" ]] && continue
        [[ "$p" -ge 1 && "$p" -le "${#arr[@]}" ]] && cmd_icon_set "${arr[$((p-1))]}" || warn "Invalid"
        ;;
      5)
        local arr=()
        while IFS= read -r t; do arr+=("$t"); done < <(find_cursor_themes)
        [[ ${#arr[@]} -eq 0 ]] && { warn "No cursor themes found"; sleep 1; continue; }
        echo
        echo "  Available cursor themes:"
        for i in "${!arr[@]}"; do
          local m=""
          [[ "${arr[$i]}" == "$(grep -oP '(?<=^gtk-cursor-theme-name=).*' "$GTK3_INI" 2>/dev/null || true)" ]] && m=" ${GREEN}← current${NC}"
          echo "  $((i+1)))  ${arr[$i]}${m}"
        done
        echo
        read -rp "  Pick [1-${#arr[@]}] or 0 to cancel: " p
        [[ -z "$p" || "$p" == "0" ]] && continue
        [[ "$p" -ge 1 && "$p" -le "${#arr[@]}" ]] && cmd_cursor_set "${arr[$((p-1))]}" || warn "Invalid"
        ;;
      6)
        read -rp "  Enter font (e.g. 'Noto Sans, 10'): " font
        [[ -n "$font" ]] && cmd_font_set "$font"
        ;;
      0)
        return
        ;;
      *)
        warn "Invalid"
        sleep 1
        ;;
    esac
    echo
  done
}

cmd_help() {
  echo
  echo "== Unified Theme Manager =="
  echo
  echo "Usage: themes.sh <command> [args]"
  echo
  echo "Interactive:"
  echo "  pick                          Interactive theme picker (menu-driven)"
  echo
  echo "labwc:"
  echo "  list                          Show current theme state"
  echo "  set <theme>                   Set labwc Openbox theme"
  echo "  override                      Edit themerc-override"
  echo
  echo "GTK:"
  echo "  gtk-set <theme>               Set GTK3 + GTK4 theme"
  echo "  gtk-css                       Edit GTK CSS overrides"
  echo
  echo "Icons & Cursors & Fonts:"
  echo "  icon-set <name>               Set icon theme"
  echo "  cursor-set <name> [size]      Set cursor theme + size"
  echo "  font-set \"<font>, <size>\"     Set system font"
  echo "  font-list [mono|sans|nerd]     List system fonts (optional filter)"
  echo "  font-preview \"<font name>\"     Preview a font in terminal"
  echo
  echo "Profiles:"
  echo "  profile list                  List profiles"
  echo "  profile pick                  Interactive profile picker"
  echo "  profile apply <name>          Apply full profile"
  echo "  profile create <name>         Save current as profile"
  echo
  echo "Download:"
  echo "  download all                  Download GTK themes, icons, cursors, fonts"
  echo "  download gtk                  GTK themes only"
  echo "  download icons                Icon themes only"
  echo "  download cursors              Cursor themes only"
  echo "  download list                 List downloadable resources"
  echo
  echo "Examples:"
  echo "  themes.sh pick                # Interactive — pick from menus"
  echo "  themes.sh profile pick        # Pick a profile interactively"
  echo "  themes.sh set Arc-Dark"
  echo "  themes.sh gtk-set Arc-Dark"
  echo "  themes.sh icon-set Papirus-Dark"
  echo "  themes.sh font-list mono"
  echo "  themes.sh font-preview \"Fira Code\""
  echo "  themes.sh download all"
  echo "  themes.sh download mono"
  echo "  themes.sh download nerd"
  echo "  themes.sh profile apply arc-dark"
  echo "  themes.sh profile create my-theme"
  echo
}

# ---- Dispatch ----
case "$ACTION" in
  list|ls|status)      cmd_list ;;
  set)                 cmd_set "$@" ;;
  override|edit)       cmd_override ;;
  gtk-set|gtk-theme)   cmd_gtk_set "$@" ;;
  gtk-css|css)         cmd_gtk_css ;;
  icon-set|icon)       cmd_icon_set "$@" ;;
  cursor-set|cursor)   cmd_cursor_set "$@" ;;
  font-set|font)       cmd_font_set "$@" ;;
  font-list|font-ls|fonts)
    cmd_font_list "${1:-}"
    ;;
  font-preview|preview-font)
    cmd_font_preview "$@"
    ;;
  profile)             cmd_profile "$@" ;;
  pick|interactive)
    cmd_pick
    ;;
  download|get)
    "$SCRIPT_DIR/download-themes.sh" "$@"
    ;;
  help|--help|-h|*)    cmd_help ;;
esac
