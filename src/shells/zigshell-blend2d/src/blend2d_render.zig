// blend2d_render.zig — Zig wrapper for C Blend2D rendering functions
// All rendering is done in C (blend2d_render.c), this file provides the Zig interface.

const std = @import("std");
const c = @import("c.zig").c;

pub const TextMetrics = struct {
    width: f64 = 0,
    height: f64 = 0,
};

pub const BlendRenderer = struct {
    handle: ?*c.BlendRenderer = null,

    pub fn init(pixel_data: [*]u8, width: i32, height: i32, stride_bytes: i32) !BlendRenderer {
        const handle = c.blend_renderer_create(pixel_data, width, height, stride_bytes);
        if (handle == null) return error.Blend2DError;
        return BlendRenderer{ .handle = handle };
    }

    pub fn deinit(self: *BlendRenderer) void {
        if (self.handle) |h| {
            c.blend_renderer_destroy(h);
            self.handle = null;
        }
    }

    pub fn flush(self: *BlendRenderer) void {
        if (self.handle) |h| c.blend_renderer_flush(h);
    }

    pub fn fillRect(self: *BlendRenderer, x: f64, y: f64, w: f64, h: f64, color: u32) void {
        if (self.handle) |handle| c.blend_renderer_fill_rect(handle, x, y, w, h, color);
    }

    pub fn fillRectRaw(self: *BlendRenderer, x: f64, y: f64, w: f64, h: f64, r: u8, g: u8, b: u8, a: u8) void {
        const color: u32 = @as(u32, a) << 24 | @as(u32, r) << 16 | @as(u32, g) << 8 | @as(u32, b);
        self.fillRect(x, y, w, h, color);
    }

    pub fn drawText(self: *BlendRenderer, text: []const u8, x: f64, y: f64, color: u32) void {
        if (text.len == 0) return;
        if (self.handle) |h| c.blend_renderer_draw_text(h, text.ptr, @intCast(text.len), x, y, color);
    }

    pub fn measureText(self: *BlendRenderer, text: []const u8) TextMetrics {
        if (text.len == 0) return .{};
        if (self.handle) |h| {
            const tm = c.blend_renderer_measure_text(h, text.ptr, @intCast(text.len));
            return .{ .width = tm.width, .height = tm.height };
        }
        return .{};
    }

    pub fn drawImage(self: *BlendRenderer, img: *c.BLImageCore, x: f64, y: f64) void {
        if (self.handle) |h| c.blend_renderer_draw_image(h, @ptrCast(img), x, y);
    }

    pub fn drawCircle(self: *BlendRenderer, cx: f64, cy: f64, radius: f64, color: u32) void {
        if (self.handle) |h| c.blend_renderer_draw_circle(h, cx, cy, radius, color);
    }

    pub fn drawBorder(self: *BlendRenderer, x: f64, y: f64, w: f64, h: f64, color: u32) void {
        if (self.handle) |handle| c.blend_renderer_draw_border(handle, x, y, w, h, color);
    }

    pub fn setFontSize(self: *BlendRenderer, size: f64) void {
        if (self.handle) |h| c.blend_renderer_set_font_size(h, size);
    }

    pub fn font_size(self: *BlendRenderer) f64 {
        if (self.handle) |h| return c.blend_renderer_get_font_size(h);
        return 0;
    }

    pub fn loadBoldFont(self: *BlendRenderer) void {
        if (self.handle) |h| c.blend_renderer_load_bold_font(h);
    }

    pub fn font_loaded(self: *BlendRenderer) bool {
        if (self.handle) |h| return c.blend_renderer_font_loaded(h);
        return false;
    }
};
