# labwc + sfwbar + crystal-dock Dotfiles

Starter configuration for [labwc](https://labwc.github.io/) (Wayland compositor), [sfwbar](https://github.com/LBCrion/sfwbar) (GTK3-native statusbar), and [crystal-dock](https://github.com/nicholasgasior/crystal-dock) (Wayland dock).

## Directory Structure

```
dotfiles/
├── install.sh              # Installation script
├── wallpaper               # Wallpaper manager script
├── wallpaper-sources.txt   # Wallpaper download sources
├── labwc/                  # labwc configuration
│   ├── rc.xml              # Keybindings, window rules, themes
│   ├── autostart           # Startup commands (shell script)
│   ├── environment         # Environment variables
│   ├── menu.xml            # Root menu
│   ├── themerc-override    # Theme overrides
│   ├── startup-wallpaper.sh
│   └── presets/            # Keybinding presets
├── sfwbar/                 # sfwbar statusbar config (default panel)
│   ├── sfwbar.config       # Main config
│   ├── sfwbar-simple.config
│   ├── catppuccin-mocha.css
│   ├── cpu-text.widget
│   ├── memory-text.widget
│   ├── network-text.widget
│   ├── volume-text.widget
│   └── battery-text.widget
├── gtk/                    # GTK3/GTK4 theme configuration
│   ├── gtk3-settings.ini
│   ├── gtk4-settings.ini
│   ├── gtk.css
│   └── theme-profiles/     # 7 GTK theme profiles
├── zebar/                  # Zebar widget files (legacy fallback)
│   ├── main/
│   ├── launcher.sh
│   └── widgets/
└── crystal-dock/           # Crystal dock config (empty, uses defaults)
```

## Quick Start

```bash
# Install all dotfiles
./dotfiles/install.sh

# Launch labwc from TTY
./scripts/start-labwc.sh
```

## labwc Configuration

The labwc config is in `dotfiles/labwc/`. It uses XML format (Openbox-compatible):

- **rc.xml** - Keybindings, window rules, themes, menus
- **autostart** - Shell script run at startup (starts sfwbar, crystal-dock, wallpaper)
- **environment** - Environment variables
- **menu.xml** - Right-click desktop menu
- **themerc-override** - Theme customization

### Key Keybindings

| Key | Action |
|-----|--------|
| `Super+Return` | Terminal (foot) |
| `Alt+D` | App launcher (rofi) |
| `Super+Q` | Close window |
| `Super+M` | Exit labwc |
| `Super+R` | Reload config |
| `Alt+1-9` | Switch workspace |
| `Ctrl+Alt+Arrows` | Window snapping |
| `Print` | Screenshot (area) |

## SFWBar Statusbar

sfwbar is the default statusbar, configured in `dotfiles/sfwbar/`. The main config (`sfwbar.config`) includes workspace pager, clock, system tray, and text widgets for CPU, memory, network, volume, and battery.

### Widget Files

- **cpu-text.widget** - CPU usage percentage
- **memory-text.widget** - Memory usage percentage
- **network-text.widget** - WiFi/Ethernet status
- **volume-text.widget** - Volume level with mute detection
- **battery-text.widget** - Battery percentage

## crystal-dock Integration

crystal-dock is configured as the primary dock in the autostart file:

```bash
crystal-dock --start --overlay
```

It provides application launching and dock functionality at the bottom of the screen.

## Wallpaper

The wallpaper script supports random selection, syncing from sources, and daemon mode:

```bash
wallpaper random    # Set random wallpaper
wallpaper sync      # Download from wallpaper-sources.txt
wallpaper daemon    # Auto-rotate every hour
wallpaper set PATH  # Set specific wallpaper
```
dotfiles/
├── install.sh              # Installation script
├── wallpaper               # Wallpaper manager script
├── wallpaper-sources.txt   # Wallpaper download sources
├── labwc/                  # labwc configuration
│   ├── rc.xml              # Keybindings, window rules, themes
│   ├── autostart           # Startup commands (shell script)
│   ├── environment         # Environment variables
│   ├── menu.xml            # Root menu
│   ├── themerc-override    # Theme overrides
│   └── startup-wallpaper.sh
└── zebar/                  # Zebar widget files
    ├── main/               # Main status bar
    │   ├── index.html
    │   └── style.css
    ├── launcher.sh         # Widget launcher script
    └── widgets/            # Additional widget themes
        ├── compact/
        ├── detailed/
        ├── minimalist/
        └── system/
```

## Quick Start

```bash
# Install all dotfiles
./dotfiles/install.sh

# Launch labwc from TTY
./scripts/start-labwc.sh
```

## labwc Configuration

The labwc config is in `dotfiles/labwc/`. It uses XML format (Openbox-compatible):

- **rc.xml** - Keybindings, window rules, themes, menus
- **autostart** - Shell script run at startup (starts crystal-dock, zebar, wallpaper)
- **environment** - Environment variables
- **menu.xml** - Right-click desktop menu
- **themerc-override** - Theme customization

### Key Keybindings

| Key | Action |
|-----|--------|
| `Super+Return` | Terminal (foot) |
| `Super+D` | App launcher (rofi) |
| `Super+Q` | Close window |
| `Super+M` | Exit labwc |
| `Super+R` | Reload config |
| `Alt+1-9` | Switch workspace |
| `Super+Alt+Arrow` | Swap windows |
| `Print` | Screenshot (grim + slurp) |

## Zebar Widgets

Widget HTML files are in `dotfiles/zebar/widgets/`. Each widget is a standalone HTML file that zebar renders as a panel.

### Widget Types

- **main** - Classic status bar with clock, CPU, memory, battery
- **minimalist** - Minimal gradient design
- **compact** - Space-optimized single-line bar
- **detailed** - 3x2 grid with comprehensive system info
- **system** - Full dashboard with all metrics

### Using Widgets

```bash
# Start all configured widgets
zebar startup

# Launch specific widget
zebar start-widget main
zebar start-widget minimalist
```

## crystal-dock Integration

crystal-dock is configured as the primary dock in the autostart file:

```bash
crystal-dock --start --overlay
```

It provides application launching and dock functionality while zebar handles status widgets.

## Wallpaper

The wallpaper script supports random selection, syncing from sources, and daemon mode:

```bash
wallpaper random    # Set random wallpaper
wallpaper sync      # Download from wallpaper-sources.txt
wallpaper daemon    # Auto-rotate every hour
wallpaper set PATH  # Set specific wallpaper
```
