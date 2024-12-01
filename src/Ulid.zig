//! A 128-bit Universally Unique Lexicographically Sortable Identifier (ULID).
//!
//! The components are encoded as 16 octets. Each component is encoded with
//! the Most Significant Byte first (network byte order).
//!
//! ```
//! 0                   1                   2                   3
//! 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
//! +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//! |                      32_bit_uint_time_high                    |
//! +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//! |     16_bit_uint_time_low      |       16_bit_uint_random      |
//! +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//! |                       32_bit_uint_random                      |
//! +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//! |                       32_bit_uint_random                      |
//! +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
//! ```

const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const Ulid = @This();

/// The size of encoded Ulid in bytes.
pub const encoded_size = 26;

pub const Error = error{
    /// The encoded Ulid is overflowed.
    Overflow,
    /// The encoded Ulid is invalid.
    Invalid,
};

bytes: [16]u8,

/// Gets the timestamp in milliseconds from the id.
pub fn timeMilli(self: Ulid) i64 {
    return @intCast(mem.readInt(u48, self.bytes[0..6], .big));
}

/// Compares two Ulid values, in constant time.
pub fn compare(self: Ulid, other: Ulid) std.math.Order {
    return std.crypto.utils.timingSafeCompare(u8, &self.bytes, &other.bytes, .big);
}

// Crockford's Base32 alphabet
const alphabet_chars = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";

fn encodeBytes(bytes: *const [16]u8, dst: *[encoded_size]u8) void {
    dst[0] = alphabet_chars[(bytes[0] & 224) >> 5];
    dst[1] = alphabet_chars[bytes[0] & 31];
    dst[2] = alphabet_chars[(bytes[1] & 248) >> 3];
    dst[3] = alphabet_chars[((bytes[1] & 7) << 2) | ((bytes[2] & 192) >> 6)];
    dst[4] = alphabet_chars[(bytes[2] & 62) >> 1];
    dst[5] = alphabet_chars[((bytes[2] & 1) << 4) | ((bytes[3] & 240) >> 4)];
    dst[6] = alphabet_chars[((bytes[3] & 15) << 1) | ((bytes[4] & 128) >> 7)];
    dst[7] = alphabet_chars[(bytes[4] & 124) >> 2];
    dst[8] = alphabet_chars[((bytes[4] & 3) << 3) | ((bytes[5] & 224) >> 5)];
    dst[9] = alphabet_chars[bytes[5] & 31];

    dst[10] = alphabet_chars[(bytes[6] & 248) >> 3];
    dst[11] = alphabet_chars[((bytes[6] & 7) << 2) | ((bytes[7] & 192) >> 6)];
    dst[12] = alphabet_chars[(bytes[7] & 62) >> 1];
    dst[13] = alphabet_chars[((bytes[7] & 1) << 4) | ((bytes[8] & 240) >> 4)];
    dst[14] = alphabet_chars[((bytes[8] & 15) << 1) | ((bytes[9] & 128) >> 7)];
    dst[15] = alphabet_chars[(bytes[9] & 124) >> 2];
    dst[16] = alphabet_chars[((bytes[9] & 3) << 3) | ((bytes[10] & 224) >> 5)];
    dst[17] = alphabet_chars[bytes[10] & 31];
    dst[18] = alphabet_chars[(bytes[11] & 248) >> 3];
    dst[19] = alphabet_chars[((bytes[11] & 7) << 2) | ((bytes[12] & 192) >> 6)];
    dst[20] = alphabet_chars[(bytes[12] & 62) >> 1];
    dst[21] = alphabet_chars[((bytes[12] & 1) << 4) | ((bytes[13] & 240) >> 4)];
    dst[22] = alphabet_chars[((bytes[13] & 15) << 1) | ((bytes[14] & 128) >> 7)];
    dst[23] = alphabet_chars[(bytes[14] & 124) >> 2];
    dst[24] = alphabet_chars[((bytes[14] & 3) << 3) | ((bytes[15] & 224) >> 5)];
    dst[25] = alphabet_chars[bytes[15] & 31];
}

