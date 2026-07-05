# Lesson: `grep > $FILE` Wipes The File Before Grep Reads It

## The Problem

A `delete_kv()` function that removes a key from a key-value store:

```bash
delete_kv() {
  local key="$1"
  local file="$KVSTORE_FILE"
  grep -v "^$key=" "$file" > "$file"
}
```

Every call to `delete_kv()` **wipes the entire file** instead of removing one key. All stored key-value pairs are lost.

## Root Cause

The shell opens the redirect (`> "$file"`) **before** starting `grep`. Opening `>` for write truncates the file to zero bytes. By the time `grep` opens the file for reading, it's empty — `grep` reads nothing, writes nothing, and the file stays empty.

This is a classic Bash pitfall. The order of operations is:

1. Shell parses the pipeline: `grep ... > "$file"`
2. Shell opens `"$file"` for write (`>`) → **file is truncated**
3. Shell forks `grep` with stdin/stdout connected
4. `grep` opens the (now-empty) file for reading → sees nothing → outputs nothing

## The Fix

Write to a temp file, then rename:

```bash
delete_kv() {
  local key="$1"
  local file="$KVSTORE_FILE"
  local tmp
  tmp=$(mktemp "${file}.XXXXXX") || return 1
  grep -v "^$key=" "$file" > "$tmp" && mv "$tmp" "$file"
}
```

`mktemp` creates a new file atomically, so `grep`'s output goes to a fresh file. After `grep` finishes, `mv` replaces the original atomically.

## Where This Applies

- `scripts/actions/kvstore.sh:46` — `delete_kv()` wipes the entire kvstore
- `scripts/actions/kvstore-cli.sh:41` — same pattern, same bug

## Pattern To Remember

Never do `cmd < "$file" > "$file"` or `cmd "$file" > "$file"`. The shell evaluates redirects left-to-right, and `>` truncates before `<` reads. Always use a temp file + `mv`.
