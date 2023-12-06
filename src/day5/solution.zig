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

const RangeDiff = [2]?Range;

const Range = struct {
    min: u64,
    /// inclusive
    max: u64,

    const Self = @This();

    pub fn overlap(self: Self, other: Self) ?Self {
        if (self.max < other.min or self.min > other.max) return null;

        var left = self;
        var right = other;
        if (left.min > right.min) {
            right = self;
            left = other;
        }

        return .{
            .min = right.min,
            .max = @min(left.max, right.max),
        };
    }

    pub fn difference(self: Self, other: Self) RangeDiff {
        const overlapOpt = self.overlap(other);
        if (overlapOpt == null) return [_]?Range{ self, null };

        const over = overlapOpt.?;
        // self is other or self is contained by other
        if (self.min == over.min and self.max == over.max) return [_]?Range{ null, null };

        var diffs: RangeDiff = [_]?Range{null, null};
        var n: usize = 0;
        if (self.min < over.min) {
            diffs[n] = .{
                .min = self.min,
                .max = over.min - 1,
            };
            n += 1;
        }

        if (self.max > over.max) {
            diffs[n] = .{
                .min = over.max + 1,
                .max = self.max,
            };
        }

        return diffs;
    }
};
const RangeSet = struct {
    // TODO: Keep this sorted, but merge on add
    list: std.ArrayList(Range),

    pub fn init(allocator: std.mem.Allocator) RangeSet {
        return .{
            .list = std.ArrayList(Range).init(allocator),
        };
    }

    pub fn deinit(self: *@This()) void {
        self.list.deinit();
    }

    fn rangeLessThan(_: void, lhs: Range, rhs: Range) bool {
        return lhs.min < rhs.min;
    }

    pub fn sort(self: *@This()) void {
        std.mem.sort(Range, self.list.items, {}, rangeLessThan);
    }

    fn insert(self: *@This(), range: Range) !void {
        try self.list.append(range);

        var n: usize = self.list.items.len - 1;
        while (n >= 1 and self.list.items[n-1].min > self.list.items[n].min) : (n -= 1) {}

        if (n >= 1) {
            if (self.list.items[n-1].overlap(self.list.items[n])) |_| {
                const prev = self.list.items[n-1];
                const current = self.list.items[n];
                self.list.items[n] = .{
                    .min = @min(prev.min, current.min),
                    .max = @max(prev.max, current.max),
                };

                _ = self.list.orderedRemove(n-1);
            }
        }

        while (n + 1 < self.list.items.len) {
            if (self.list.items[n].overlap(self.list.items[n+1]) == null) break;
            const current = self.list.items[n];
            const next = self.list.items[n + 1];
            self.list.items[n] = .{
                .min = @min(current.min, next.min),
                .max = @max(current.max, next.max),
            };

            _ = self.list.orderedRemove(n+1);
        }
    }
};

pub fn part2(reader: Reader) !u64 {
    var buf: [256]u8 = undefined;

    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var datas: [2]RangeSet = [_]RangeSet {
        RangeSet.init(arena),
        RangeSet.init(arena),
    };
    defer for (&datas) |*data| {
        data.deinit();
    };
    var currentDataIndex: usize = 0;

    if (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var parser = Parser { .buf = line };

        if (!parser.maybeSlice("seeds: ")) return error.ExpectedSeeds;

        var data = &datas[1];
        while(parser.peek(0)) |_| {
            const start = parser.number().?;
            _ = parser.maybe(' ');
            const len = parser.number().?;
            _ = parser.maybe(' ');

            const range = Range {
                .min = start,
                .max = start + len - 1,
            };

            try data.list.append(range);
        }

        data.sort();
    } else {
        return error.NoInput;
    }

    // std.log.debug("{any}", .{datas[1].list.items});

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;
        var data = &datas[currentDataIndex];
        var otherData = &datas[(currentDataIndex + 1) % 2];

        var parser = Parser { .buf = line };

        // std.log.debug("{any}", .{data});
        if (!std.ascii.isDigit(parser.buf[0])) {
            for (data.list.items) |range| {
                try otherData.insert(range);
            }
            try data.list.resize(0);
            // std.log.debug("{any}", .{otherData.list.items});
            currentDataIndex = (currentDataIndex + 1) % 2;
            continue;
        }

        const dest = parser.number().?;
        _ = parser.maybe(' ');

        var src = Range {
            .min = parser.number().?,
            .max = 0,
        };
        _ = parser.maybe(' ');

        const len = parser.number().?;
        src.max = src.min + len - 1;

        var n: usize = 0;
        while (n < data.list.items.len) {
            var nDelta: usize = 1;
            defer n += nDelta;
            const range = data.list.items[n];
            if (range.overlap(src)) |overlap| {
                // std.log.debug("{any} overlaps {any} (overlap {any})", .{range, src, overlap});
                const mapped = .{
                    .min = overlap.min + dest - src.min,
                    .max = overlap.max + dest - src.min,
                };
                // std.log.debug("overlap {any} mapped to {any})", .{overlap, mapped});
                try otherData.insert(mapped);
                
                _ = data.list.orderedRemove(n);
                nDelta = 0;

                const rangeDiff = range.difference(overlap);
                for (rangeDiff) |diffOpt| {
                    if (diffOpt) |diff| {
                        // std.log.debug("diff {any})", .{diff});
                        try data.insert(diff);
                    }
                }
            }
        }
    }

    return @min(datas[0].list.items[0].min, datas[1].list.items[0].min);
}
