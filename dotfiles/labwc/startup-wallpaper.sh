#!/bin/bash
# Random wallpaper launcher for labwc
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
img=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | shuf -n 1)
exec swaybg -i "$img" -m fill
