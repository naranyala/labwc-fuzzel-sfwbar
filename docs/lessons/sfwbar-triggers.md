# Lesson: Triggers vs Interval for On-Demand Widget Updates

## The Problem

Using `interval` to poll for changes wastes resources when the widget only needs to update in response to a specific event.

## Two Update Mechanisms

### Interval-Based (Polling)

```ini
export button "volume-text" {
  interval = 2000  # Re-read variables every 2 seconds
  label { value = Str(XVolLevel, 0) + "%" }
}
```

Widget re-renders every 2 seconds, even if nothing changed.

### Trigger-Based (Event-Driven)

```ini
export button "media-player" {
  trigger = "media-updated"  # Only re-render when this trigger fires
  label { value = XMediaTitle }
}

# Somewhere else in the config:
scanner {
  exec("playerctl metadata --follow --format '{{ title }}'") {
    XMediaTitle = Grab(First)
    EmitTrigger("media-updated")  # Signal the widget to refresh
  }
}
```

Widget only re-renders when `EmitTrigger("media-updated")` is called.

## How Triggers Work

1. Scanner or action calls `EmitTrigger("event-name")`
2. All widgets with `trigger = "event-name"` re-read their variables and re-render
3. Other widgets are unaffected

## When to Use Each

| Mechanism | Best For | Overhead |
|---|---|---|
| `interval` | Time-varying data (clock, CPU, memory) | Constant polling |
| `trigger` | Event-driven data (media changes, notifications) | Zero when idle |
| Both | Data that changes both on events and over time | Polling + instant events |

## Example: Notification Center

```ini
Private {
  TriggerAction "notification-updated", XNotificationUpdate()
  TriggerAction "notification-removed", XNotificationRemove()

  export button "ncenter" {
    trigger = "notification-group"  # Only update on notification events
    value = XNotificationIcon();
    action = PopUp("XNotificationWindow");
  }
}

# The ncenter module listens for freedesktop notification events
# and calls EmitTrigger("notification-group") when a notification arrives
```

## Rules

1. Use `trigger` when data changes are **sparse and unpredictable** (notifications, media track changes)
2. Use `interval` when data changes are **continuous and predictable** (CPU, clock, volume)
3. Use **both** when you need instant event response PLUS periodic refresh as fallback
4. Trigger names must be unique strings — use descriptive names like `"media-updated"`, `"notification-group"`
