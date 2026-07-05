# Lesson 16: Non-Atomic File Updates — Race Conditions in State Files

**File affected:** `scripts/ocws-network-bandwidth.sh`
**Severity:** Medium — partial/corrupted state files when two processes run concurrently

---

## What Happened

The network stats updater builds a new state file by appending to a `.tmp` file,
then replaces the live file:

```bash
update_network_stats() {
    for iface in $interfaces; do
        # Append stats for this interface
        echo "$iface $rx_bytes $tx_bytes $timestamp" >> "$NET_STATS_FILE.tmp"

        # Also try to update the live file mid-loop with sed
        sed -i "s/^$iface .*/$iface $rx_bytes $tx_bytes $timestamp/" "$NET_STATS_FILE" \
            2>/dev/null || echo "$iface $rx_bytes $tx_bytes $timestamp" >> "$NET_STATS_FILE"
        # ^^ BUG: live file is modified while .tmp is also being built
    done

    # Then replace atomically...
    mv "$NET_STATS_FILE.tmp" "$NET_STATS_FILE" 2>/dev/null || true
    # ^^ ...but the mv may overwrite the sed changes made in the loop
}
```

Two problems:
1. The `sed -i` modifies the live `$NET_STATS_FILE` mid-loop while simultaneously
   building `$NET_STATS_FILE.tmp`. The final `mv` then **overwrites all the sed
   changes** with the `.tmp` file, making the `sed` calls pointless.
2. If two instances of the script run at the same time (daemon + manual trigger),
   both write to the same `.tmp` file, producing garbled output.

## The Fix

Pick one strategy and use it consistently. The cleanest is write-to-temp-then-move,
with a per-process temp file to avoid collisions:

```bash
update_network_stats() {
    # Use a per-process temp file to avoid collisions
    local tmp
    tmp=$(mktemp "${NET_STATS_FILE}.XXXXXX")

    for iface in $interfaces; do
        local stats
        stats=$(collect_interface_stats "$iface")
        [[ -z "$stats" ]] && continue

        # Write new stats to temp (not the live file)
        echo "$iface $stats" >> "$tmp"
    done

    # Atomic replace — readers either see the old file or the new one, never a partial
    mv "$tmp" "$NET_STATS_FILE"
}
```

For the history file, use a lock to prevent concurrent appends:

```bash
# Append to history with a lock
(
    flock -x 200
    echo "$iface $rx_rate $tx_rate $timestamp" >> "$NET_HISTORY_FILE"
) 200>"${NET_HISTORY_FILE}.lock"
```

## The General Rule

> **Never modify a live file and build a replacement simultaneously.**
> Choose one:
>
> A) **In-place update:** `sed -i` or direct writes — safe only for single-process,
>    single-field updates.
>
> B) **Write-then-replace:** Write the complete new content to a temp file,
>    then `mv` it atomically. Use `mktemp` to avoid temp file collisions between
>    concurrent processes.

```bash
# BAD — modifies live file AND builds replacement simultaneously
for item in "${items[@]}"; do
    echo "$item" >> "$FILE.tmp"
    sed -i "s/old/new/" "$FILE"   # races with the tmp build
done
mv "$FILE.tmp" "$FILE"            # overwrites sed changes

# GOOD — write entirely to temp, then single atomic swap
tmp=$(mktemp "$FILE.XXXXXX")
for item in "${items[@]}"; do
    echo "$item" >> "$tmp"
done
mv "$tmp" "$FILE"
```

## `mktemp` vs. Hardcoded `.tmp` Suffix

```bash
# BAD — two concurrent runs write to the same .tmp file
"$FILE.tmp"

# GOOD — each run gets a unique temp file
tmp=$(mktemp "$FILE.XXXXXX")   # e.g. network-stats.aB3xQ9
```

`mktemp` guarantees uniqueness and creates the file atomically. Always use it when
building replacement files.
