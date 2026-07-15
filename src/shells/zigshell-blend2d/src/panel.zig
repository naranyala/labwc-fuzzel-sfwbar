// panel.zig — Widget system for Blend2D panel
// Adapted from zigshell-cairo-pango: cairo_t → BlendRenderer, Pango → Blend2D text.

const std = @import("std");
const c = @import("c.zig").c;
const toplevel = @import("toplevel.zig");
const icon = @import("icon.zig");
const blend2d = @import("blend2d_render.zig");

const PANEL_HEIGHT = 36;
const MAX_TOPLEVELS = 64;
const MAX_WIDGETS = 64;

// ---- Widget System ----

pub const WidgetType = enum {
    workspaces,
    toplevel_task,
    launcher,
    cpu,
    mem,
    temp,
    disk,
    battery,
    volume,
    network,
    media,
    clock,
    power,
};

pub const Widget = struct {
    wtype: WidgetType,
    name: [64]u8,
    side: u8,
    cached_w: i32,

    measure_fn: ?*const fn (*Widget, i32) i32 = null,
    draw_fn: ?*const fn (*Widget, *blend2d.BlendRenderer, i32, i32, i32) void = null,
    update_fn: ?*const fn (*Widget) void = null,
    click_fn: ?*const fn (*Widget, u32, i32, i32) bool = null,

    priv: ?*anyopaque = null,

    ws_labels: [64]u8 = std.mem.zeroes([64]u8),
    cpu_prev_total: i32 = 0,
    cpu_prev_idle: i32 = 0,
    cpu_txt: [32]u8 = std.mem.zeroes([32]u8),
    mem_txt: [32]u8 = std.mem.zeroes([32]u8),
    temp_txt: [32]u8 = std.mem.zeroes([32]u8),
    disk_txt: [32]u8 = std.mem.zeroes([32]u8),
    bat_lvl: i32 = -1,
    bat_charging: bool = false,
    bat_txt: [32]u8 = std.mem.zeroes([32]u8),
    vol_pct: i32 = 0,
    vol_mute: bool = false,
    vol_txt: [32]u8 = std.mem.zeroes([32]u8),
    net_txt: [64]u8 = std.mem.zeroes([64]u8),
    media_txt: [96]u8 = std.mem.zeroes([96]u8),
    media_playing: bool = false,
    clock_fmt: [32]u8 = std.mem.zeroes([32]u8),
    clock_txt: [64]u8 = std.mem.zeroes([64]u8),
    cmd: [128]u8 = std.mem.zeroes([128]u8),
};

pub const PanelCtx = struct {
    toplevels: []toplevel.ToplevelInfo,
    count: *i32,
    seat: ?*c.wl_seat,
};

// ---- Text Rendering Helpers ----

pub fn widgetText(renderer: *blend2d.BlendRenderer, text: [*:0]const u8, x: i32, h: i32, font_size: f64, r: f64, g: f64, b: f64) i32 {
    renderer.setFontSize(font_size);
    const color: u32 = @as(u32, 255) << 24 | @as(u32, @intFromFloat(r * 255)) << 16 | @as(u32, @intFromFloat(g * 255)) << 8 | @as(u32, @intFromFloat(b * 255));

    const text_slice = std.mem.sliceTo(text, 0);
    const tm = renderer.measureText(text_slice);
    const y_offset = @divTrunc(h - @as(i32, @intFromFloat(tm.height)), 2);
    renderer.drawText(text_slice, @floatFromInt(x), @floatFromInt(y_offset), color);
    return @intFromFloat(tm.width);
}

pub fn widgetIconGlyph(renderer: *blend2d.BlendRenderer, glyph: [*:0]const u8, x: i32, h: i32, r: f64, g: f64, b: f64) void {
    _ = widgetText(renderer, glyph, x, h, 11.0, r, g, b);
}

// ---- Widget Measure/Draw Functions ----

