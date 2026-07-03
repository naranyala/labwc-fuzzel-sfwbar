# labwc + Zebar + crystal-dock Dotfiles

Starter configuration for [labwc](https://labwc.github.io/) (Wayland compositor), [zebar](https://github.com/nicholasgasior/zebar) (widget tool), and [crystal-dock](https://github.com/nicholasgasior/crystal-dock) (Wayland dock).

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
