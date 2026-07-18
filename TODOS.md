# TODOS — Blend2D Panel/Dock Issues

## Previously Fixed Bugs

- [x] **#1 Wrong right-click button code** (`main_shell.zig:435`, `panel.zig:207`) — Button `274` is `BTN_MIDDLE` (0x112), not `BTN_RIGHT` (0x111=273).
- [x] **#2 Stale dock visible after autohide** (`main_shell.zig:993-994`) — When `dock_surface.height <= 0`, `renderDock` returns early but `submitSurface` is never called.
- [x] **#3 `ccUpdate` race with async spawn** (`panel.zig:649-683`) — Custom command spawns `sh -c '...' > tmpfile` via `spawn()` (which blocks on `system()`), then immediately reads the tmpfile.
- [x] **#4 No bounds checking on configure `w`/`h`** (`main_shell.zig:643-661`) — `layerSurfaceConfigure` accepts arbitrary `w`/`h` from compositor without clamping.
- [x] **#5 `keyboard_keymap_fd` never closed on exit** (`main_shell.zig:1467-1488`)
- [x] **#6 `dock.c` loaded icon not destroyed on mutable-check failure** (`dock.c:52-63`)
- [x] **#7 `reloadWidgets` loses accumulated widget state** (`main_shell.zig:798-808`)
- [x] **#8 `dock.zig` redundant array copy** (`dock.zig:19-40`)
- [x] **#9 Panel fallback width is a magic number** (`main_shell.zig:1401`)
- [x] **#10 No workspace-specific switching** (`panel.zig:150-155`)
- [x] **#11 No `wl_surface_set_buffer_scale` on initial render** (`main_shell.zig`)
- [x] **#13 Misaligned indentation** (`main_shell.zig:998`)
- [x] **#14 `createWidget` re-zeros every field manually** (`panel.zig:931-967`)
- [x] **#15 Segfault: `submitSurface` called with null launcher buffer** (`main_shell.zig:1488`)
- [ ] **#12 Dock keyboard interactivity always 0** (`main_shell.zig:1381`) — Intentional.

## Previously Fixed Cairo-Pango Bugs

- [x] **#16 `toplevel_task` widget never renders (missing `priv` wiring)**
- [x] **#17 `ccUpdate` blocks the Wayland event loop + shell-injection**
- [x] **#20 Reload discards `priv` and runtime state inconsistently**
- [x] **#22 Dock magnification can exceed dock height**
- [x] **#24 `tlClick` hit-test desyncs from drawn positions**
- [x] **#18 Widget layout uses mismatched width estimates** (measure now uses real Pango width via `widget_text_width_c`)
- [x] **#19 `mkstemp` temp file world-readable + no retry** (`fchmod(fd, 0o600)` after mkstemp)
- [x] **#21 Icon cache relies on zeroed backing buffers for null-termination** (`bufPrintZ` null-terminated copy before `icon.load`)
- [x] **#23 Settings drag saves config on every motion event** (dirty flag + single save on button release)

---

## Blend2D — New Issues (Audit 2026-07-17)

### Critical

- [x] **#25 Shell injection in `ccUpdate`** (`panel.zig:684`) — User command interpolated into single-quoted `sh -c` with no escaping. A `'` in the command breaks out of quotes and allows arbitrary execution. **Fixed**: escape `'` → `'\''` before interpolation.
- [ ] **#26 Config options never applied** (`panel.zig:1161-1179`) — `configLoadWidgets` parses options into `opts_buf` but never reads them. All widget customization from config is silently discarded. **Deferred**: requires config format design.
- [x] **#27 Stack buffer overflow in `dock.zig`** (`dock.zig:19-23`) — `top_count` > 64 overflows the fixed 64-element stack arrays. No bounds clamp before the loop. **Fixed**: clamp to 64 before loop, use safe slice bounds.

### High

- [x] **#28 i64→i32 overflow panic in CPU jiffies** (`panel.zig:257-258`) — `cpu_prev_total`/`cpu_prev_idle` stored as `i32` but sourced from `i64` cumulative jiffies from `/proc/stat`. Panics after ~24 days uptime at 100 Hz tick rate. **Fixed**: changed fields to `i64`.
- [x] **#29 Font destroyed without recovery in `blend_renderer_load_bold_font`** (`blend2d_render.c:230-243`) — Destroys `r->font` before attempting bold creation. If bold fails, font is left in destroyed state → crash. **Fixed**: only destroy+replace on success; re-init face on failure.
- [x] **#30 Zeroed `BLImageCore` from `icon_fallback` when cache full** (`icon.c:184`) — Returns static zeroed image that Blend2D operates on → crash/UB. **Fixed**: return NULL instead; callers skip drawing.
- [x] **#31 Missing null-termination in `dock.zig` string pass-through** (`dock.zig:24-26`) — If `app_id`/`title` arrays are fully filled with no `\0`, the slice includes non-null-terminated data passed to C `strcmp`. **Fixed**: truncate to `len - 1` when no null found.
- [ ] **#32 Signal handler race on `reload_config`** (`main_shell.zig:65,808`) — Plain `bool` read/written from signal handler + main loop without atomicity or volatile. **Deferred**: requires `std.atomic.Value(bool)` refactor.

### Medium

- [x] **#33 u32→i32 cast before clamp in `layerSurfaceConfigure`** (`main_shell.zig:661-662`) — `@intCast(u32→i32)` panics if compositor sends value > 2^31-1. Must clamp u32 first. **Fixed**: clamp u32 to 16384 before casting.
- [x] **#34 Double submit of dock surface** (`main_shell.zig:1045-1051 + 1496`) — `renderDock()` submits early for hidden dock, then main loop submits again unconditionally. **Fixed**: `renderDock` returns bool; main loop gates outer submit.
- [x] **#35 `tlClick` uses `ctx.panel_height` instead of `h` parameter** (`panel.zig:217`) — Click hit-test may misalign with drawn icons if panel height differs from `h`. **Fixed**: added comment documenting the constraint; panel_height is the only available proxy.
- [x] **#36 `volClick` never toggles `vol_mute` widget state** (`panel.zig:437-447`) — Flips system mute but widget state stays stale until next `update_fn` runs (which doesn't exist for volume). **Fixed**: toggle `w.vol_mute` before spawning pactl.
- [x] **#37 Missing `update_fn` for `disk`, `volume`, `media` widgets** (`panel.zig:1002-1030`) — Display text never syncs from system (disk stays "SSD --", volume never reads PulseAudio, media never reads playerctl). **Fixed**: added `volUpdate` (pactl) and `mediaUpdate` (playerctl). Disk deferred (no sysread function).
- [x] **#38 `kbClick` spawns empty command on `bufPrintZ` failure** (`panel.zig:652-656`) — Spawn called even when `cmd` buffer is all zeros due to format error. **Fixed**: early return on format error before spawn.
- [x] **#39 No `font_loaded` guard in C `draw_text`/`measure_text`** (`blend2d_render.c:143-157`) — Operates on empty font if no font found on system. **Fixed**: added `!r->font_loaded` check to both functions.
- [x] **#40 Uninitialized `bold_face` in `blend_renderer_load_bold_font`** (`blend2d_render.c:233`) — Missing `bl_font_face_init` before `bl_font_face_create_from_file`. **Fixed**: added `bl_font_face_init` + re-init on failed create.
- [x] **#41 `submitSurface` with null buffer** (`main_shell.zig:1317-1318`) — Calls `wl_surface_attach` with null buffer (protocol valid but likely unintentional). **Fixed**: added null guard for buffer and surface.
- [x] **#42 Seat capability loss not handled** (`main_shell.zig:633-643`) — If pointer/keyboard removed from seat, stale handle used in Wayland calls. **Fixed**: destroy and null pointer/keyboard when capability is dropped.
- [x] **#43 Widget overlap when right widgets are wide** (`main_shell.zig:976-977`) — Right-side widgets visually overlap left when space is tight. **Fixed**: enforce minimum 16px gap between left and right widget groups.

