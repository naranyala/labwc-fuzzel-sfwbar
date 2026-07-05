# Lesson 3: Relative Paths That Only Work From the Project Root

**File affected:** `scripts/actions/workspace-actions.sh`
**Severity:** High — every subcommand silently fails when called from a keybind

---

## What Happened

Every subcommand delegation used paths relative to the current working directory:

```bash
./scripts/actions/audio.sh up 5%
./scripts/actions/brightness.sh down 10%
./scripts/actions/screenshot.sh
```

When labwc fires a keybind, the working directory is usually the user's `$HOME`, not
the project root. So every single `./scripts/...` path resolves to a non-existent
file and the action silently fails with "No such file or directory".

The same issue affected `scripts/actions/dock.sh` being called as a bare word
`scripts/actions/dock.sh` without even the leading `./`.

## The Fix

Resolve an absolute base path from `BASH_SOURCE[0]` at the top of the script, then
use it everywhere:

```bash
ACTIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(dirname "$ACTIONS_DIR")"

# Now all calls are absolute, regardless of cwd
"$ACTIONS_DIR/audio.sh" up 5%
"$ACTIONS_DIR/brightness.sh" down 10%
"$SCRIPTS_DIR/theme-engine.sh" list
```

`BASH_SOURCE[0]` is the path to the currently executing script, even when called
via a symlink in `~/.local/bin/`. `cd && pwd` normalises it to an absolute path
without relying on `realpath` being available.

## Why `$0` Is Not Enough

`$0` is unreliable:
- When sourced: `$0` is the parent shell's name, not the script path.
- When called through a symlink: `$0` may be the symlink path, not the real file.

`BASH_SOURCE[0]` is the actual script file path in all cases.

## The General Rule

> Scripts that call other scripts must **never** use `./` or bare relative paths.
> Always anchor to `BASH_SOURCE[0]`.

```bash
# At the top of every script that delegates to siblings
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Call siblings
"$SCRIPT_DIR/sibling.sh" arg1 arg2
```

## Also Applies To Config Paths

The same bug appears whenever a script assumes a config file is relative to cwd:

```bash
# BAD — only works if you're in the right directory
fuzzel --config ./dotfiles/fuzzel/fuzzel.ini

# GOOD — always works
fuzzel --config "$HOME/.config/fuzzel/fuzzel.ini"
```
