const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const assert = std.debug.assert;
const milliTimestamp = std.time.milliTimestamp;

pub const Error = error{
    /// The encoded ULID is overflowed.
    Overflow,
    /// The size is invalid.
    InvalidSize,
    /// The encoded ULID contains invalid Crockford's base32 letters.
    InvalidBase32Char,
};

inline fn to_u8(n: anytype) u8 {
    return @as(u8, @intCast(n & 0xFF));
}

/// The Max ULID is a special form of ULID that is specified to have
/// all 128 bits set to `1`. This UUID can be thought of as the inverse
/// of `zero_ulid`.
pub const max_ulid = ULID{
    .timestamp = std.math.maxInt(u48),
    .entropy = std.math.maxInt(u80),
};

/// The Zero ULID is a special form of ULID that is specified to have
/// all 128 bits set to `0`.
pub const zero_ulid = ULID{
    .timestamp = 0,
    .entropy = 0,
};

/// A 128-bit Universally Unique Lexicographically Sortable Identifier (ULID).
///
/// The components are encoded as 16 octets. Each component is encoded with
/// the Most Significant Byte first (network byte order).
///
/// ```
///  0                   1                   2                   3
///  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// |                      32_bit_uint_time_high                    |
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// |     16_bit_uint_time_low      |       16_bit_uint_random      |
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// |                       32_bit_uint_random                      |
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// |                       32_bit_uint_random                      |
/// +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
/// ```
pub const ULID = struct {
    /// The size of ULID in bytes.
    pub const bytes_size = 16;
    /// The size of encoded ULID in bytes.
    pub const encoded_size = 26;

    /// A 48-bit integer representing UNIX-time in milliseconds.
    timestamp: u48,
    /// A random 80-bit integer.
    entropy: u80,

    /// Generates a new ULID with an optional timestamp.
    pub fn new(timestamp: ?i64) ULID {
        const time: i64 = timestamp orelse milliTimestamp();
        const entropy = std.crypto.random.int(u80);

        return ULID{
            .timestamp = @as(u48, @intCast(time & 0xFFFFFFFFFFFF)),
            .entropy = entropy,
        };
    }

    /// Gets the timestamp in milliseconds from the id.
    pub fn timeMilli(ulid: ULID) i64 {
        return @as(i64, @intCast(ulid.timestamp));
    }

    // Crockford's Base32 alphabet
    const alphabet_chars = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";

    /// Encodes the ULID into the lexicographically sortable string
    /// using Crockford's Base32. E.g. `01AN4Z07BY79KA1307SR9X4MV3`
    ///
    /// Canonical string representation:
    ///
    /// ```
    /// ttttttttttrrrrrrrrrrrrrrrr
    ///
    /// where
    ///     t is Timestamp                (10 characters)
    ///     r is Randomness (aka Entropy) (16 characters)
    /// ```
    pub fn encode(ulid: ULID, dest: []u8) Error![]const u8 {
        if (dest.len < encoded_size) {
            return Error.InvalidSize;
        }

        const tt = ulid.timestamp;
        const rd = ulid.entropy;

        dest[0] = alphabet_chars[(to_u8(tt >> 40) & 224) >> 5];
        dest[1] = alphabet_chars[to_u8(tt >> 40) & 31];
        dest[2] = alphabet_chars[(to_u8(tt >> 32) & 248) >> 3];
        dest[3] = alphabet_chars[((to_u8(tt >> 32) & 7) << 2) | ((to_u8(tt >> 24) & 192) >> 6)];
        dest[4] = alphabet_chars[(to_u8(tt >> 24) & 62) >> 1];
        dest[5] = alphabet_chars[((to_u8(tt >> 24) & 1) << 4) | ((to_u8(tt >> 16) & 240) >> 4)];
        dest[6] = alphabet_chars[((to_u8(tt >> 16) & 15) << 1) | ((to_u8(tt >> 8) & 128) >> 7)];
        dest[7] = alphabet_chars[(to_u8(tt >> 8) & 124) >> 2];
        dest[8] = alphabet_chars[((to_u8(tt >> 8) & 3) << 3) | ((to_u8(tt) & 224) >> 5)];
        dest[9] = alphabet_chars[to_u8(tt) & 31];

        dest[10] = alphabet_chars[(to_u8(rd >> 72) & 248) >> 3];
        dest[11] = alphabet_chars[((to_u8(rd >> 72) & 7) << 2) | ((to_u8(rd >> 64) & 192) >> 6)];
        dest[12] = alphabet_chars[(to_u8(rd >> 64) & 62) >> 1];
        dest[13] = alphabet_chars[((to_u8(rd >> 64) & 1) << 4) | ((to_u8(rd >> 56) & 240) >> 4)];
        dest[14] = alphabet_chars[((to_u8(rd >> 56) & 15) << 1) | ((to_u8(rd >> 48) & 128) >> 7)];
        dest[15] = alphabet_chars[(to_u8(rd >> 48) & 124) >> 2];
        dest[16] = alphabet_chars[((to_u8(rd >> 48) & 3) << 3) | ((to_u8(rd >> 40) & 224) >> 5)];
        dest[17] = alphabet_chars[to_u8(rd >> 40) & 31];
        dest[18] = alphabet_chars[(to_u8(rd >> 32) & 248) >> 3];
        dest[19] = alphabet_chars[((to_u8(rd >> 32) & 7) << 2) | ((to_u8(rd >> 24) & 192) >> 6)];
        dest[20] = alphabet_chars[(to_u8(rd >> 24) & 62) >> 1];
        dest[21] = alphabet_chars[((to_u8(rd >> 24) & 1) << 4) | ((to_u8(rd >> 16) & 240) >> 4)];
        dest[22] = alphabet_chars[((to_u8(rd >> 16) & 15) << 1) | ((to_u8(rd >> 8) & 128) >> 7)];
        dest[23] = alphabet_chars[(to_u8(rd >> 8) & 124) >> 2];
        dest[24] = alphabet_chars[((to_u8(rd >> 8) & 3) << 3) | ((to_u8(rd) & 224) >> 5)];
        dest[25] = alphabet_chars[to_u8(rd) & 31];

        return dest[0..encoded_size];
    }

    // base32 char lookup table
    const table = [256]u8{
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x01,
        0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E,
        0x0F, 0x10, 0x11, 0xFF, 0x12, 0x13, 0xFF, 0x14, 0x15, 0xFF,
        0x16, 0x17, 0x18, 0x19, 0x1A, 0xFF, 0x1B, 0x1C, 0x1D, 0x1E,
        0x1F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x0A, 0x0B, 0x0C,
        0x0D, 0x0E, 0x0F, 0x10, 0x11, 0xFF, 0x12, 0x13, 0xFF, 0x14,
        0x15, 0xFF, 0x16, 0x17, 0x18, 0x19, 0x1A, 0xFF, 0x1B, 0x1C,
        0x1D, 0x1E, 0x1F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
    };

    /// Parses an encoded ULID. Returns:
    /// - `Error.InvalidSize` if `str.len` is less than 26.
    /// - `Error.Overflow` if the id is larger than the maximum ULID.
    /// - `Error.InvalidBase32Char` if the id contains invalid base32's letters.
    pub fn decode(str: []const u8) Error!ULID {
        if (str.len < encoded_size) {
            return Error.InvalidSize;
        }

        if (str[0] > '7') {
            return Error.Overflow;
        }

        for (str, 0..encoded_size) |_, i| {
            if (table[str[i]] == 0xFF) return Error.InvalidBase32Char;
        }

        var tt: u48 = 0;
        tt = (table[str[0]] << 5) | table[str[1]];
        tt <<= 8;
        tt |= (table[str[2]] << 3) | (table[str[3]] >> 2);
        tt <<= 8;
        tt |= (table[str[3]] << 6) | (table[str[4]] << 1) | (table[str[5]] >> 4);
        tt <<= 8;
        tt |= (table[str[5]] << 4) | (table[str[6]] >> 1);
        tt <<= 8;
        tt |= (table[str[6]] << 7) | (table[str[7]] << 2) | (table[str[8]] >> 3);
        tt <<= 8;
        tt |= (table[str[8]] << 5) | table[str[9]];

        var ep: u80 = 0;
        ep <<= 8;
        ep |= (table[str[10]] << 3) | (table[str[11]] >> 2);
        ep <<= 8;
        ep |= (table[str[11]] << 6) | (table[str[12]] << 1) | (table[str[13]] >> 4);
        ep <<= 8;
        ep |= (table[str[13]] << 4) | (table[str[14]] >> 1);
        ep <<= 8;
        ep |= (table[str[14]] << 7) | (table[str[15]] << 2) | (table[str[16]] >> 3);
        ep <<= 8;
        ep |= (table[str[16]] << 5) | table[str[17]];
        ep <<= 8;
        ep |= (table[str[18]] << 3) | (table[str[19]] >> 2);
        ep <<= 8;
        ep |= (table[str[19]] << 6) | (table[str[20]] << 1) | (table[str[21]] >> 4);
        ep <<= 8;
        ep |= (table[str[21]] << 4) | (table[str[22]] >> 1);
        ep <<= 8;
        ep |= (table[str[22]] << 7) | (table[str[23]] << 2) | (table[str[24]] >> 3);
        ep <<= 8;
        ep |= (table[str[24]] << 5) | table[str[25]];

        return ULID{ .timestamp = tt, .entropy = ep };
    }

    /// Converts the ULID into a 16-byte array. Returns error if `dest.len` is less than 16.
    pub fn toArray(ulid: ULID, dest: []u8) Error![]u8 {
        if (dest.len < bytes_size) {
            return Error.InvalidSize;
        }

        mem.writeInt(u48, dest[0..6], ulid.timestamp, .big);
        mem.writeInt(u80, dest[6..16], ulid.entropy, .big);

        return dest[0..bytes_size];
    }

    /// Converts the ULID into an unsigned 128-bit integer.
    pub fn toU128(ulid: ULID) u128 {
        var ret: u128 = 0;

        ret = ulid.timestamp;
        ret <<= 80;
        ret |= ulid.entropy;

        return ret;
    }
};

