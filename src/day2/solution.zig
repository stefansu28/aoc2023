const std = @import("std");
const Reader = std.fs.File.Reader;

inline fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

pub fn part1(reader: Reader) !u64 {
    var sum: u64 = 0;
    var buf: [256]u8 = undefined;
    var game: u64 = 1;

    const MAX_RED = 12;
    const MAX_GREEN = 13;
    const MAX_BLUE = 14;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        defer game += 1;
        var inc = game;
        defer sum += inc;

        var parser = std.fmt.Parser { .buf = line, .pos = "Game ".len };

        _ = parser.number();
        parser.pos += 2;// skip ": "

        while (parser.peek(0)) |_| {
            const count = parser.number().?;
            parser.pos += 1; // skip space

            const start = parser.pos;
            while (parser.pos < parser.buf.len and parser.peek(0) != ',' and parser.peek(0) != ';') : (parser.pos += 1) {}
            const color = parser.buf[start..parser.pos];
            parser.pos += 2; // skip ,/; and space

            var max: u8 = 0;
            if (std.mem.eql(u8, color, "red")) {
                max = MAX_RED;
            } else if (std.mem.eql(u8, color, "green")) {
                max = MAX_GREEN;
            } else if (std.mem.eql(u8, color, "blue")) {
                max = MAX_BLUE;
            }

            if (count > max) {
                inc = 0;
                break;
            }
        }
    }

    return sum;
}

pub fn part2(reader: Reader) !u64 {
    var sum: u64 = 0;
    var buf: [256]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var parser = std.fmt.Parser { .buf = line, .pos = "Game ".len };
        
        var max_red: u64 = 0;
        var max_green: u64 = 0;
        var max_blue: u64 = 0;

        _ = parser.number();
        parser.pos += 2;// skip ": "

        while (parser.peek(0)) |_| {
            const count = parser.number().?;
            parser.pos += 1; // skip space

            const start = parser.pos;
            while (parser.pos < parser.buf.len and parser.peek(0) != ',' and parser.peek(0) != ';') : (parser.pos += 1) {}
            const color = parser.buf[start..parser.pos];
            parser.pos += 2; // skip ,/; and space

            if (std.mem.eql(u8, color, "red")) {
                max_red = @max(max_red, count);
            } else if (std.mem.eql(u8, color, "green")) {
                max_green = @max(max_green, count);
            } else if (std.mem.eql(u8, color, "blue")) {
                max_blue = @max(max_blue, count);
            }
        }

        sum += max_red * max_green * max_blue;
    }

    return sum;
}
