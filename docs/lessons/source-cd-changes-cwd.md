# Lesson 13: `source`-ing a Script That Calls `cd`

**File affected:** `scripts/workspace-presets.sh` sourced from `scripts/actions/workspace.sh`
**Severity:** Medium — silently changes the calling script's working directory

---

## What Happened

`workspace.sh` sources `workspace-presets.sh` to import its functions:

```bash
# workspace.sh
source_workspace_presets() {
    local preset_script="$PROJECT_DIR/scripts/workspace-presets.sh"
    if [[ -f "$preset_script" ]]; then
        source "$preset_script"
    fi
}
```

But `workspace-presets.sh` contains a bare `cd` at the top level:

```bash
# workspace-presets.sh (top-level code, not inside a function)
cd "$PROJECT_DIR"
```

When `source` is used, the sourced file runs in the **calling shell's environment**.
Any `cd` executed at the top level of the sourced file changes the working directory
of the caller — permanently, for the rest of its execution.

After `source_workspace_presets` returns, `workspace.sh` is now silently running
from `$PROJECT_DIR` instead of wherever it was called from. Any subsequent relative
paths in `workspace.sh` now resolve differently.

## Why This Is Subtle

If you run `source some_script.sh` expecting to import only function definitions,
you implicitly run all top-level code in that file too. Shell scripts don't have
an "import only functions" mechanism — `source` is a wholesale execution.

## The Fix

**Option A:** Remove the bare `cd` from `workspace-presets.sh`. If functions inside
need to reference files relative to `$PROJECT_DIR`, pass it as an argument or use
absolute paths built from `$PROJECT_DIR` directly:

```bash
# workspace-presets.sh — no top-level cd
create_preset() {
    local name="$1"
    # Use $PROJECT_DIR directly, don't cd to it
    local rc_file="$PROJECT_DIR/dotfiles/labwc/rc.xml"
    grep -o '...' "$rc_file"
}
```

**Option B:** If `cd` is truly necessary for the function's logic, do it in a
subshell so it doesn't affect the caller:

```bash
# Changes cwd only inside the subshell
(
    cd "$PROJECT_DIR" || exit 1
    do_something_relative
)
# Back here, cwd is unchanged
```

**Option C:** Guard the sourced file so bare code only runs when executed directly,
not when sourced:

```bash
# workspace-presets.sh
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Running directly — top-level code is safe here
    cd "$PROJECT_DIR"
    main "$@"
fi
# Function definitions below run regardless
```

## The General Rule

> **Files intended to be `source`d must contain only function and variable
> definitions at the top level.** Any executable statements (especially `cd`,
> `exit`, `trap`, `set`) affect the calling shell.

```bash
# BAD source-able file
cd /some/path         # affects caller
export FOO=bar        # affects caller's environment
trap cleanup EXIT     # overrides caller's trap

my_function() { ... }

# GOOD source-able file — only definitions
MY_CONSTANT="value"   # variables are OK
my_function() { ... } # functions are OK
```

## How to Catch It

```bash
# Check for top-level cd in files that are sourced
grep -n '^cd ' scripts/workspace-presets.sh

# Or broader: find cd not inside a function
awk '/^[a-z_]+\(\)/{in_fn=1} /^\}/{in_fn=0} /^cd / && !in_fn{print NR": "$0}' \
    scripts/workspace-presets.sh
```
