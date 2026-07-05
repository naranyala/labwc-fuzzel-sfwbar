# grim + slurp — Learning Material

> Sources: `./sources/grim`, `./sources/slurp`
> Upstreams: https://sr.ht/~emersion/grim, https://github.com/emersion/slurp

---

## What are grim and slurp?

**grim** captures screenshots on Wayland using the `wlr-screencopy` protocol.
**slurp** lets the user interactively select a screen region, printing geometry to stdout.

They are designed to be piped together — slurp selects, grim captures.
In OCWS they power `scripts/actions/screenshot.sh`.

---

## grim

```bash
# All outputs → file
grim ~/Pictures/screenshot.png

# Pipe to stdout
grim -

# Specific output
grim -o HDMI-A-1 ~/Pictures/hdmi.png

# Specific region
grim -g "100,200 800x600" ~/Pictures/region.png

# Region from slurp
grim -g "$(slurp)" ~/Pictures/region.png

# Region → clipboard
grim -g "$(slurp)" - | wl-copy

# JPEG output
grim -t jpeg -q 90 ~/Pictures/screenshot.jpg
```

### grim flags

| Flag | Description |
|------|-------------|
| `-o OUTPUT` | Capture a named output |
| `-g GEOMETRY` | Capture region `"X,Y WxH"` |
| `-t TYPE` | Output format: `png` (default) or `jpeg` |
| `-q N` | JPEG quality (1–100) |
| `-s SCALE` | Scale factor |
| `-c` | Include cursor |

---

## slurp

```bash
# Select a region → prints "X,Y WxH"
slurp

# Select a point
slurp -p

# Select an output → prints output name
slurp -o -f "%o"
```

### slurp flags

| Flag | Description |
|------|-------------|
| `-p` | Point selection mode |
| `-o` | Output selection mode |
| `-f FORMAT` | Output format string |
| `-b COLOR` | Background overlay color (#RRGGBBAA) |
| `-c COLOR` | Selection border color |
| `-d` | Show dimensions in selection box |

---

## OCWS Screenshot Patterns

```bash
# Region → save
grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +'%s').png

# Region → copy
grim -g "$(slurp)" - | wl-copy

# Fullscreen → save + notify
grim ~/Pictures/Screenshots/$(date +'%s').png
notify-send "Screenshot saved" --icon=camera
```

---

## Build from Source

```bash
# grim
cd sources/grim && meson build && ninja -C build
sudo ninja -C build install

# slurp
cd sources/slurp && meson setup build && ninja -C build
sudo ninja -C build install
```
