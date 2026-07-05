# Lesson 9: Function Parameters That Shadow Outer Variables — But Silently Use the Wrong Ones

**File affected:** `scripts/playerctl.sh`
**Severity:** Medium — seek functions always use the fallback default, never the caller's value

---

## What Happened

```bash
MODE="${1:-help}"
STEP="${2:--10}"    # outer $2 captured here

seek_forward() {
    local seconds=${2:-10}   # BUG: $2 here is the function's 2nd arg, not the outer $2
    run_playerctl seek "+${seconds}s"
}

seek_backward() {
    local seconds=${2:-10}   # same bug
    run_playerctl seek "-${seconds}s"
}
```

`seek_forward` and `seek_backward` are called with no arguments:

```bash
seek-forward|...) seek_forward "${MODE: -3}" ;;
```

So inside the function, `$1="${MODE: -3}"` and `$2` is empty. `${2:-10}` always
evaluates to the fallback `10`. The caller's `"${MODE: -3}"` value passed as `$1`
is completely ignored.

The intent was probably to use `$1` (the first function arg), not `$2`.

### Secondary Bug: `${MODE: -3}` for extracting the number

```bash
seek-forward|seek+|--10|--30|--60)
    seek_forward "${MODE: -3}"
```

`${MODE: -3}` extracts the last 3 characters of `$MODE`. For `"--10"` that gives
`"-10"`, not `"10"`. Seeking with `seek "+{-10}s"` fails or behaves unexpectedly.

## The Fix

```bash
seek_forward() {
    local seconds="${1:-10}"    # $1 is the first arg TO THIS FUNCTION
    run_playerctl seek "+${seconds}s"
    pass "Seeked forward ${seconds}s"
}

seek_backward() {
    local seconds="${1:-10}"
    run_playerctl seek "-${seconds}s"
    pass "Seeked backward ${seconds}s"
}

# Call site — extract only the digit portion
seek-forward|seek+)
    seek_forward "${STEP#-}"    # strip leading minus from STEP if present
    ;;
```

Or simpler: just use `$STEP` (which already holds `$2` from the outer scope):

```bash
seek-forward)
    seek_forward "${STEP:--10}"
    ;;
```

## The General Rule

> **Inside a function, `$1`, `$2`, `$3` are the function's own positional parameters.**
> They have no relation to the outer script's `$1`, `$2`, `$3`.

```bash
X="$2"        # outer $2

my_func() {
    echo "$2"  # THIS is the 2nd arg to my_func, NOT the outer $2
    echo "$X"  # correct way to access the outer value
}

my_func "a" "b"   # inside: $1="a", $2="b"
my_func            # inside: $1="", $2="" — ${2:-fallback} fires
```

## How to Catch It

Read every function definition and ask:
- "Does this function's `$N` parameter match what the call site actually passes?"
- "Is the fallback default the real intent, or is it masking a missing argument?"

```bash
# List every function that uses $2 or $3 (common source of this bug)
grep -n 'local.*${2' scripts/playerctl.sh
grep -n 'local.*${3' scripts/playerctl.sh
```
