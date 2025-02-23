const std = @import("std");

fn dir() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

pub const package = std.build.Pkg{
    .name = "zf",
    .source = .{ .path = dir() ++ "/src/lib.zig" },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Expose zf as a Zig module
    _ = b.addModule("zf", .{
        .source_file = .{ .path = "src/lib.zig" },
    });

    const ziglyph = b.dependency("ziglyph", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "zf",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addCSourceFile(.{
        .file = .{ .path = "src/loop.c" },
        .flags = &.{},
    });

    exe.addModule("ziglyph", ziglyph.module("ziglyph"));
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const run_step = b.step("run", "Run zf");
    run_step.dependOn(&run_cmd.step);

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    tests.addModule("ziglyph", ziglyph.module("ziglyph"));

    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
