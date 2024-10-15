const std = @import("std");
const libxml2 = @import("libxml2.zig");
// const zlib = @import("zlib").zlib;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const xml2_options = libxml2.Options.fromBuildZigOptions(b);

    const xml2 = try libxml2.create(b, target, optimize, xml2_options);
    b.installArtifact(xml2.step);

    // todo: uncomment when zig-zlib is updated
    // const z = zlib.create(b, target, optimize);
    // z.link(xml2_with_libs.step, .{});

    // // const static_binding_test = b.addTest(.{
    // //     .root_source_file = b.path("test/basic.zig"),
    // //     .optimize = optimize,
    // // });
    // xml2.link(static_binding_test);

    const test_step = b.step("test", "Run tests");
    _ = test_step;
    // test_step.dependOn(&static_binding_test.step);
}

pub fn moduleFromCHeader(b: *std.Build, header: std.Build.LazyPath, dependency_options: anytype) *std.Build.Module {
    const this_dep = b.dependencyFromBuildZig(@This(), dependency_options);
    const src_dep = this_dep.builder.dependency("libxml2", .{});

    const zig_libxml = b.addTranslateC(.{
        .target = dependency_options.target,
        .optimize = dependency_options.optimize,
        .root_source_file = header,
    });
    zig_libxml.addIncludePath(this_dep.path("override/include"));
    zig_libxml.addIncludePath(src_dep.path("include"));

    const lxml_mod = zig_libxml.createModule();
    lxml_mod.linkLibrary(this_dep.artifact("xml2"));

    return lxml_mod;
}