fn wsMeasure(w: *Widget, h: i32) i32 {
    _ = h;
    const len = std.mem.indexOfScalar(u8, &w.ws_labels, 0) orelse w.ws_labels.len;
    return @intCast(len * 7 + 8);
}

fn wsDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    _ = y;
    _ = widgetText(renderer, @ptrCast(&w.ws_labels), x, h, 10.0, 0.6, 0.6, 0.7);
}

fn wsClick(w: *Widget, btn: u32, _: i32, _: i32) bool {
    _ = w;
    if (btn != 1) return false;
    _ = c.system("wlrctl workgroup next");
    return true;
}

fn tlMeasure(w: *Widget, h: i32) i32 {
    if (w.priv == null) return 0;
    const ctx: *PanelCtx = @ptrCast(@alignCast(w.priv.?));
    const icon_size = h - 12;
    if (ctx.count.* == 0) return 0;
    return ctx.count.* * (icon_size + 4);
}

fn tlDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    if (w.priv == null) return;
    const ctx: *PanelCtx = @ptrCast(@alignCast(w.priv.?));
    const icon_size = h - 12;
    const cy = y + @divTrunc(h - icon_size, 2);

    for (0..@intCast(ctx.count.*)) |i| {
        const icon_x = x + @as(i32, @intCast(i)) * (icon_size + 4);
        const name_slice = ctx.toplevels[i].app_id[0..std.mem.indexOfScalar(u8, &ctx.toplevels[i].app_id, 0) orelse ctx.toplevels[i].app_id.len];
        const title_slice = ctx.toplevels[i].title[0..std.mem.indexOfScalar(u8, &ctx.toplevels[i].title, 0) orelse ctx.toplevels[i].title.len];
        const name = if (name_slice.len > 0) name_slice else title_slice;

        const icon_img = icon.load(@ptrCast(name.ptr), icon_size) orelse
            icon.fallback(@ptrCast(name.ptr), icon_size);

        var loaded_icon = icon_img;
        renderer.drawImage(&loaded_icon, @floatFromInt(icon_x), @floatFromInt(cy));

        if (ctx.toplevels[i].focused) {
            renderer.fillRect(
                @floatFromInt(icon_x + 2),
                @floatFromInt(h - 4),
                @floatFromInt(icon_size - 4),
                2,
                0xFF4C7FBF, // blue focus indicator
            );
        }
    }
}

fn tlClick(w: *Widget, btn: u32, lx: i32, ly: i32) bool {
    _ = ly;
    if (w.priv == null) return false;
    const ctx: *PanelCtx = @ptrCast(@alignCast(w.priv.?));
    const icon_size = 24;
    const idx = @divTrunc(lx, icon_size + 4);
    if (idx >= 0 and idx < ctx.count.*) {
        const handle: ?*c.zwlr_foreign_toplevel_handle_v1 = @ptrCast(@alignCast(ctx.toplevels[@intCast(idx)].handle));
        if (btn == 1) {
            if (ctx.seat) |seat| {
                _ = c.zwlr_foreign_toplevel_handle_v1_activate(handle, seat);
            }
        } else if (btn == 3 or btn == 274) {
            _ = c.zwlr_foreign_toplevel_handle_v1_close(handle);
        }
        return true;
    }
    return false;
}

fn launcherMeasure(w: *Widget, h: i32) i32 {
    _ = w;
    _ = h;
    return 22;
}

fn launcherDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    _ = w;
    _ = y;
    widgetIconGlyph(renderer, "\xe2\x8c\x98", x + 4, h, 0.8, 0.8, 0.85); // ⌘
}

fn launcherClick(w: *Widget, btn: u32, x: i32, y: i32) bool {
    _ = x;
    _ = y;
    if (btn != 1) return false;
    _ = c.system(@ptrCast(&w.cmd));
    return true;
}

