# mako — Learning Material

> Source: `./sources/mako` | Upstream: https://github.com/emersion/mako

---

## What is mako?

**mako** is a lightweight notification daemon for Wayland. It implements the
FreeDesktop Notifications Specification over D-Bus — any app that calls `notify-send`
or uses `libnotify` will display toasts through mako.

In OCWS, mako is launched from `dotfiles/labwc/autostart` and styled glassmorphically.

**OCWS replacement:** `ocws-notify` (src/ocws-notify.c) is the C-native notification daemon
that replaces mako. It implements the same D-Bus interface (`org.freedesktop.Notifications`)
with zero GTK dependency. `ocws-osd-notify` adds a glassmorphic popup overlay via gtk-layer-shell.

---

## Running

```bash
mako &
```

Control at runtime with `makoctl`:

```bash
makoctl dismiss          # dismiss topmost
makoctl dismiss --all    # dismiss all
makoctl restore          # restore last dismissed
makoctl mode -s dnd      # do not disturb mode
makoctl reload           # reload config live
```

---

## Configuration

`~/.config/mako/config` — OCWS provides `dotfiles/mako/config`.

```ini
font=JetBrains Mono 11
background-color=#0f0f19b5
text-color=#cdd6f4ff
border-color=#7aa2f766
border-size=1
border-radius=10
width=380
padding=12
margin=10
icon-path=/usr/share/icons/Papirus-Dark
max-icon-size=48
default-timeout=5000
anchor=top-right
markup=1
format=<b>%s</b>\n%b

[urgency=high]
border-color=#f38ba8ff
background-color=#1e0f0fb5
default-timeout=0

[app-name=Spotify]
default-timeout=3000
```

### Key options

| Option | Description |
|--------|-------------|
| `anchor` | Position: `top-right`, `bottom-center`, etc. |
| `default-timeout` | Auto-dismiss ms (0 = never) |
| `layer` | Wayland layer: `overlay`, `top`, `bottom` |
| `max-visible` | Max shown at once (-1 = unlimited) |
| `sort` | Sort order: `+time`, `-time`, `+priority` |

---

## OCWS Integration

| File | Role |
|------|------|
| `dotfiles/labwc/autostart` | `mako &` on session start |
| `dotfiles/mako/config` | Glassmorphic theme styling |
| `scripts/actions/*.sh` | Scripts send toasts via `notify-send` |

```bash
notify-send "Volume" "75%" --icon=audio-volume-high
```

---

## Build from Source

```bash
cd sources/mako
meson setup build && ninja -C build
sudo ninja -C build install
```

**Dependencies:** meson, wayland, pango, cairo, systemd/elogind/basu (sd-bus), gdk-pixbuf (optional)
