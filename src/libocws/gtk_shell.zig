// gtk_shell.zig — Zig GTK3 wrapper for zigshell ecosystem
//
// Wraps GTK3 via @cImport and bridges zigshell shared modules (toplevel,
// apps, sysread, icon) into reusable Zig structs. Future GTK apps can be
// written in Zig, importing this module for ready-made widgets + system
// integration.
//
// Usage:
//   const gtk = @import("gtk_shell");
//   var bar = gtk.ToplevelBar.init(display);
//   g_timeout_add(500, pollCallback, &bar);

const std = @import("std");
const c = @cImport({
    @cInclude("gtk_c.h");
});

const toplevel = @import("shellcore").toplevel;
const sysread = @import("shellcore").sysread;

// ============================================================================
// Icon — theme icon loader wrapping the zigshell icon.c
// ============================================================================

pub const Icon = struct {
    /// Load a theme icon by app_id, returning a GdkPixbuf at the given size.
    /// Returns null if the icon cannot be loaded.
    pub fn load(app_id: [*:0]const u8, size: i32) ?*c.GdkPixbuf {
        const theme = c.gtk_icon_theme_get_default();
        if (theme == null) return null;

        // Try to look up the icon in the current theme
        const gicon = c.g_icon_new_for_string(app_id, null) orelse return null;
        defer c.g_object_unref(gicon);

        const paintable = c.gtk_icon_theme_lookup_by_gicon(theme, gicon, size, @intCast(c.GTK_ICON_LOOKUP_FORCE_SIZE));
        if (paintable == null) return null;
        defer c.g_object_unref(paintable);

        return c.gdk_pixbuf_get_from_texture(@ptrCast(paintable));
    }

    /// Load icon with size as comptime-known value for better optimization.
    pub fn loadFixed(app_id: [*:0]const u8, comptime size: i32) ?*c.GdkPixbuf {
        return load(app_id, size);
    }
};

// ============================================================================
// ToplevelBar — taskbar widget showing running applications
// ============================================================================

pub const ToplevelBar = struct {
    box: *c.GtkWidget,
    display: ?*c.wl_display,
    toplevels: [toplevel.MAX_TOPLEVELS]toplevel.ToplevelInfo,
    toplevel_count: i32,
    buttons: [toplevel.MAX_TOPLEVELS]?*c.GtkWidget,
    button_count: i32,

    pub fn init(display: ?*c.wl_display) ToplevelBar {
        const box = c.gtk_box_new(c.GTK_ORIENTATION_HORIZONTAL, 4) orelse unreachable;
        c.gtk_widget_set_name(box, "toplevel-bar");
        c.gtk_widget_set_halign(box, c.GTK_ALIGN_START);
        c.gtk_widget_set_valign(box, c.GTK_ALIGN_CENTER);

        return .{
            .box = box,
            .display = display,
            .toplevels = std.mem.zeroes([toplevel.MAX_TOPLEVELS]toplevel.ToplevelInfo),
            .toplevel_count = 0,
            .buttons = std.mem.zeroes([toplevel.MAX_TOPLEVELS]?*c.GtkWidget),
            .button_count = 0,
        };
    }

    pub fn widget(self: *const ToplevelBar) *c.GtkWidget {
        return self.box;
    }

    /// Poll for toplevel changes and update the button list.
    /// Call this from a GLib timeout (e.g., every 500ms).
    pub fn poll(self: *ToplevelBar) void {
        // Remove buttons for closed toplevels
        var i: i32 = 0;
        while (i < self.button_count) {
            const btn = self.buttons[@intCast(i)] orelse {
                i += 1;
                continue;
            };
            const handle = @as(?*anyopaque, @ptrCast(c.g_object_get_data(@ptrCast(btn), "toplevel_handle")));
            var found = false;
            for (0..@intCast(self.toplevel_count)) |j| {
                if (self.toplevels[j].handle == handle) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                c.gtk_widget_destroy(btn);
                // Shift remaining buttons
                var k: usize = @intCast(i);
                while (k < @as(usize, @intCast(self.button_count)) - 1) : (k += 1) {
                    self.buttons[k] = self.buttons[k + 1];
                }
                self.button_count -= 1;
            } else {
                i += 1;
            }
        }

        // Add buttons for new toplevels
        for (0..@intCast(self.toplevel_count)) |j| {
            const info = &self.toplevels[j];
            var already_exists = false;
            for (0..@intCast(self.button_count)) |k| {
                if (self.buttons[k]) |b| {
                    const handle = @as(?*anyopaque, @ptrCast(c.g_object_get_data(@ptrCast(b), "toplevel_handle")));
                    if (handle == info.handle) {
                        already_exists = true;
                        break;
                    }
                }
            }
            if (!already_exists and self.button_count < toplevel.MAX_TOPLEVELS) {
                const btn = self.createButton(info);
                self.buttons[@intCast(self.button_count)] = btn;
                self.button_count += 1;
                c.gtk_box_pack_start(@ptrCast(self.box), btn, 0, 0, 2);
            }
        }

        c.gtk_widget_show_all(self.box);
    }

    fn createButton(self: *ToplevelBar, info: *toplevel.ToplevelInfo) *c.GtkWidget {
        _ = self;
        const btn = c.gtk_button_new();
        c.gtk_widget_set_name(btn, "toplevel-btn");

        // Use app_id or title as label
        const app_id = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&info.app_id)), 0);
        const title = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&info.title)), 0);
        const label = if (app_id.len > 0) app_id else if (title.len > 0) title else "unknown";

        const lbl = c.gtk_label_new(label.ptr);
        c.gtk_container_add(@ptrCast(btn), @ptrCast(lbl));

        // Store handle for later lookup
        c.g_object_set_data(@ptrCast(btn), "toplevel_handle", info.handle);

        // Click handler — activate the toplevel
        _ = c.g_signal_connect_data(btn, "clicked", @ptrCast(&toplevelActivate), @ptrCast(info.handle), null, c.G_CONNECT_AFTER);

        // Style based on focus state
        if (info.focused) {
            const ctx = c.gtk_widget_get_style_context(btn);
            c.gtk_style_context_add_class(ctx, "focused");
        }

        return btn;
    }

    fn toplevelActivate(handle: ?*anyopaque, _: ?*c.GtkButton) callconv(.c) void {
        // The handle is stored as the user_data of the button
        // In a real implementation, we'd need the wl_seat to activate
        // For now, this is a placeholder that logs the activation
        if (handle) |h| {
            std.log.info("toplevel activate: handle={any}", .{h});
        }
    }
};

