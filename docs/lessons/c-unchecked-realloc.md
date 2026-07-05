# Lesson: Unchecked `realloc()` Return Causes Silent Corruption

## The Problem

When memory is exhausted, `realloc()` returns NULL but the code continues writing to the buffer:

```c
// src/ocws-kv.c:112
kv->entries = realloc(kv->entries, kv->capacity * sizeof(ocws_kv_entry));
//            ^^^^^^^^  if NULL, the old pointer is LOST
kv->entries[kv->count].key = xstrdup(key);
//              ^^^^^^^^  NULL dereference — CRASH
```

When `realloc` fails:
1. **Old pointer is lost** — the original `kv->entries` memory is leaked forever
2. **NULL is written to `kv->entries`** — subsequent access at line 114 crashes with NULL dereference
3. **`kv->count` is already incremented** — the data structure is in an inconsistent state

## Root Cause

GLib's `g_realloc()` aborts on OOM, but the project uses raw `realloc()` in `ocws-kv.c`. Raw `realloc()` returns NULL on failure. The code assumes it always succeeds, which is safe for a desktop app under normal memory pressure, but a single OOM event corrupts the entire kv store and crashes the program.

Same pattern at two locations:

```c
// Line 111-112
kv->capacity *= 2;
kv->entries = realloc(kv->entries, kv->capacity * sizeof(ocws_kv_entry));

// Line 162-163 — same pattern
kv->capacity *= 2;
kv->entries = realloc(kv->entries, kv->capacity * sizeof(ocws_kv_entry));
```

There's also an integer overflow risk: if `kv->capacity` doubles repeatedly past `SIZE_MAX / sizeof(ocws_kv_entry)`, the multiplication wraps to a small value, `realloc` returns a small buffer, and subsequent writes overflow the heap.

## The Fix

Use a temporary pointer and check for failure:

```c
ocws_kv_entry *tmp = realloc(kv->entries,
    kv->capacity * sizeof(ocws_kv_entry));
if (!tmp) {
    // realloc failed — old entries still valid, kv not corrupted
    return OCWS_KV_ERR_OOM;
}
kv->entries = tmp;
```

For integer overflow protection, check before multiplying:

```c
if (kv->capacity > SIZE_MAX / sizeof(ocws_kv_entry) / 2) {
    return OCWS_KV_ERR_OOM;  // would overflow
}
kv->capacity *= 2;
ocws_kv_entry *tmp = realloc(kv->entries,
    kv->capacity * sizeof(ocws_kv_entry));
```

## Where This Applies

| File | Line | Issue |
|------|------|-------|
| `src/ocws-kv.c` | 112 | Unchecked `realloc` overwrites `kv->entries` with NULL |
| `src/ocws-kv.c` | 163 | Same pattern, second growth path |
| `src/ocws-kv.c` | 111 | Integer overflow in `capacity * sizeof(...)` |
| `src/ocws-kv.c` | 162 | Same overflow risk |

## Pattern To Remember

Never assign `realloc()` result directly to the original pointer. If `realloc` fails, it returns NULL without freeing the old memory. Use a `tmp` pointer, check for NULL, then assign. This pattern is not unique to this project — it's the #1 realloc mistake in C.
