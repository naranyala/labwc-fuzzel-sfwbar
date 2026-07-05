# Lesson 1: Corrupted Function Definitions

**File affected:** `scripts/actions/launcher.sh`
**Severity:** Critical — script fails to load entirely

---

## What Happened

The `run_command` function definition was accidentally broken into two fragments:

```bash
# BROKEN
r 
local cmd="${*:-}"
  if [ -z "$cmd" ]; then
    ...
  fi
}
```

`r` is interpreted as a command (not a function name), and the bare `local` on the
next line is a syntax error outside any function. Bash rejects the entire script at
parse time — none of the other functions in the file work either.

## The Fix

Restore the correct `function_name() {` header on a single line:

```bash
# CORRECT
run_command() {
  local cmd="${*:-}"
  ...
}
```

## How to Catch It Early

```bash
# Always syntax-check scripts before committing
bash -n scripts/actions/launcher.sh
```

A clean parse prints nothing. Any error means the whole script is broken.

Add this to your pre-commit hook or CI:

```bash
find scripts/ -name "*.sh" -exec bash -n {} \; && echo "All scripts OK"
```

## Root Cause Pattern

Copy-paste or editor mishap that truncates the function name while leaving the
body intact. Because the body still looks syntactically plausible (assignments,
if-blocks), no visual scan catches it — only a parse check will.
