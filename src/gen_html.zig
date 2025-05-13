const std = @import("std");
const parser_import = @import("parse.zig");

const default_template = @embedFile("include/templates/template.html");

pub fn gen_html(info: parser_import.Info, template: ?[]const u8) ![]u8 {
    const stderr = std.io.getStdErr().writer();
    const last_template = template orelse default_template;
    const alc = std.heap.page_allocator;

    std.debug.print("Compiling template HTML\n", .{});

    const replacements = [_]struct { tag: []const u8, value: []const u8 }{
        .{ .tag = "{TITLE}", .value = info.title },
        .{ .tag = "{DATE}", .value = info.date },
        .{ .tag = "{GENHTML}", .value = info.body },
    };

    var current_template = try alc.dupe(u8, last_template);
    errdefer alc.free(current_template);

    for (replacements) |replacement| {
        const replaced = replace_tag(alc, current_template, replacement.tag, replacement.value) catch |err| {
            if (err == Err.TagNotFound) {
                try stderr.print("| \x1b[33mwarning:\x1b[0m {s} section not found\n", .{replacement.tag});
                try stderr.print("| {s} not found. Don't need it?\x1b[0m\n", .{replacement.tag});
                continue;
            } else {
                try stderr.print("| \x1b[31mError:\x1b[0m FAILED: {s}\n", .{@errorName(err)});
                try stderr.print("| This is an error that should not exist\n", .{});
                std.process.exit(1);
            }
        };

        std.debug.print("| {s}\n", .{replacement.tag});
        alc.free(current_template);
        current_template = replaced;
    }

    return current_template;
}
const Err = error{
    TagNotFound,
    OutOfMemory,
};

fn replace_tag(allocator: std.mem.Allocator, source: []const u8, tag: []const u8, value: []const u8) Err![]u8 {
    if (std.mem.indexOf(u8, source, tag) == null) {
        return Err.TagNotFound;
    }

    const size = std.mem.replacementSize(u8, source, tag, value);
    const buffer = try allocator.alloc(u8, size);
    _ = std.mem.replace(u8, source, tag, value, buffer);
    return buffer;
}
