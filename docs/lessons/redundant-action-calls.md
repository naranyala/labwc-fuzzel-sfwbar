# Lesson 10: Redundant Action Calls — Doing the Same Thing Twice

**File affected:** `scripts/playerctl.sh`
**Severity:** Medium — `play` and `pause` commands issue two playerctl calls instead of one

---

## What Happened

```bash
main() {
    case "$MODE" in
        play|pause|stop)
            play_pause          # <-- always toggles play/pause
            if [[ "$MODE" == "play" ]]; then play       # <-- then explicitly plays
            elif [[ "$MODE" == "pause" ]]; then pause   # <-- or explicitly pauses
            else stop
            fi
            ;;
```

When `MODE=play`, the code:
1. Calls `play_pause` → `playerctl play-pause` (toggles)
2. Then calls `play` → `playerctl play` (plays again)

If the player was already playing, step 1 pauses it, then step 2 immediately plays
it again — net result is no change, but with two IPC round-trips.

If the player was paused, step 1 plays it, then step 2 plays it again (no-op, but
still wasteful).

The `play_pause` call was clearly copied from the `play-pause` branch and left in
by mistake. The `play|pause|stop` branch should call only the specific action:

## The Fix

```bash
main() {
    case "$MODE" in
        play)
            play
            ;;
        pause)
            pause
            ;;
        stop)
            stop
            ;;
        play-pause)
            play_pause
            ;;
```

## The General Pattern

This is the "action + redundant side-effect" pattern:

```bash
# BAD — the outer action is a superset of the inner ones
case "$MODE" in
    a|b|c)
        do_all_three   # runs regardless of which branch
        if [[ "$MODE" == "a" ]]; then do_a; fi
        if [[ "$MODE" == "b" ]]; then do_b; fi
        ;;
```

Should be:

```bash
# GOOD — each branch does exactly what it says
case "$MODE" in
    a)  do_a ;;
    b)  do_b ;;
    c)  do_c ;;
```

## Secondary: the `play_pause` Function Name Is Misleading

`play_pause` runs `playerctl play-pause` (a toggle). But it reads like "play and
pause at the same time." A clearer name is `toggle_playback` or `play_pause_toggle`.
Misleading function names are a common reason copy-paste bugs like this survive code
review — the reader assumes it's doing something it isn't.

## How to Catch It

Look for `case` arms that call a function before dispatching into per-branch logic:

```bash
grep -A 10 'case "\$MODE"' scripts/playerctl.sh
```

If a function call appears before the `if/elif` chain inside a `case` arm, ask:
"Is this call intentional, or was it copied from a sibling branch?"
