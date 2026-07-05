# swayidle — Learning Material

> Source: `./sources/swayidle` | Upstream: https://github.com/swaywm/swayidle

---

## What is swayidle?

**swayidle** is an idle management daemon for Wayland. It listens for user inactivity via
the `ext-idle-notify` protocol and fires shell commands on timeout — or before sleep.

In OCWS, swayidle handles auto-lock, display power-off, and pre-sleep locking.

---

## Syntax

```bash
swayidle [options] [events...]
```

Event types:
- `timeout <seconds> <cmd> [resume <cmd>]`
- `before-sleep <cmd>`
- `after-resume <cmd>`
- `lock <cmd>` — triggered by `loginctl lock-session`
- `unlock <cmd>`

---

## OCWS Configuration

```bash
# from dotfiles/labwc/autostart
swayidle -w \
  timeout 300  'swaylock -f -c 000000' \
  timeout 360  'wlr-randr --output eDP-1 --off' \
    resume     'wlr-randr --output eDP-1 --on' \
  before-sleep 'swaylock -f -c 000000' &
```

- 5 min → lock screen
- 6 min → turn off display, restore on resume
- Before suspend → lock immediately

The `-w` flag waits for the lock command to finish before processing further events
(prevents the display turning off before swaylock grabs input).

---

## More Patterns

```bash
# Dim before locking
swayidle -w \
  timeout 240 'brightnessctl -s set 10%' resume 'brightnessctl -r' \
  timeout 300 'swaylock -f' \
  lock 'swaylock -f' \
  unlock 'pkill swaylock'
```

---

## Build from Source

```bash
cd sources/swayidle
meson build/ && ninja -C build/
sudo ninja -C build/ install
```

**Dependencies:** meson, wayland, wayland-protocols, scdoc (optional)
