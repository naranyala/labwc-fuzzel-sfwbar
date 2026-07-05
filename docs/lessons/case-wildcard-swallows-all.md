# Lesson 2: Wildcard `*` in the Wrong Case Arm

**File affected:** `scripts/actions/workspace-actions.sh`
**Severity:** High — all named actions silently fall back to the menu, nothing executes

---

## What Happened

The main dispatch used this pattern:

```bash
MODE="${1:-list}"
shift

case "$MODE" in
    list|ls|help|--help|-h|*)   # <-- the |* here is the bug
        show_fuzzel_menu
        ;;
    *)
        execute_action "$1"     # <-- dead code, never reached
        ;;
esac
```

The `|*` appended to the first arm means "or anything else". Bash evaluates case
arms in order and stops at the first match. Because `*` matches everything, the
second `*)` arm is permanently unreachable — every possible value of `$MODE` hits
the menu instead of executing the intended action.

A secondary bug is also present: after `shift`, the code tries to read `"$1"` again,
but `shift` already advanced `$1` to what was formerly `$2` (or empty).

## The Fix

```bash
MODE="${1:-list}"
shift

case "$MODE" in
    list|ls|help|--help|-h)
        show_fuzzel_menu
        ;;
    *)
        execute_action "$MODE"   # use $MODE, not $1 (which was shifted)
        ;;
esac
```

Key changes:
1. Remove `|*` from the first arm so named values fall through.
2. Pass `$MODE` (captured before the shift) instead of `$1` (which has moved).

## The General Rule

> **Never place `|*` in the middle of a `case` arm list.** `*` is a catch-all and
> must always be the last arm, alone, with no other patterns.

```bash
# BAD
case "$x" in
    foo|bar|*)   echo "foo/bar/anything" ;;  # * eats everything
    baz)         echo "never reached" ;;
esac

# GOOD
case "$x" in
    foo|bar)     echo "foo or bar" ;;
    baz)         echo "baz" ;;
    *)           echo "fallback" ;;
esac
```

## How to Catch It

```bash
# shellcheck flags this as SC2172 / unreachable patterns
shellcheck scripts/actions/workspace-actions.sh
```
