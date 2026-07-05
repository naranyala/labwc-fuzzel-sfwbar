# Lesson 4: Positional Arguments Already Consumed

**Files affected:** `scripts/actions/audio.sh`, `scripts/actions/network.sh`
**Severity:** Medium — specific subcommands (`set-sink`, `wifi-connect`, `bt-connect`) receive no input

---

## What Happened

### audio.sh — set-sink reads `$2` but it was already captured as `STEP`

At the top of the script:

```bash
MODE="${1:-up}"
STEP="${2:-5%}"     # $2 is consumed here as the step amount
```

Then inside the `set-sink` branch:

```bash
set-sink)
    local_sink_id="${2:-}"    # BUG: $2 in a case block is still the outer $2
    if [ -z "$local_sink_id" ]; then
        fail "Usage: $0 set-sink <sink-id>"
    fi
```

`${2:-}` here re-reads `$2` from the outer script scope — which is already stored in
`$STEP` (or empty if not given). If you call `audio.sh set-sink 42`, then `$STEP`
holds `"42"`, but `${2:-}` also holds `"42"` — it accidentally works. But if you
call `audio.sh set-sink` with no ID, you get the unhelpful default `"5%"` as the
sink ID instead of a clean error.

The safer fix is to read from the captured variable:

```bash
set-sink)
    local_sink_id="${STEP:-}"
    if [ -z "$local_sink_id" ] || [ "$local_sink_id" = "5%" ]; then
        fail "Usage: $0 set-sink <sink-id>"
    fi
```

### network.sh — Function reads `$2`/`$3` which are the *function's* parameters, not the script's

```bash
wifi_connect() {
    local ssid="${2:-}"       # BUG: inside a function, $2 is the 2nd arg to the function
    local pass_input="${3:-}" # BUG: $3 is the 3rd arg to the function
```

The call site was:
```bash
wifi-connect) wifi_connect "$@" ;;
```

`$@` expands to all outer script positional args: `$1=wifi-connect $2=<ssid> $3=<pass>`.
So inside the function, `$1=wifi-connect`, `$2=<ssid>`, `$3=<pass>`.
The function correctly needed `$2` and `$3` — but only because `$1` (the mode) was
being passed. This is fragile and confusing.

The clean fix is: don't pass MODE as a function argument. Use `${@:2}` to skip it:

```bash
# Call site: skip the first arg (MODE)
wifi-connect) wifi_connect "${@:2}" ;;

# Function: now $1 = ssid, $2 = password
wifi_connect() {
    local ssid="${1:-}"
    local pass_input="${2:-}"
```

## The General Rule

> **Capture your positional args at the top of a script once.** Inside functions,
> never re-read `$1`/`$2`/`$3` — they refer to the function's own argument list,
> not the outer script's.

```bash
# Outer script
MODE="$1"
ARG="$2"

some_function() {
    # Here $1, $2, $3... are THIS FUNCTION's args, not the outer script's
    # Use the captured vars if you need the outer values:
    echo "$MODE"   # correct
    echo "$1"      # $1 of the function, not the script
}

some_function "$ARG"   # pass explicitly what the function needs
```

## How to Catch It

`shellcheck` warns about many of these via SC2034 (variable assigned but unused)
or by flagging `${2:-}` patterns inside functions where the intent is likely wrong.

```bash
shellcheck scripts/actions/audio.sh
shellcheck scripts/actions/network.sh
```
