# Lesson: autostart Ordering Matters

## The Problem

The labwc `autostart` script launches services in sequence. Services have implicit dependencies on each other. Wrong ordering causes silent failures.

## Dependency Chain

```
DBus environment setup
    ↓
Wallpaper
    ↓
sfwbar (reads config, starts scanners)
    ↓
ocws-daemon.sh (pushes IPC to sfwbar)
    ↓
Notification daemon
Clipboard manager
Screen protection
Keyring daemon
    ↓
Idle locker (uses swaylock, needs keyring)
```

## Why Order Matters

### 1. DBus Must Come First

```sh
# DBus environment MUST be set before any app that uses portals
dbus-update-activation-environment --systemd --all
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
```

Without this, `xdg-desktop-portal` and screen sharing fail silently.

### 2. sfwbar Before ocws-daemon

```sh
nohup sfwbar -f "$HOME/.config/ocws/ocws.config" > /dev/null 2>&1 &
# ...
"$OCWS_DAEMON" &  # Must come after sfwbar — it sends IPC to sfwbar
```

If `ocws-daemon.sh` starts before sfwbar, `sfwbar -R "SetVal ..."` fails because there's no sfwbar instance to connect to.

### 3. Kill Before Restart

```sh
pkill -x sfwbar 2>/dev/null
sleep 0.2
nohup sfwbar -f "$HOME/.config/ocws/ocws.config" > /dev/null 2>&1 &
```

The `sleep 0.2` ensures the old sfwbar process has fully exited before starting a new one. Without it, the new instance might fail to bind to the layer shell.

### 4. Clipboard After sfwbar

```sh
pkill -f "wl-paste.*cliphist" 2>/dev/null || true
pkill -f "wl-paste.*watch" 2>/dev/null || true
sleep 0.1
wl-paste --type text/plain --watch cliphist store 2>/dev/null &
```

Stale `wl-paste` processes from a previous compositor session must be killed first, or clipboard history breaks.

## Common Failures

| Symptom | Likely Cause |
|---|---|
| sfwbar has no icons | DBus not set up, or icon theme not loaded |
| Volume widget shows 0% | `ocws-daemon.sh` started before sfwbar |
| Clipboard doesn't persist | `wl-paste` started before `cliphist` |
| Screen doesn't lock | `swayidle` started before `swaylock` is available |
| Notification popup missing | `mako`/`dunst` started before DBus |