// ============================================================================
// SysreadBar — system metrics bar (CPU/mem/battery/volume)
// ============================================================================

pub const SysreadBar = struct {
    box: *c.GtkWidget,
    cpu_label: *c.GtkWidget,
    mem_label: *c.GtkWidget,
    bat_label: *c.GtkWidget,
    vol_label: *c.GtkWidget,
    cpu_prev_total: i64,
    cpu_prev_idle: i64,
    bat_lvl: i32,
    bat_charging: bool,
    vol_mute: bool,

    pub fn init() SysreadBar {
        const box = c.gtk_box_new(c.GTK_ORIENTATION_HORIZONTAL, 8) orelse unreachable;
        c.gtk_widget_set_name(box, "sysread-bar");
        c.gtk_widget_set_halign(box, c.GTK_ALIGN_END);
        c.gtk_widget_set_valign(box, c.GTK_ALIGN_CENTER);

        const cpu = c.gtk_label_new("CPU --") orelse unreachable;
        const mem = c.gtk_label_new("MEM --") orelse unreachable;
        const bat = c.gtk_label_new("BAT ?") orelse unreachable;
        const vol = c.gtk_label_new("VOL --") orelse unreachable;

        c.gtk_box_pack_end(@ptrCast(box), vol, 0, 0, 4);
        c.gtk_box_pack_end(@ptrCast(box), bat, 0, 0, 4);
        c.gtk_box_pack_end(@ptrCast(box), mem, 0, 0, 4);
        c.gtk_box_pack_end(@ptrCast(box), cpu, 0, 0, 4);

        return .{
            .box = box,
            .cpu_label = cpu,
            .mem_label = mem,
            .bat_label = bat,
            .vol_label = vol,
            .cpu_prev_total = 0,
            .cpu_prev_idle = 0,
            .bat_lvl = -1,
            .bat_charging = false,
            .vol_mute = false,
        };
    }

    pub fn widget(self: *const SysreadBar) *c.GtkWidget {
        return self.box;
    }

    /// Update all metrics. Call from a GLib timeout (e.g., every 1000ms).
    pub fn update(self: *SysreadBar) void {
        self.updateCpu();
        self.updateMem();
        self.updateBat();
        self.updateVol();
    }

    fn updateCpu(self: *SysreadBar) void {
        var buf: [32]u8 = std.mem.zeroes([32]u8);
        var pt: i64 = self.cpu_prev_total;
        var pi: i64 = self.cpu_prev_idle;
        sysread.cpu(&buf, &pt, &pi);
        self.cpu_prev_total = pt;
        self.cpu_prev_idle = pi;

        const text = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&buf)), 0);
        var lbl_buf: [64]u8 = std.mem.zeroes([64]u8);
        const formatted = std.fmt.bufPrintZ(&lbl_buf, "<b>{s}</b>", .{text}) catch return;
        c.gtk_label_set_markup(@ptrCast(self.cpu_label), @ptrCast(formatted.ptr));
    }

    fn updateMem(self: *SysreadBar) void {
        var buf: [32]u8 = std.mem.zeroes([32]u8);
        sysread.mem(&buf);

        const text = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&buf)), 0);
        var lbl_buf: [64]u8 = std.mem.zeroes([64]u8);
        const formatted = std.fmt.bufPrintZ(&lbl_buf, "<b>{s}</b>", .{text}) catch return;
        c.gtk_label_set_markup(@ptrCast(self.mem_label), @ptrCast(formatted.ptr));
    }

    fn updateBat(self: *SysreadBar) void {
        var buf: [32]u8 = std.mem.zeroes([32]u8);
        var lvl: i32 = self.bat_lvl;
        var charging: bool = self.bat_charging;
        sysread.battery(&buf, &lvl, &charging);
        self.bat_lvl = lvl;
        self.bat_charging = charging;

        const text = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&buf)), 0);
        var lbl_buf: [64]u8 = std.mem.zeroes([64]u8);
        const formatted = std.fmt.bufPrintZ(&lbl_buf, "<b>{s}</b>", .{text}) catch return;
        c.gtk_label_set_markup(@ptrCast(self.bat_label), @ptrCast(formatted.ptr));
    }

    fn updateVol(self: *SysreadBar) void {
        // Volume is read from pactl — simplified for now
        const text: [*:0]const u8 = if (self.vol_mute) "VOL [mute]" else "VOL --";
        c.gtk_label_set_text(@ptrCast(self.vol_label), text);
    }
};

