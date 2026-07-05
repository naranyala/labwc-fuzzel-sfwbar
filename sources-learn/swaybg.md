# swaybg — Learning Material

> Source: `./sources/swaybg` | Upstream: https://github.com/swaywm/swaybg

---

## What is swaybg?

**swaybg** is a minimal wallpaper utility for Wayland. It uses the `wlr-layer-shell` protocol
to render an image (or solid color) as the desktop background on any wlroots-compatible compositor.

In OCWS, swaybg is launched from `dotfiles/labwc/autostart` to set the wallpaper on boot.

**OCWS replacement:** `ocws-wallpaper` (src/ocws-wallpaper.c) is the dynamic wallpaper engine
that replaces swaybg. It provides time-of-day wallpaper transitions with crossfade.

---

## Usage

```bash
# Set a wallpaper image (fill mode)
swaybg -i ~/Pictures/wallpaper.jpg -m fill

# Solid color background
swaybg -c 1a1a2e

# Tile an image
swaybg -i ~/Pictures/tile.png -m tile

# Target a specific output
swaybg -o DP-1 -i ~/Pictures/wallpaper.jpg -m fill
```

### Scale Modes

| Mode | Description |
|------|-------------|
| `stretch` | Scale to fill, ignore aspect ratio |
| `fill` | Scale to fill, crop to maintain aspect ratio |
| `fit` | Scale to fit, letterbox |
| `center` | Center without scaling |
| `tile` | Tile repeatedly |
| `solid_color` | Use `-c` color instead of image |

---

## OCWS Integration

```bash
# from dotfiles/labwc/autostart
WP_DIR="$HOME/Pictures/wallpapers"
WP_FILE=$(find "$WP_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" \) | shuf -n 1)
swaybg -i "$WP_FILE" -m fill &
```

---

## Build from Source

```bash
cd sources/swaybg
meson build/ && ninja -C build/
sudo ninja -C build/ install
```

**Dependencies:** meson, wayland, wayland-protocols, cairo, gdk-pixbuf2 (optional: non-PNG formats)
