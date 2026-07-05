# gammastep — Learning Material

> Source: `./sources/gammastep` | Upstream: https://gitlab.com/chinstrap/gammastep

---

## What is gammastep?

**gammastep** adjusts your screen's color temperature based on time of day — warmer at night,
cooler during the day — to reduce eye strain. It is a Wayland-compatible fork of Redshift,
using the `wlr-gamma-control` protocol.

In OCWS, gammastep is launched from autostart for always-on day/night color adjustment.

---

## Usage

```bash
# Auto location (uses GeoClue)
gammastep &

# Manual coordinates (latitude:longitude)
gammastep -l 40.7:-74.0 &

# Custom temperature range (day:night in Kelvin)
gammastep -t 6500:3500 &

# With gamma correction
gammastep -t 6500:3500 -g 1.0 &

# One-shot: set temp and exit (no daemon)
gammastep -O 4000

# Reset to neutral
gammastep -x

# Graphical indicator in system tray
gammastep-indicator &
```

### Key Flags

| Flag | Description |
|------|-------------|
| `-l LAT:LON` | Manual coordinates |
| `-t DAY:NIGHT` | Color temperature in Kelvin (default 6500:4500) |
| `-g GAMMA` | Gamma correction (default 1.0) |
| `-b DAY:NIGHT` | Screen brightness adjustment (0.1–1.0) |
| `-O TEMP` | One-shot: set to fixed temperature |
| `-x` | Reset color to neutral |
| `-r` | Disable temperature transitions |

---

## Configuration File

`~/.config/gammastep/config.ini`:

```ini
[general]
location-provider=manual
adjustment-method=wayland

[manual]
lat=40.71
lon=-74.00

[temperature]
day=6500
night=3200

[brightness]
day=1.0
night=0.8

[gamma]
day=1.0
night=0.9
```

---

## OCWS Integration

```bash
# from dotfiles/labwc/autostart
gammastep -t 6500:3500 -g 1.0 -r &
```

The `-r` flag disables the gradual transition (instant switch at sunrise/sunset).
Remove `-r` for a smooth fade effect.

| File | Role |
|------|------|
| `dotfiles/labwc/autostart` | Launches gammastep at session start |
| `scripts/actions/brightness.sh` | May complement brightness with gamma |
| `dotfiles/ocws/nightlight.widget` | Toggle widget that starts/kills gammastep |

---

## Night Light Toggle (OCWS widget)

```bash
# nightlight.widget — toggle gammastep on/off
if pgrep -x gammastep > /dev/null; then
  pkill gammastep && gammastep -x   # kill + reset gamma
else
  gammastep -t 6500:3200 &
fi
```

---

## Build from Source

```bash
cd sources/gammastep
./bootstrap && ./configure --prefix=/usr/local
make && sudo make install
```

**Dependencies:** autoconf, intltool, glib2, wayland, geoclue-2 (optional)