fn cpuUpdate(w: *Widget) void {
    const f = c.fopen("/proc/stat", "r") orelse return;
    defer _ = c.fclose(f);
    var line: [128]u8 = std.mem.zeroes([128]u8);
    if (c.fgets(&line, line.len, f) != null) {
        var u: i32 = 0;
        var n: i32 = 0;
        var s: i32 = 0;
        var io_i: i32 = 0;
        var irq: i32 = 0;
        var sirq: i32 = 0;
        _ = c.sscanf(&line, "cpu %d %d %d %d %*d %d %d", &u, &n, &s, &io_i, &irq, &sirq);
        const idle = io_i;
        const total = u + n + s + io_i + irq + sirq;
        const dtotal = total - w.cpu_prev_total;
        const didle = idle - w.cpu_prev_idle;
        if (dtotal > 0) {
            const pct = @divTrunc(100 * (dtotal - didle), dtotal);
            _ = std.fmt.bufPrintZ(&w.cpu_txt, "CPU {d}%", .{pct}) catch {};
        }
        w.cpu_prev_total = total;
        w.cpu_prev_idle = idle;
    }
}

fn cpuMeasure(w: *Widget, h: i32) i32 {
    _ = w;
    _ = h;
    return 60;
}

fn cpuDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    const bar_w: f64 = 60.0;
    const bar_h: f64 = @floatFromInt(h - 16);
    const bar_y: f64 = @floatFromInt(y + 8);

    // Bar background
    renderer.fillRect(@floatFromInt(x), bar_y, bar_w, bar_h, 0xFF262633);

    // Fill based on percentage
    var pct: f64 = 0;
    if (c.sscanf(&w.cpu_txt, "CPU %lf%%", &pct) == 1) {
        const fill_w = bar_w * pct / 100.0;
        const color: u32 = if (pct < 50.0)
            0xFF4CCC7F // green
        else if (pct < 80.0)
            0xFFE6B333 // yellow
        else
            0xFFE63333; // red
        renderer.fillRect(@floatFromInt(x), bar_y, fill_w, bar_h, color);
    }

    _ = widgetText(renderer, @ptrCast(&w.cpu_txt), x + 4, h, 9.0, 1.0, 1.0, 1.0);
}

fn cpuClick(w: *Widget, btn: u32, x: i32, y: i32) bool {
    _ = w;
    _ = x;
    _ = y;
    if (btn != 1) return false;
    _ = c.system("foot btop &");
    return true;
}

fn memUpdate(w: *Widget) void {
    const f = c.fopen("/proc/meminfo", "r") orelse return;
    defer _ = c.fclose(f);
    var total: i64 = 0;
    var avail: i64 = 0;
    var k: [32]u8 = std.mem.zeroes([32]u8);
    var v: i64 = 0;
    while (c.fscanf(f, "%31s %ld kB", &k, &v) == 2) {
        if (std.mem.eql(u8, std.mem.sliceTo(&k, 0), "MemTotal:")) total = v
        else if (std.mem.eql(u8, std.mem.sliceTo(&k, 0), "MemAvailable:")) avail = v;
    }
    if (total > 0) {
        const used = total - avail;
        const pct: i64 = @divTrunc(100 * used, total);
        _ = std.fmt.bufPrintZ(&w.mem_txt, "MEM {d}%", .{pct}) catch {};
    }
}

fn memMeasure(w: *Widget, h: i32) i32 {
    _ = w;
    _ = h;
    return 70;
}

fn memDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    const bar_w: f64 = 70.0;
    const bar_h: f64 = @floatFromInt(h - 16);
    const bar_y: f64 = @floatFromInt(y + 8);

    renderer.fillRect(@floatFromInt(x), bar_y, bar_w, bar_h, 0xFF262633);

    var pct: f64 = 0;
    if (c.sscanf(&w.mem_txt, "MEM %lf%%", &pct) == 1) {
        const fill_w = bar_w * pct / 100.0;
        renderer.fillRect(@floatFromInt(x), bar_y, fill_w, bar_h, 0xFF6699E6);
    }

    _ = widgetText(renderer, @ptrCast(&w.mem_txt), x + 4, h, 9.0, 1.0, 1.0, 1.0);
}

