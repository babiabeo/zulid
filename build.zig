const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zulid_module = b.addModule("zulid", .{
        .root_source_file = b.path("src/zulid.zig"),
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addStaticLibrary(.{
        .name = "zulid",
        .root_source_file = b.path("src/zulid.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    // tests

    const lib_tests = b.addTest(.{
        .root_source_file = b.path("src/zulid.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tests_suite = b.addRunArtifact(lib_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&tests_suite.step);

    // docs

    const doc_lib = b.addTest(.{
        .name = "zulid",
        .root_source_file = b.path("src/zulid.zig"),
        .target = target,
        .optimize = .Debug,
    });
    const install_docs = b.addInstallDirectory(.{
        .source_dir = doc_lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    const run_docs = b.addRunArtifact(doc_lib);
    install_docs.step.dependOn(&run_docs.step);

    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(&install_docs.step);
    b.default_step.dependOn(docs_step);

    // bench

    const zbench = b.dependency("zbench", .{
        .target = target,
        .optimize = optimize,
    });

    const lib_bench = b.addExecutable(.{
        .name = "bench",
        .root_source_file = b.path("bench/main.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });

    lib_bench.root_module.addImport("zulid", zulid_module);
    lib_bench.root_module.addImport("zbench", zbench.module("zbench"));

    // b.installArtifact(lib_bench);

    const bench = b.addRunArtifact(lib_bench);

    const benchmark = b.step("bench", "Run benchmark");
    benchmark.dependOn(&bench.step);
}
