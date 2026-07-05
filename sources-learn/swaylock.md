# swaylock — Learning Material

> Source: `./sources/swaylock` | Upstream: https://github.com/swaywm/swaylock

---

## What is swaylock?

**swaylock** is a screen locking utility for Wayland using the `ext-session-lock-v1` protocol.
It takes over all outputs and blocks input until the user authenticates.

In OCWS, swaylock is triggered by swayidle (auto-lock after idle) and the power menu.

---

## Usage

```bash
# Lock with solid black background (most common)
swaylock -f -c 000000

# Lock with a background image
swaylock -f -i ~/Pictures/wallpaper.jpg

# Lock with fill scaling
swaylock -f -i ~/Pictures/wallpaper.jpg -s fill
```

### Key Flags

| Flag | Description |
|------|-------------|
| `-f` | Fork into background after locking |
| `-c COLOR` | Solid background color (hex RRGGBB) |
| `-i IMAGE` | Background image |
| `-s MODE` | Image scaling: fill, fit, stretch, tile, center |
| `--no-unlock-indicator` | Hide the circular indicator |
| `--show-failed-attempts` | Show failed attempt count |

---

## Config File

`~/.config/swaylock/config`:

```ini
color=0f0f19
font=JetBrains Mono
indicator-radius=80
ring-color=7aa2f7
key-hl-color=89b4fa
inside-color=0f0f1988
text-color=cdd6f4
```

---

## OCWS Integration

```bash
# swayidle (autostart) triggers swaylock
swayidle -w \
  timeout 300 'swaylock -f -c 000000' \
  before-sleep 'swaylock -f -c 000000' &
```

---

## Build from Source

```bash
cd sources/swaylock
meson build && ninja -C build
sudo ninja -C build install
```

**Dependencies:** meson, wayland, wayland-protocols, libxkbcommon, cairo, gdk-pixbuf2, pam (optional)

**Without PAM:** `sudo chmod a+s /usr/local/bin/swaylock`