fn memClick(w: *Widget, btn: u32, x: i32, y: i32) bool {
    _ = w;
    _ = x;
    _ = y;
    if (btn != 1) return false;
    _ = c.system("foot htop &");
    return true;
}

fn tempUpdate(w: *Widget) void {
    const f = c.fopen("/sys/class/thermal/thermal_zone0/temp", "r") orelse {
        _ = std.fmt.bufPrintZ(&w.temp_txt, "--\xc2\xb0C", .{}) catch {};
        return;
    };
    defer _ = c.fclose(f);
    var mt: i32 = -1;
    _ = c.fscanf(f, "%d", &mt);
    if (mt > 0) {
        _ = std.fmt.bufPrintZ(&w.temp_txt, "{d}\xc2\xb0C", .{@divTrunc(mt, 1000)}) catch {};
    } else {
        _ = std.fmt.bufPrintZ(&w.temp_txt, "--\xc2\xb0C", .{}) catch {};
    }
}

fn tempMeasure(w: *Widget, h: i32) i32 {
    _ = w;
    _ = h;
    return 56;
}

fn tempDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    _ = y;
    widgetIconGlyph(renderer, "\xe2\x99\x81", x, h, 0.9, 0.6, 0.4); // ♨
    _ = widgetText(renderer, @ptrCast(&w.temp_txt), x + 16, h, 9.0, 0.8, 0.8, 0.82);
}

fn tempClick(w: *Widget, btn: u32, x: i32, y: i32) bool {
    _ = w;
    _ = x;
    _ = y;
    if (btn != 1) return false;
    _ = c.system("foot sensors &");
    return true;
}

fn diskMeasure(w: *Widget, h: i32) i32 {
    _ = w;
    _ = h;
    return 64;
}

fn diskDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    _ = y;
    widgetIconGlyph(renderer, "\xe2\xa5\xa5", x, h, 0.5, 0.8, 0.6); // ▥
    _ = widgetText(renderer, @ptrCast(&w.disk_txt), x + 16, h, 9.0, 0.8, 0.8, 0.82);
}

fn diskClick(w: *Widget, btn: u32, x: i32, y: i32) bool {
    _ = w;
    _ = x;
    _ = y;
    if (btn != 1) return false;
    _ = c.system("pcmanfm-qt &");
    return true;
}

fn batMeasure(w: *Widget, h: i32) i32 {
    _ = w;
    _ = h;
    return 64;
}

fn batDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    const bat_w: f64 = 24.0;
    const bat_h: f64 = 14.0;
    const bat_y: f64 = @floatFromInt(y + @divTrunc(h - 14, 2));

    // Outline
    renderer.drawBorder(@as(f64, @floatFromInt(x)), bat_y, bat_w, bat_h, 0xFF9999A6);

    // Nub
    renderer.fillRect(@as(f64, @floatFromInt(x)) + bat_w, bat_y + 4.0, 2.0, bat_h - 8.0, 0xFF9999A6);

    if (w.bat_lvl >= 0) {
        const fill_w = (bat_w - 4.0) * @as(f64, @floatFromInt(w.bat_lvl)) / 100.0;
        const color: u32 = if (w.bat_lvl > 50)
            0xFF4CCC7F
        else if (w.bat_lvl > 20)
            0xFFE6B333
        else
            0xFFE63333;
        renderer.fillRect(@as(f64, @floatFromInt(x)) + 2.0, bat_y + 2.0, fill_w, bat_h - 4.0, color);
    }

    _ = widgetText(renderer, @ptrCast(&w.bat_txt), x + 30, h, 9.0, 0.8, 0.8, 0.82);
}

