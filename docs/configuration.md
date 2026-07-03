# labwc Configuration Guide

This guide covers configuring labwc (Lab Wayland Compositor) with sfwbar and crystal-dock.

## Configuration Files

labwc uses six configuration files in `~/.config/labwc/`:

| File | Purpose |
|------|---------|
| `rc.xml` | Keybindings, window rules, themes, menus |
| `autostart` | Commands run at compositor startup (shell script) |
| `environment` | Environment variables |
| `menu.xml` | Right-click desktop menu |
| `themerc-override` | Theme customizations |
| `shutdown` | Commands run on shutdown |

## Quick Start

```bash
# Install configs from this repo
./dotfiles/install.sh

# Launch from TTY
./scripts/start-labwc.sh
```

## Keybindings (rc.xml)

Default keybindings are defined in `rc.xml`. Key format: `A-` = Alt, `S-` = Super, `C-` = Ctrl.

### System
| Key | Action |
|-----|--------|
| `S-r` | Reload config |
| `S-q` / `A-F4` | Close window |
| `S-m` | Exit labwc |

### Launchers
| Key | Action |
|-----|--------|
| `A-Return` | Terminal (foot) |
| `A-d` | App launcher (rofi) |

### Window Management
| Key | Action |
|-----|--------|
| `A-e` | Toggle floating |
| `A-f` | Toggle fullscreen |
| `S-a` | Toggle maximize |
| `A-space` | Root menu |

### Focus
| Key | Action |
|-----|--------|
| `A-Left/Right/Up/Down` | Focus direction |

### Window Movement
| Key | Action |
|-----|--------|
| `S-A-Left/Right/Up/Down` | Swap windows |
| `S-Left/Right/Up/Down` | Resize windows |

### Desktops (Workspaces)
| Key | Action |
|-----|--------|
| `A-1` to `A-9` | Switch to desktop 1-9 |
| `S-A-1` to `S-A-9` | Send window to desktop 1-9 |

### Gaps
| Key | Action |
|-----|--------|
| `A-,` | Increase gaps |
| `A-.` | Decrease gaps |

### Media
| Key | Action |
|-----|--------|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Toggle mute |
| `XF86AudioPlay` | Play/pause |
| `XF86AudioNext` | Next track |
| `XF86AudioPrev` | Previous track |

## Autostart

The `autostart` file is a shell script that runs at startup:

```sh
#!/bin/sh
# Wallpaper
wallpaper random &

# crystal-dock
crystal-dock --start --overlay &

# SFWBar (primary panel/statusbar/taskbar)
sfwbar &

# Notification daemon
mako &
```

## Environment

The `environment` file sets variables before labwc starts:

```
XDG_CURRENT_DESKTOP=labwc
XDG_SESSION_TYPE=wayland
QT_QPA_PLATFORM=wayland
GDK_BACKEND=wayland
XCURSOR_SIZE=24
```

## Window Rules

Add window rules in `rc.xml`:

```xml
<applications>
  <application class="foot">
    <fixed_position>no</fixed_position>
  </application>
  <application class="crystal-dock">
    <skip_taskbar>yes</skip_taskbar>
    <fixed_position>yes</fixed_position>
  </application>
</applications>
```

## Menus

The root menu is defined in `menu.xml`:

```xml
<labwc_menu>
  <item label="Terminal">
    <action name="Execute"><command>foot</command></action>
  </item>
  <item label="Rofi Launcher">
    <action name="Execute"><command>rofi -show drun</command></action>
  </item>
  <separator/>
  <item label="Exit labwc">
    <action name="Exit"/>
  </item>
</labwc_menu>
```

## Theming

labwc uses Openbox themes. Place themes in `~/.local/share/themes/<theme>/labwc/`.

Override specific values in `themerc-override`:

```
activetextfont=sans 10
activebg=#2d2d2d
activetext=#d4d4d4
border.width=1
border.color=#3c3c3c
titlebar.height=28
```

## Reloading Configuration

```bash
# Reload config and theme
labwc --reconfigure

# Or use keybinding
# Default: SUPER+R
```

## SFWBar Statusbar

SFWBar is the primary panel/statusbar/taskbar, configured in `~/.config/sfwbar/`:

```bash
# Start SFWBar (runs at startup via autostart)
sfwbar &

# Start with minimal config
sfwbar -c ~/.config/sfwbar/sfwbar-simple.config
```

SFWBar config files:
- `~/.config/sfwbar/sfwbar.config` — Main config with all widgets
- `~/.config/sfwbar/catppuccin-mocha.css` — GTK CSS theme
- `~/.config/sfwbar/*.widget` — Individual widget files

## crystal-dock Integration

crystal-dock is the primary dock, configured in autostart:

```bash
crystal-dock --start --overlay
```

## Troubleshooting

### Config validation
```bash
# Check XML syntax
xmllint --noout ~/.config/labwc/rc.xml

# Reload after changes
labwc --reconfigure
```

### Common issues
- **No decorations**: Check `<decoration>server</decoration>` in rc.xml
- **Keybindings not working**: Verify XKB key names in rc.xml
- **Autostart not running**: Make sure `~/.config/labwc/autostart` is executable

## References

- [labwc documentation](https://labwc.github.io/)
- [labwc wiki](https://github.com/labwc/labwc/wiki)
- [Openbox theme specification](https://github.com/labwc/labwc-scope)
