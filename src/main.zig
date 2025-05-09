const std = @import("std");
const parse = @import("./parse.zig");
const gen_html = @import("./gen_html.zig");
const template = @embedFile("./template_doc");
const read_file = @import("read_file.zig");

pub fn main() !void {
    const alc = std.heap.page_allocator;

    const stderr = std.io.getStdErr().writer();

    const args = std.process.argsAlloc(alc) catch |err| {
        try stderr.print("Failed to get args: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };

    if (args.len == 1) {
        try stderr.print("{s}: No file specified.\n", .{args[0]});
        try stderr.print("Usage: {s} [-t] <file>\n", .{args[0]});
        std.process.exit(1);
    }

    if (std.mem.eql(u8, args[1], "--template") or std.mem.eql(u8, args[1], "--template")) {
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
