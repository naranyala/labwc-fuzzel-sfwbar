const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const c_flags = &[_][]const u8{
        "-std=gnu11",
        "-Wall",
        "-Wextra",
        "-Wno-deprecated-declarations",
        "-O2",
        "-Isrc/gui",
        "-Isrc/libocws",
    };

    // ocws-equalizer: GTK3 audio equalizer with 10-band EQ, presets, and FFT visualizer
    {
        const exe = b.addExecutable(.{
            .name = "ocws-equalizer",
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });

        exe.root_module.addCSourceFile(.{ .file = b.path("src/gui/ocws-equalizer.c"), .flags = c_flags });
        exe.root_module.addCSourceFile(.{ .file = b.path("src/libocws/audio_analysis.c"), .flags = c_flags });
        exe.root_module.addCSourceFile(.{ .file = b.path("src/libocws/audio_stream.c"), .flags = c_flags });

        exe.root_module.linkSystemLibrary("gtk+-3.0", .{});
        exe.root_module.linkSystemLibrary("glib-2.0", .{});
        exe.root_module.linkSystemLibrary("pulse", .{});
        exe.root_module.linkSystemLibrary("pulse-simple", .{});
        exe.root_module.linkSystemLibrary("fftw3", .{});
        exe.root_module.linkSystemLibrary("m", .{});
        exe.root_module.linkSystemLibrary("ayatana-appindicator3-0.1", .{});

        b.installArtifact(exe);
        const step = b.step("ocws-equalizer", "Build the OCWS Equalizer");
        step.dependOn(&exe.step);
    }

    // Build system unification for C GUI apps
    _ = buildGtkApp(b, target, optimize, "ocws-settings", &.{
        "src/gui/ocws-settings.c",
        "src/gui/settings/settings-ui.c",
        "src/gui/settings/settings-tabs.c",
        "src/core/utils.c",
    });
    
    _ = buildGtkApp(b, target, optimize, "ocws-welcome", &.{
        "src/gui/ocws-welcome.c",
        "src/core/utils.c",
    });

    const ws_exe = buildGtkApp(b, target, optimize, "ocws-workspace-mgr", &.{
        "src/gui/ocws-workspace-mgr.c",
        "src/core/utils.c",
        "protocols/wlr-foreign-toplevel-management-unstable-v1-client.c",
    });
    ws_exe.root_module.linkSystemLibrary("wayland-client", .{});

    _ = buildGtkApp(b, target, optimize, "ocws-theme-center", &.{
        "src/gui/ocws-theme-center.c",
        "src/core/utils.c",
    });

    // ocws-gtk-shell: Zig GTK3 wrapper library for zigshell ecosystem
    // Provides reusable GTK widgets that bridge zigshell shared modules
    // (toplevel, sysread, apps, icon) with GTK3.
    {
        const shellcore = b.createModule(.{
            .root_source_file = b.path("src/shells/shared/shellcore.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        shellcore.addIncludePath(b.path("src"));
        shellcore.addIncludePath(b.path("src/libocws"));
        shellcore.addIncludePath(b.path("src/shells/zigshell-cairo-pango/src"));
        // GTK/Pango/Cairo/GLib include paths for dock_c_impl.c
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/gtk-3.0" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/pango-1.0" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/cairo" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/glib-2.0" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/lib64/glib-2.0/include" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/gdk-pixbuf-2.0" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/harfbuzz" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/freetype2" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/libpng16" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/pixman-1" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/libmount" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/blkid" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/sysprof-6" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/fribidi" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/librsvg-2.0" });
        shellcore.addSystemIncludePath(.{ .cwd_relative = "/usr/include/libxml2" });
        shellcore.addIncludePath(b.path("src/shells/shared/protocol"));
        shellcore.addCSourceFile(.{
            .file = b.path("src/shells/zigshell-cairo-pango/src/dock_c_impl.c"),
            .flags = &.{ "-std=gnu11", "-Wall" },
        });
        shellcore.addCSourceFile(.{
            .file = b.path("src/shells/shared/protocol/wlr-layer-shell-unstable-v1-client-protocol.c"),
            .flags = &.{ "-std=gnu11", "-Wall" },
        });
        shellcore.addCSourceFile(.{
            .file = b.path("src/shells/shared/protocol/wlr-foreign-toplevel-management-unstable-v1-client-protocol.c"),
            .flags = &.{ "-std=gnu11", "-Wall" },
        });
        shellcore.addCSourceFile(.{
            .file = b.path("src/shells/shared/protocol/xdg-shell-client-protocol.c"),
            .flags = &.{ "-std=gnu11", "-Wall" },
        });

        const lib = b.addLibrary(.{
            .name = "ocws-gtk-shell",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/libocws/gtk_shell.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });
        lib.root_module.addImport("shellcore", shellcore);
        lib.root_module.addIncludePath(b.path("src/libocws"));
        lib.root_module.linkSystemLibrary("gtk+-3.0", .{});
        lib.root_module.linkSystemLibrary("glib-2.0", .{});
        lib.root_module.linkSystemLibrary("wayland-client", .{});
        b.installArtifact(lib);

        const gtk_shell_step = b.step("gtk-shell", "Build the GTK shell wrapper library");
        gtk_shell_step.dependOn(&lib.step);

        // Tests for gtk_shell.zig
        const gtk_shell_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/libocws/gtk_shell.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            }),
        });
        gtk_shell_tests.root_module.addImport("shellcore", shellcore);
        gtk_shell_tests.root_module.addIncludePath(b.path("src/libocws"));
        gtk_shell_tests.root_module.linkSystemLibrary("gtk+-3.0", .{});
        gtk_shell_tests.root_module.linkSystemLibrary("glib-2.0", .{});
        gtk_shell_tests.root_module.linkSystemLibrary("wayland-client", .{});
        gtk_shell_tests.root_module.linkSystemLibrary("librsvg-2.0", .{});

        const run_gtk_shell_tests = b.addRunArtifact(gtk_shell_tests);
        const test_gtk_shell = b.step("test-gtk-shell", "Run GTK shell wrapper tests");
        test_gtk_shell.dependOn(&run_gtk_shell_tests.step);
    }

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tests.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    tests.root_module.addIncludePath(b.path("src"));

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}

fn buildGtkApp(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    name: []const u8,
    c_sources: []const []const u8,
) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = name,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const c_flags = &[_][]const u8{
        "-std=gnu11",
        "-Wall",
        "-O2",
        "-Isrc/gui",
        "-Isrc/libocws",
        "-Isrc/core",
        "-Iprotocols",
    };

    for (c_sources) |src| {
        exe.root_module.addCSourceFile(.{ .file = b.path(src), .flags = c_flags });
    }

    exe.root_module.linkSystemLibrary("gtk+-3.0", .{});
    exe.root_module.linkSystemLibrary("glib-2.0", .{});

    b.installArtifact(exe);
    const step = b.step(name, b.fmt("Build {s}", .{name}));
    step.dependOn(&exe.step);

    return exe;
}
