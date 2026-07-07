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

    // === Unified Binary (Zig harness) ===
    {
        const exe = b.addExecutable(.{
            .name = "ocws",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
                .root_source_file = b.path("src/ocws.zig"),
            }),
        });

        b.installArtifact(exe);

        // Tests
        const tests = b.addTest(.{
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .root_source_file = b.path("src/tests.zig"),
            }),
        });
        const run_tests = b.addRunArtifact(tests);
        const test_step = b.step("test", "Run integration tests");
        test_step.dependOn(&run_tests.step);
    }

    const c_utils = [_][]const u8{
        "ocws-shot",
        "ocws-clip",
        "ocws-lock",
        "ocws-sysmon",
        "ocws-network-bandwidth",
        "ocws-player",
        "ocws-state",
        "ocws-validate",
        "ocws-brightness",
        "ocws-volume",
        "ocws-recorder",
        "ocws-emit",
        "ocws-search",
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

    // ocws-welcome: GTK3 Welcome GUI
    {
        const welcome = b.addExecutable(.{
            .name = "ocws-welcome",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        welcome.root_module.addCSourceFile(.{
            .file = b.path("src/ocws-welcome.c"),
            .flags = c_flags,
        });
        welcome.root_module.addCSourceFile(.{
            .file = b.path("src/utils.c"),
            .flags = c_flags,
        });
        welcome.root_module.linkSystemLibrary("gtk+-3.0", .{});
        welcome.root_module.linkSystemLibrary("glib-2.0", .{});

        b.installArtifact(welcome);
    }

    // ocws-settings: GTK3 Settings GUI
    {
        const settings = b.addExecutable(.{
            .name = "ocws-settings",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        settings.root_module.addCSourceFile(.{
            .file = b.path("src/ocws-settings.c"),
            .flags = c_flags,
        });
        settings.root_module.addCSourceFile(.{
            .file = b.path("src/settings/settings-ui.c"),
            .flags = c_flags,
        });
        settings.root_module.addCSourceFile(.{
            .file = b.path("src/settings/settings-tabs.c"),
            .flags = c_flags,
        });
        settings.root_module.addCSourceFile(.{
            .file = b.path("src/utils.c"),
            .flags = c_flags,
        });
        settings.root_module.linkSystemLibrary("gtk+-3.0", .{});
        settings.root_module.linkSystemLibrary("glib-2.0", .{});

        b.installArtifact(settings);
    }

    // ocws-pkgmgr: GTK3 Package Manager GUI
    {
        const pkgmgr = b.addExecutable(.{
            .name = "ocws-pkgmgr",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        pkgmgr.root_module.addCSourceFile(.{
            .file = b.path("src/ocws-pkgmgr.c"),
            .flags = c_flags,
        });
        pkgmgr.root_module.addCSourceFile(.{
            .file = b.path("src/utils.c"),
            .flags = c_flags,
        });
        pkgmgr.root_module.linkSystemLibrary("gtk+-3.0", .{});
        pkgmgr.root_module.linkSystemLibrary("glib-2.0", .{});

        b.installArtifact(pkgmgr);
    }
}