// ============================================================================
// DockWidget — horizontal dock with pinned apps
// ============================================================================

pub const DockWidget = struct {
    box: *c.GtkWidget,
    pins: [100][128]u8,
    pin_count: usize,
    running: [toplevel.MAX_TOPLEVELS]toplevel.ToplevelInfo,
    running_count: i32,
    buttons: [100 + toplevel.MAX_TOPLEVELS]?*c.GtkWidget,
    button_count: i32,

    pub fn init() DockWidget {
        const box = c.gtk_box_new(c.GTK_ORIENTATION_HORIZONTAL, 6) orelse unreachable;
        c.gtk_widget_set_name(box, "dock-widget");
        c.gtk_widget_set_halign(box, c.GTK_ALIGN_CENTER);
        c.gtk_widget_set_valign(box, c.GTK_ALIGN_END);
        c.gtk_widget_set_margin_bottom(box, 8);

        return .{
            .box = box,
            .pins = std.mem.zeroes([100][128]u8),
            .pin_count = 0,
            .running = std.mem.zeroes([toplevel.MAX_TOPLEVELS]toplevel.ToplevelInfo),
            .running_count = 0,
            .buttons = std.mem.zeroes([100 + toplevel.MAX_TOPLEVELS]?*c.GtkWidget),
            .button_count = 0,
        };
    }

    pub fn widget(self: *const DockWidget) *c.GtkWidget {
        return self.box;
    }

    /// Load pinned apps from a config file's [dock.pins] section.
    pub fn loadPins(self: *DockWidget, path: []const u8) void {
        const f = std.fs.cwd().openFile(path, .{}) catch return;
        defer f.close();

        var buf: [4096]u8 = undefined;
        const n = f.readAll(&buf) catch return;
        const content = buf[0..n];

        var in_pins = false;
        var line_it = std.mem.splitScalar(u8, content, '\n');
        while (line_it.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \t\r");
            if (line.len == 0 or line[0] == '#') continue;
            if (std.mem.eql(u8, line, "[dock.pins]")) {
                in_pins = true;
                continue;
            }
            if (line[0] == '[') {
                in_pins = false;
                continue;
            }
            if (in_pins and self.pin_count < 100) {
                const name = std.mem.trim(u8, line, " \t");
                if (name.len > 0 and name.len < 128) {
                    @memcpy(self.pins[self.pin_count][0..name.len], name);
                    self.pins[self.pin_count][name.len] = 0;
                    self.pin_count += 1;
                }
            }
        }
    }

    /// Update the dock with current running toplevels.
    pub fn update(self: *DockWidget, tops: []toplevel.ToplevelInfo, count: i32) void {
        // Store running toplevels
        self.running_count = count;
        for (0..@intCast(count)) |i| {
            self.running[i] = tops[i];
        }

        // Rebuild buttons
        self.rebuildButtons();
    }

    fn rebuildButtons(self: *DockWidget) void {
        // Remove old buttons
        for (0..@intCast(self.button_count)) |i| {
            if (self.buttons[i]) |btn| {
                c.gtk_widget_destroy(btn);
            }
        }
        self.button_count = 0;

        // Add pinned app buttons
        for (0..self.pin_count) |i| {
            const name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&self.pins[i])), 0);
            const btn = self.createDockButton(name, null);
            self.buttons[self.button_count] = btn;
            self.button_count += 1;
            c.gtk_box_pack_start(@ptrCast(self.box), btn, 0, 0, 2);
        }

        // Add running app buttons (if not already pinned)
        for (0..@intCast(self.running_count)) |i| {
            const info = &self.running[i];
            const app_id = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&info.app_id)), 0);
            var is_pinned = false;
            for (0..self.pin_count) |j| {
                const pin_name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&self.pins[j])), 0);
                if (std.mem.eql(u8, app_id, pin_name)) {
                    is_pinned = true;
                    break;
                }
            }
            if (!is_pinned and self.button_count < self.buttons.len) {
                const btn = self.createDockButton(app_id, info);
                self.buttons[self.button_count] = btn;
                self.button_count += 1;
                c.gtk_box_pack_start(@ptrCast(self.box), btn, 0, 0, 2);
            }
        }

        c.gtk_widget_show_all(self.box);
    }

    fn createDockButton(_: *DockWidget, name: [*:0]const u8, info: ?*toplevel.ToplevelInfo) *c.GtkWidget {
        const btn = c.gtk_button_new();
        c.gtk_widget_set_name(btn, "dock-btn");

        const lbl = c.gtk_label_new(name);
        c.gtk_container_add(@ptrCast(btn), @ptrCast(lbl));

        // Style
        const ctx = c.gtk_widget_get_style_context(btn);
        c.gtk_style_context_add_class(ctx, "dock_app");

        if (info != null and info.?.focused) {
            c.gtk_style_context_add_class(ctx, "focused");
        }

        // Right-click context menu for unpin
        const name_copy = std.mem.sliceTo(name, 0);
        _ = c.g_signal_connect_data(btn, "button-press-event", @ptrCast(&dockButtonPress), @ptrCast(@constCast(name_copy.ptr)), null, c.G_CONNECT_AFTER);

        return btn;
    }

    /// Pin an app by name. Returns true if added.
    pub fn pinApp(self: *DockWidget, app_name: []const u8) bool {
        if (app_name.len == 0 or app_name.len >= 128) return false;
        if (self.pin_count >= 100) return false;
        if (self.isPinned(app_name)) return false;

        @memcpy(self.pins[self.pin_count][0..app_name.len], app_name);
        self.pins[self.pin_count][app_name.len] = 0;
        self.pin_count += 1;
        return true;
    }

    /// Unpin an app by name. Returns true if removed.
    pub fn unpinApp(self: *DockWidget, app_name: []const u8) bool {
        for (0..self.pin_count) |i| {
            const pin_name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&self.pins[i])), 0);
            if (std.mem.eql(u8, app_name, pin_name)) {
                // Shift remaining pins
                var j = i;
                while (j < self.pin_count - 1) : (j += 1) {
                    @memcpy(&self.pins[j], &self.pins[j + 1]);
                }
                self.pin_count -= 1;
                // Clear the last entry
                self.pins[self.pin_count] = std.mem.zeroes([128]u8);
                return true;
            }
        }
        return false;
    }

    /// Check if an app is pinned.
    pub fn isPinned(self: *DockWidget, app_name: []const u8) bool {
        for (0..self.pin_count) |i| {
            const pin_name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&self.pins[i])), 0);
            if (std.mem.eql(u8, app_name, pin_name)) {
                return true;
            }
        }
        return false;
    }

    /// Save pins to a config file.
    pub fn savePins(self: *DockWidget, path: []const u8) void {
        const file = std.fs.cwd().createFile(path, .{ .truncate = true }) catch return;
        defer file.close();

        _ = file.writeAll("[dock.pins]\n") catch return;
        for (0..self.pin_count) |i| {
            const name = std.mem.sliceTo(@as([*:0]const u8, @ptrCast(&self.pins[i])), 0);
            file.writeAll(name) catch continue;
            _ = file.writeAll("\n") catch continue;
        }
    }

    fn dockButtonPress(_: ?*anyopaque, event: ?*c.GdkEventButton, name_ptr: ?*anyopaque) callconv(.c) c.gboolean {
        if (event == null or name_ptr == null) return 0;
        const btn_event = event.?;

        // Right-click (button 3)
        if (btn_event.button != 3) return 0;

        // Create context menu
        const menu = c.gtk_menu_new();
        const unpin_item = c.gtk_menu_item_new_with_label("Unpin from Dock");
        c.gtk_menu_shell_append(@ptrCast(menu), @ptrCast(unpin_item));

        // Store name for the callback
        c.g_object_set_data(@ptrCast(menu), "app_name", name_ptr);

        _ = c.g_signal_connect_data(unpin_item, "activate", @ptrCast(&unpinAppCallback), @ptrCast(menu), null, c.G_CONNECT_AFTER);

        c.gtk_widget_show_all(menu);
        c.gtk_menu_popup_at_pointer(@ptrCast(menu), @ptrCast(btn_event));

        return 1; // Handled
    }

    fn unpinAppCallback(_: ?*anyopaque, menu: ?*c.GtkWidget) callconv(.c) void {
        if (menu == null) return;
        const name_ptr = @as(?[*:0]const u8, @ptrCast(c.g_object_get_data(@ptrCast(menu.?), "app_name")));
        if (name_ptr) |name| {
            // Find the DockWidget instance and unpin
            // Note: In a real implementation, we'd pass the DockWidget pointer
            // For now, we just log the action
            std.log.info("unpin: {s}", .{std.mem.sliceTo(name, 0)});
        }
    }
};

