# Getting Started with labwc + sfwbar + crystal-dock

## Prerequisites

- **labwc** - Lab Wayland Compositor ([build from source](../download-labwc.sh) or install via package manager)
- **sfwbar** - GTK3 Wayland-native statusbar/taskbar panel (primary panel/statusbar)
- **crystal-dock** - Wayland dock
- **foot** - Wayland terminal
- **rofi** - Application launcher
- **swaybg** - Wallpaper setter

## Quick Install

```bash
# 1. Build labwc from source (if not installed)
./download-labwc.sh --install

# 2. Install dotfiles
./dotfiles/install.sh

# 3. Launch from TTY (Ctrl+Alt+F2, then login)
./scripts/start-labwc.sh
```

## Step-by-Step Setup

### 1. Install labwc

**From source:**
```bash
./download-labwc.sh --install
```

**Or via package manager:**
```bash
# Debian/Ubuntu
sudo apt install labwc

# Arch
sudo pacman -S labwc

# Fedora
sudo dnf install labwc
```

### 2. Install Dependencies

```bash
# Required
sudo apt install swaybg foot rofi

# Optional (for full experience)
sudo apt install crystal-dock grim slurp wl-copy playerctl wpctl mako
```

### 3. Install Configuration

```bash
./dotfiles/install.sh
```

This copies:
- `rc.xml` → `~/.config/labwc/rc.xml` (keybindings, window rules)
- `autostart` → `~/.config/labwc/autostart` (startup commands)
- `environment` → `~/.config/labwc/environment` (env vars)
- `menu.xml` → `~/.config/labwc/menu.xml` (desktop menu)
- SFWBar config → `~/.config/sfwbar/` (sfwbar.config, CSS, widget files)
- GTK settings → `~/.config/gtk-3.0/` and `~/.config/gtk-4.0/`
- Scripts → `~/.local/bin/` (including actions/)
- Wallpaper script → `~/.local/bin/wallpaper`

### 4. Launch labwc

**From TTY:**
```bash
# Switch to TTY: Ctrl+Alt+F2
# Login and run:
./scripts/start-labwc.sh
```

**From display manager:**
Log out and select "labwc" from your login screen.

## What Gets Installed

| Component | Config Location | Purpose |
|-----------|----------------|---------|
| labwc | `~/.config/labwc/` | Compositor config |
| sfwbar | `~/.config/sfwbar/` | Statusbar/taskbar/panel |
| crystal-dock | autostart | Primary dock |
| wallpaper | `~/.local/bin/wallpaper` | Wallpaper manager |

## Verifying Installation

```bash
# Check labwc is installed
labwc --version

# Check config exists
ls ~/.config/labwc/

# Check autostart has crystal-dock and sfwbar
grep -E "crystal-dock|sfwbar" ~/.config/labwc/autostart
```

## Customizing

### Keybindings
Edit `~/.config/labwc/rc.xml`. See [configuration.md](configuration.md) for keybinding reference.

### Autostart
Edit `~/.config/labwc/autostart` to add/remove startup programs.

### Statusbar
Edit `~/.config/sfwbar/sfwbar.config` to customize the statusbar layout and widgets.

### GTK Themes
Theme profiles are in `dotfiles/gtk/theme-profiles/`. Use `theme-picker` to switch themes.

### Wallpaper
```bash
wallpaper random    # Set random wallpaper
wallpaper sync      # Download wallpapers from sources
wallpaper set PATH  # Set specific wallpaper
wallpaper daemon    # Auto-rotate wallpapers
```

## Troubleshooting

### labwc won't start
- Make sure you're on a TTY, not inside another Wayland session
- Check dependencies: `labwc --version`
- Check config syntax: validate `rc.xml` with `xmllint --noout ~/.config/labwc/rc.xml`

### crystal-dock not appearing
- Check it's in autostart: `grep crystal-dock ~/.config/labwc/autostart`
- Launch manually: `crystal-dock --start --overlay`

### SFWBar not appearing
- Check sfwbar is installed: `sfwbar --version`
- Check config exists: `ls ~/.config/sfwbar/`
- Start manually: `sfwbar &`

## References

- [labwc documentation](https://labwc.github.io/)
- [labwc getting started](https://labwc.github.io/getting-started.html)
- [configuration guide](configuration.md)
