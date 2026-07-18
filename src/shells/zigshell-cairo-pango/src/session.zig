// session.zig — Session popup module
const std = @import("std");
const c = @import("c.zig").c;
const panel_mod = @import("panel.zig");

pub const SESSION_W: i32 = 220;
pub const SESSION_ROW_H: i32 = 36;
pub const SET_CARD_Y: i32 = 52;

pub const SessionAction = struct {
    label: []const u8,
    glyph: []const u8,
    cmd: []const u8,
};

pub const SESSION_ACTIONS = [_]SessionAction{
    .{ .label = "Lock", .glyph = "🔒", .cmd = "swaylock -f -c 000000 &" },
    .{ .label = "Logout", .glyph = "⏏", .cmd = "loginctl terminate-user $USER &" },
    .{ .label = "Suspend", .glyph = "🌙", .cmd = "systemctl suspend &" },
    .{ .label = "Hibernate", .glyph = "❄", .cmd = "systemctl hibernate &" },
    .{ .label = "Reboot", .glyph = "🔄", .cmd = "systemctl reboot &" },
    .{ .label = "Shutdown", .glyph = "⏻", .cmd = "systemctl poweroff &" },
};

pub const SettingsRect = struct { x: i32, y: i32, w: i32, h: i32 };

pub fn sessionRect(panel_width: i32) SettingsRect {
    return .{
        .x = panel_width - SESSION_W - 12,
        .y = SET_CARD_Y,
        .w = SESSION_W,
        .h = @as(i32, @intCast(SESSION_ACTIONS.len)) * SESSION_ROW_H + 12,
    };
}

pub fn roundedRect(cr: *c.cairo_t, x: f64, y: f64, w: f64, h: f64, r: f64) void {
    c.cairo_move_to(cr, x + w - r, y);
    c.cairo_arc(cr, x + w - r, y + r, r, -std.math.pi / 2.0, 0);
    c.cairo_arc(cr, x + w - r, y + h - r, r, 0, std.math.pi / 2.0);
    c.cairo_arc(cr, x + r, y + h - r, r, std.math.pi / 2.0, std.math.pi);
    c.cairo_arc(cr, x + r, y + r, r, std.math.pi, 3.0 * std.math.pi / 2.0);
    c.cairo_close_path(cr);
}

pub fn draw(cr: *c.cairo_t, panel_width: i32, pointer_x: i32, pointer_y: i32, pointer_on_panel: bool) void {
    const r = sessionRect(panel_width);
    c.cairo_set_source_rgba(cr, 0.06, 0.06, 0.09, 0.96);
    roundedRect(cr, @floatFromInt(r.x), @floatFromInt(r.y), @floatFromInt(r.w), @floatFromInt(r.h), 12.0);
    c.cairo_fill(cr);
    c.cairo_set_source_rgba(cr, 0.3, 0.5, 1.0, 0.25);
    c.cairo_set_line_width(cr, 1.5);
    roundedRect(cr, @floatFromInt(r.x), @floatFromInt(r.y), @floatFromInt(r.w), @floatFromInt(r.h), 12.0);
    c.cairo_stroke(cr);
    _ = panel_mod.widgetText(cr, "Session", r.x + 14, r.y + 24, "Inter Bold 13", 0.98, 0.98, 1.0);
    var i: usize = 0;
    while (i < SESSION_ACTIONS.len) : (i += 1) {
        const a = SESSION_ACTIONS[i];
        const ry = r.y + 12 + @as(i32, @intCast(i)) * SESSION_ROW_H + 22;
        const hover = pointer_on_panel and pointer_x >= r.x + 6 and pointer_x < r.x + r.w - 6 and pointer_y >= ry and pointer_y < ry + SESSION_ROW_H - 4;
        if (hover) {
            c.cairo_set_source_rgba(cr, 0.2, 0.45, 0.95, 0.16);
            roundedRect(cr, @floatFromInt(r.x + 6), @floatFromInt(ry), @floatFromInt(r.w - 12), @floatFromInt(SESSION_ROW_H - 4), 7.0);
            c.cairo_fill(cr);
        }
        _ = panel_mod.widgetText(cr, @ptrCast(a.glyph.ptr), r.x + 14, ry + SESSION_ROW_H - 8, "Inter 13", 0.9, 0.9, 0.95);
        _ = panel_mod.widgetText(cr, @ptrCast(a.label.ptr), r.x + 40, ry + SESSION_ROW_H - 8, "Inter 12", 0.92, 0.92, 0.95);
    }
}

pub fn handleClick(x: i32, y: i32, _: u32, panel_width: i32) void {
    const r = sessionRect(panel_width);
    if (x < r.x or x > r.x + r.w or y < r.y or y > r.y + r.h) {
        panel_mod.session_open = false;
        return;
    }
    var i: usize = 0;
    while (i < SESSION_ACTIONS.len) : (i += 1) {
        const ry = r.y + 12 + @as(i32, @intCast(i)) * SESSION_ROW_H + 22;
        if (y >= ry and y < ry + SESSION_ROW_H - 4 and x >= r.x + 6 and x < r.x + r.w - 6) {
            const a = SESSION_ACTIONS[i];
            _ = panel_mod.spawnCmd(@ptrCast(a.cmd.ptr));
            panel_mod.session_open = false;
            return;
        }
    }
}
