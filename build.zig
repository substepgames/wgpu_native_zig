const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mode_str = switch (optimize) {
        .Debug => "debug",
        else => "release",
    };

    const wgpu_root = "lib/wgpu-native";

    const root_module = b.addModule("wgpu", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });

    root_module.addIncludePath(b.path(wgpu_root ++ "/ffi"));
    root_module.addIncludePath(b.path(wgpu_root ++ "/ffi/include/webgpu"));

    const translate_step = b.addTranslateC(.{
        .root_source_file = b.path(
            wgpu_root ++ "/ffi/include/webgpu/wgpu.h",
        ),
        .target = target,
        .optimize = optimize,
    });

    translate_step.addIncludePath(b.path(wgpu_root ++ "/ffi"));

    translate_step.addIncludePath(b.path(wgpu_root ++ "/ffi/include/webgpu"));

    const wgpu_c_mod = translate_step.addModule("wgpu-c");
    wgpu_c_mod.resolved_target = target;
    wgpu_c_mod.link_libcpp = true;

    const wgpu_lib_dir = b.path(b.fmt("{s}/target/{s}", .{ wgpu_root, mode_str }));

    const wgpu_so_path = b.path(b.fmt("{s}/target/{s}/libwgpu_native.so", .{ wgpu_root, mode_str }));

    const so_install_file = b.addInstallLibFile(wgpu_so_path, "libwgpu_native.so");

    b.getInstallStep().dependOn(&so_install_file.step);

    const write_files = b.addNamedWriteFiles("lib");

    _ = write_files.addCopyFile(wgpu_so_path, "libwgpu_native.so");

    root_module.addLibraryPath(wgpu_lib_dir);
    root_module.linkSystemLibrary("wgpu_native", .{});
}
