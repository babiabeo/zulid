const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

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
}