fn batUpdate(w: *Widget) void {
    const f = c.fopen("/sys/class/power_supply/BAT0/capacity", "r");
    if (f == null) {
        std.mem.copyForwards(u8, &w.bat_txt, "BAT ?");
        return;
    }
    const cap_file = f.?;
    defer _ = c.fclose(cap_file);
    var cap_buf: [32]u8 = std.mem.zeroes([32]u8);
    if (c.fgets(@ptrCast(&cap_buf), cap_buf.len, cap_file) != null) {
        const cap_str = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&cap_buf)), 0);
        w.bat_lvl = std.fmt.parseInt(i32, std.mem.trimEnd(u8, cap_str, "\n\r"), 10) catch -1;
    }

    const st_file = c.fopen("/sys/class/power_supply/BAT0/status", "r");
    if (st_file) |sf| {
        defer _ = c.fclose(sf);
        var st_buf: [32]u8 = std.mem.zeroes([32]u8);
        if (c.fgets(@ptrCast(&st_buf), st_buf.len, sf) != null) {
            const st_str = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&st_buf)), 0);
            w.bat_charging = std.mem.startsWith(u8, std.mem.trimEnd(u8, st_str, "\n\r"), "Charging");
        }
    }

    if (w.bat_lvl < 0) {
        std.mem.copyForwards(u8, &w.bat_txt, "BAT ?");
    } else if (w.bat_charging) {
        _ = std.fmt.bufPrintZ(&w.bat_txt, "+{d}%", .{w.bat_lvl}) catch std.mem.copyForwards(u8, &w.bat_txt, "BAT ?");
    } else {
        _ = std.fmt.bufPrintZ(&w.bat_txt, "{d}%", .{w.bat_lvl}) catch std.mem.copyForwards(u8, &w.bat_txt, "BAT ?");
    }
}

fn batClick(w: *Widget, btn: u32, x: i32, y: i32) bool {
    _ = w;
    _ = x;
    _ = y;
    if (btn != 1) return false;
    _ = c.system("foot upower -i /org/freedesktop/UPower/devices/battery_BAT0 &");
    return true;
}

fn volMeasure(w: *Widget, h: i32) i32 {
    _ = w;
    _ = h;
    return 64;
}

fn volDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    _ = y;
    widgetIconGlyph(renderer, if (w.vol_mute) "\xf0\x9f\x94\x87" else "\xf0\x9f\x94\x8a", x, h, 0.6, 0.8, 0.9); // 🔇 or 🔊
    _ = widgetText(renderer, @ptrCast(&w.vol_txt), x + 18, h, 9.0, 0.8, 0.8, 0.82);
}

fn volClick(w: *Widget, btn: u32, x: i32, y: i32) bool {
    _ = x;
    _ = y;
    if (btn != 1) return false;
    if (w.vol_mute) {
        _ = c.system("pactl set-sink-mute @DEFAULT_SINK@ 0 &");
    } else {
        _ = c.system("pactl set-sink-mute @DEFAULT_SINK@ 1 &");
    }
    return true;
}

fn netMeasure(w: *Widget, h: i32) i32 {
    _ = w;
    _ = h;
    return 92;
}

fn netDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    _ = y;
    widgetIconGlyph(renderer, "\xf0\x9f\x93\xb6", x, h, 0.5, 0.9, 0.6); // 📶
    _ = widgetText(renderer, @ptrCast(&w.net_txt), x + 18, h, 9.0, 0.8, 0.8, 0.82);
}

fn netClick(w: *Widget, btn: u32, x: i32, y: i32) bool {
    _ = w;
    _ = x;
    _ = y;
    if (btn != 1) return false;
    _ = c.system("nm-applet &");
    return true;
}

fn mediaMeasure(w: *Widget, h: i32) i32 {
    _ = h;
    const len = std.mem.indexOfScalar(u8, &w.media_txt, 0) orelse w.media_txt.len;
    return @intCast(len * 6 + 20);
}

fn mediaDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    _ = y;
    if (w.media_txt[0] == 0) return;
    widgetIconGlyph(renderer, if (w.media_playing) "\xe2\x96\xb6" else "\xe2\x9d\x9c", x, h, 0.9, 0.8, 0.4); // ▶ or ❚❚
    _ = widgetText(renderer, @ptrCast(&w.media_txt), x + 18, h, 9.0, 0.85, 0.85, 0.88);
}