/// Encodes the Ulid into the lexicographically sortable string
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
pub fn encode(self: Ulid, dest: *[encoded_size]u8) void {
    return encodeBytes(&self.bytes, dest);
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

/// Parses and returns a new Ulid from an Crockford's Base32 encoded string.
pub fn decode(str: []const u8) Error!Ulid {
    if (str.len < encoded_size) {
        return Error.Invalid;
    }

    if (str[0] > '7') {
        return Error.Overflow;
    }

    for (str, 0..encoded_size) |_, i| {
        if (table[str[i]] == 0xFF)
            return Error.Invalid;
    }

    var bytes: [16]u8 = undefined;

    // timestamp
    bytes[0] = (table[str[0]] << 5) | table[str[1]];
    bytes[1] = (table[str[2]] << 3) | (table[str[3]] >> 2);
    bytes[2] = (table[str[3]] << 6) | (table[str[4]] << 1) | (table[str[5]] >> 4);
    bytes[3] = (table[str[5]] << 4) | (table[str[6]] >> 1);
    bytes[4] = (table[str[6]] << 7) | (table[str[7]] << 2) | (table[str[8]] >> 3);
    bytes[5] = (table[str[8]] << 5) | table[str[9]];

    // entropy
    bytes[6] = (table[str[10]] << 3) | (table[str[11]] >> 2);
    bytes[7] = (table[str[11]] << 6) | (table[str[12]] << 1) | (table[str[13]] >> 4);
    bytes[8] = (table[str[13]] << 4) | (table[str[14]] >> 1);
    bytes[9] = (table[str[14]] << 7) | (table[str[15]] << 2) | (table[str[16]] >> 3);
    bytes[10] = (table[str[16]] << 5) | table[str[17]];
    bytes[11] = (table[str[18]] << 3) | (table[str[19]] >> 2);
    bytes[12] = (table[str[19]] << 6) | (table[str[20]] << 1) | (table[str[21]] >> 4);
    bytes[13] = (table[str[21]] << 4) | (table[str[22]] >> 1);
    bytes[14] = (table[str[22]] << 7) | (table[str[23]] << 2) | (table[str[24]] >> 3);
    bytes[15] = (table[str[24]] << 5) | table[str[25]];

    return Ulid{ .bytes = bytes };
}

/// Converts the Ulid into a 128-bit big-endian unsigned integer.
pub fn toU128(self: Ulid) u128 {
    return mem.readInt(u128, self.bytes[0..], .big);
}

test "ulid.compare" {
    const id1 = try Ulid.decode("01JE0R6Z1WHMS9Q70C5JRD6C8H");
    const id2 = try Ulid.decode("01JE0R785J97RD5RZMZBF6ZS1P");

    try testing.expectEqual(id1.compare(id2), .lt);
    try testing.expectEqual(id2.compare(id1), .gt);
    try testing.expectEqual(id1.compare(id1), .eq);
}

test "ulid.decode" {
    const nil_id: []const u8 = "00000000000000000000000000";
    const nil_decoded = try Ulid.decode(nil_id);
    const expected = [_]u8{0} ** 16;

    try testing.expectEqualSlices(u8, &expected, &nil_decoded.bytes);

    const overflow_id: []const u8 = "80000000000000000000000000";
    try testing.expectError(Error.Overflow, Ulid.decode(overflow_id));

    const invalid_id: []const u8 = "0000000OIOIOI0000000000000";
    try testing.expectError(Error.Invalid, Ulid.decode(invalid_id));
}

test "ulid.toU128" {
    const id = Ulid{ .bytes = [16]u8{
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
    } };
    const expected: u128 = 0x000102030405060708090A0B0C0D0E0F;
    const result = id.toU128();

    try testing.expectEqual(expected, result);
}
