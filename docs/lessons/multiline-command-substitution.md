# Lesson 15: Unquoted Line Continuation in Command Substitution

**File affected:** `scripts/actions/clipboard.sh`
**Severity:** High — `select_and_paste` always fails; fuzzel is never invoked

---

## What Happened

```bash
select_and_paste() {
  if command -v cliphist &>/dev/null; then
    local selected
    if command -v fuzzel &>/dev/null; then
      selected=$(cliphist list | fuzzel --dmenu --theme="$HOME/.config/fuzzel/fuzzel.ini" 
          --prompt "Clipboard" --placeholder "Search clipboard history..." 
          --match-mode="fuzzy" --width 400 --height 300)
```

The command substitution `$(...)` spans three visual lines, but there are no
continuation backslashes (`\`). In bash, a newline inside `$(...)` terminates the
command — it does **not** automatically continue to the next line.

So the shell sees:
```
fuzzel --dmenu --theme="..." 
```
then a newline, which ends the fuzzel command. The remaining two lines:
```
    --prompt "Clipboard" --placeholder "..." 
    --match-mode="fuzzy" --width 400 --height 300
```
are parsed as a new command at the top level of the function body — bare words that
are not a valid command. The whole function body fails to parse.

With `set -euo pipefail`, the script exits. Without it, `selected` is empty and
the paste silently does nothing.

## The Fix

Add backslash line continuations inside the command substitution:

```bash
selected=$(cliphist list | fuzzel --dmenu \
    --theme="$HOME/.config/fuzzel/fuzzel.ini" \
    --prompt "Clipboard" \
    --placeholder "Search clipboard history..." \
    --match-mode="fuzzy" \
    --width 400 \
    --height 300)
```

Or put it on one line:

```bash
selected=$(cliphist list | fuzzel --dmenu --theme="$HOME/.config/fuzzel/fuzzel.ini" --prompt "Clipboard" --width 400 --height 300)
```

## The General Rule

> Inside `$(...)`, `$(( ))`, `[[ ]]`, and `(( ))`, **newlines end the current
> command.** They do NOT automatically continue the command on the next line.
> You must use `\` to continue, or keep the command on one line.

```bash
# BAD — newline terminates the command early
result=$(some-command --flag-one
    --flag-two
    --flag-three)

# GOOD — explicit continuation
result=$(some-command --flag-one \
    --flag-two \
    --flag-three)

# ALSO GOOD — single line
result=$(some-command --flag-one --flag-two --flag-three)
```

This also applies to pipelines:

```bash
# BAD — pipe on next line is a new command, not a continuation
result=$(grep "pattern" file
    | sort
    | head -5)

# GOOD — pipe at end of line continues
result=$(grep "pattern" file \
    | sort \
    | head -5)

# ALSO GOOD — pipe at start with backslash
result=$(grep "pattern" file |
    sort |
    head -5)   # trailing pipe continues the expression — no backslash needed
```

## How to Catch It

```bash
bash -n scripts/actions/clipboard.sh
# Syntax errors from unintended line breaks appear here

shellcheck scripts/actions/clipboard.sh
# SC1078: double-quote mismatch, SC1079: unexpected token
```

Also: any `$(` with a multi-line body that lacks `\` at every non-final line is
a candidate for this bug.
