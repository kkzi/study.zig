const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "SimCortex",
        .root_source_file = b.path("src/SimCortex/SimCortex.zig"),
        .target = target,
        .optimize = optimize,
    });

    const network = b.dependency("network", .{
        .optimize = optimize,
        .target = target,
    });
    exe.root_module.addImport("network", network.module("network"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
