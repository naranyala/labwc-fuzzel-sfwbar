// config.zig — SIGHUP handler and widget reload
const std = @import("std");
const c = @import("c.zig").c;
const pcfg = @import("panel_config.zig");
const panel_mod = @import("panel.zig");

pub var reload_config: bool = false;

pub fn onSighup(_: c_int) callconv(.c) void {
    reload_config = true;
}

pub fn reloadWidgets(
    config_path: ?[]const u8,
    widgets: []panel_mod.Widget,
    widget_count: *i32,
) void {
    const path = config_path orelse return;
    const old_count = widget_count.*;
    var old_widgets: [panel_mod.MAX_WIDGETS]panel_mod.Widget = undefined;
    const preserve = @min(@as(usize, @intCast(@max(0, old_count))), panel_mod.MAX_WIDGETS);
    for (0..preserve) |i| old_widgets[i] = widgets[i];

    _ = pcfg.Config.load(std.heap.page_allocator, path, .{ .widgets = widgets, .count = widget_count });

    for (0..@intCast(@max(0, widget_count.*))) |i| {
        for (0..preserve) |j| {
            if (widgets[i].wtype == old_widgets[j].wtype) {
                widgets[i].cpu_prev_total = old_widgets[j].cpu_prev_total;
                widgets[i].cpu_prev_idle = old_widgets[j].cpu_prev_idle;
                widgets[i].cpu_txt = old_widgets[j].cpu_txt;
                widgets[i].mem_txt = old_widgets[j].mem_txt;
                widgets[i].temp_txt = old_widgets[j].temp_txt;
                widgets[i].disk_txt = old_widgets[j].disk_txt;
                widgets[i].bat_lvl = old_widgets[j].bat_lvl;
                widgets[i].bat_charging = old_widgets[j].bat_charging;
                widgets[i].bat_txt = old_widgets[j].bat_txt;
                widgets[i].vol_mute = old_widgets[j].vol_mute;
                widgets[i].vol_txt = old_widgets[j].vol_txt;
                widgets[i].net_txt = old_widgets[j].net_txt;
                widgets[i].net_rx_prev = old_widgets[j].net_rx_prev;
                widgets[i].net_tx_prev = old_widgets[j].net_tx_prev;
                break;
            }
        }
    }
    std.log.info("zigshell-cairo-pango: reloaded config from {s}", .{path});
}