fn mediaClick(w: *Widget, btn: u32, x: i32, y: i32) bool {
    _ = w;
    _ = x;
    _ = y;
    if (btn != 1) return false;
    _ = c.system("playerctl play-pause &");
    return true;
}

fn clkMeasure(w: *Widget, h: i32) i32 {
    _ = h;
    const len = std.mem.indexOfScalar(u8, &w.clock_txt, 0) orelse w.clock_txt.len;
    return @intCast(len * 7 + 16);
}

fn clkDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    _ = y;
    _ = widgetText(renderer, @ptrCast(&w.clock_txt), x, h, 10.0, 0.85, 0.85, 0.85);
}

fn clkClick(w: *Widget, btn: u32, x: i32, y: i32) bool {
    _ = w;
    _ = x;
    _ = y;
    if (btn != 1) return false;
    _ = c.system("foot calcurse &");
    return true;
}

fn pwrMeasure(w: *Widget, h: i32) i32 {
    _ = w;
    _ = h;
    return 22;
}

fn pwrDraw(w: *Widget, renderer: *blend2d.BlendRenderer, x: i32, y: i32, h: i32) void {
    _ = w;
    _ = y;
    widgetIconGlyph(renderer, "\xe2\x8f\xbb", x + 4, h, 0.9, 0.5, 0.5); // ⏻
}

fn pwrClick(w: *Widget, btn: u32, x: i32, y: i32) bool {
    _ = x;
    _ = y;
    if (btn != 1) return false;
    _ = c.system(@ptrCast(&w.cmd));
    return true;
}

// ---- Widget Creation ----

pub const WidgetList = struct {
    widgets: [MAX_WIDGETS]Widget,
    count: i32,
};

pub fn widgetCreateDefault() WidgetList {
    var result = WidgetList{
        .widgets = std.mem.zeroes([MAX_WIDGETS]Widget),
        .count = 0,
    };

    const defaults = [_]struct { wtype: WidgetType, side: u8 }{
        .{ .wtype = .workspaces, .side = 0 },
        .{ .wtype = .toplevel_task, .side = 0 },
        .{ .wtype = .launcher, .side = 0 },
        .{ .wtype = .cpu, .side = 1 },
        .{ .wtype = .mem, .side = 1 },
        .{ .wtype = .temp, .side = 1 },
        .{ .wtype = .disk, .side = 1 },
        .{ .wtype = .battery, .side = 1 },
        .{ .wtype = .volume, .side = 1 },
        .{ .wtype = .network, .side = 1 },
        .{ .wtype = .media, .side = 1 },
        .{ .wtype = .clock, .side = 1 },
        .{ .wtype = .power, .side = 1 },
    };

    for (defaults) |d| {
        const idx: usize = @intCast(result.count);
        result.widgets[idx] = createWidget(d.wtype);
        result.widgets[idx].side = d.side;
        result.count += 1;
    }

    return result;
}

