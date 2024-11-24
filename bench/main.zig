const std = @import("std");
const zulid = @import("zulid");
const zbench = @import("zbench");

fn benchNew(_: std.mem.Allocator) void {
    _ = zulid.ULID.new(null);
}

fn benchEncode(_: std.mem.Allocator) void {
    var encoded: [zulid.ULID.encoded_size]u8 = undefined;
    _ = zulid.max_ulid.encode(encoded[0..]) catch unreachable;
}

fn benchDecode(_: std.mem.Allocator) void {
    const uid_str: []const u8 = "01JDEGB7D6RSA8QK5SPB13TYP6";
    _ = zulid.ULID.decode(uid_str) catch unreachable;
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();

    try bench.add("ULID.new", benchNew, .{});
    try bench.add("ULID.encode", benchEncode, .{});
    try bench.add("ULID.decode", benchDecode, .{});

    try stdout.print("\n", .{});
    try bench.run(stdout);
}
