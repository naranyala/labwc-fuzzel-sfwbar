# Lesson: Easing Functions for Smooth UI Transitions

## The Problem

Abrupt changes in brightness, volume, or other values feel jarring. Users expect smooth animated transitions like macOS or Windows.

## The Pattern

Both `ocws-brightness.c` and `ocws-volume.c` implement smooth transitions using **ease-out cubic** easing:

```c
static double ease_out_cubic(double t) {
    return 1.0 - pow(1.0 - t, 3);
}

static void animate_to(int target, int duration_ms) {
    int cur = get_current_value();
    int steps = duration_ms / 8;  // ~8ms per step
    double start_val = (double)cur;
    double end_val = (double)target;

    for (int i = 1; i <= steps; i++) {
        double t = (double)i / steps;
        double eased = ease_out_cubic(t);
        int val = (int)(start_val + (end_val - start_val) * eased + 0.5);
        set_value(val);
        usleep(8000);  // ~8ms between frames = ~120fps
    }
    set_value(target);  // Ensure exact final value
}
```

## How Easing Works

Linear: `f(t) = t` — constant speed, feels mechanical
Ease-out cubic: `f(t) = 1 - (1-t)³` — starts fast, decelerates at end, feels natural

```
Value
  │     ╭──────────── target
  │    ╱
  │   ╱
  │  ╱
  │ ╱
  │╱
  └────────────────── Time
  0%              100%
```

## Timing Parameters

| Tool | Step Duration | Total Duration | Steps |
|---|---|---|---|
| Brightness adjust | 8ms | 100ms | ~12 |
| Brightness set | 8ms | 200ms | ~25 |
| Volume adjust | 10ms | 100ms | ~10 |
| Volume set | 10ms | 200ms | ~20 |

## When to Use Animated Transitions

| Action | Animate? | Why |
|---|---|---|
| Volume change (scroll) | YES | Frequent, small changes feel smooth |
| Volume set (slider) | YES | Large jumps need easing |
| Brightness change | YES | Same as volume |
| Toggle mute | NO | Instant state change, no transition needed |
| Theme switch | DEBATABLE | Could be nice, but complex to implement |
