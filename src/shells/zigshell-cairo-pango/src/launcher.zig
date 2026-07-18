// launcher.zig — App launcher module
const std = @import("std");
const c = @import("c.zig").c;

pub var launcher_open = false;
pub var launcher_hover_idx: i32 = -1;
pub var launcher_scroll: i32 = 0;

pub fn toggleLauncher() void {
    // Floating launcher panel is disabled by default. Intentionally a no-op.
    return;
}
