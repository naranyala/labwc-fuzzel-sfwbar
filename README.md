# labwc + Zebar + crystal-dock

Starter configuration for a Wayland desktop environment using:
- **labwc** - Lightweight Wayland compositor (Openbox-inspired)
- **zebar** - HTML/CSS/JS widget tool
- **crystal-dock** - Wayland dock

## Quick Start

```bash
# Build labwc from source
./download-labwc.sh --install

# Install configuration
./dotfiles/install.sh

# Launch from TTY (Ctrl+Alt+F2)
./scripts/start-labwc.sh
```

## What's Included

- **labwc config** - Keybindings, window rules, autostart
- **Zebar widgets** - Main bar, minimalist, compact, detailed, system dashboard
- **Wallpaper manager** - Random rotation, download sources, daemon mode
- **crystal-dock** - Primary dock integration

## Project Structure

```
├── download-labwc.sh        # Build labwc from source
├── scripts/
│   └── start-labwc.sh       # Launch script with checks
├── dotfiles/
│   ├── install.sh           # Installation script
│   ├── labwc/               # labwc config files
│   │   ├── rc.xml           # Keybindings & window rules
│   │   ├── autostart        # Startup commands
│   │   ├── environment      # Environment variables
│   │   └── menu.xml         # Desktop menu
│   ├── zebar/               # Widget HTML files
│   └── wallpaper            # Wallpaper manager
├── config/
│   └── labwc/               # Reference config copies
└── widgets/                 # Enhanced widget themes
```

## Keybindings

| Key | Action |
|-----|--------|
| `Super+Return` | Terminal |
| `Super+D` | App launcher |
| `Super+Q` | Close window |
| `Super+M` | Exit labwc |
| `Super+R` | Reload config |
| `Alt+1-9` | Switch workspace |
| `Print` | Screenshot |

See [docs/configuration.md](docs/configuration.md) for full keybinding reference.

## Documentation

- [Getting Started](docs/getting-started.md)
- [Configuration Guide](docs/configuration.md)

## Requirements

- labwc (build with `./download-labwc.sh` or install via package manager)
- zebar
- crystal-dock
- foot (terminal)
- rofi (launcher)
- swaybg (wallpaper)
