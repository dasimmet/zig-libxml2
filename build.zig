const std = @import("std");
const libxml2 = @import("libxml2.zig");
// const zlib = @import("zlib").zlib;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const xml2 = try libxml2.create(b, target, optimize, .{
        // We don't have the required libs so don't build these
        .iconv = false,
        .lzma = false,
        .zlib = false,
        .thread = b.option(bool, "thread", "with threads") orelse true,
    });
    b.installArtifact(xml2.step);

    // Tests that we can depend on other libraries like zlib
    const xml2_with_libs = try libxml2.create(b, target, optimize, .{
        // We don't have the required libs so don't build these
        .iconv = false,
        .lzma = false,

        // Testing this
        .zlib = true,
    });
    // todo: uncomment when zig-zlib is updated
    // const z = zlib.create(b, target, optimize);
    // z.link(xml2_with_libs.step, .{});

    // // const static_binding_test = b.addTest(.{
    // //     .root_source_file = b.path("test/basic.zig"),
    // //     .optimize = optimize,
    // // });
    // xml2.link(static_binding_test);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&xml2_with_libs.step.step);
    // test_step.dependOn(&static_binding_test.step);
}

pub fn link(b: *std.Build, compile: *std.Build.Step.Compile, opt: anytype) void {
    const this_dep = b.dependencyFromBuildZig(@This(), opt);
    const src_dep = this_dep.builder.dependency("libxml2", .{});
    compile.linkLibrary(this_dep.artifact("xml2"));
    compile.addIncludePath(this_dep.path("override/include"));
    compile.addIncludePath(src_dep.path("include"));
}


pub const LinkHeaderModuleOptions = struct {
    b: *std.Build,
    compile: *std.Build.Step.Compile,
    header: std.Build.LazyPath,
    import_name: []const u8 = "libxml2",
};

// translates a c `header` to zig, adds it as an import to `compile`
// and links the libxml2 c library
pub fn linkHeaderModule(opt: LinkHeaderModuleOptions, dependency_options: anytype) void {
    const this_dep = opt.b.dependencyFromBuildZig(@This(), dependency_options);
    const src_dep = this_dep.builder.dependency("libxml2", .{});

    const zig_libxml = opt.b.addTranslateC(.{
        .target = opt.compile.root_module.resolved_target orelse opt.b.host,
        .optimize = opt.compile.root_module.optimize orelse .Debug,
        .root_source_file = opt.header,
    });
    opt.compile.step.dependOn(&zig_libxml.step);
    zig_libxml.addIncludeDir(this_dep.path("override/include").getPath(this_dep.builder));
    zig_libxml.addIncludeDir(src_dep.path("include").getPath(src_dep.builder));
    opt.compile.root_module.addImport(opt.import_name, zig_libxml.createModule());

    link(opt.b, opt.compile, dependency_options);
}