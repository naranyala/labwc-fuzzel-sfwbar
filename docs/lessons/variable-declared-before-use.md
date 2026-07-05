# Lesson 11: Referencing a Variable Before It Is Declared

**File affected:** `scripts/ocws-state.sh` — `update_playerctl_state()`
**Severity:** Medium — function always errors out; player state is never written

---

## What Happened

```bash
update_playerctl_state() {
    if [[ $# -ge 8 ]]; then
        local artist="$1" title="$2" album="$3"
        local status="$4" position="$5" length="$6"
        # $7 and $8 are never captured into variables

        local playing=false
        if [[ "$status" == "playing" ]]; then
            playing=true
        fi

        jq -n ... \
              --argjson file_size "$file_size" \   # BUG: $file_size is never set
              '...' > "$PLAYERCTL_STATE_FILE"
    fi
}
```

The function accepts 8 parameters (`$1`–`$8`) but only assigns `$1`–`$6` to named
local variables. `$7` and `$8` are never captured. Then `jq` is called with
`--argjson file_size "$file_size"`, but `$file_size` doesn't exist anywhere in this
scope.

With `set -u` (which this file uses), this is a fatal error: `unbound variable:
file_size`. Without `set -u`, `$file_size` expands to an empty string, which makes
`jq --argjson file_size ""` fail because `""` is not valid JSON.

Either way, the `$PLAYERCTL_STATE_FILE` is never written.

## The Fix

Capture all positional parameters:

```bash
update_playerctl_state() {
    if [[ $# -ge 8 ]]; then
        local artist="$1" title="$2" album="$3"
        local status="$4" position="$5" length="$6"
        local playing_arg="$7"    # was missing
        local file_size="$8"      # was missing — caused the crash

        local playing=false
        if [[ "$status" == "playing" ]]; then
            playing=true
        fi

        jq -n --arg artist "$artist" --arg title "$title" --arg album "$album" \
              --arg status "$status" --argjson position "$position" \
              --argjson length "$length" --argjson playing "$playing" \
              --argjson file_size "$file_size" \
              '{...}' > "$PLAYERCTL_STATE_FILE"
    fi
}
```

## The General Rule

> When a function accepts N parameters, map **all N** to named local variables at
> the top of the function. A mismatch between the number of declared parameters
> and the function signature is a reliable sign of this bug.

```bash
# BAD — $7 and $8 are silently forgotten
process_event() {
    local name="$1" type="$2" value="$3"
    local ts="$4" src="$5" dst="$6"
    # missing: $7 = flags, $8 = priority

    do_something "$flags"   # unbound or empty
}

# GOOD — every parameter is named
process_event() {
    local name="$1" type="$2" value="$3"
    local ts="$4" src="$5" dst="$6"
    local flags="$7" priority="$8"

    do_something "$flags"
}
```

## Companion: Always Count Your Call Sites

When you add a parameter to a function, grep every call site:

```bash
grep -n 'update_playerctl_state' scripts/ocws-state.sh
```

If any call site passes fewer arguments than the function expects, you have a mismatch.

## How to Catch It

```bash
# set -u makes unbound variables fatal — enable it in every script
set -euo pipefail

# shellcheck detects SC2154 (variable referenced but not assigned)
shellcheck scripts/ocws-state.sh
```
