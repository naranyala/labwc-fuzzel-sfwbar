# Lesson: Atomic File Writes Prevent Corruption

## The Problem

When a process writes to a file and is killed mid-write (e.g., compositor crash, power loss), the file is left in a partial/corrupted state. For config stores and state files, this means data loss.

## The Pattern

`ocws-kv.c` uses the **write-to-temp-then-rename** pattern:

```c
int ocws_kv_flush(ocws_kv *kv) {
    // 1. Write to a temporary file
    char *tmppath = malloc(strlen(kv->path) + 5);
    snprintf(tmppath, ..., "%s.tmp", kv->path);
    FILE *f = fopen(tmppath, "w");
    fprintf(f, "# OCWS State Store\n");
    for (size_t i = 0; i < kv->count; i++)
        fprintf(f, "%s=%s\n", kv->entries[i].key, kv->entries[i].value);
    fclose(f);

    // 2. Atomically replace the original
    if (rename(tmppath, kv->path) != 0) {
        // Fallback: remove and retry
        remove(kv->path);
        rename(tmppath, kv->path);
    }
    free(tmppath);
    kv->dirty = 0;
    return 0;
}
```

## Why `rename()` Is Atomic

On Linux (and most POSIX systems), `rename()` is atomic when source and destination are on the same filesystem. Either:
- The old file exists and the new file replaces it, OR
- The rename fails and the old file is untouched

There's no intermediate state where the file is half-written.

## When to Use This

- State files that survive compositor reloads
- Config files written by background daemons
- Any file that multiple processes might read while another writes

## When NOT to Bother

- Files written once at startup (autostart scripts)
- Files written by a single process that never crashes
- Temporary files that are consumed immediately

## Related: `ocws-state.sh`

The shell-based state persistence (`ocws-state.sh`) writes JSON via `jq`:

```bash
jq -n --arg artist "$artist" ... > "$MEDIA_STATE_FILE"
```

This is **not atomic** — if the process is killed during the write, the JSON file is corrupted. For production use, it should write to a temp file and rename:

```bash
tmpfile="${MEDIA_STATE_FILE}.tmp"
jq -n ... > "$tmpfile" && mv "$tmpfile" "$MEDIA_STATE_FILE"
```
