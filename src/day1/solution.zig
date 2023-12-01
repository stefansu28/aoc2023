const std = @import("std");
const Reader = std.fs.File.Reader;

pub fn part1(reader: Reader) !u64 {
    var sum: u64 = 0;
    var buf: [256]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const first: u8 = blk: {
            for (line) |c| {
                if (c >= '0' and c <= '9') {
                    break :blk c;
                }
            }
            unreachable;
        };

        const last: u8 = blk: {
            var n: usize = line.len - 1;
            while (n >= 0) : (n -= 1) {
                const c = line[n];
                if (c >= '0' and c <= '9') {
                    break :blk c;
                }
            }
            unreachable;
        };

        const str = [_]u8 { first, last };
        sum += try std.fmt.parseInt(u64, &str, 10);
    }

    return sum;
}

const words = [_][]const u8 {
    "one",
    "two",
    "three",
    "four",
    "five",
    "six",
    "seven",
    "eight",
    "nine",
};

pub fn part2(reader: Reader) !u64 {
    var sum: u64 = 0;
    var buf: [256]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const first: u8 = blk: {
            for (line, 0..) |c, index| {
                if (c >= '0' and c <= '9') {
                    break :blk c;
                }

                const rest = line[index..];
                for (words, 0..) |word, n| {
                    if (std.mem.startsWith(u8, rest, word)) {
                        break :blk @as(u8, @intCast(n)) + '1';
                    }
                }
            }
            unreachable;
        };

        const last: u8 = blk: {
            var n: usize = line.len - 1;
            while (n >= 0) : (n -= 1) {
                const c = line[n];
                if (c >= '0' and c <= '9') {
                    break :blk c;
                }

                const rest = line[n..];
                for (words, 0..) |word, m| {
                    if (std.mem.startsWith(u8, rest, word)) {
                        break :blk @as(u8, @intCast(m)) + '1';
                    }
                }
            }
            unreachable;
        };

        const str = [_]u8 { first, last };
        sum += try std.fmt.parseInt(u64, &str, 10);
    }

    return sum;
}
