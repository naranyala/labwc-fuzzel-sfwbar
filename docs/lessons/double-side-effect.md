# Lesson 7: Running a Side Effect the Tool Already Handled

**File affected:** `scripts/actions/screenshot.sh`
**Severity:** Low — wrong clipboard content ends up in clipboard for annotate modes

---

## What Happened

The `annotate` and `annotate-full` modes pipe the screenshot directly into `satty`
(or `swappy`), which handles both saving and copying to clipboard internally:

```bash
annotate)
    grim -g "$(slurp)" - | satty - --save-file "$FILEPATH" --copy-to-clipboard
    return   # <-- returns from take_screenshot()
    ;;
```

But after `take_screenshot` returns, the script unconditionally ran:

```bash
# Copy to clipboard (if file was created)
if $CLIPBOARD && [ -f "$FILEPATH" ]; then
    wl-copy < "$FILEPATH"   # BUG: overwrites what satty already put in the clipboard
fi
```

`satty --copy-to-clipboard` copies the *annotated* image (with drawings, arrows,
text overlays). The `wl-copy` block then reads the *raw* saved file and overwrites
the clipboard with the un-annotated version. The user's annotations are lost from
the clipboard even though they're saved to disk.

## The Fix

Guard the clipboard block against the modes that already handle it:

```bash
# Skip clipboard copy for annotate modes — satty/swappy already handled it
if $CLIPBOARD && [ -f "$FILEPATH" ] && [[ "$MODE" != "annotate" && "$MODE" != "annotate-full" ]]; then
    if command -v wl-copy &>/dev/null; then
        wl-copy < "$FILEPATH"
    fi
    pass "Copied to clipboard"
fi
```

## The General Pattern

This class of bug happens whenever:
1. A tool is invoked with a flag that performs side effect X.
2. The calling script also performs side effect X after the tool returns.

The result is side effect X happening twice — sometimes harmlessly (double
notification), sometimes destructively (second write overwrites the first).

```
tool --do-the-thing       <-- does X internally
calling_script_also_does_X  <-- overwrites or duplicates
```

## How to Catch It

Before adding a post-action step, ask:
- Does any tool in the pipeline already do this?
- Check `man <tool>` or `<tool> --help` for flags like `--copy-to-clipboard`,
  `--notify`, `--save`, `--output`.

For `satty`: `satty --help | grep clip`
For `swappy`: `swappy --help | grep output`

If the tool handles it, skip the post-step, or make the post-step conditional.

## Related: The `annotate-full` Fallback Also Has This

When neither `satty` nor `swappy` is installed, the fallback captures to `$FILEPATH`
and returns normally — in that case the clipboard block *should* run. The conditional
fix above handles this correctly: the block only skips when `MODE` is an annotate
mode, not when the fallback path is taken (the file is still created and the clipboard
block fires normally).
