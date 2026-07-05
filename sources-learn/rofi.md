# rofi — Learning Material

> Source: `./sources/rofi` | Upstream: https://github.com/DaveDavenport/rofi

---

## What is rofi?

**rofi** is a window switcher, application launcher, and dmenu replacement for Linux.
It supports both X11 and Wayland (via `rofi-wayland` fork). In OCWS, rofi is available
as a **fallback launcher** when fuzzel is not installed or for advanced use cases
that need rofi's richer feature set.

---

## Running

```bash
# Application launcher (default mode)
rofi -show drun

# Window switcher
rofi -show window

# Run dialog (type command)
rofi -show run

# dmenu mode (pipe entries, get selection)
echo -e "Option A\nOption B\nOption C" | rofi -dmenu

# With a prompt
echo -e "yes\nno" | rofi -dmenu -p "Confirm?"
```

---

## Modes

| Mode | Description |
|------|-------------|
| `drun` | Desktop file launcher (apps with .desktop entries) |
| `run` | Free-form command runner |
| `window` | Window switcher (like Alt+Tab) |
| `ssh` | SSH host launcher |
| `filebrowser` | File browser |

---

## Configuration

`~/.config/rofi/config.rasi`:

```css
configuration {
    modi: "drun,run,window";
    show-icons: true;
    icon-theme: "Papirus-Dark";
    terminal: "foot";
    font: "JetBrains Mono 11";
    display-drun: " Apps";
    display-run: " Run";
    display-window: " Windows";
}

configuration /* { */
{
    show-icons:         true;
    terminal:           "foot";
    drun-display-format: "{name}";
}

* {
    bg:       #1e1e2ecc;
    bg-alt:   #313244cc;
    fg:       #cdd6f4;
    accent:   #89b4fa;
    urgent:   #f38ba8;
    selected: #45475acc;

    background-color: transparent;
    text-color:       @fg;
    margin:  0;
    padding: 0;
    spacing: 0;
}

window {
    width:            40%;
    background-color: @bg;
    border:           1px solid selected;
    border-radius:    12px;
    padding:          20px;
}

inputbar {
    padding:    8px 12px;
    spacing:    8px;
    children:   [ prompt, entry ];
}

prompt {
    text-color: @accent;
}

entry {
    placeholder:       "Search...";
    placeholder-color: @fg;
}

listview {
    lines:   8;
    columns: 1;
    spacing: 4px;
    padding: 8px 0 0 0;
}

element {
    padding:    8px 12px;
    border-radius: 8px;
    spacing:    12px;
}

element selected {
    background-color: @selected;
}

element-icon {
    size: 24px;
}

element-text {
    expand:   true;
}
```

---

## Rofi as Fallback Launcher in OCWS

OCWS prefers fuzzel as the primary launcher (faster, Wayland-native, no GTK dependency).
rofi is available as a fallback:

```bash
# Fuzzel is primary
if command -v fuzzel >/dev/null 2>&1; then
    fuzzel
else
    rofi -show drun
fi
```

---

## Advanced rofi Features

### Custom Modes (script mode)
```bash
# Create a custom menu from a script
rofi -show Power -modi "Power:~/.config/rofi/scripts/power-menu.sh"
```

### Icon Support
```bash
# Show app icons
rofi -show drun -show-icons

# Custom icon theme
rofi -show drun -icon-theme "Papirus-Dark"
```

### Multi-select
```bash
# Select multiple entries
echo -e "Item1\nItem2\nItem3" | rofi -dmenu -multi-select -markup-rows
```

### Keyboard Shortcuts (within rofi)

| Key | Action |
|-----|--------|
| `Ctrl+j/k` | Navigate up/down |
| `Ctrl+u` | Clear input |
| `Ctrl+a` | Select all |
| `Enter` | Confirm selection |
| `Escape` | Cancel |

---

## OCWS Integration

| File | Role |
|------|------|
| `dotfiles/rofi/` | OCWS rofi config (glassmorphic theme) |
| `scripts/actions/*.sh` | Scripts using rofi as fallback picker |
| `dotfiles/ocws/clipboard.widget` | Clipboard picker (uses fuzzel, falls back to rofi) |

---

## Build from Source (rofi-wayland)

```bash
git clone https://github.com/DaveDavenport/rofi.git
cd rofi
git checkout wayland
mkdir build && cd build
meson setup -Dwayland=enabled ..
ninja
sudo ninja install
```

**Dependencies:** meson, ninja, wayland, wayland-protocols, pango, cairo, glib, libinput, xcb (optional, for X11)

---

## rofi vs fuzzel

| Feature | fuzzel | rofi |
|---------|--------|------|
| Wayland-native | Yes | Yes (rofi-wayland fork) |
| GTK dependency | No | Yes |
| Startup speed | ~0.1s | ~0.3s |
| Memory usage | ~5MB | ~30MB |
| Icon support | Basic | Full |
| Custom modes | No | Yes (script mode) |
| Window switcher | No | Yes |
| OCWS primary | Yes | No (fallback) |
