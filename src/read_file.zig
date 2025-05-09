const std = @import("std");

/// Please free after use
/// Usage:
/// ```zig
/// const read = @import("./read_file.zig");
/// const std = @import("std");
///
/// fn main(){
///     const content = read.read_file("./test.txt");
///     const allocation = std.
///     for (content.items) |line| {
///         std.debug.print("{s}\n", .{line});
///         allocation.free(line);
///     }
/// }
/// ```
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
