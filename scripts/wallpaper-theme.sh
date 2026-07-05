#!/bin/bash
# -------------------------------------------------------------------
# OCWS Wallpaper Theme Generator
# Extracts dominant colors from wallpaper, generates theme INI
# Usage: wallpaper-theme.sh [wallpaper_path]
# -------------------------------------------------------------------

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OCWS_COLOR="$PROJECT_DIR/zig-out/bin/ocws-color"
THEME_DIR="$PROJECT_DIR/themes"

# Find wallpaper
WALLPAPER="${1:-}"
if [[ -z "$WALLPAPER" ]]; then
    # Try to find current wallpaper
    if command -v swaybg >/dev/null 2>&1; then
        WALLPAPER=$(pgrep -a swaybg 2>/dev/null | grep -oP '(?<=-i )\S+' | head -1)
    fi
    if [[ -z "$WALLPAPER" ]]; then
        # Check common wallpaper directories
        for dir in "$HOME/Pictures/wallpapers" "$HOME/.wallpaper" "/usr/share/backgrounds"; do
            if [[ -d "$dir" ]]; then
                WALLPAPER=$(find "$dir" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null | shuf -n 1)
                [[ -n "$WALLPAPER" ]] && break
            fi
        done
    fi
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "Usage: $0 [wallpaper_path]"
    echo "No wallpaper found. Provide a path or set a wallpaper first."
    exit 1
fi

echo "Extracting colors from: $WALLPAPER"

# Extract colors using ocws-color
if [[ -x "$OCWS_COLOR" ]]; then
    COLORS=$("$OCWS_COLOR" "$WALLPAPER" 2>/dev/null)
else
    echo "ocws-color not built yet. Run: zig build"
    echo "Falling back to default Catppuccin Mocha palette."
    COLORS="bg=#1e1e2e fg=#cdd6f4 accent=#89b4fa surface=#313244 border=#45475a"
fi

# Parse extracted colors
BG=$(echo "$COLORS" | grep -oP 'bg=\K[^ ]+' || echo "#1e1e2e")
FG=$(echo "$COLORS" | grep -oP 'fg=\K[^ ]+' || echo "#cdd6f4")
ACCENT=$(echo "$COLORS" | grep -oP 'accent=\K[^ ]+' || echo "#89b4fa")
SURFACE=$(echo "$COLORS" | grep -oP 'surface=\K[^ ]+' || echo "#313244")
BORDER=$(echo "$COLORS" | grep -oP 'border=\K[^ ]+' || echo "#45475a")

echo "Extracted colors:"
echo "  BG:      $BG"
echo "  FG:      $FG"
echo "  Accent:  $ACCENT"
echo "  Surface: $SURFACE"
echo "  Border:  $BORDER"

# Generate theme INI
THEME_NAME="wallpaper-auto"
THEME_FILE="$THEME_DIR/${THEME_NAME}.ini"

cat > "$THEME_FILE" << EOF
[meta]
name = Wallpaper Auto
description = Auto-generated from wallpaper colors
author = ocws-wallpaper-theme

[colors]
bg = $BG
fg = $FG
accent = $ACCENT
surface = $SURFACE
border = $BORDER
urgent = #f38ba8
ok = #a6e3a1
muted = #a6adc8

[ocws]
blur = 5
border = 1
radius = 8
shadow = 4
EOF

echo ""
echo "Theme generated: $THEME_FILE"
echo "Apply with: $SCRIPT_DIR/theme-engine.sh apply $THEME_FILE"
