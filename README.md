# zulid

Universally Unique Lexicographically Sortable Identifier for Zig.

## Background

UUID can be suboptimal for many use-cases because:

- It isn't the most character efficient way of encoding 128 bits of randomness
- UUID v1/v2 is impractical in many environments, as it requires access to a
  unique, stable MAC address
- UUID v3/v5 requires a unique seed and produces randomly distributed IDs, which
  can cause fragmentation in many data structures
- UUID v4 provides no other information than randomness which can cause
  fragmentation in many data structures

Instead, herein is ULID:

- 128-bit compatibility with UUID
- 1.21e+24 unique ULIDs per millisecond
- Lexicographically sortable!
- Canonically encoded as a 26 character string, as opposed to the 36 character
  UUID
- Uses Crockford's base32 for better efficiency and readability (5 bits per
  character)
- Case insensitive
- No special characters (URL safe)
- Monotonic sort order (correctly detects and handles the same millisecond)

## Installation

First, fetch `zulid` using Zig's package manager. This will download and add the
package to `build.zig.zon`:

```sh
zig fetch --save git+https://github.com/babiabeo/zulid
```

Then, update your `build.zig` in order to use the package:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zulid = b.dependency("zulid", .{
        .target = target,
        .optimize = optimize,
    }).module("zulid");

    const exe = b.addExecutable(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("zulid", zulid);
    
    // ...
}
```

## Usage

Here is a simple usage:

```zig
const std = @import("std");
const zulid = @import("zulid");

pub fn main() !void {
    const id = zulid.ULID.new(null);
    
    var out: [zulid.ULID.encoded_size]u8 = undefined;
    _ = try id.encode(out[0..]);

    std.debug.print("{s}", .{out});
}
```

With custom timestamp:

```zig
const std = @import("std");
const zulid = @import("zulid");

pub fn main() !void {
    const id = zulid.ULID.new(1732434408285);
    
    var out: [zulid.ULID.encoded_size]u8 = undefined;
    _ = try id.encode(out[0..]);

    std.debug.print("{s}", .{out});
}
```

## Specification

Below is the current specification of ULID as implemented in **zulid**.

```
 01AN4Z07BY      79KA1307SR9X4MV3

|----------|    |----------------|
 Timestamp          Randomness
   48bits             80bits
```

### Components

**Timestamp**

- 48 bit integer
- UNIX-time in milliseconds
- Won't run out of space 'til the year 10889 AD

**Randomness**

- 80 bits
- Cryptographically secure source of randomness (default)

### Canonical String Representation

```
ttttttttttrrrrrrrrrrrrrrrr

where
    t is Timestamp  (10 characters)
    r is Randomness (16 characters)
```

#### Encoding

Crockford's Base32 is used as shown. This alphabet excludes the letters I, L, O,
and U to avoid confusion and abuse.

```
0123456789ABCDEFGHJKMNPQRSTVWXYZ
```

### Binary Layout and Byte Order

The components are encoded as 16 octets. Each component is encoded with the Most
Significant Byte first (network byte order).

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                      32_bit_uint_time_high                    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|     16_bit_uint_time_low      |       16_bit_uint_random      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                       32_bit_uint_random                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                       32_bit_uint_random                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

# TODO

- [ ] Add `compare` function to compare 2 ULIDs.
- [ ] Allow custom random number generator.

# License

MIT License
