const std = @import("std");
const parser_import = @import("./parse.zig");

const template = @embedFile("./template.html");

pub fn gen_html(info: parser_import.Info) ![]u8 {
    const alc = std.heap.page_allocator;

    const replaced_title = try replace_tag(alc, template, "{TITLE}", info.title);
    defer alc.free(replaced_title);

    const replaced_date = try replace_tag(alc, replaced_title, "{DATE}", info.date);
    defer alc.free(replaced_date);

    const replaced_body = try replace_tag(alc, replaced_date, "{GENHTML}", info.body);

    return replaced_body;
}

fn replace_tag(allocator: std.mem.Allocator, source: []const u8, tag: []const u8, value: []const u8) ![]u8 {
    const size = std.mem.replacementSize(u8, source, tag, value);
    const buffer = try allocator.alloc(u8, size);
    _ = std.mem.replace(u8, source, tag, value, buffer);
    return buffer;
}