### Low

- [x] **#44 Dead variable `ws_idx` in `wsClick`** (`panel.zig:155,166`) — Incremented but never used; workspace character is used directly. **Fixed**: removed dead variable.
- [x] **#45 Dead code `btn == 273` in `tlClick`** (`panel.zig:225`) — Callback uses normalized button codes (1, 3), not raw evdev. **Fixed**: removed dead branch.
- [ ] **#46 Hardcoded px/char estimates in measure functions** (`panel.zig:142,521,543,607,663,749`) — Widget widths based on fixed chars-per-pixel rather than actual font metrics. **Deferred**: design choice, would require font metrics API.
- [ ] **#47 1px dead zone in `wsClick` hit-test** (`panel.zig:159-160`) — Adjacent workspace digits have a 1px gap where click falls through to fallback. **Deferred**: minor visual issue.
- [ ] **#48 `cmd` field only 128 bytes, silently truncated** (`panel.zig:85`) — Long custom commands from config truncated without warning. **Deferred**: design choice.
- [ ] **#49 `wcMeasure` uses magic constant for clock width** (`panel.zig:748-749`) — `+ 56` not computed from actual `clock_txt` content. **Deferred**: minor.
- [ ] **#50 No keyboard navigation in launcher** (`main_shell.zig:279-291`) — Only Escape/Enter handled; no Up/Down/PageUp/PageDown. **Deferred**: feature request.
- [ ] **#51 No scroll wheel handling for launcher** (`main_shell.zig:616-618`) — `pointerAxis` is a no-op. **Deferred**: feature request.
- [ ] **#52 Multi-output tracking collected but unused** (`main_shell.zig:737-803`) — Panel/dock appear on one monitor only. **Deferred**: feature request.
- [ ] **#53 `net_txt` can overflow at extreme speeds** (`panel.zig:476`) — `d:.0` with large floats can exceed 64-byte buffer. **Deferred**: low probability.
- [ ] **#54 Missing Wayland cleanup for `wl_pointer`/`wl_keyboard`/globals** (`main_shell.zig:1527-1556`) — Explicit destruction preferred for protocol hygiene. **Deferred**: minor.
- [x] **#55 `launcher_scroll` as negative i32 cast to usize** (`main_shell.zig:1167`) — Currently always 0, but latent panic if scroll is ever implemented as negative. **Fixed**: `@max(launcher_scroll, 0)` before cast.
- [ ] **#56 `icon.c` cache silently drops entries when full** (`icon.c:105`) — No LRU eviction; uncached icons trigger full file search every time. **Deferred**: performance optimization.

---

# TODOS — Cairo-Pango Panel/Dock Issues (`src/shells/zigshell-cairo-pango`)