test "ulid.timeMilli" {
    const id = ULID.new(123456);
    const tt = id.timeMilli();

    try testing.expectEqual(tt, 123456);
}

test "ulid.encode" {
    const max_expected: []const u8 = "7ZZZZZZZZZZZZZZZZZZZZZZZZZ";
    var max_out: [ULID.encoded_size]u8 = undefined;

    _ = try max_ulid.encode(max_out[0..]);
    try testing.expectEqualStrings(max_expected, max_out[0..]);

    const min_expected: []const u8 = "00000000000000000000000000";
    var min_out: [ULID.encoded_size]u8 = undefined;

    _ = try zero_ulid.encode(min_out[0..]);
    try testing.expectEqualStrings(min_expected, min_out[0..]);
}

test "ulid.decode" {
    const id = ULID.new(null);
    var out: [ULID.encoded_size]u8 = undefined;

    _ = try id.encode(out[0..]);
    const decoded_id = try ULID.decode(out[0..]);

    try testing.expectEqual(id.timestamp, decoded_id.timestamp);
    try testing.expectEqual(id.entropy, decoded_id.entropy);

    const overflow_id: []const u8 = "80000000000000000000000000";
    try testing.expectError(Error.Overflow, ULID.decode(overflow_id));

    const invalid_id: []const u8 = "0000000OIOIOI0000000000000";
    try testing.expectError(Error.InvalidBase32Char, ULID.decode(invalid_id));
}

test "ulid.toArray" {
    const id = ULID{
        .timestamp = 0x000102030405,
        .entropy = 0x060708090A0B0C0D0E0F,
    };
    const expected = [ULID.bytes_size]u8{
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
    };

    var bytes: [ULID.bytes_size]u8 = undefined;
    _ = try id.toArray(bytes[0..]);

    try testing.expectEqualSlices(u8, expected[0..], bytes[0..]);
}

test "ulid.toU128" {
    const id = ULID{
        .timestamp = 0x000102030405,
        .entropy = 0x060708090A0B0C0D0E0F,
    };
    const expected: u128 = 0x000102030405060708090A0B0C0D0E0F;
    const result = id.toU128();

    try testing.expectEqual(expected, result);
}
