# Lesson: Hardcoded `/tmp` Paths Cause Race Conditions And Stale Files

## The Problem

Build scripts use fixed paths in `/tmp`:

```bash
# build-ocws-core.sh:27
BUILD_DIR="/tmp/ocws-build"
```

If two instances run simultaneously (e.g., CI parallel jobs, or a user runs a build while an update is in progress), they **clobber each other's files**. If an instance crashes, the stale directory is left behind forever.

## Root Cause

Hardcoded `/tmp` paths (not using `mktemp`) create three problems:

1. **Race condition**: Two parallel invocations write to the same directory
2. **Stale data**: A remnant from a prior failed build can confuse a new build
3. **Permission mismatch**: If one user creates `/tmp/ocws-build` as root, an unprivileged user can't clean it up

The same pattern appears in other scripts:

| File | Path | Issue |
|------|------|-------|
| `build-ocws-core.sh:27` | `/tmp/ocws-build` | Race + stale dirs |
| `dotfiles/ocws/ocws-daemon.sh:13` | `/tmp/ocws-state`, `/tmp/ocws-current-song` | Race + no cleanup |
| `scripts/install-fonts.sh:123-126` | `/tmp/inter-font.zip` | No cleanup on failure |
| `scripts/install-fonts-cursors.sh:13-23` | `/tmp/JetBrainsMono.tar.xz`, `/tmp/Bibata.tar.xz` | No cleanup |
| `scripts/ocws-media-widget-updater.sh:36` | `/tmp/ocws-cover-art/*.png` | Race (fixed name) |

## The Fix

Use `mktemp` for all temporary files and directories, and always add a cleanup `trap`:

```bash
# build-ocws-core.sh
BUILD_DIR=$(mktemp -d "/tmp/ocws-build.XXXXXX") || exit 1
trap 'rm -rf "$BUILD_DIR"' EXIT  # Clean up even on failure
```

For the daemon state files, use a PID-based name:

```bash
STATE_FILE="/tmp/ocws-state-$$"  # $$ = current PID, unique per instance
```

Or better, use the user's runtime directory:

```bash
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
STATE_FILE="$RUNTIME_DIR/ocws-state-${USER}"
```

## Verification

```bash
# Find hardcoded /tmp paths in scripts
grep -rn '/tmp/' scripts/ dotfiles/ --include='*.sh' | grep -v 'mktemp'
```

## Pattern To Remember

Never use hardcoded names in `/tmp`. Two invocations will collide. Always use `mktemp` (for files) or `$$` (for PID-unique names), and always add `trap ... EXIT` to clean up. `/tmp` is shared among all users and processes — it's not private workspace.
