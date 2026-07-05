# Lesson: Widget Interval vs Scanner Step Are Independent

## The Problem

Widgets have an `interval` property and scanners have a `step` property. These control different things and are often confused.

## Two Timing Systems

### Scanner `step` — How Often Data Is Fetched

```ini
scanner {
  step = 2000  # Poll every 2 seconds
  exec("/bin/sh -c 'wpctl get-volume @DEFAULT_SINK@ 2>/dev/null'") {
    XVolRaw = Grab(First)
    XVolLevel = Val(RegEx("Volume: ([0-9.]+)", XVolRaw)) * 100
  }
}
```

`step` controls how often the `exec()` command runs. The scanner runs independently of any widget.

### Widget `interval` — How Often the Widget Refreshes

```ini
export button "volume-text" {
  interval = 2000  # Refresh display every 2 seconds
  label { value = Str(XVolLevel, 0) + "%" }
}
```

`interval` controls how often the widget re-reads its variables and re-renders.

## How They Interact

```
Scanner (step=2000ms)          Widget (interval=2000ms)
┌─────────────────┐            ┌─────────────────┐
│ T+0s: exec → XVolLevel=75  │ T+0s: display 75%│
│ T+2s: exec → XVolLevel=80  │ T+2s: display 80%│
│ T+4s: exec → XVolLevel=80  │ T+4s: display 80%│
└─────────────────┘            └─────────────────┘
```

- If `interval` < `step`: Widget refreshes faster than data updates → sees same value multiple times
- If `interval` > `step`: Data updates faster than widget renders → some updates are missed
- If `interval` = `step`: Best case — each data update triggers one widget refresh

## Common Mistakes

### Mistake 1: Setting widget interval without a scanner

```ini
# This widget reads XVolLevel but has no local scanner
# and no include() for the scanner source
export button "volume-text" {
  interval = 2000
  label { value = Str(XVolLevel, 0) + "%" }  # XVolLevel is never set!
}
```

**Fix**: Include the scanner source or add a local scanner block.

### Mistake 2: Scanner step too fast

```ini
scanner {
  step = 100  # Polls every 100ms — wasteful for battery status
  exec("cat /sys/class/power_supply/BAT0/capacity") {
    XBatLvl = Val(Grab(First))
  }
}
```

**Fix**: Battery changes slowly. Use `step = 5000` or higher.

### Mistake 3: Widget interval too slow for real-time data

```ini
scanner {
  step = 2000  # Network rates update every 2s
}
export button "network-bandwidth" {
  interval = 10000  # Widget only refreshes every 10s — misses updates
  label { value = Str(XNetRateRx, 0) + " KB/s" }
}
```

**Fix**: Set widget `interval` ≤ scanner `step`.

## Rules of Thumb

| Data Type | Scanner Step | Widget Interval |
|---|---|---|
| Clock/time | 1000ms | 1000ms |
| Volume/brightness | 2000ms | 2000ms |
| CPU/memory | 2000ms | 2000ms |
| Battery | 5000ms | 5000ms |
| Network rates | 2000ms | 2000ms |
| Temperature | 3000ms | 3000ms |
| Weather | 600000ms | 600000ms |
