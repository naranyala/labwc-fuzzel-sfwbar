# fuzzel — Learning Material

> Source: `./sources/fuzzel` | Upstream: https://codeberg.org/dnkl/fuzzel

---

## What is fuzzel?

**fuzzel** is a Wayland-native application launcher and fuzzy finder, inspired by rofi and dmenu.
It is minimal, performant, pure C, and has zero dependency on GTK or Qt — it renders directly
via Wayland using `pixman`, `cairo`, and `fcft` (font rendering).

In OCWS, fuzzel is used as:
- The **primary app launcher** (Super+Space / launcher button)
- A **dmenu-mode picker** for scripted menus (emoji picker, clipboard, power menu, etc.)
- A **fuzzy calculator** and other interactive script utilities

---

## Key Concepts

### Wayland-native (no XWayland)
fuzzel communicates directly with the Wayland compositor using the
`wlr-layer-shell-unstable-v1` protocol. It renders its own window using shared memory
buffers — no toolkit involved.

### Two Modes

| Mode | Description |
|------|-------------|
| **App launcher** | Reads `.desktop` files from `$XDG_DATA_DIRS/applications/`, fuzzy-searches, launches |
| **dmenu mode** | Reads newline-separated entries from STDIN, returns the selected entry to STDOUT |

### Fuzzy Matching
fuzzel uses fzf-style substring matching. It ranks results by how closely they match,
showing frequency-boosted results (apps you launch often appear higher).

---

## Running fuzzel

```bash
# App launcher (default)
fuzzel

# dmenu mode: pipe input, get selection on stdout
echo -e "Option A\nOption B\nOption C" | fuzzel --dmenu

# With a prompt
echo -e "yes\nno" | fuzzel --dmenu --prompt "Confirm? "

# Execute arbitrary input (don't need a match)
fuzzel --accept-input

# Password mode (hides input)
fuzzel --dmenu --password

# Set lines shown
fuzzel --lines 10

# Horizontal layout
fuzzel --lines 1 --horizontal
```

---

## Configuration File

fuzzel reads `~/.config/fuzzel/fuzzel.ini` (or `$XDG_CONFIG_HOME/fuzzel/fuzzel.ini`).

OCWS provides a themed config at `dotfiles/fuzzel/fuzzel.ini`.

### Full config example:

```ini
[main]
font=JetBrains Mono:size=12
dpi-aware=yes
prompt=  
icon-theme=Papirus-Dark
icons-enabled=yes
fields=name,generic,comment,categories,filename,keywords
lines=10
width=35
horizontal-pad=20
vertical-pad=10
inner-pad=5
image-size-ratio=0.5
action-color=7aa2f7ff
match-mode=fzf

[colors]
background=0f0f19b5            # RRGGBBAA hex
text=cdd6f4ff
match=7aa2f7ff
selection=1a1a2eff
selection-text=cdd6f4ff
selection-match=89b4faff
border=7aa2f766

[border]
width=1
radius=10

[dmenu]
mode=text                      # text or index
```

### Color format
All colors are `RRGGBBAA` hex (8 digits). The last two digits are the alpha channel.
- `ff` = fully opaque
- `b5` = ~71% opacity (translucent)
- `00` = fully transparent

---

## Using fuzzel in OCWS Scripts

### App Launcher (`scripts/actions/launcher.sh`)
```bash
#!/bin/bash
fuzzel
```

### Power Menu
```bash
#!/bin/bash
choice=$(printf "  Shutdown\n  Reboot\n  Suspend\n  Lock\n  Logout" | \
    fuzzel --dmenu --prompt "Power: " --lines 5)

case "$choice" in
    *Shutdown)  systemctl poweroff ;;
    *Reboot)    systemctl reboot ;;
    *Suspend)   systemctl suspend ;;
    *Lock)      swaylock -f ;;
    *Logout)    labwc --exit ;;
esac
```

### Emoji Picker
```bash
#!/bin/bash
# fuzzel-emoji.sh
emoji=$(cat ~/.local/share/emoji.txt | fuzzel --dmenu --prompt "Emoji: ")
echo -n "$emoji" | wl-copy
```

### Clipboard Manager
```bash
#!/bin/bash
# Show clipboard history via cliphist
cliphist list | fuzzel --dmenu --prompt "Clipboard: " | cliphist decode | wl-copy
```