// ============================================================================
// Launcher — app launcher popup with search
// ============================================================================

pub const Launcher = struct {
    window: ?*c.GtkWidget,
    entry: ?*c.GtkWidget,
    flow: ?*c.GtkWidget,
    scroll: ?*c.GtkWidget,
    apps_list: [256]AppEntry,
    apps_count: i32,
    filtered: [256]i32,
    filtered_count: i32,
    dock: ?*DockWidget,

    const AppEntry = struct {
        name: [128]u8,
        exec: [256]u8,
        icon: [128]u8,
        name_len: usize,
        exec_len: usize,
        icon_len: usize,
    };

    pub fn init() Launcher {
        return initWithDock(null);
    }

    pub fn initWithDock(dock: ?*DockWidget) Launcher {
        const window = c.gtk_window_new(c.GTK_WINDOW_TOPLEVEL);
        c.gtk_widget_set_name(window, "launcher-window");
        c.gtk_window_set_title(@ptrCast(window), "Applications");
        c.gtk_window_set_default_size(@ptrCast(window), 520, 420);
        c.gtk_window_set_position(@ptrCast(window), c.GTK_WIN_POS_CENTER);
        c.gtk_window_set_decorated(@ptrCast(window), 0);
        c.gtk_window_set_keep_above(@ptrCast(window), 1);

        // Search entry at top
        const entry = c.gtk_search_entry_new();
        c.gtk_widget_set_name(entry, "launcher-search");

        // Scrolled flow box
        const scroll = c.gtk_scrolled_window_new(null, null);
        c.gtk_scrolled_window_set_policy(@ptrCast(scroll), c.GTK_POLICY_NEVER, c.GTK_POLICY_AUTOMATIC);

        const flow = c.gtk_flow_box_new();
        c.gtk_flow_box_set_homogeneous(@ptrCast(flow), 1);
        c.gtk_flow_box_set_column_spacing(@ptrCast(flow), 8);
        c.gtk_flow_box_set_row_spacing(@ptrCast(flow), 8);
        c.gtk_container_add(@ptrCast(scroll), @ptrCast(flow));

        // Layout
        const vbox = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 8);
        c.gtk_widget_set_margin_start(vbox, 12);
        c.gtk_widget_set_margin_end(vbox, 12);
        c.gtk_widget_set_margin_top(vbox, 12);
        c.gtk_widget_set_margin_bottom(vbox, 12);
        c.gtk_box_pack_start(@ptrCast(vbox), entry, 0, 0, 0);
        c.gtk_box_pack_start(@ptrCast(vbox), scroll, 1, 1, 0);
        c.gtk_container_add(@ptrCast(window), @ptrCast(vbox));

        return .{
            .window = window,
            .entry = entry,
            .flow = flow,
            .scroll = scroll,
            .apps_list = std.mem.zeroes([256]AppEntry),
            .apps_count = 0,
            .filtered = std.mem.zeroes([256]i32),
            .filtered_count = 0,
            .dock = dock,
        };
    }

    pub fn widget(self: *const Launcher) *c.GtkWidget {
        return self.window;
    }

    pub fn show(self: *Launcher) void {
        self.populateApps();
        self.filterApps("");
        if (self.window) |w| c.gtk_widget_show_all(w);
        if (self.entry) |e| c.gtk_widget_grab_focus(e);
    }

    pub fn hide(self: *Launcher) void {
        if (self.window) |w| c.gtk_widget_hide(w);
    }

    fn populateApps(self: *Launcher) void {
        self.apps_count = 0;

        // Scan /usr/share/applications/*.desktop
        self.scanDir("/usr/share/applications");
        self.scanDir("/usr/local/share/applications");

        const home = std.posix.getenv("HOME") orelse return;
        var buf: [512]u8 = undefined;
        const local_path = std.fmt.bufPrintZ(&buf, "{s}/.local/share/applications", .{home}) catch return;
        self.scanDir(local_path);
    }

    fn scanDir(self: *Launcher, dir_path: []const u8) void {
        const dir = std.fs.cwd().openDir(dir_path, .{}) catch return;
        defer dir.close();

        var iter = dir.iterate();
        while (iter.next() catch null) |entry| {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.name, ".desktop")) continue;
            if (self.apps_count >= 256) break;

            var path_buf: [512]u8 = undefined;
            const full_path = std.fmt.bufPrintZ(&path_buf, "{s}/{s}", .{ dir_path, entry.name }) catch continue;
            self.parseDesktopFile(full_path) catch continue;
        }
    }

    fn parseDesktopFile(self: *Launcher, path: []const u8) !void {
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        var buf: [4096]u8 = undefined;
        const n = try file.readAll(&buf);
        const content = buf[0..n];

        var entry = &self.apps_list[@intCast(self.apps_count)];
        var in_desktop = false;
        var no_display = false;

        var line_it = std.mem.splitScalar(u8, content, '\n');
        while (line_it.next()) |raw_line| {
            const line = std.mem.trim(u8, raw_line, "\r");
            if (line.len == 0) continue;
            if (line[0] == '[') {
                in_desktop = std.mem.eql(u8, line, "[Desktop Entry]");
                continue;
            }
            if (!in_desktop) continue;

            if (std.mem.startsWith(u8, line, "Name=")) {
                const v = line[5..];
                const len = @min(v.len, entry.name.len - 1);
                @memcpy(entry.name[0..len], v[0..len]);
                entry.name[len] = 0;
                entry.name_len = len;
            } else if (std.mem.startsWith(u8, line, "Exec=")) {
                const v = line[5..];
                const len = @min(v.len, entry.exec.len - 1);
                @memcpy(entry.exec[0..len], v[0..len]);
                entry.exec[len] = 0;
                entry.exec_len = len;
            } else if (std.mem.startsWith(u8, line, "Icon=")) {
                const v = line[5..];
                const len = @min(v.len, entry.icon.len - 1);
                @memcpy(entry.icon[0..len], v[0..len]);
                entry.icon[len] = 0;
                entry.icon_len = len;
            } else if (std.mem.startsWith(u8, line, "NoDisplay=true")) {
                no_display = true;
            }
        }

        if (!no_display and entry.name_len > 0) {
            self.apps_count += 1;
        }
    }

    fn filterApps(self: *Launcher, query: []const u8) void {
        self.filtered_count = 0;
        for (0..@intCast(self.apps_count)) |i| {
            const entry = &self.apps_list[i];
            const name = entry.name[0..entry.name_len];
            if (query.len == 0 or std.mem.indexOf(u8, name, query) != null) {
                self.filtered[@intCast(self.filtered_count)] = @intCast(i);
                self.filtered_count += 1;
            }
        }
        self.rebuildFlow();
    }

    fn rebuildFlow(self: *Launcher) void {
        const flow = self.flow orelse return;

        // Clear existing children
        const children = c.gtk_container_get_children(@ptrCast(flow));
        if (children != null) {
            var l = children;
            while (l != null) {
                const next = l.?.*.next;
                c.gtk_widget_destroy(@ptrCast(l.?.*.data));
                l = next;
            }
        }

        // Add filtered apps with icons and pin buttons
        for (0..@intCast(self.filtered_count)) |i| {
            const idx = self.filtered[i];
            const entry = &self.apps_list[@intCast(idx)];

            const btn = c.gtk_button_new();
            c.gtk_widget_set_size_request(btn, 140, 72);

            const vbox = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 4);
            c.gtk_widget_set_halign(vbox, c.GTK_ALIGN_CENTER);
            c.gtk_widget_set_valign(vbox, c.GTK_ALIGN_CENTER);

            // Load icon from Icon= field
            if (entry.icon_len > 0) {
                const icon_name = entry.icon[0..entry.icon_len];
                const img = c.gtk_image_new_from_icon_name(@ptrCast(icon_name.ptr), 48);
                if (img) |image| {
                    c.gtk_box_pack_start(@ptrCast(vbox), image, 0, 0, 0);
                }
            }

            // App name with pin button
            const hbox = c.gtk_box_new(c.GTK_ORIENTATION_HORIZONTAL, 4);
            c.gtk_widget_set_halign(hbox, c.GTK_ALIGN_CENTER);

            const lbl = c.gtk_label_new(entry.name[0..entry.name_len].ptr);
            c.gtk_label_set_ellipsize(@ptrCast(lbl), c.PANGO_ELLIPSIZE_END);
            c.gtk_label_set_max_width_chars(@ptrCast(lbl), 12);
            c.gtk_box_pack_start(@ptrCast(hbox), lbl, 0, 0, 0);

            // Pin/unpin button
            const pin_btn = c.gtk_button_new();
            c.gtk_widget_set_size_request(pin_btn, 24, 24);
            const is_pinned = if (self.dock) |dock| dock.isPinned(entry.name[0..entry.name_len]) else false;
            const pin_lbl = if (is_pinned) c.gtk_label_new("-") else c.gtk_label_new("+");
            c.gtk_container_add(@ptrCast(pin_btn), @ptrCast(pin_lbl));

            // Style pin button
            const pin_ctx = c.gtk_widget_get_style_context(pin_btn);
            c.gtk_style_context_add_class(pin_ctx, "pin-btn");
            if (is_pinned) {
                c.gtk_style_context_add_class(pin_ctx, "pinned");
            }

            // Store app name for pin callback
            c.g_object_set_data(@ptrCast(pin_btn), "app_name", @ptrCast(@constCast(entry.name[0..entry.name_len].ptr)));
            c.g_object_set_data(@ptrCast(pin_btn), "is_pinned", @ptrCast(@as(?*anyopaque, if (is_pinned) @ptrFromInt(1) else null)));

            _ = c.g_signal_connect_data(pin_btn, "clicked", @ptrCast(&togglePinApp), @ptrCast(self), null, c.G_CONNECT_AFTER);

            c.gtk_box_pack_start(@ptrCast(hbox), pin_btn, 0, 0, 0);

            c.gtk_box_pack_start(@ptrCast(vbox), hbox, 0, 0, 0);

            c.gtk_container_add(@ptrCast(btn), @ptrCast(vbox));

            // Store exec for launch
            c.g_object_set_data(@ptrCast(btn), "exec_ptr", @ptrCast(@constCast(entry.exec[0..entry.exec_len].ptr)));

            _ = c.g_signal_connect_data(btn, "clicked", @ptrCast(&launchApp), null, null, c.G_CONNECT_AFTER);

            c.gtk_flow_box_insert(@ptrCast(flow), btn, -1);
        }

        c.gtk_widget_show_all(flow);
    }

    fn togglePinApp(pin_btn: ?*anyopaque, launcher_ptr: ?*anyopaque) callconv(.c) void {
        if (pin_btn == null or launcher_ptr == null) return;

        const app_name_ptr = @as(?[*:0]const u8, @ptrCast(c.g_object_get_data(@ptrCast(pin_btn.?), "app_name")));
        const is_pinned_flag = @as(?*anyopaque, @ptrCast(c.g_object_get_data(@ptrCast(pin_btn.?), "is_pinned")));
        const launcher = @as(*Launcher, @ptrCast(launcher_ptr.?));

        if (app_name_ptr) |name_ptr| {
            const name = std.mem.sliceTo(name_ptr, 0);
            if (launcher.dock) |dock| {
                if (is_pinned_flag != null) {
                    // Currently pinned, unpin it
                    if (dock.unpinApp(name)) {
                        std.log.info("unpinned: {s}", .{name});
                    }
                } else {
                    // Not pinned, pin it
                    if (dock.pinApp(name)) {
                        std.log.info("pinned: {s}", .{name});
                    }
                }
                // Rebuild dock buttons
                dock.rebuildButtons();
                // Rebuild launcher to update pin buttons
                launcher.rebuildFlow();
            }
        }
    }

    fn launchApp(_: ?*anyopaque, button: ?*c.GtkButton) callconv(.c) void {
        if (button == null) return;
        const exec_ptr = @as(?[*:0]const u8, @ptrCast(c.g_object_get_data(@ptrCast(button.?), "exec_ptr")));
        if (exec_ptr) |exec| {
            var buf: [512]u8 = undefined;
            const cmd = std.fmt.bufPrintZ(&buf, "{s} &", .{std.mem.sliceTo(exec, 0)}) catch return;
            _ = c.system(@ptrCast(cmd.ptr));
        }
    }
};