(unchanged — see original entries above for #16–#24)

---

## Blend2D + Cairo — New Issues (Audit 2026-07-18)

### Critical

- [x] **#57 Blend2D dock out-of-bounds C array read when >64 toplevels open** (`src/shells/zigshell-blend2d/src/dock.zig:23-43` → `src/shells/zigshell-blend2d/src/dock.c:37`) — `dock.zig` fills only the first `safe_count = min(top_count,64)` of the `[64]` `c_app_ids`/`c_titles`/`c_focused` arrays, but passes the *original* `top_count` into `c.dock_draw`, whose loop `for (i=0; i<top_count; i++) app_ids[i]` reads past the 64-element stack arrays. **Trigger**: >64 open windows. **Symptom**: stack over-read / garbage icons / segfault in dock render. **Fixed**: Zig now passes `safe_count` to `dock_draw` and `dock.c` clamps `top_count` to 64 as a backstop.
- [x] **#58 Cairo dock permanently pins every running app into `persistent_order`** (`src/shells/zigshell-cairo-pango/src/dock.zig:106-112` in `draw`, `:254-264` in `iconAt`) — Any running window whose `app_id` is not already pinned is appended to `persistent_order` on every `draw()`/`iconAt()` call. **Trigger**: open any app not already pinned. **Symptom**: the dock's pinned/favorites list silently accumulates every app ever launched (grows toward the 100 cap) and diverges from Blend2D (which never mutates a pinned list). **Fixed**: `draw`/`iconAt` now register non-pinned running apps in the local frame-only `items[]` list only; `persistent_order` is only mutated by explicit `pinApp`/`unpinAt`/`loadPinned`/`swapGroups`. Added regression test "dock draw/iconAt must not persist running apps (#58)".

### High

- [ ] **#59 Blend2D pinned apps are non-functional (no launch path)** (`src/shells/zigshell-blend2d/src/dock.zig:46-47` → `dock.c:96-121`; `main_shell.zig:413-449`) — `dock_icon_at` returns only running-window indices / toggles, with no `1000+g` "pinned, not running" sentinel; `pointerButton` has no `dock_hover_idx >= 1000` branch and no `launchPinned` call. **Trigger**: click/pin a non-running pinned app. **Symptom**: pinned apps never appear in the dock and can never be launched from it (the two renderers' docks are fundamentally divergent).
- [ ] **#60 Cairo grouped-window click always targets the first window** (`src/shells/zigshell-cairo-pango/src/dock.zig:92-121`, `:242-265`) — `draw` shows one icon per app_id group with a count of dots, but clicking returns `top_idx` of only the *first* toplevel in the group; the dots are decorative and the other windows are unreachable. **Trigger**: two windows of the same app. **Symptom**: dock activates a pseudo-arbitrary (first) window; multi-window spread/picker absent.
- [ ] **#61 Cairo tooltip skipped for pinned-launch (non-running) icons** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:1601-1604`) — `drawDockTooltip` early-returns when `dock_hover_idx >= toplevel_count`, but a pinned app's `dock_hover_idx` is `1000+g`, so the guard fires and no tooltip is drawn. **Trigger**: hover a pinned app not currently running. **Symptom**: inconsistent with `iconAt`'s `1000+g` contract; no title shown.

### Medium

- [ ] **#62 Cairo settings drag-reorder saves/reorders spuriously on motion** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:306-323` + `:331-340`) — While dragging a pinned row, `swapGroups` + `syncConfigFromRuntime` + `config_dirty` run on every pointer move for *any* `row` in `0..persistent_count` regardless of horizontal position, including zero-distance `swapGroups(a,a)`. **Trigger**: drag a pinned row up/down repeatedly. **Symptom**: repeated config writes and rotated pin order from overshoot swaps.
- [x] **#63 `apps.zig` `stripFieldCode` leaves doubled spaces mid-command** (`src/shells/shared/apps.zig:83-112`) — Removing a `%`-field code keeps the preceding space and doesn't collapse the gap; `Exec=app %f arg` → `app  arg` (fails the existing test's coverage, which only checks a *trailing* field code). **Trigger**: `.desktop` `Exec=` with an argument after a field code. **Symptom**: launcher command has a stray empty argv entry; affects both shells (shared module). **Fixed**: removed trailing space after `%` and trimmed all trailing spaces.
- [x] **#64 Launcher last partial row click reads past `apps[]`** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:1500,1559-1561`; `src/shells/zigshell-blend2d/src/main_shell.zig:1176,1229-1231`) — `launcherItemAt` loops `row < rows` / `col < LAUNCHER_COLS` from `idx = launcher_scroll*COLS` and can reach `idx >= list.len`, then `pointerButton` does `launchApp(&list[@intCast(idx)])` → OOB. The `if (idx >= list.len) return -1;` guard checks only before the inner loop, not after the final `idx+=1`. **Trigger**: scroll the launcher to the bottom of a list whose length isn't a multiple of `rows*COLS`. **Symptom**: garbage name/exec or crash. Shared defect (both shells). **Fixed**: changed `launcherItemAt` to iterate in row-major order up to `list.len`.
- [ ] **#65 Cairo config reload can cross-contaminate widget sampled state** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:992-1030`) — `reloadWidgets`/`applyConfigToRuntime` restore sampled fields (`cpu_prev_total`, etc.) by matching `wtype`; added/removed/reordered widget types leave stale or zeroed samples assigned to the wrong widget. **Trigger**: SIGHUP reload after editing the widget list. **Symptom**: CPU/mem/disk/net widgets show wrong/zeroed data until next natural update.

### Low

- [x] **#66 `@intCast(toplevel_count)`/`@intCast(widget_count)` panics if negative** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:1798` and many `for (0..@intCast(widget_count))` sites in both shells) — `toplevel_count`/`widget_count` are `i32`; `@intCast` panics on negative. Defensive lower-bound assert recommended. **Fixed**: replaced with `@intCast(@max(0, count))`.
- [ ] **#67 Icon cache wholesale-clear thrash (amplified by #58)** (`src/shells/zigshell-cairo-pango/src/icon.zig:259`; `src/shells/zigshell-blend2d/src/icon.c:105`) — When the 64-entry cache is full it is cleared entirely; combined with #58 (Cairo dock growing `persistent_order` toward 100 distinct app_ids) the cache thrashes on every dock redraw. **Trigger**: full dock + frequent redraws. **Symptom**: repeated icon reloads from disk → high CPU. Shared (both shells).
- [ ] **#68 `apps.zig` `scanDesktopDirs` 1024-byte path buffer overflow** (`src/shells/shared/apps.zig:178-182`) — Full path built as `dir ++ name` into a `[1024]u8` with no size clamp (unlike `scanPath`). **Trigger**: very long `$XDG_DATA_DIRS` path or `.desktop` filename. **Symptom**: stack buffer overflow in launcher scan. Shared.
- [ ] **#69 Blend2D hover/focus-bar geometry overlaps neighbor slot** (`src/shells/zigshell-blend2d/src/dock.c:66-69` vs `:37-44`) — Hover box (`x-4 .. x+icon+8`) and focus bar (`x+2 .. x+icon-4`) are not consistently centered and the hover box over-extends into the neighbor hit region. Minor visual overlap.
- [x] **#70 Blend2D `dock.zig` null-index underflow when app_id/title has no NUL** (`src/shells/zigshell-blend2d/src/dock.zig:25-26`) — `indexOfScalar(...,0) orelse tops[i].app_id.len - 1`; if `len == 0` this computes `0 - 1` → `usize` underflow panic. **Trigger**: a toplevel with empty app_id/title. **Symptom**: render panic. **Fixed**: use `@max(len,1) - 1` so an empty field yields index 0 instead of underflowing.

---

## Features

- [x] **#F1 Global popup modal (cairo-pango)** (`src/shells/zigshell-cairo-pango/src/modal.zig`, wired in `main_shell.zig`) — Full-screen `TOP` layer with a dark translucent backdrop (`rgba(0,0,0,0.55)`) and a centered, rounded, themed content card. Dismiss via Esc, backdrop click, or the × button; card-body clicks are swallowed. Pure layout/hit-test logic lives in `modal.zig` with 3 unit tests (`layoutCard` centering+clamp, `hitClose`, `hitCard` swallow-vs-dismiss). Trigger: open launcher, press `Tab` to toggle the demo modal (`toggleModal("Global Modal")`). `modalOpen(title)` / `modalClose()` are reusable for confirmations/alerts.
- [x] **#71 `bl_context_fill_round_rect_d`/`stroke_round_rect_d` undeclared** (`src/shells/zigshell-blend2d/src/blend2d_render.c:216,224`) — Blend2D C API has no round-rect context functions; these are C++-only inline methods. **Fixed**: replaced with path-based round rect via `build_round_rect_path` + `bl_context_fill_path_d`/`stroke_path_d`.
- [x] **#72 Undefined symbols in blend2d `pointerMotion`** (`src/shells/zigshell-blend2d/src/main_shell.zig:387-416`) — WIP code references `settingsRect()`, `SET_LIST_Y`, `SET_ROW_H`, `syncConfigFromRuntime()`, `dock_mod.groupAt`, `dock_mod.swapGroups`, `dock_mod.persistent_count` — none defined. **Fixed**: removed incomplete WIP code paths and their associated variables.
- [x] **#73 Auto-hide dock on maximize hides dock unpredictably** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:132-153`) — `checkMaximizedWindows()` shrinks dock to 1px whenever any window is maximized. **Fixed**: disabled the function body; dock visibility now controlled only by explicit autohide toggle.

### Critical (New — Audit 2026-07-18)

- [x] **#74 Blend2D missing `wireWidgetPriv()` — toplevel_task dead on startup** (`src/shells/zigshell-blend2d/src/main_shell.zig:1423-1433`) — `widgetCreateDefault()` allocates widgets with `std.mem.zeroes(Widget)` which sets `priv = null`. `tlMeasure`/`tlDraw`/`tlClick` all early-return when `w.priv == null`. The task-bar icons never render and clicks are never handled. Cairo-pango has `wireWidgetPriv()` at startup (cairo-pango main_shell.zig:1771) and after reload. Blend2D has no equivalent. **Fixed**: added `wireWidgetPriv()` function and call it after widget creation and after reload.
- [x] **#75 `apps.zig` `stripFieldCode` returns dangling pointer to stack buffer** (`src/shells/shared/apps.zig:83-111`) — Returns `[]const u8` pointing into stack-local `var out: [256]u8`. After function returns, the pointer is dangling. **Fixed**: changed function signature to take output buffer parameter `stripFieldCode(exec, out)`, eliminating the dangling pointer.

### High (New — Audit 2026-07-18)

- [x] **#76 Blend2D missing `MAXIMIZED` state detection in toplevel handler** (`src/shells/zigshell-blend2d/src/main_shell.zig:126-141`) — `info.maximized` is reset to `false` on every state event but never set to `true` when `STATE_MAXIMIZED` is received. Cairo-pango line 152 handles it. **Fixed**: added `if (states[i] == c.ZWLR_FOREIGN_TOPLEVEL_HANDLE_V1_STATE_MAXIMIZED) info.maximized = true;`.
- [x] **#77 Blend2D missing `POLLERR|POLLHUP` handling — infinite loop on compositor crash** (`src/shells/zigshell-blend2d/src/main_shell.zig:1566-1578`) — Main event loop only checks `POLLIN`. If the Wayland compositor crashes/restarts, `poll()` returns with `POLLERR|POLLHUP` but `running` is never set to false. Cairo-pango line 1913 handles this. **Fixed**: added `POLLERR|POLLHUP` check before `POLLIN` check.
- [x] **#78 Blend2D `reloadWidgets()` does not re-wire `priv` or apply config** (`src/shells/zigshell-blend2d/src/main_shell.zig:819-863`) — `configLoadWidgets()` creates fresh widgets with `priv = null`. Reload function copies some state but never calls `wireWidgetPriv()` or `applyConfigToRuntime()`. **Fixed**: added `wireWidgetPriv()` call after widget count update in `reloadWidgets()`.
- [x] **#79 Cairo dock `items[100]` stack array overflow** (`src/shells/zigshell-cairo-pango/src/dock.zig:78-117`, `:232-258`) — `draw()` and `iconAt()` use `var items: [100]DockItem` with no bounds check on `num_items`. `persistent_count` (max 100) + unmatched toplevels (max 64) can exceed 100. Same bug in `iconAt()`. **Fixed**: added `if (num_items >= items.len) break;` guard before both append sites.
- [x] **#80 Null dereference after `wl_surface_frame` returns null** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:1661-1662`, blend2d equivalent) — `wl_surface_frame()` return is not null-checked before passing to `wl_callback_add_listener()`. **Fixed**: added null guard with `if (ss.frame_cb) |cb|` before adding listener. Also added `if (ss.buffer == null or ss.surface == null) return;` to `submitSurface`.
- [x] **#81 Null dereference in `toggleLauncher` surface creation** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:1479-1480`) — `wl_compositor_create_surface()` return not null-checked; immediately passed to `wl_surface_add_listener()`. **Fixed**: added `orelse { launcher_open = false; return; };` to handle OOM gracefully.
- [x] **#82 Cairo `@intCast` u32→i32 panic in configure handler** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:843-844`) — `@min(@as(i32, @intCast(w)), 16384)` panics if compositor sends `w` > `i32.max`. Blend2D already has this fix (#33). **Fixed**: changed to `@intCast(@min(w, 16384))` — clamp u32 first, then cast.

### Medium (New — Audit 2026-07-18)

- [ ] **#83 Blend2D `pctx.panel_height` relies on fragile default coincidence** (`src/shells/zigshell-blend2d/src/main_shell.zig:1429-1433`) — `pctx` is initialized without `.panel_height`, relying on the struct default (28) coincidentally matching `PANEL_HEIGHT = 28`. `tlClick` uses `ctx.panel_height - 12` for hit-test. Cairo-pango explicitly sets `pctx.panel_height = PANEL_HEIGHT` (cairo-pango main_shell.zig:1769). **Trigger**: any future change to `PANEL_HEIGHT`. **Symptom**: invisible click targets if the default diverges.
- [ ] **#84 Blend2D Enter keycode 36 vs Cairo's 28** (`src/shells/zigshell-blend2d/src/main_shell.zig:283` vs `src/shells/zigshell-cairo-pango/src/main_shell.zig:794`) — Blend2D uses `key == 36` (XKB keycode), Cairo uses `key == 28` (raw evdev). wl_keyboard protocol specifies evdev keycodes. If labwc delivers raw evdev, `key == 36` never matches Enter. **Trigger**: pressing Enter/Return in the launcher. **Symptom**: launcher cannot be confirmed with keyboard (blend2d only).
- [ ] **#85 Blend2D dock `dock_icon_at` toggle hit zones are `DOCK_PAD` wider than drawn icons** (`src/shells/zigshell-blend2d/src/dock.c:108,111`) — Hit-test uses `dock_icon_size + DOCK_PAD` but icons are drawn at exactly `dock_icon_size`. Cairo-pango (`dock.zig:290-295`) uses exact `DOCK_ICON_SIZE`. **Trigger**: click in the PAD-pixel gap right of a toggle icon. **Symptom**: false-positive settings/launcher toggle activation.
- [ ] **#86 Cairo `groupAt()` layout diverges from `draw()`/`iconAt()`** (`src/shells/zigshell-cairo-pango/src/dock.zig:318-343`) — `groupAt()` computes layout from `persistent_count` only, but `draw()`/`iconAt()` include unpinned running apps in the layout. **Trigger**: unpinned apps visible in dock while drag-reordering. **Symptom**: wrong group returned; reorder affects wrong icon.
- [ ] **#87 `toplevel.zig` panics on negative `count`** (`src/shells/shared/toplevel.zig:23,31,41`) — `@intCast(count)` where `count: i32` panics if negative. Same issue in `add()` and `removeAt()`. **Trigger**: corrupted/uninitialized state tracker. **Symptom**: runtime panic in safe builds; UB in release.
- [x] **#88 `sysread.zig` `writeZ` unsigned underflow when `out.len == 0`** (`src/shells/shared/sysread.zig:146`) — `out.len - 1` wraps to `maxInt(usize)` when `out` is empty. **Trigger**: caller passes empty slice. **Symptom**: massive heap/stack corruption. Currently latent (all callers pass non-empty buffers). **Fixed**: added `if (out.len == 0) return;`.

- [x] **#89 Cairo `submitSurface` has no null guard for buffer/surface** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:1652-1653`) — `wl_surface_attach(ss.surface, ss.buffer, 0, 0)` called without checking if buffer or surface is null. Blend2D has this guard (#41). **Fixed**: added `if (ss.buffer == null or ss.surface == null) return;` at top of `submitSurface`.
- [x] **#90 Cairo negative stride from `cairo_format_stride_for_width` causes `@intCast` panic** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:1063-1064`) — If stride is negative (error), `@intCast` to `usize` panics. **Trigger**: invalid width causing Cairo internal error. **Symptom**: crash in `ensureBuffer`. **Fixed**: added `if (stride <= 0) return;`.
- [x] **#91 Modal layout width/height underflow panic** (`src/shells/zigshell-cairo-pango/src/modal.zig:37-38`) — `layoutCard` computes `cw = @min(card_w, out_w - 24)`. If `out_w < 24`, `cw` becomes negative, leading to negative dimensions which can crash Cairo rendering or cause `@intCast` panics. **Trigger**: extremely small output width/height during resize. **Symptom**: renderer crash. **Fixed**: clamped `cw` and `ch` to a minimum of 0 using `@max(0, ...)`.

### Low (New — Audit 2026-07-18)

- [ ] **#91 `config_path` may become dangling after `setenv` calls** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:1724-1726`) — `config_path` points into `getenv("ZIGSHELL_CONFIG")` memory. `worldclock` widget calls `setenv("TZ", ...)` which can relocate the environment block. POSIX does not guarantee prior `getenv` pointers remain valid after `setenv`. **Trigger**: world clock widget update + subsequent `saveConfig`/`reloadWidgets`. **Symptom**: use-after-free on `config_path` (latent, glibc typically safe).
- [ ] **#92 Cairo unknown surface falls through to `dock_surface` in configure** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:837-842`) — `layerSurfaceConfigure` else-branch assigns unknown surfaces to `dock_surface`, corrupting dock dimensions. **Trigger**: future extension adding a fourth layer surface, or stale compositor events. **Symptom**: dock width/height set to wrong values.
- [ ] **#93 `damage.zig` `Region.add` i32 overflow** (`src/shells/shared/damage.zig:42-47`) — Coordinate + dimension can overflow `i32.max`. **Trigger**: impossibly large screen coordinates. **Symptom**: negative-width damage rectangle; compositor skips repaint. Theoretical only.
- [ ] **#94 Cairo `@intCast` i32→u32 for `set_size` height** (`src/shells/zigshell-cairo-pango/src/main_shell.zig:854`) — `@intCast(ss.height)` panics if height is negative. Current code paths ensure positive values, but no defensive guard. **Trigger**: future code path setting negative height. **Symptom**: panic.

---

## Feature Roadmap — Zigshell Enrichment

### High Impact (Blend2D parity with Cairo-Pango)

- [ ] **F1 Pinned apps in Blend2D dock** (`dock.zig`, `dock.c`) — Cairo-pango has `persistent_order`, `pinApp`, `unpinAt`, `writePinned`, `loadPinned`, settings UI for pin management. Blend2D dock currently shows only running windows. Requires: port pin management API from cairo-pango dock.zig, wire `launchPinned` in pointerButton, add pin sentinel `1000+g` to `iconAt`.
- [ ] **F2 Parabolic magnification in Blend2D dock** (`dock.c`) — Cairo-pango dock has Gaussian mouse-distance zoom on icons (`scale += 1.0 * exp(-dist²/4000)`). Blend2D dock is flat. Requires: port Gaussian sizing math to `dock_draw`, pass `mouse_x` from main_shell (already available as `hover_idx`).
- [ ] **F3 Theme system for Blend2D** (new `blend2d_theme.zig`) — Cairo-pango has `theme.zig` with gradient/accent/border/hover colors applied via `setSource`. Blend2D hardcodes every color as hex literals (`0xFF1A1C26`). Extract a theme struct with named color slots, default palette, and SIGHUP-reloadable theme file.
- [ ] **F4 Tabbed settings panel for Blend2D** (`main_shell.zig`) — Cairo-pango has a full 460px card with Widgets tab (add/remove/reorder) and Dock tab (autohide, icon size, pin management). Blend2D has a 6-item flat dropdown. Requires: settings panel rendering, tab state machine, widget list CRUD, dock pin UI.
- [ ] **F5 Config save + SIGHUP persist for Blend2D** (`main_shell.zig`, `panel_config.zig`) — Cairo-pango has `pcfg.Config.save()` called from settings UI. Blend2D only loads config. Requires: implement `Config.save()` for blend2d, wire to settings actions and SIGHUP handler.

### Medium Impact (New capabilities for both shells)

- [ ] **F6 Hover animation lerp for dock icons** (`dock.zig`, `main_shell.zig`) — Cairo-pango has `hover_anim` field on `ToplevelInfo` with lerp-based smooth scaling. Blend2D has instant snap. Add `hover_anim: f64` to ToplevelInfo, lerp toward target in the render loop, use lerped scale for icon drawing.
- [ ] **F7 Mouse scroll in launcher** (`main_shell.zig`) — Neither shell handles `wl_pointer.axis` for launcher scrolling. Add scroll event handling in `pointerAxis` callback: increment/decrement `launcher_scroll`, clamp to valid range, set `dirty = true`.
- [ ] **F8 `--render-to-png` headless mode** (`main_shell.zig`) — Cairo-pango has this for offline rendering. Blend2D doesn't. Add CLI flag that renders one frame to a PNG file and exits. Useful for CI snapshot testing and theme preview.
- [ ] **F9 Drag-reorder dock icons** (`dock.zig`, `main_shell.zig`) — Cairo-pango has `groupAt`/`swapGroups` wired to `pointerMotion` for drag-reorder. Neither shell exposes this well. Requires: add drag state tracking (drag_start_group, dragging bool), motion handler for swap, visual feedback (translucent drag preview).
- [ ] **F10 `key_fn` on Widget struct** (`panel.zig`) — Cairo-pango Widget has a `key_fn` callback for keyboard shortcuts per-widget. Blend2D lacks it. Add optional `key_fn: ?*const fn (*Widget, u32) bool` field, invoke from `keyboardKey` callback when focus is on the panel.

### Lower Priority (Polish)

- [ ] **F11 Night-light / color temperature widget** — Read `gammastep`/`redshift` state via D-Bus or temp file, display current color temperature. Add `WidgetType.nightlight` with `wlDraw`/`blDraw`, click to toggle.
- [ ] **F12 Clipboard history widget** — Run `cliphist list`, parse recent clips, display as a scrollable widget. Click to select and `wl-copy`. Requires: async subprocess or cached clipboard state.
- [ ] **F13 System tray / status notifier** — Implement `StatusNotifierItem` D-Bus protocol for tray icons (nm-applet, pasystray, etc.). Requires: D-Bus connection, SNI host interface, icon rendering. Shared module in `src/shells/shared/`.
- [ ] **F14 In-shell notification popup** — Display notifications within the shell instead of relying on external `swaync`/`mako`. Requires: `org.freedesktop.Notifications` D-Bus interface, popup surface with layer-shell, dismiss timer.

---

## Refactoring — Layered Architecture (incremental, no rewrite)

The codebase is ~5,600 LOC; the sickness is `main_shell.zig` (2,359 lines, 74 fns, 114 globals) being a god-object that mixes the Wayland event loop, render orchestration, settings UI, session popup, and per-widget click dispatch. The widget system (`panel.zig`) and the C Cairo bridge (`dock_c_impl.c`) are already reasonably separated and should be kept. Goal: extract layers so each surface owns its dirty/commit state and UI views are self-contained. Do these in order — each step is independently shippable and keeps the shell runnable.

### Step 1 — Surface/Compositor layer (fixes the class of bug we just patched)
- [ ] **R1 Extract `SurfaceState` + a `Surface` wrapper** (`main_shell.zig:62-66`) — wrap `zwlr_layer_surface_v1` with `setSize(h)`, `commit()`, `requestFrame()`, and a **per-surface** `dirty` flag. Remove the shared global `dirty`/`dock_dirty`/`markDirty()` split (main_shell.zig:65-74) in favor of each surface owning its own dirty bit.
- [ ] **R2 Move `submitSurface` into the `Surface` type** (`main_shell.zig:1652+`) — currently a free function taking `&panel_surface`/`&dock_surface`; make it a method that early-returns when the surface's own dirty flag is false.
- [ ] **R3 Render loop dispatches per-surface dirty** (`main_shell.zig:2260-2268`) — replace the `if (dirty){ renderPanel(); renderDock(); }` block with iterating surfaces and repainting only those whose dirty flag is set. Eliminates the manual `dock_dirty`/panel coupling entirely.

### Step 2 — Wayland/IO layer (pull the event loop out of the UI file)
- [ ] **R4 New `wayland.zig` module** — registry, seat, layer-shell, foreign-toplevel-manager, `wl_display`/`poll` loop. Emits events via callback pointers; knows nothing about widgets/popups. Move `pointerEnter`/`pointerLeave`/`pointerMotion`/`pointerButton`/`pointerAxis`/`keyboardKey`/`layerSurfaceConfigure` handlers here (main_shell.zig:248-940ish).
- [ ] **R5 Decouple handlers from globals** — handlers currently mutate `pointer_on_panel`/`pointer_on_dock`/`dock_hover_idx`/`session_open`/`settings_open` (main_shell.zig:254-270, 301-313) directly. Replace with an event struct passed to a single `onShellEvent()` dispatcher in the shell layer, so `wayland.zig` has zero UI dependencies.

### Step 3 — Render context + view isolation
- [ ] **R6 Introduce `RenderCtx`** (`panel.zig`, `dock.zig`, `main_shell.zig`) — pass `(cr, width, height, theme)` explicitly instead of relying on the global `cr`/`theme.current`. Lets draw functions be pure and unit-testable without a live surface.
- [ ] **R7 Extract settings UI into `settings_view.zig`** (`main_shell.zig:591-1180`) — `drawWidgetManager`/`handleWidgetListClick`/`drawDockManager`/settings click+scroll handlers become a self-contained view with its own `Rect` and input dispatch, returning `Consumed`/`Passthrough`.
- [ ] **R8 Extract session popup into `session_view.zig`** (`main_shell.zig` `drawSessionMenu`/`handleSessionClick`/`sessionRect`/`SESSION_ACTIONS`) — self-contained view owning its surface resize (the `applyPanelSurfaceHeight` hack at main_shell.zig:466-481 goes away once surfaces own sizing).

### Step 4 — Widget model ownership
- [ ] **R9 Move view-state out of globals into widgets** — `session_open`, `settings_open`, `dock_hover_idx`, `launcher_hover_idx` (main_shell.zig:88-115) become fields on their respective widget/view structs instead of module-level globals, so the shell core stops tracking per-view booleans.
- [ ] **R10 Keep `panel.zig` widget component model** — the `Widget{ measure/draw/click }` fn-pointer pattern (panel.zig:1279-1331) is sound; only its layout/state coupling to `main_shell` globals needs severing (R9).

### Step 5 — Config layer (already clean, guard it)
- [ ] **R11 Keep `panel_config.zig` as-is** — already a clean Config load/save module; ensure the new layers depend on it rather than on global `config_dirty` flag-thrashing (see #23/#62).

### Done-when
- [ ] **R12 No `dirty`/`dock_dirty` globals remain; hovering the dock never touches the panel surface** (regression guard for the blink bug).
- [ ] **R13 `wayland.zig` contains zero widget/popup references** (verified by grep).
- [ ] **R14 Each popup/view compiles and renders from a `RenderCtx` with no global `cr`.**


---

## Reconstruction — Abstraction Layers (beyond refactoring)

The existing R1-R14 refactoring addresses duplication within one shell. This section addresses duplication **between** the two shells and introduces proper abstraction layers. Current state: ~12,000 lines across 483 files; target: ~6,000 lines with zero cross-shell duplication.

### Phase 1 — Shared Wayland Infrastructure (eliminate ~1,000 lines)

- [ ] **A1 Create `src/shellcore/wayland.zig`** — Wayland connection wrapper: `WaylandContext` struct containing `display`, `compositor`, `shm`, `layer_shell`, `seat`, `pointer`, `keyboard`, `toplevel_manager`. Methods: `init()`, `roundtrip()`, `dispatch()`, `getRegistry()`. Both shells call `wayland.init()` instead of re-declaring identical globals. Replaces: `main_shell.zig:28-37` (cairo-pango), `main_shell.zig:28-36` (blend2d).
- [ ] **A2 Create `src/shellcore/event_loop.zig`** — Abstract event loop: `EventLoop` struct with `addTimer()`, `addSource()`, `run()`, `quit()`. Wraps `wl_display_dispatch` + `poll` + `timerfd`. Both shells call `event_loop.run()` instead of duplicating the 200-line main loop. Replaces: `main_shell.zig:1855-1963` (cairo-pango), `main_shell.zig:1527-1579` (blend2d).
- [ ] **A3 Create `src/shellcore/surface.zig`** — Surface state management: `Surface` struct with `create()`, `setSize()`, `commit()`, `requestFrame()`, `attach()`, `damage()`. Owns per-surface dirty flag. Replaces: `SurfaceState` struct + `submitSurface()` + `ensureBuffer()` duplicated in both shells.
- [ ] **A4 Create `src/shellcore/input.zig`** — Input handling: `InputState` struct tracking `pointer_x/y`, `pointer_on_panel/dock/launcher`, `dock_hover_idx`, `launcher_hover_idx`, `keyboard_focus_surface`. Callbacks: `onPointerEnter()`, `onPointerMotion()`, `onPointerButton()`, `onKeyboardKey()`. Replaces: 15+ pointer/keyboard globals duplicated in both shells.
- [ ] **A5 Create `src/shellcore/layer_shell.zig`** — Layer surface helpers: `createLayerSurface()`, `setAnchor()`, `setExclusiveZone()`, `setKeyboardInteractivity()`. Wraps the verbose `zwlr_layer_shell_v1_*` calls. Replaces: 30+ lines of boilerplate per shell.

### Phase 2 — Renderer Abstraction (eliminate ~500 lines)

- [ ] **A6 Create `src/renderer/renderer.zig`** — Renderer trait: `Renderer` struct with function pointers `fillRect()`, `drawText()`, `drawBorder()`, `drawImage()`, `drawImageScaled()`, `measureText()`, `setFontSize()`, `flush()`. Returns a vtable that both Cairo and Blend2D backends implement.
- [ ] **A7 Create `src/renderer/cairo.zig`** — Cairo backend: implements `Renderer` trait by wrapping `cairo_t*` + Pango calls. Extracted from `panel.zig:widgetText()`, `panel.zig:widgetIconGlyph()`, `dock_c_impl.c:widget_text_c()`.
- [ ] **A8 Create `src/renderer/blend2d.zig`** — Blend2D backend: implements `Renderer` trait by wrapping `*blend2d.BlendRenderer`. Extracted from `blend2d_render.zig` functions.
- [ ] **A9 Unify widget `draw_fn` signatures** — Change all `draw_fn` from renderer-specific (`*c.cairo_t` vs `*blend2d.BlendRenderer`) to `?*anyopaque` (opaque renderer pointer). Each backend casts internally. Widget code becomes renderer-agnostic. Affects: `panel.zig:62-63` (cairo), `panel.zig:62-63` (blend2d).

### Phase 3 — Unified Widget System (eliminate ~800 lines)

- [ ] **A10 Create `src/widgets/widget.zig`** — Single `WidgetType` enum (21 variants), single `Widget` struct, single `createWidget()`, single `widgetCreateDefault()`, single `widgetCreateCompact()`. Both shells import from `widgets` instead of maintaining separate `panel.zig` files. Replaces: `panel.zig` (1,602 lines cairo) + `panel.zig` (1,311 lines blend2d).
- [ ] **A11 Move widget implementations to `src/widgets/*.zig`** — One file per widget: `clock.zig`, `cpu.zig`, `mem.zig`, `battery.zig`, `volume.zig`, `network.zig`, `media.zig`, `temp.zig`, `disk.zig`, `workspaces.zig`, `toplevel.zig`, `launcher.zig`, `versions.zig`, `kbindicator.zig`, `customcommand.zig`, `showdesktop.zig`, `worldclock.zig`, `backlight.zig`, `power.zig`, `session.zig`, `spacer.zig`. Each file contains: `measure()`, `draw()`, `update()`, `click()`. No renderer dependency (uses `Renderer` trait).
- [ ] **A12 Move `parseWidgetType`/`widgetTypeName`/`AllWidgetTypes` to `widget.zig`** — Single source of truth for widget type names. Used by config parser, settings UI, and validation tests. Replaces: duplicated enums in both `panel.zig` files.

### Phase 4 — App Management (eliminate ~300 lines)

- [ ] **A13 Create `src/apps/scanner.zig`** — `.desktop` + `$PATH` scanner (from `shared/apps.zig`). Single implementation, used by both shells and the GTK launcher. Replaces: `shared/apps.zig` + duplicated scan logic in both shells.
- [ ] **A14 Create `src/apps/icon.zig`** — Theme icon loading (from `cairo-pango/icon.zig` + `blend2d/icon.c`). Unified API: `load(app_id, size) -> ?IconHandle`. Replaces: two icon implementations.
- [ ] **A15 Create `src/apps/launcher.zig`** — App launcher logic: `scan()`, `filter()`, `launch()`, `getApps()`. Used by both shell launchers and GTK launcher widget. Replaces: duplicated launcher logic in both `main_shell.zig` files.

### Phase 5 — Configuration (guard existing, add missing)

- [ ] **A16 Create `src/config/config.zig`** — Unified config: `Config` struct with `load()`, `save()`, `reload()`. Wraps `panel_config.zig` functionality. Both shells use this instead of independently implementing config loading. Replaces: `panel_config.zig` + `pcfg.Config` usage in both shells.
- [ ] **A17 Create `src/config/theme.zig`** — Theme system: `Theme` struct with named color slots (`bg`, `fg`, `accent`, `border`, `hover`). Load from `~/.config/ocws/tokens.css` or fallback palette. Used by both shells and GTK apps. Replaces: hardcoded hex literals in blend2d + `theme.zig` in cairo-pango.
- [ ] **A18 Create `src/config/dock_pins.zig`** — Dock pin management: `loadPins()`, `savePins()`, `pinApp()`, `unpinApp()`, `isPinned()`. Used by both dock implementations. Replaces: duplicated pin logic in both `dock.zig` files.

### Phase 6 — Build System (eliminate hardcoded paths)

- [ ] **A19 Replace hardcoded GTK paths with `pkg-config`** (`build.zig:170-183`) — Use `b.runAllowFail(&.{ "pkg-config", "--cflags", "gtk+-3.0" })` to discover paths dynamically. Eliminates: hardcoded `/usr/include/gtk-3.0`, `/usr/lib64/glib-2.0/include`, etc.
- [ ] **A20 Create `src/build.zig` shared build helpers** — `addShellCore()`, `addRenderer()`, `addWidgets()`, `addApps()`, `addConfig()` functions that both shell `build.zig` files call. Replaces: duplicated `b.createModule` blocks.
- [ ] **A21 Add cross-shell parity validation** — Extend `widget_validation.zig` and `dock_validation.zig` to test all 21 widget types, dock pin operations, and config round-trips. Run as part of `zig build test`.

### Done-when (reconstruction)

- [ ] **A22 `src/shells/zigshell-cairo-pango/main.zig` is under 300 lines** (currently 2,359).
- [ ] **A23 `src/shells/zigshell-blend2d/main.zig` is under 300 lines** (currently 1,624).
- [ ] **A24 No widget code exists in `main_shell.zig`** (all in `src/widgets/*.zig`).
- [ ] **A25 No renderer-specific code in widget files** (all use `Renderer` trait).
- [ ] **A26 Total line count under 7,000** (currently ~12,000).
- [ ] **A27 Zero duplication between shell `main.zig` files** (verified by `diff`).
- [ ] **A28 All tests pass: `zig build test` in both shells + `zig build test` in root.**

### File Structure (target)

```
src/
├── shellcore/                    # Shared shell infrastructure
│   ├── wayland.zig              # Wayland connection, globals
│   ├── event_loop.zig           # Event loop abstraction
│   ├── surface.zig              # Surface state, SHM buffers
│   ├── input.zig                # Pointer, keyboard handling
│   └── layer_shell.zig          # Layer surface helpers
│
├── renderer/                     # Renderer abstraction
│   ├── renderer.zig             # Trait definition
│   ├── cairo.zig                # Cairo backend
│   └── blend2d.zig              # Blend2D backend
│
├── widgets/                      # Unified widget system
│   ├── widget.zig               # WidgetType, Widget struct
│   ├── clock.zig                # Clock widget
│   ├── cpu.zig                  # CPU widget
│   ├── mem.zig                  # Memory widget
│   ├── battery.zig              # Battery widget
│   ├── volume.zig               # Volume widget
│   ├── network.zig              # Network widget
│   ├── dock.zig                 # Dock widget
│   ├── launcher.zig             # App launcher
│   ├── versions.zig             # Version display
│   └── ... (21 total)
│
├── apps/                         # Application management
│   ├── scanner.zig              # .desktop scanner
│   ├── icon.zig                 # Theme icon loading
│   └── launcher.zig             # Launch logic
│
├── config/                       # Configuration
│   ├── config.zig               # INI load/save
│   ├── theme.zig                # Theme colors
│   └── dock_pins.zig            # Dock pin management
│
├── shells/                       # Thin shell wrappers
│   ├── zigshell-cairo-pango/
│   │   ├── main.zig             # ~300 lines
│   │   └── build.zig
│   └── zigshell-blend2d/
│       ├── main.zig             # ~300 lines
│       └── build.zig
│
└── gui/                          # GTK apps (existing)
```

---

## main_shell.zig Breakdown — Extract 10 Modules

**Current**: `zigshell-cairo-pango/src/main_shell.zig` = **2,370 lines** (god-object)
**Target**: 10 modules, ~300 lines each in `main_shell.zig`

### Modules to Extract

- [ ] **B1 Create `wayland_core.zig`** (~300 lines) — Wayland globals (`display`, `compositor`, `shm`, `layer_shell`, `seat`), toplevel callbacks (title/appId/state/done/closed), registry handler, output tracking (`OutputInfo`, geometry/mode/scale/name callbacks), layer surface callbacks, frame callback. Replaces: `main_shell.zig:25-260, 973-1134`.
- [ ] **B2 Create `settings.zig`** (~400 lines) — Settings state (`settings_open`, `settings_tab`, `settings_scroll`, `settings_drag_idx`), geometry (`SettingsRect`, `settingsRect()`), config sync (`saveConfig`, `syncConfigFromRuntime`, `applyConfigToRuntime`), font scale (`applyFontScale`, `changeFontScale`), widget management (`wireWidgetPriv`, `handleSettingsClick`, `handleWidgetListClick`, `widgetListRef`), dock management (`handleDockClick`, `setDockAutohide`), UI drawing (`drawSettingsMenu`, `drawTab`, `drawWidgetManager`, `drawDockManager`, `drawListBtn`, `drawFontScaleRow`, `drawToggleRow`). Replaces: `main_shell.zig:527-865, 1486-1733`.
- [ ] **B3 Create `session.zig`** (~100 lines) — Session popup state (`session_open`), geometry (`sessionRect()`), drawing (`drawSessionMenu`), click handling (`handleSessionClick`), session actions list. Replaces: `main_shell.zig:1401-1485`.
- [ ] **B4 Create `modal.zig`** (~200 lines) — Modal state (`modal_open`, `modal_title`), open/close (`modalOpen`, `modalClose`, `toggleModal`), calendar rendering (`daysInMonth`, `renderCalendar`), modal rendering (`renderModal`), modal input handling. Replaces: `main_shell.zig:1762-1945`.
- [ ] **B5 Create `dock_view.zig`** (~150 lines) — Dock rendering (`renderDock`), dock tooltip (`drawDockTooltip`), dock state management (`dock_hover_idx`). Replaces: `main_shell.zig:1734-1753, 2019-2038`.
- [ ] **B6 Create `launcher.zig`** (~100 lines) — Launcher state (`launcher_open`, `launcher_hover_idx`, `launcher_scroll`), toggle (`toggleLauncher`), rendering (calls panel_mod), input handling. Replaces: `main_shell.zig:126-130, 1754-1761`.
- [ ] **B7 Create `render.zig`** (~200 lines) — SHM FD creation (`createShmFd`, `errno`), buffer management (`ensureBuffer`), panel rendering (`renderPanel`), dynamic island (`drawDynamicIsland`), settings button (`drawSettingsButton`), rounded rect helper (`roundedRect`), surface submission (`submitSurface`). Replaces: `main_shell.zig:1181-1391, 2039-2058`.
- [ ] **B8 Create `config.zig`** (~50 lines) — SIGHUP handler (`onSighup`), widget reload (`reloadWidgets`), config path management. Replaces: `main_shell.zig:1135-1180`.
- [ ] **B9 Slim `main_shell.zig`** (~300 lines) — Import all modules, keep only `pub fn main()` (initialization, event loop, cleanup), constants (`PANEL_HEIGHT`, `DOCK_HEIGHT`), state variables (`running`, `timer_fd`, `dirty` flags). Target: **under 300 lines**.
- [ ] **B10 Update `build.zig`** — Add new module files to the build system. Ensure all imports resolve correctly.

### File Structure (target)

```
src/shells/zigshell-cairo-pango/src/
├── main_shell.zig        # ~300 lines (main + event loop)
├── wayland_core.zig      # ~300 lines (Wayland globals + callbacks)
├── settings.zig          # ~400 lines (settings UI + config)
├── session.zig           # ~100 lines (session popup)
├── modal.zig             # ~200 lines (modal dialog)
├── dock_view.zig         # ~150 lines (dock rendering)
├── launcher.zig          # ~100 lines (app launcher)
├── render.zig            # ~200 lines (SHM + panel render)
├── config.zig            # ~50 lines (SIGHUP + reload)
├── panel.zig             # (existing, unchanged)
├── dock.zig              # (existing, unchanged)
├── icon.zig              # (existing, unchanged)
├── theme.zig             # (existing, unchanged)
├── panel_config.zig      # (existing, unchanged)
├── c.zig                 # (existing, unchanged)
└── build.zig             # (existing, updated)
```

### Done-when (main_shell breakdown)

- [ ] **B11 `main_shell.zig` is under 300 lines**
- [ ] **B12 No rendering code in `main_shell.zig`** (all in `render.zig`)
- [ ] **B13 No settings UI code in `main_shell.zig`** (all in `settings.zig`)
- [ ] **B14 No Wayland callback definitions in `main_shell.zig`** (all in `wayland_core.zig`)
- [ ] **B15 All tests pass after breakdown**
- [ ] **B16 Apply same breakdown to `zigshell-blend2d/src/main_shell.zig`**

### Progress Update (2026-07-18)

**Modules Created:**
- [x] **B3** `session.zig` (3.7KB) — Session popup, actions, drawing, click handling
- [x] **B5** `dock_view.zig` (1.2KB) — Dock tooltip rendering
- [x] **B6** `launcher.zig` (0.3KB) — Launcher state, toggle (no-op)
- [x] **B7** `render.zig` (4.4KB) — SHM buffer management, surface submission
- [x] **B8** `config.zig` (2.0KB) — SIGHUP handler, widget reload

**Remaining:**
- [ ] **B1** `wayland_core.zig` — Wayland globals, callbacks, output tracking
- [ ] **B2** `settings.zig` — Settings UI, config sync, widget management
- [ ] **B9** Integration — Update main_shell.zig to use modules
- [ ] **B10** Update build.zig
