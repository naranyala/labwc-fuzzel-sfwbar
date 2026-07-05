# ocws-daemon — Background Daemon Learning Material

> Script: `dotfiles/ocws/ocws-daemon.sh`

---

## What is ocws-daemon?

`ocws-daemon.sh` is the background event loop that bridges system state changes to the
OCWS UI. It monitors hardware events (volume keys, battery, brightness, media player,
network, bluetooth) and pushes updates to sfwbar via `ocws-emit`.

Without the daemon, widgets would only update on their polling intervals (2-5 seconds).
With the daemon, updates are instant — volume changes appear in 0ms, not 2000ms.

---

## Architecture

```
Hardware/Software Events
    │
    ├── udev (backlight, battery)
    ├── inotifywait (volume ALSA)
    ├── playerctl --follow (media)
    ├── wpctl subscribe (PipeWire volume)
    └── rfkill event (bluetooth)
    │
    ▼
ocws-daemon.sh (event loop)
    │
    ├── detects change
    ├── reads new value
    └── calls ocws-emit Variable Value
    │
    ▼
sfwbar IPC → Widget Update
```

---

## What It Monitors

| Event Source | Detection Method | Variables Updated |
|-------------|-----------------|-------------------|
| Volume | `wpctl subscribe` / `inotifywait` on ALSA | `XVolLevel`, `XVolMuted` |
| Brightness | udev monitor on `/sys/class/backlight` | `XBrightness` |
| Battery | udev monitor on `/sys/class/power_supply` | `XBatteryLevel`, `XBatteryStatus` |
| Media player | `playerctl --follow --format` | `XMediaTitle`, `XMediaArtist`, `XMediaStatus` |
| WiFi | `iwctl` event or `wpa_cli` | `XNetState` |
| Bluetooth | `rfkill event` | `XBtState` |

---

## Starting the Daemon

```bash
# From dotfiles/labwc/autostart
~/.config/ocws/ocws-daemon.sh &
```

The daemon runs as a background process and survives compositor reloads (via `nohup` or
being re-launched by autostart).

---

## Relationship to ocws-emit

```
ocws-daemon.sh  →  calls  →  ocws-emit.sh  →  pushes  →  sfwbar
(event detector)            (broadcaster)               (UI)
```

The daemon is the "brain" that knows WHEN to send updates.
ocws-emit is the "mouth" that sends them to sfwbar.

---

## Relationship to ocws-sysmon

`ocws-sysmon` is a compiled C binary that reads `/proc/stat`, `/proc/meminfo`,
`/sys/class/backlight`, etc. in one efficient pass and outputs `KEY=VALUE` lines.

`ocws-daemon.sh` handles EVENT-DRIVEN sources (volume key press, media track change)
while `ocws-sysmon.source` handles POLL-DRIVEN sources (CPU usage, memory percentage).

| Approach | Tool | Use Case |
|----------|------|----------|
| Event-driven | ocws-daemon + ocws-emit | Volume, brightness, media, bluetooth |
| Poll-driven | ocws-sysmon.source | CPU, memory, network throughput, disk |

---

## Persistence with ocws-kv

When the compositor restarts, all sfwbar IPC variables are lost.
`ocws-daemon.sh` can save/restore state using `ocws-kv`:

```bash
# Save state on change
ocws-kv set volume.level "$NEW_VOL"
ocws-kv set brightness.percent "$NEW_BRIGHT"

# Restore on startup
VOL=$(ocws-kv get volume.level 2>/dev/null || echo "50")
sfwbar -R "SetVal XVolLevel = $VOL"
```
