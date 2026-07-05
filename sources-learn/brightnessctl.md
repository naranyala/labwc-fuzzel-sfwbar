# brightnessctl — Learning Material

> Source: `./sources/brightnessctl` | Upstream: https://github.com/Hummer12007/brightnessctl

---

## What is brightnessctl?

**brightnessctl** reads and controls device brightness on Linux — primarily screen backlight
and keyboard LEDs — without requiring sudo, by using udev rules or systemd-logind.

In OCWS, brightnessctl powers the brightness widget and the brightness action scripts.

**OCWS replacement:** `ocws-brightness` (src/ocws-brightness.c) is the C-native replacement
that provides smooth animated brightness transitions with cubic easing, reads/writes directly
to `/sys/class/backlight/`, and supports `get/set/up/down/min/max/monitor` commands.

---

## Usage

```bash
# Get current brightness (raw value)
brightnessctl get

# Get max brightness
brightnessctl max

# Get info about all devices
brightnessctl --list

# Set absolute value
brightnessctl set 500

# Set percentage
brightnessctl set 50%

# Increase by percentage delta
brightnessctl set +10%

# Decrease by percentage delta
brightnessctl set 10%-

# Save current state (before dimming)
brightnessctl --save set 10%

# Restore saved state
brightnessctl --restore

# Target a specific device
brightnessctl --device=intel_backlight set 50%
```

### Flags

| Flag | Description |
|------|-------------|
| `-d`, `--device=NAME` | Target device (wildcard ok) |
| `-c`, `--class=CLASS` | Device class (backlight, leds) |
| `-l`, `--list` | List all controllable devices |
| `-q`, `--quiet` | Suppress output |
| `-m`, `--machine-readable` | Output in `device,class,value,max,percent` format |
| `-e`, `--exponent[=K]` | Exponential brightness curve |
| `-s`, `--save` | Save state before change |
| `-r`, `--restore` | Restore saved state |

---

## OCWS Integration

```bash
# from scripts/actions/brightness.sh
brightnessctl set +5%    # increase
brightnessctl set 5%-    # decrease

# Value for widget display
CURRENT=$(brightnessctl -m | cut -d',' -f4)  # percentage
ocws-emit System.Brightness "$CURRENT"
```

| File | Role |
|------|------|
| `scripts/actions/brightness.sh` | Keybind-triggered brightness up/down |
| `dotfiles/ocws/` | Brightness percentage displayed via ocws-emit |
| `dotfiles/labwc/rc.xml` | `XF86MonBrightnessUp/Down` keybinds |

---

## Permissions

By default, brightnessctl installs udev rules to allow members of the `video` group
to control backlight devices without sudo:

```bash
sudo usermod -aG video $USER
```

---

## Build from Source

```bash
cd sources/brightnessctl
./configure && make
sudo make install
```
