const std = @import("std");

/// Please free after use
///
pub fn read_file(path: []const u8) ![]u8 {
    const stderr = std.io.getStdErr().writer();
    const alc = std.heap.page_allocator;

    const content = std.fs.cwd().readFileAlloc(alc, path, std.math.maxInt(usize)) catch |err| {
        try stderr.print("Failed to read file: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };

    return content;
}
