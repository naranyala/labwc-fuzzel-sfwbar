// dock_view.zig — Dock rendering module
const std = @import("std");
const c = @import("c.zig").c;
const toplevel = @import("shellcore").toplevel;
const panel_mod = @import("panel.zig");

pub fn drawDockTooltip(
    cr: *c.cairo_t,
    surf_w: i32,
    surf_h: i32,
    pointer_x: i32,
    pointer_on_dock: bool,
    dock_hover_idx: i32,
    toplevels_ptr: [*]toplevel.ToplevelInfo,
    toplevel_count: i32,
) void {
    if (!pointer_on_dock) return;
    if (dock_hover_idx < 0 or dock_hover_idx >= toplevel_count) return;
    const title = std.mem.sliceTo(&toplevels_ptr[@intCast(dock_hover_idx)].title, 0);
    if (title.len == 0) return;
    const pad: i32 = 8;
    const tw: i32 = @as(i32, @intCast(title.len)) * 7 + pad * 2;
    const th: i32 = 22;
    var bx: i32 = pointer_x -| @divTrunc(tw, 2);
    if (bx < 0) bx = 0;
    if (bx + tw > surf_w) bx = surf_w - tw;
    const by: i32 = surf_h - th - 4;
    c.cairo_set_source_rgba(cr, 0.08, 0.08, 0.1, 0.95);
    c.cairo_rectangle(cr, @floatFromInt(bx), @floatFromInt(by), @floatFromInt(tw), @floatFromInt(th));
    c.cairo_fill(cr);
    _ = panel_mod.widgetText(cr, @ptrCast(title.ptr), bx + pad, by + th, "Sans 10", 0.9, 0.9, 0.9);
}
