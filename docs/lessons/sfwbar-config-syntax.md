# Lesson: sfwbar Config Syntax Is Not Bash

## The Problem

sfwbar config files (`.widget`, `.config`, `.source`) look similar to shell scripts but use a **completely different syntax**. Mixing bash constructs into sfwbar config causes silent failures or parse errors.

## What sfwbar Supports

### Control Flow

```ini
# sfwbar uses If() with capitalized I and parenthesized args
If(XBatLvl > 80, "high", "low")

# Not bash-style:
# if [ $bat -gt 80 ]; then echo "high"; fi
```

### Functions

```ini
# sfwbar Function declaration
Function MyFunc() {
  Return "hello"
}

# Not bash-style:
# my_func() { echo "hello"; }
```

### Variable Scoping

```ini
# sfwbar uses "local" keyword (not "local" with type)
Private {
  Var my_var = "value"
}

# Not bash-style:
# local my_var="value"
```

### Shell Commands

```ini
# Use Exec() to run shell commands
action = Exec("pactl set-volume @DEFAULT_SINK@ 0.05+")

# Not bash-style:
# pactl set-volume @DEFAULT_SINK@ 0.05+
```

## What sfwbar Does NOT Support

| Bash Construct | sfwbar Equivalent |
|---|---|
| `if [ condition ]; then ... fi` | `If(condition, true_val, false_val)` |
| `elif` | Nested `If()` |
| `command -v foo` | `Ident(foo)` or check at shell level |
| `echo "text" > file` | `Exec("echo text > file")` |
| `mkdir -p dir` | `Exec("mkdir -p dir")` |
| `$((expr))` | `Val(expr)` or inline math |
| `function name() { }` | `Function name() { }` |
| `local var=value` | `Var var = value` inside `Private {}` |

## Example: Incorrect vs Correct

### WRONG (bash in sfwbar config)

```ini
ExecuteApp() {
  local app_name="$1"
  if command -v kitty >/dev/null 2>&1; then
    kitty -e "bash -c '$app_name'"
  elif command -v foot >/dev/null 2>&1; then
    foot -e "bash -c '$app_name'"
  fi
}
```

### CORRECT (sfwbar syntax)

```ini
Function ExecuteApp() {
  Exec("fuzzel --command " + $1)
}
```

## Rule of Thumb

If a line uses bash features (`$()`, `[]`, `if/elif/else`, `echo`, pipes `|`), it belongs in a **shell script** called via `Exec()`, not inline in sfwbar config.

Inline sfwbar config should only use: `If()`, `Exec()`, `Val()`, `Str()`, `Match()`, `RegEx()`, and sfwbar's built-in functions.