// ============================================================================
// DockLauncher — fixed dock icon that opens the app launcher
// ============================================================================

pub const DockLauncher = struct {
    button: *c.GtkWidget,
    launcher: *Launcher,

    pub fn init(launcher: *Launcher) DockLauncher {
        const btn = c.gtk_button_new() orelse unreachable;
        c.gtk_widget_set_name(btn, "dock-launcher");
        c.gtk_widget_set_size_request(btn, 48, 48);

        // Use a grid icon as the launcher symbol
        const img = c.gtk_image_new_from_icon_name("view-app-grid", 48);
        if (img) |image| {
            c.gtk_container_add(@ptrCast(btn), @ptrCast(image));
        }

        // Style as dock button
        const ctx = c.gtk_widget_get_style_context(btn);
        c.gtk_style_context_add_class(ctx, "dock_app");
        c.gtk_style_context_add_class(ctx, "launcher");

        // Click handler — show/hide launcher
        _ = c.g_signal_connect_data(btn, "clicked", @ptrCast(&toggleLauncher), @ptrCast(launcher), null, c.G_CONNECT_AFTER);

        return .{
            .button = btn,
            .launcher = launcher,
        };
    }

    pub fn widget(self: *const DockLauncher) *c.GtkWidget {
        return self.button;
    }

    fn toggleLauncher(launcher_ptr: ?*anyopaque, _: ?*c.GtkButton) callconv(.c) void {
        if (launcher_ptr) |ptr| {
            const launcher = @as(*Launcher, @ptrCast(ptr));
            if (launcher.window) |w| {
                const visible = c.gtk_widget_get_visible(w);
                if (visible != 0) {
                    launcher.hide();
                } else {
                    launcher.show();
                }
            }
        }
    }
};

