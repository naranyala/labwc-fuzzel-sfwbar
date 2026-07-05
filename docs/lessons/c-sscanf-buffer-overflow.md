# Lesson: `sscanf` `%s` Into Fixed Buffer Causes Stack Overflow

## The Problem

A hex color buffer defined as 8 bytes, but parsed with a format string that reads up to 127 bytes:

```c
// src/ocws-style.c
typedef struct {
  char hex[8];  // 8 bytes on stack
  // ...
} ocws_color_t;

// Line 197-199
sscanf(line, "surface=%127s", theme->surface.hex);
```

A config file line like `surface=#11223344556677889900aabbccddeeff` writes 40+ bytes into an 8-byte buffer, **corrupting the stack**.

## Root Cause

The `%127s` specifier tells `sscanf` to read up to 127 characters. The target buffer `hex[8]` can only hold 7 characters + null terminator. The mismatch between format specifier and buffer size was introduced when the same `sscanf` pattern was copy-pasted for all fields:

```c
// For theme->name[128]:  %63s  ← buffer is 128, but specifier allows only 63 (OK)
// For theme->gtk_theme[128]:  %127s  ← matches buffer size (OK)
// For theme->icon_theme[128]:  %127s  ← matches buffer size (OK)
// For theme->font_mono[256]:   %255s  ← matches buffer size (OK)
// For theme->surface.hex[8]:   %127s  ← **OVERFLOW** buffer is 8, specifier allows 127 (X)
```

Same issue at `src/ocws-style.c:84` where `snprintf` into `hex[8]` can write 9+ bytes:

```c
snprintf(color.hex, sizeof(color.hex), "%s%02x", hex, (int)(color.a * 255));
//                                     ^^  ^^^^
//                                     |    + up to 2 chars
//                                     + up to 6 chars = 8 chars + null = 9 bytes
```

## The Fix

Fix the format specifier to match the buffer size, and increase the buffer to be safe:

```c
// Increase buffer to standard color string size
typedef struct {
  char hex[12];  // "#RRGGBBAA\0" = 10 chars max
  // ...
} ocws_color_t;

// Fix format specifier
sscanf(line, "surface=%11s", theme->surface.hex);
//                  ^^^^  max 11 chars + null fits in 12-byte buffer

// Fix snprintf
snprintf(color.hex, sizeof(color.hex), "%s%02x", hex, (int)(color.a * 255));
// sizeof(color.hex) = 12, safe for "#RRGGBBAA\0"
```

## Verification

```bash
# Find all sscanf with %s into fixed buffers
grep -rn 'sscanf.*%[0-9]*s' src/ --include='*.c'
grep -rn 'sscanf.*%127s' src/ --include='*.c'
```

## Where This Applies

| File | Line | Buffer | Format | Severity |
|------|------|--------|--------|----------|
| `src/ocws-style.c` | 197 | `char hex[8]` | `%127s` | **CRASH** — stack corruption |
| `src/ocws-style.c` | 84 | `char hex[8]` | `%s%02x` (snprintf) | **CRASH** — 9 bytes into 8 |

## Pattern To Remember

When using `sscanf` with `%s`, the width specifier **must** be `buffer_size - 1`. Copy-pasting `sscanf` patterns between fields with different buffer sizes is how this bug happens. Always verify the buffer size against the format specifier, especially for small buffers like color hex strings.
