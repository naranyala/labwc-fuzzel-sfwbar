# wlr-randr — Learning Material

> Source: `./sources/wlr-randr` | Upstream: https://gitlab.freedesktop.org/emersion/wlr-randr

---

## What is wlr-randr?

**wlr-randr** is an xrandr-like CLI tool for managing display outputs on wlroots-based
Wayland compositors. It uses the `wlr-output-management` protocol to query and configure
outputs (resolution, position, scale, orientation, on/off).

In OCWS, wlr-randr is used by swayidle to turn off and restore the display on idle.

---

## Usage

```bash
# List all outputs and their current state
wlr-randr

# Turn an output off
wlr-randr --output eDP-1 --off

# Turn an output on
wlr-randr --output eDP-1 --on

# Set resolution and refresh rate
wlr-randr --output eDP-1 --mode 1920x1080@60Hz

# Set scale (HiDPI)
wlr-randr --output eDP-1 --scale 1.5

# Set position (multi-monitor layout)
wlr-randr --output HDMI-A-1 --pos 1920,0

# Set transform (rotation)
wlr-randr --output eDP-1 --transform 90   # rotate 90°
```

### Transforms

| Value | Description |
|-------|-------------|
| `normal` | No rotation |
| `90` | 90° clockwise |
| `180` | 180° |
| `270` | 270° clockwise |
| `flipped` | Horizontal flip |

---

## OCWS Integration

Used in swayidle to blank and restore the display:

```bash
# from dotfiles/labwc/autostart (swayidle config)
swayidle -w \
  timeout 360 'wlr-randr --output eDP-1 --off' \
    resume    'wlr-randr --output eDP-1 --on' \
  ...
```

Also used in `scripts/actions/` for display management quick settings.

---

## Build from Source

```bash
cd sources/wlr-randr
meson build && ninja -C build
sudo ninja -C build install
```

**Dependencies:** meson, wayland
