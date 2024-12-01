const std = @import("std");
const Ulid = @import("Ulid.zig");

const mem = std.mem;
const testing = std.testing;

/// The size of encoded Ulid in bytes.
pub const encoded_size = Ulid.encoded_size;

/// The Nil Ulid is a special form of Ulid that is specified to have all 128 bits set to 0.
pub const nil_ulid = Ulid{ .bytes = [_]u8{0} ** 16 };

/// The Max Ulid is a special form of Ulid that is specified to have all 128 bits set to 1.
/// This Ulid can be thought of as the inverse of `nil_ulid`.
pub const max_ulid = Ulid{ .bytes = [_]u8{0xFF} ** 16 };

/// The default Ulid generator.
pub const Generator = struct {
    bytes: [16]u8,

    pub fn init(timestamp: ?i64) Generator {
        const tt: u64 = @intCast(timestamp orelse std.time.milliTimestamp());
        var bytes: [16]u8 = undefined;

        bytes[0] = @truncate(tt >> 40);
        bytes[1] = @truncate(tt >> 32);
        bytes[2] = @truncate(tt >> 24);
        bytes[3] = @truncate(tt >> 16);
        bytes[4] = @truncate(tt >> 8);
        bytes[5] = @truncate(tt);

        std.crypto.random.bytes(bytes[6..16]);

        return .{ .bytes = bytes };
    }

    pub fn toULID(self: Generator) Ulid {
        return Ulid{ .bytes = self.bytes };
    }

    pub fn encode(self: Generator, dest: *[Ulid.encoded_size]u8) void {
        return self.toULID().encode(dest);
    }
};

test "ulid.timeMilli" {
    const id = Generator.init(123456);
    const tt = id.toULID().timeMilli();

    try testing.expectEqual(tt, 123456);
}

test "ulid.encode" {
    const max_expected: []const u8 = "7ZZZZZZZZZZZZZZZZZZZZZZZZZ";
    var max_out: [encoded_size]u8 = undefined;

    max_ulid.encode(&max_out);
    try testing.expectEqualStrings(max_expected, max_out[0..]);

    const min_expected: []const u8 = "00000000000000000000000000";
    var min_out: [encoded_size]u8 = undefined;

    nil_ulid.encode(&min_out);
    try testing.expectEqualStrings(min_expected, min_out[0..]);
}
