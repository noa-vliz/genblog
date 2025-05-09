const std = @import("std");
const read = @import("./read_file.zig");

pub const Info = struct {
    title: []const u8,
    date: []const u8,
    body: []const u8,
};

pub const ParseState = enum {
    none,
    title,
    body,
    title_strings,
    date,
    end,
};

pub const Parser = struct {
    alloc: std.mem.Allocator,
    state: ParseState = .none,
    title: std.ArrayList(u8),
    date: std.ArrayList(u8),
    body: std.ArrayList(u8),

    pub fn init(alloc: std.mem.Allocator) Parser {
        return Parser{
            .alloc = alloc,
            .title = std.ArrayList(u8).init(alloc),
            .date = std.ArrayList(u8).init(alloc),
            .body = std.ArrayList(u8).init(alloc),
        };
    }

    pub fn deinit(self: *Parser) void {
        self.title.deinit();
        self.date.deinit();
        self.body.deinit();
    }

    pub fn parse_line(self: *Parser, line: []const u8) !void {
        if (std.mem.startsWith(u8, line, "#title")) {
            self.state = .title_strings;
            return;
        } else if (std.mem.startsWith(u8, line, "#date")) {
            self.state = .date;
            return;
        } else if (std.mem.startsWith(u8, line, "#body")) {
            self.state = .body;
            return;
        }
        switch (self.state) {
            .title_strings => try self.title.appendSlice(line),
            .date => try self.date.appendSlice(line),
            .body => {
                // "."から始まる行は<h2>タグで囲み、それ以外は<p>タグで囲む
                if (line.len > 0) {
                    if (std.mem.startsWith(u8, line, ".")) {
                        try self.body.appendSlice("<h2>");
                        try self.body.appendSlice(line);
                        try self.body.appendSlice("</h2>\n");
                    } else {
                        try self.body.appendSlice("<p>");
                        try self.body.appendSlice(line);
                        try self.body.appendSlice("</p>\n");
                    }
                }
            },
            else => {},
        }
    }

    pub fn finalize(self: *Parser) Info {
        return Info{
            .title = self.title.toOwnedSlice() catch unreachable,
            .date = self.date.toOwnedSlice() catch unreachable,
            .body = self.body.toOwnedSlice() catch unreachable,
        };
    }
};

pub fn parse_file(path: []const u8) !Info {
    const stderr = std.io.getStdErr().writer();
    const alloc = std.heap.page_allocator;

    const file_content = read.read_file(path) catch |err| {
        try stderr.print("Failed to read file: {s}\n", .{@errorName(err)});
        return err;
    };

    defer alloc.free(file_content);

    var parser = Parser.init(alloc);
    defer parser.deinit();

    var lines = std.mem.tokenizeAny(u8, file_content, "\n");
    while (lines.next()) |line| {
        try parser.parse_line(line);
    }

    return parser.finalize();
}

