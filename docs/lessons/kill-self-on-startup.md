# Lesson 5: Killing Yourself on Startup

**File affected:** `dotfiles/ocws/ocws-daemon.sh`
**Severity:** High — daemon never starts; it terminates itself immediately every time

---

## What Happened

The daemon's first line was:

```bash
pkill -f "ocws-daemon.sh" 2>/dev/null
sleep 0.1
```

The intent was to kill any *previous* instance before starting fresh. But `pkill -f`
matches against the full command line of every running process. The newly launched
script's own command line contains `"ocws-daemon.sh"` — so it matches itself and
is killed before it does any meaningful work.

The timing is non-deterministic. Sometimes the `pkill` fires fast enough to kill the
new process. Sometimes the race goes the other way. The result is a daemon that works
occasionally, which is the worst kind of bug to debug.

## The Fix

Exclude the current process's PID:

```bash
_MY_PID=$$
pgrep -f "ocws-daemon.sh" 2>/dev/null \
    | grep -v "^${_MY_PID}$" \
    | xargs -r kill 2>/dev/null || true
sleep 0.2
```

`$$` is the PID of the current shell. `grep -v "^${_MY_PID}$"` strips it from the
kill list. `xargs -r` skips `kill` entirely if the list is empty (no previous
instances).

## Alternative: Use a PID File

A PID file is the classic daemon pattern and avoids the race entirely:

```bash
PIDFILE="/tmp/ocws-daemon.pid"

# Kill previous instance if it's still running
if [ -f "$PIDFILE" ]; then
    old_pid=$(cat "$PIDFILE")
    kill "$old_pid" 2>/dev/null || true
    sleep 0.1
fi

# Write our PID
echo $$ > "$PIDFILE"

# Clean up on exit
trap 'rm -f "$PIDFILE"' EXIT INT TERM
```

This is more robust: you only kill the exact PID that the last run recorded.

## The General Rule

> **`pkill -f <scriptname>` always matches the calling script itself.**
> Never use it as the first line of a daemon without excluding `$$`.

```bash
# BAD — kills itself
pkill -f "my-daemon.sh"

# GOOD — excludes self
pgrep -f "my-daemon.sh" | grep -v "^$$" | xargs -r kill

# ALSO GOOD — use a PID file instead
```

## Related: `killall` Has the Same Problem

```bash
# BAD — kills everything named "bash" including the running script
killall bash

# Use process-specific names or PID files instead
```
