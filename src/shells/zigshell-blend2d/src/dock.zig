// dock.zig — Dock rendering via Blend2D
// Adapted from zigshell-cairo-pango: cairo_t → BlendRenderer.

const std = @import("std");
const c = @import("c.zig").c;

const toplevel = @import("toplevel.zig");
const icon = @import("icon.zig");
const blend2d = @import("blend2d_render.zig");

const PAD = 8;
const FOCUS_BAR_H = 3;

pub const DOCK_ICON_SIZE = 28;

fn iconX(slot_idx: i32, start_x: i32) i32 {
    return start_x + slot_idx * (DOCK_ICON_SIZE + PAD);
}

pub fn draw(
    renderer: *blend2d.BlendRenderer,
    w: i32,
    h: i32,
    tops: []toplevel.ToplevelInfo,
    top_count: i32,
    hover_idx: i32,
) void {
    // Background gradient (two-tone)
    renderer.fillRect(0, 0, @floatFromInt(w), @divTrunc(@as(f64, @floatFromInt(h)), 2.0), 0xFF141419);
    renderer.fillRect(0, @divTrunc(@as(f64, @floatFromInt(h)), 2.0), @floatFromInt(w), @divTrunc(@as(f64, @floatFromInt(h)), 2.0), 0xFF0D0D12);

    // Top border line
    renderer.fillRect(0, 0, @floatFromInt(w), 1, 0xFF404045);

    const cy = @divTrunc(h - DOCK_ICON_SIZE, 2);

    // Center the running-apps icon row horizontally
    const slot = DOCK_ICON_SIZE + PAD;
    const total_w: i32 = if (top_count > 0) top_count * slot - PAD else 0;
    var start_x = @divTrunc(w - total_w, 2);
    if (start_x < 0) start_x = 0;

    for (0..@intCast(top_count)) |i| {
        const x = iconX(@intCast(i), start_x);
        const icon_y = cy;

        const app_id_slice = tops[i].app_id[0..std.mem.indexOfScalar(u8, &tops[i].app_id, 0) orelse tops[i].app_id.len];
        const title_slice = tops[i].title[0..std.mem.indexOfScalar(u8, &tops[i].title, 0) orelse tops[i].title.len];
        const name = if (app_id_slice.len > 0) app_id_slice else title_slice;

        const icon_img = icon.load(@ptrCast(name.ptr), DOCK_ICON_SIZE) orelse
            icon.fallback(@ptrCast(name.ptr), DOCK_ICON_SIZE);

        // Hover highlight
        if (@as(i32, @intCast(i)) == hover_idx) {
            renderer.fillRect(
                @floatFromInt(x - 4),
                @floatFromInt(icon_y - 4),
                @floatFromInt(DOCK_ICON_SIZE + 8),
                @floatFromInt(DOCK_ICON_SIZE + 8),
                0x1FFFFFFF, // white 12% alpha
            );
        }

        // Draw the icon
        var loaded_icon = icon_img;
        renderer.drawImage(&loaded_icon, @floatFromInt(x), @floatFromInt(icon_y));

        // Focus indicator bar
        if (tops[i].focused) {
            renderer.fillRect(
                @floatFromInt(x + 2),
                @floatFromInt(cy - FOCUS_BAR_H),
                @floatFromInt(DOCK_ICON_SIZE - 4),
                @floatFromInt(FOCUS_BAR_H),
                0xFF4C7FBF, // blue
            );
        }
    }
}

pub fn iconAt(w: i32, _: i32, _: []toplevel.ToplevelInfo, top_count: i32, mouse_x: i32) i32 {
    const slot = DOCK_ICON_SIZE + PAD;
    const total_w: i32 = if (top_count > 0) top_count * slot - PAD else 0;
    var start_x = @divTrunc(w - total_w, 2);
    if (start_x < 0) start_x = 0;

    for (0..@intCast(top_count)) |i| {
        const x = iconX(@intCast(i), start_x);
        if (mouse_x >= x and mouse_x < x + DOCK_ICON_SIZE + PAD) return @intCast(i);
    }
    return -1;
}