### Fuzzy Calculator
```bash
#!/bin/bash
# fuzzel-calc.sh
# Note: fuzzel doesn't support live previews as you type (unlike rofi-calc).
# It will accept your mathematical expression and pass it to bc on Enter.
result=$(echo "" | fuzzel --dmenu --prompt "calc: " --accept-input)
echo "$result" | bc | wl-copy
```

---

## dmenu Mode Details

dmenu mode (`--dmenu` or invoked as `dmenu`) reads from STDIN:

```bash
# Basic selection
selected=$(printf "alpha\nbeta\ngamma" | fuzzel --dmenu)
echo "You chose: $selected"

# Return index instead of value (0-based)
selected=$(printf "alpha\nbeta\ngamma" | fuzzel --dmenu --index)

# Exact match only (no fuzzy, for multi-stage menus)
selected=$(printf "yes\nno" | fuzzel --dmenu --exact-match)

# Null-separated input
printf "alpha\0beta\0gamma" | fuzzel --dmenu --null-delimited
```

### Rofi Protocol (icons in dmenu mode)
fuzzel supports Rofi's icon protocol in dmenu entries:
```bash
printf "Firefox\0icon\x1ffirefox\nTerminal\0icon\x1futilities-terminal" | \
    fuzzel --dmenu
```

---

## Source Code Structure

```
sources/fuzzel/
├── main.c             # Entry point, argument parsing, mode dispatch
├── application.c/h    # .desktop file parsing and app list
├── match.c/h          # Fuzzy matching algorithm
├── config.c/h         # fuzzel.ini parser
├── render.c/h         # Wayland surface rendering (pixman/cairo)
├── wayland.c/h        # Wayland protocol setup (layer-shell, seat, etc.)
├── key-binding.c/h    # Keyboard input handling
├── dmenu.c/h          # dmenu mode implementation
├── prompt.c/h         # Input prompt handling
├── icon.c/h           # Icon loading and rendering
├── png.c              # PNG icon backend
├── nanosvg.c          # Built-in SVG rendering (nanosvg)
├── clipboard.c/h      # Paste support
├── path.c/h           # $PATH executable listing
├── xdg.c/h            # XDG base dir and .desktop file discovery
├── doc/               # Man page sources (.scd format)
├── test/              # Automated Fish shell tests
└── meson.build        # Build system
```

---

## Build from Source

```bash
cd sources/fuzzel
mkdir -p bld/release && cd bld/release
meson --buildtype=release \
    -Denable-cairo=auto \
    -Dpng-backend=libpng \
    -Dsvg-backend=nanosvg \
    ../..
ninja
sudo ninja install
```

**Runtime dependencies:**
- `pixman`
- `wayland` (client + cursor)
- `xkbcommon`
- `fcft` (font rendering)
- `cairo` (optional, needed for librsvg SVG backend)
- `libpng` (optional, for PNG icons)
- `librsvg` (optional, for high-quality SVG icons)

**Build dependencies:**
- `meson`, `ninja`
- `wayland-protocols`
- `scdoc` (man page generation)

---

## OCWS-Specific Config (`dotfiles/fuzzel/fuzzel.ini`)

OCWS sets fuzzel to match its glassmorphic theme:
- Translucent dark background (`background=1e1e2eb5` — Catppuccin Mocha base + alpha)
- Rounded corners (`radius=10`)
- Catppuccin Mocha colors for text, selection, match highlights
- JetBrains Mono or Noto Sans font
- Icons enabled with Papirus-Dark theme

The theme-engine script regenerates `fuzzel.ini` from `templates/fuzzel.ini.tmpl`
whenever the user switches themes.

---

## Useful References

- Man page: `man fuzzel` and `man fuzzel.ini`
- Source man pages: `sources/fuzzel/doc/fuzzel.1.scd`, `sources/fuzzel/doc/fuzzel.ini.5.scd`
- OCWS launcher scripts: `scripts/actions/launcher.sh`, `scripts/actions/fuzzel-emoji.sh`
- OCWS fuzzel config: `dotfiles/fuzzel/fuzzel.ini`
- OCWS template: `templates/fuzzel.ini.tmpl`