// ============================================================================
// GLib integration helpers
// ============================================================================

/// Add a GLib timeout that calls the given Zig callback.
/// The callback must have signature `fn(?*anyopaque) callconv(.c) c.gboolean`.
pub fn glibTimeoutAdd(interval_ms: u32, callback: anytype, data: anytype) c.guint {
    return c.g_timeout_add(interval_ms, @ptrCast(@constCast(&callback)), @ptrCast(data));
}

/// Run the GTK main loop.
pub fn gtkMainLoop() void {
    c.gtk_main();
}

/// Quit the GTK main loop.
pub fn gtkMainQuit() void {
    c.gtk_main_quit();
}

// ============================================================================
// Tests
// ============================================================================

test "ToplevelBar init" {
    const bar = ToplevelBar.init(null);
    try std.testing.expect(bar.toplevel_count == 0);
    try std.testing.expect(bar.button_count == 0);
}

test "SysreadBar init" {
    const bar = SysreadBar.init();
    try std.testing.expect(bar.cpu_prev_total == 0);
    try std.testing.expect(bar.bat_lvl == -1);
}

test "DockWidget init" {
    const dock = DockWidget.init();
    try std.testing.expect(dock.pin_count == 0);
    try std.testing.expect(dock.running_count == 0);
}

test "Launcher init" {
    const launcher = Launcher.init();
    try std.testing.expect(launcher.apps_count == 0);
    try std.testing.expect(launcher.filtered_count == 0);
}
