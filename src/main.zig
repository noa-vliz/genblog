const std = @import("std");
const parse = @import("parse.zig");
const gen_html = @import("gen_html.zig");
const util = @import("utils.zig");
const read_file = @import("read_file.zig");

const template = @embedFile("./template_doc");
const version_info = @embedFile("genblog_version");

fn version() !void {
    const v = try util.trim(version_info);
    std.debug.print("genblog {s}\n", .{v});
    std.debug.print("Copyright (C) 2025 noa-vliz.\n", .{});
    std.debug.print("Licensed under the MIT License\n", .{});
    std.debug.print("Source: https://github.com/noa-vliz/genblog\n", .{});
}

pub fn main() !void {
    const alc = std.heap.page_allocator;

    const stderr = std.io.getStdErr().writer();

    const args = std.process.argsAlloc(alc) catch |err| {
        try stderr.print("Failed to get args: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };

    if (args.len == 1) {
        try stderr.print("{s}: No file specified.\n", .{args[0]});
        try stderr.print("Usage: {s} [-tv] <file>\n", .{args[0]});
        std.process.exit(1);
    }

    // template生成フラグ
    const is_template = std.mem.eql(u8, args[1], "--template");
    const is_template2 = std.mem.eql(u8, args[1], "-t");

    if (is_template or is_template2) {
        if (args.len == 3) {
            const file = try std.fs.cwd().createFile(args[2], .{});
            defer file.close();

            try file.writeAll(template);
            std.debug.print("Template created to {s}\n", .{args[2]});
            std.process.exit(0);
        } else {
            std.debug.print("Please specify a file\n", .{});
            std.debug.print("Usage: {s} --template <file>\n", .{args[0]});
            std.process.exit(1);
        }
    }

    // version
    const is_version = std.mem.eql(u8, args[1], "--version");
    const is_version2 = std.mem.eql(u8, args[1], "-v");

    if (is_version or is_version2) {
        try version();
        std.process.exit(0);
    }

    // ファイルの内容を順序に見て出力する
    for (args[1..]) |arg| {
        const output_file = try std.fmt.allocPrint(alc, "{s}.html", .{arg});

        const tmp = try parse.parse_file(arg);
        std.debug.print("title: {s}\ndate: {s}\n", .{ tmp.title, tmp.date });

        const generated_html = try gen_html.gen_html(tmp);

        const file = try std.fs.cwd().createFile(output_file, .{});

        try file.writeAll(generated_html);
        std.debug.print("HTML file created to {s}\n", .{output_file});

        alc.free(generated_html);
    }
}
