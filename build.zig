const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const c_flags = &[_][]const u8{
        "-std=gnu99",
        "-Wall",
        "-Wextra",
        "-O2",
    };

    // Single-file C utilities (no external deps)
    const c_utils = [_][]const u8{
        "ocws-shot",
        "ocws-clip",
        "ocws-lock",
        "ocws-sysmon",
        "ocws-brightness",
        "ocws-volume",
        "ocws-recorder",
    };

    for (c_utils) |util_name| {
        const exe = b.addExecutable(.{
            .name = util_name,
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        const src_path = b.fmt("src/{s}.c", .{util_name});

        exe.root_module.addCSourceFile(.{
            .file = b.path(src_path),
            .flags = c_flags,
        });

        b.installArtifact(exe);
    }

    // ocws-kv: links ocws-kv.c library + CLI
    {
        const exe = b.addExecutable(.{
            .name = "ocws-kv",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        exe.root_module.addCSourceFile(.{
            .file = b.path("src/ocws-kv.c"),
            .flags = c_flags,
        });
        exe.root_module.addCSourceFile(.{
            .file = b.path("src/ocws-kv-cli.c"),
            .flags = c_flags,
        });

        b.installArtifact(exe);
    }

    // ocws-color: needs cairo
    {
        const exe = b.addExecutable(.{
            .name = "ocws-color",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        exe.root_module.addCSourceFile(.{
            .file = b.path("src/ocws-color.c"),
            .flags = c_flags,
        });

        exe.root_module.linkSystemLibrary("cairo", .{});
        exe.root_module.linkSystemLibrary("m", .{});
        b.installArtifact(exe);
    }

    // ocws-ocr: needs tesseract + leptonica
    {
        const exe = b.addExecutable(.{
            .name = "ocws-ocr",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        exe.root_module.addCSourceFile(.{
            .file = b.path("src/ocws-ocr.c"),
            .flags = c_flags,
        });

        exe.root_module.linkSystemLibrary("tesseract", .{});
        exe.root_module.linkSystemLibrary("lept", .{});
        b.installArtifact(exe);
    }

    // ocws-notify: needs glib + gio
    {
        const exe = b.addExecutable(.{
            .name = "ocws-notify",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        exe.root_module.addCSourceFile(.{
            .file = b.path("src/ocws-notify.c"),
            .flags = c_flags,
        });

        exe.root_module.linkSystemLibrary("glib-2.0", .{});
        exe.root_module.linkSystemLibrary("gio-2.0", .{});
        exe.root_module.linkSystemLibrary("gobject-2.0", .{});
        b.installArtifact(exe);
    }

    // ocws-wallpaper: needs cairo + wayland-client
    {
        const exe = b.addExecutable(.{
            .name = "ocws-wallpaper",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        exe.root_module.addCSourceFile(.{
            .file = b.path("src/ocws-wallpaper.c"),
            .flags = c_flags,
        });

        exe.root_module.linkSystemLibrary("cairo", .{});
        b.installArtifact(exe);
    }

    // ocws-live-bg: GTK Layer Shell Live Background
    {
        const live_bg = b.addExecutable(.{
            .name = "ocws-live-bg",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        live_bg.root_module.addCSourceFile(.{
            .file = b.path("src/ocws-live-bg.c"),
            .flags = c_flags,
        });
        live_bg.root_module.linkSystemLibrary("gtk+-3.0", .{});
        live_bg.root_module.linkSystemLibrary("gtk-layer-shell-0", .{});
        live_bg.root_module.linkSystemLibrary("m", .{});

        b.installArtifact(live_bg);
    }

    // ocws-osd-notify: GTK Layer Shell Notification Daemon
    {
        const osd_notify = b.addExecutable(.{
            .name = "ocws-osd-notify",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        osd_notify.root_module.addCSourceFile(.{
            .file = b.path("src/ocws-osd-notify.c"),
            .flags = c_flags,
        });
        osd_notify.root_module.linkSystemLibrary("gtk+-3.0", .{});
        osd_notify.root_module.linkSystemLibrary("gtk-layer-shell-0", .{});
        osd_notify.root_module.linkSystemLibrary("gio-2.0", .{});
        osd_notify.root_module.linkSystemLibrary("glib-2.0", .{});

        b.installArtifact(osd_notify);
    }

    // ocws-hypertile: Dynamic Window Tiling Daemon
    {
        const hypertile = b.addExecutable(.{
            .name = "ocws-hypertile",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        hypertile.root_module.addCSourceFile(.{
            .file = b.path("src/ocws-hypertile.c"),
            .flags = c_flags,
        });
        hypertile.root_module.linkSystemLibrary("wayland-client", .{});

        b.installArtifact(hypertile);
    }
}
