const std = @import("std");
const read = @import("./read_file.zig");
const util = @import("./utils.zig");

pub const Info = struct {
    title: []const u8,
    date: []const u8,
    body: []const u8,
};

pub const ParseState = enum {
    none,
    title,
    body,
    body_code,
    body_mini_code,
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
                // "."から始まる行は<h2>タグで囲み、..は<h3>。--は<hr>。
                // !から始まるものは<img>
                // ![src="" alt=""]
                if (line.len > 0) {
                    const alc = std.heap.page_allocator;
                    if (std.mem.startsWith(u8, line, "..")) {
                        const ln = try util.replace(line, "..", "");
                        defer alc.free(ln);

                        try self.body.appendSlice("<h3>");
                        try self.body.appendSlice(ln);
                        try self.body.appendSlice("</h3>\n");
                        // .
                    } else if (std.mem.startsWith(u8, line, ".")) {
                        const ln = try util.replace(line, ".", "");
                        defer alc.free(ln);

                        try self.body.appendSlice("<h2>");
                        try self.body.appendSlice(ln);
                        try self.body.appendSlice("</h2>\n");
                        // --
                    } else if (std.mem.eql(u8, line, "--")) {
                        try self.body.appendSlice("<hr>\n");
                        // ![]
                    } else if (std.mem.startsWith(u8, line, "!")) {
                        var replaced = try util.replace(line, "!", "");
                        replaced = try util.replace(replaced, "[", "<img ");
                        replaced = try util.replace(replaced, "[", ">");
                        defer alc.free(replaced);
                        try self.body.appendSlice(replaced);
                        // ```
                    } else if (std.mem.startsWith(u8, line, "```")) {
                        self.state = .body_code;
                        try self.body.appendSlice("<pre>\n");

                        // ` `
                    } else if (std.mem.indexOf(u8, line, "`")) |_| {
                        const result = try mini_pre(alc, line);
                        try self.body.appendSlice(result);
                        // -
                    } else if (std.mem.startsWith(u8, line, "--")) {
                        const ln = try util.replace(line, "--", "");
                        defer alc.free(ln);

                        try self.body.appendSlice("<p><s>");
                        try self.body.appendSlice(ln);
                        try self.body.appendSlice("</p></s>\n");
                    } else if (std.mem.startsWith(u8, line, "-")) {
                        const ln = try util.replace(line, "-", "");
                        defer alc.free(ln);

                        try self.body.appendSlice("<p><small>");
                        try self.body.appendSlice(ln);
                        try self.body.appendSlice("</p></small>\n");
                    } else {
                        try self.body.appendSlice("<p>");
                        try self.body.appendSlice(line);
                        try self.body.appendSlice("</p>\n");
                    }
                }
            },
            .body_code => {
                const alc = std.heap.page_allocator;
                if (line.len > 0) {
                    if (std.mem.startsWith(u8, line, "```")) {
                        self.state = .body;
                        try self.body.appendSlice("</pre>\n");
                    } else {
                        var result = try util.replace(line, "&", "&amp;");
                        result = try util.replace(result, "<", "&lt;");
                        result = try util.replace(result, ">", "&gt;");
                        try self.body.appendSlice(result);
                        try self.body.appendSlice("\n");

                        defer alc.free(result);
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

fn mini_pre(allocator: std.mem.Allocator, text: []const u8) ![]u8 {
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    // テキスト内でバッククォートの位置を検索
    const start_idx = std.mem.indexOf(u8, text, "`") orelse return try allocator.dupe(u8, text);

    // バッククォート前のテキストをそのまま追加
    try buf.appendSlice(text[0..start_idx]);

    // 始まりのバッククォートをスキップ
    var i: usize = start_idx + 1;
    var found_end = false;

    // 次のバッククォートまでの内容をエスケープして処理
    while (i < text.len) {
        const c = text[i];
        if (c == '`') {
            found_end = true;
            i += 1;
            break;
        }

        switch (c) {
            '&' => try buf.appendSlice("&amp;"),
            '<' => try buf.appendSlice("&lt;"),
            '>' => try buf.appendSlice("&gt;"),
            else => try buf.append(c),
        }
        i += 1;
    }

    // 終了のバッククォート以降の残りのテキストを追加
    if (found_end and i < text.len) {
        try buf.appendSlice(text[i..]);
    }

    return buf.toOwnedSlice();
}

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
