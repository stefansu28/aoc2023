const std = @import("std");
const Reader = std.fs.File.Reader;

const Parser = @import("../utils.zig").Parser;

const State = enum {
    SEED,
    MAP,
};

pub fn part1(reader: Reader) !u64 {
    var buf: [256]u8 = undefined;

    var state: State = .SEED;
    var dataBuff: [32]u64 = undefined;
    var data: []u64 = &dataBuff;
    data.len = 0;
    var toMapCount: usize = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;

        var parser = Parser { .buf = line };
        switch (state) {
            .SEED => {
                if (!parser.maybeSlice("seeds: ")) return error.ExpectedSeeds;
                while(parser.peek(0)) |_| {
                    if (parser.number()) |seed| {
                        dataBuff[data.len] = @intCast(seed);
                        data.len += 1;
                    }
                    _ = parser.maybe(' ');
                }
                state = .MAP;
            },
            .MAP => {
                // std.log.debug("{any}", .{data});
                if (!std.ascii.isDigit(parser.buf[0])) {
                    toMapCount = data.len;
                    continue;
                }

                const dest = parser.number().?;
                _ = parser.maybe(' ');

                const src = parser.number().?;
                _ = parser.maybe(' ');

                const range = parser.number().?;

                var n: usize = 0;
                while (n < toMapCount) : (n += 1) {
                    const val = data[n];
                    if (val >= src and val < src + range) {
                        const mapped = val - src + dest;
                        toMapCount -= 1;
                        data[n] = data[toMapCount];
                        data[toMapCount] = mapped;
                    }
                }
            }
        }
    }

    return std.mem.min(u64, data);
}

pub fn part2(reader: Reader) !u64 {
    _ = reader;

    @panic("TODO");
}