fn createWidget(wtype: WidgetType) Widget {
    var w: Widget = undefined;
    w.wtype = wtype;
    w.name = std.mem.zeroes([64]u8);
    w.side = 0;
    w.cached_w = 0;
    w.priv = null;
    w.ws_labels = std.mem.zeroes([64]u8);
    w.cpu_prev_total = 0;
    w.cpu_prev_idle = 0;
    w.cpu_txt = std.mem.zeroes([32]u8);
    w.mem_txt = std.mem.zeroes([32]u8);
    w.temp_txt = std.mem.zeroes([32]u8);
    w.disk_txt = std.mem.zeroes([32]u8);
    w.bat_lvl = -1;
    w.bat_charging = false;
    w.bat_txt = std.mem.zeroes([32]u8);
    w.vol_pct = 0;
    w.vol_mute = false;
    w.vol_txt = std.mem.zeroes([32]u8);
    w.net_txt = std.mem.zeroes([64]u8);
    w.media_txt = std.mem.zeroes([96]u8);
    w.media_playing = false;
    w.clock_fmt = std.mem.zeroes([32]u8);
    w.clock_txt = std.mem.zeroes([64]u8);
    w.cmd = std.mem.zeroes([128]u8);
    w.update_fn = null;
    w.click_fn = null;

    switch (wtype) {
        .workspaces => {
            std.mem.copyForwards(u8, &w.ws_labels, " 1 2 3 4 ");
            w.measure_fn = wsMeasure;
            w.draw_fn = wsDraw;
            w.click_fn = wsClick;
        },
        .toplevel_task => {
            w.measure_fn = tlMeasure;
            w.draw_fn = tlDraw;
            w.click_fn = tlClick;
        },
        .launcher => {
            std.mem.copyForwards(u8, &w.cmd, "fuzzel &");
            w.measure_fn = launcherMeasure;
            w.draw_fn = launcherDraw;
            w.click_fn = launcherClick;
        },
        .cpu => {
            std.mem.copyForwards(u8, &w.cpu_txt, "CPU --");
            w.measure_fn = cpuMeasure;
            w.draw_fn = cpuDraw;
            w.update_fn = cpuUpdate;
            w.click_fn = cpuClick;
        },
        .mem => {
            std.mem.copyForwards(u8, &w.mem_txt, "MEM --");
            w.measure_fn = memMeasure;
            w.draw_fn = memDraw;
            w.update_fn = memUpdate;
            w.click_fn = memClick;
        },
        .temp => {
            std.mem.copyForwards(u8, &w.temp_txt, "--\xc2\xb0C");
            w.measure_fn = tempMeasure;
            w.draw_fn = tempDraw;
            w.update_fn = tempUpdate;
            w.click_fn = tempClick;
        },
        .disk => {
            std.mem.copyForwards(u8, &w.disk_txt, "SSD --");
            w.measure_fn = diskMeasure;
            w.draw_fn = diskDraw;
            w.click_fn = diskClick;
        },
        .battery => {
            std.mem.copyForwards(u8, &w.bat_txt, "BAT ?");
            w.measure_fn = batMeasure;
            w.draw_fn = batDraw;
            w.click_fn = batClick;
            w.update_fn = batUpdate;
        },
        .volume => {
            w.measure_fn = volMeasure;
            w.draw_fn = volDraw;
            w.click_fn = volClick;
        },
        .network => {
            std.mem.copyForwards(u8, &w.net_txt, "off");
            w.measure_fn = netMeasure;
            w.draw_fn = netDraw;
            w.click_fn = netClick;
        },
        .media => {
            w.measure_fn = mediaMeasure;
            w.draw_fn = mediaDraw;
            w.click_fn = mediaClick;
        },
        .clock => {
            std.mem.copyForwards(u8, &w.clock_fmt, "%H:%M");
            w.measure_fn = clkMeasure;
            w.draw_fn = clkDraw;
            w.update_fn = clkUpdate;
            w.click_fn = clkClick;
        },
        .power => {
            std.mem.copyForwards(u8, &w.cmd, "loginctl poweroff &");
            w.measure_fn = pwrMeasure;
            w.draw_fn = pwrDraw;
            w.click_fn = pwrClick;
        },
    }

    return w;
}

fn clkUpdate(w: *Widget) void {
    const now = c.time(null);
    var tm: c.struct_tm = std.mem.zeroes(c.struct_tm);
    _ = c.localtime_r(&now, &tm);
    _ = c.strftime(&w.clock_txt, w.clock_txt.len, &w.clock_fmt, &tm);
}

// ---- Widget List Operations ----

pub fn widgetListUpdate(widgets: []Widget) void {
    for (widgets) |*w| {
        if (w.update_fn) |fn_ptr| fn_ptr(w);
    }
}

pub fn widgetListWidth(widgets: []Widget, h: i32, pad: i32) i32 {
    var total: i32 = 0;
    for (widgets) |*w| {
        const width = if (w.measure_fn) |fn_ptr| fn_ptr(w, h) else 0;
        w.cached_w = width;
        total += width + pad;
    }
    return total;
}
