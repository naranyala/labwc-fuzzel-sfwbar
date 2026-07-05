# Lesson: Missing `set -e` Makes Scripts Silently Continue After Errors

## The Problem

14 shell scripts in this project have **no shell options at all**:

```bash
#!/bin/bash
# No set -e, no set -u, no set -o pipefail
# Every error is silently swallowed
```

When a command in one of these scripts fails (e.g., `mkdir` fails, `curl` times out, `grep` finds nothing), the script just keeps running. Subsequent commands operate on incomplete or wrong data, producing subtle corruption rather than a clear error.

## Root Cause

Bash defaults to "keep going" mode. Without `set -e`, a command's non-zero exit code is simply ignored. This means:

- `mkdir /nonexistent/path` fails → script continues, writes to wrong dir
- `cp missing-file dest` fails → script continues, dest is stale/empty
- `curl -o output https://api.example.com` times out → script continues, output is empty/error

The following scripts are affected:

| File | Line | Issue |
|------|------|-------|
| `scripts/ocws-emit.sh` | none | No options at all |
| `dotfiles/ocws/ocws-daemon.sh` | none | No options at all |
| `scripts/ocws-plugin-loader.sh` | none | No options at all |
| `scripts/start-simple-panel.sh` | none | No options at all |
| `scripts/actions/dock.sh` | none | No options at all |
| `scripts/actions/kvstore.sh` | none | No options at all |
| `scripts/actions/kvstore-cli.sh` | none | No options at all |
| `scripts/actions/fuzzel-emoji.sh` | none | No options at all |
| `scripts/actions/fuzzel-calc.sh` | none | No options at all |
| `scripts/actions/dotfiles-menu.sh` | none | No options at all |
| `scripts/actions/build-kvstore.sh` | none | No options at all |
| `scripts/workspace-presets.sh` | none | No options at all |
| `scripts/playerctl.sh` | none | No options at all |
| `scripts/actions/menu-aesthetics.sh` | none | No options at all |

Another 15 scripts use `set -uo pipefail` but omit `-e`:

| File | Line | Options |
|------|------|---------|
| `scripts/ocws-state.sh` | 7 | `set -uo pipefail` |
| `scripts/ocws-configure.sh` | 7 | `set -uo pipefail` |
| `scripts/ocws-network-bandwidth.sh` | 7 | `set -uo pipefail` |
| `scripts/ocws-media-widget-updater.sh` | 5 | `set -uo pipefail` |
| `scripts/ocws-media-art.sh` | 8 | `set -uo pipefail` |
| `scripts/ocws-fetch-art.sh` | 11 | `set -uo pipefail` |
| `scripts/theme-engine.sh` | 17 | `set -uo pipefail` |

## The Fix

Add `set -euo pipefail` at the top of every script, right after the shebang:

```bash
#!/bin/bash
set -euo pipefail
```

If a specific command is expected to fail, explicitly handle it:

```bash
# Option A: Allow failure, ignore
some_command_that_may_fail || true

# Option B: Allow failure, capture exit code
some_command_that_may_fail || rc=$?

# Option C: Conditionally run
if ! some_command; then
  log "Command failed, continuing..."
fi
```

## Pattern To Remember

Every bash script must start with `set -euo pipefail`. Without `-e`, errors become data corruption. Without `-u`, typos in variable names silently expand to empty strings. Without `pipefail`, pipelines `cmd1 | cmd2` succeed even if `cmd1` fails.
