// render.zig — SHM buffer management and rendering helpers
const std = @import("std");
const c = @import("c.zig").c;
const wayland = @import("c.zig").c;
const damage = @import("shellcore").damage;

const shm_log = std.log.scoped(.shm);

pub const SurfaceState = struct {
    surface: ?*c.wl_surface = null,
    layer_surface: ?*c.zwlr_layer_surface_v1 = null,
    width: i32 = 0,
    height: i32 = 0,
    scale: u32 = 1,
    frame_cb: ?*c.wl_callback = null,
    cairo_surface: ?*c.cairo_surface_t = null,
    cairo_cr: ?*c.cairo_t = null,
    shm_data: ?[*]u8 = null,
    buffer: ?*c.wl_buffer = null,
    buf_width: i32 = 0,
    buf_height: i32 = 0,
    buf_size: usize = 0,
    dirty_region: damage.Region = damage.Region.init(),
    dirty: bool = true,
};

fn createShmFd(size: usize) ?i32 {
    var name_buf: [19]u8 = "/tmp/wl_shm-XXXXXX".* ++ .{0};
    const name_z: [*:0]u8 = @ptrCast(&name_buf);
    const fd = c.mkstemp(name_z);
    if (fd < 0) {
        shm_log.err("mkstemp failed for SHM backing file (size={d})", .{size});
        return null;
    }
    _ = c.unlink(name_z);
    if (c.ftruncate(fd, @intCast(size)) < 0) {
        shm_log.err("ftruncate failed for SHM fd (size={d})", .{size});
        _ = c.close(fd);
        return null;
    }
    return fd;
}

fn getErrno() c_int {
    return std.c._errno().*;
}

pub fn ensureBuffer(ss: *SurfaceState, shm: ?*c.wl_shm) void {
    const w = ss.width * @as(i32, @intCast(ss.scale));
    const h = ss.height * @as(i32, @intCast(ss.scale));
    if (w <= 0 or h <= 0) return;
    const stride = c.cairo_format_stride_for_width(c.CAIRO_FORMAT_ARGB32, w);
    if (stride <= 0) return;
    const size: usize = @intCast(@as(i64, stride) * @as(i64, h));

    if (ss.buffer != null and (ss.buf_width != w or ss.buf_height != h)) {
        c.wl_buffer_destroy(ss.buffer);
        ss.buffer = null;
        c.cairo_destroy(ss.cairo_cr);
        ss.cairo_cr = null;
        c.cairo_surface_destroy(ss.cairo_surface);
        ss.cairo_surface = null;
        _ = c.munmap(ss.shm_data, ss.buf_size);
        ss.shm_data = null;
    }

    if (ss.buffer == null) {
        const fd = createShmFd(size) orelse return;
        const data_ptr = c.mmap(null, size, c.PROT_READ | c.PROT_WRITE, c.MAP_SHARED, fd, 0);
        if (data_ptr == c.MAP_FAILED) {
            shm_log.err("mmap failed for buffer ({d}x{d})", .{w, h});
            _ = c.close(fd);
            return;
        }
        ss.shm_data = @ptrCast(data_ptr);
        const pool = c.wl_shm_create_pool(shm, fd, @intCast(size));
        ss.buffer = c.wl_shm_pool_create_buffer(pool, 0, w, h, stride, c.WL_SHM_FORMAT_ARGB8888);
        c.wl_shm_pool_destroy(pool);
        _ = c.close(fd);
        if (ss.buffer == null) {
            shm_log.err("wl_shm_pool_create_buffer returned null ({d}x{d})", .{w, h});
            _ = c.munmap(ss.shm_data, size);
            ss.shm_data = null;
            return;
        }
        ss.cairo_surface = c.cairo_image_surface_create_for_data(ss.shm_data, c.CAIRO_FORMAT_ARGB32, w, h, stride);
        ss.cairo_cr = c.cairo_create(ss.cairo_surface);
        c.cairo_scale(ss.cairo_cr, @floatFromInt(ss.scale), @floatFromInt(ss.scale));
        if (ss.surface) |s| c.wl_surface_set_buffer_scale(s, @intCast(ss.scale));
        ss.buf_width = w;
        ss.buf_height = h;
        ss.buf_size = size;
    }
}

pub fn submitSurface(ss: *SurfaceState) void {
    if (!ss.dirty) return;
    ss.dirty = false;
    if (ss.buffer == null or ss.surface == null) return;
    c.wl_surface_attach(ss.surface, ss.buffer, 0, 0);
    const r = ss.dirty_region;
    if (r.active) {
        c.wl_surface_damage_buffer(ss.surface, r.x, r.y, r.w, r.h);
    } else {
        c.wl_surface_damage_buffer(ss.surface, 0, 0, ss.buf_width, ss.buf_height);
    }
    ss.dirty_region.reset();
    if (ss.frame_cb) |cb| c.wl_callback_destroy(cb);
    ss.frame_cb = c.wl_surface_frame(ss.surface);
    c.wl_surface_commit(ss.surface);
}

pub fn roundedRect(cr: *c.cairo_t, x: f64, y: f64, w: f64, h: f64, r: f64) void {
    c.cairo_move_to(cr, x + w - r, y);
    c.cairo_arc(cr, x + w - r, y + r, r, -std.math.pi / 2.0, 0);
    c.cairo_arc(cr, x + w - r, y + h - r, r, 0, std.math.pi / 2.0);
    c.cairo_arc(cr, x + r, y + h - r, r, std.math.pi / 2.0, std.math.pi);
    c.cairo_arc(cr, x + r, y + r, r, std.math.pi, 3.0 * std.math.pi / 2.0);
    c.cairo_close_path(cr);
}
