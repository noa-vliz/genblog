const std = @import("std");

pub fn replace(source: []const u8, from: []const u8, to: []const u8) ![]u8 {
    const allocator = std.heap.page_allocator;
    const replacement_count = std.mem.count(u8, source, from);
    const new_len = source.len - (replacement_count * from.len) + (replacement_count * to.len);

    const buffer = try allocator.alloc(u8, new_len);

    _ = std.mem.replace(u8, source, from, to, buffer);

    return buffer;
}

pub fn trim(source: []const u8) ![]u8 {
    const trimed = replace(source, "\n", "");
    return trimed;
}
