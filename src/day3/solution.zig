const std = @import("std");
const Reader = std.fs.File.Reader;

const Parser = @import("../util.zig").Parser;

inline fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

pub fn part1(reader: Reader) !u64 {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var lines = std.ArrayList([]u8).init(arena);

    var sum: u64 = 0;

    while (try reader.readUntilDelimiterOrEofAlloc(arena, '\n', 256)) |line| {
        (try lines.addOne()).* = line;
    }

    for (lines.items, 0..) |line, row| {

        // std.log.debug("line: {s}", .{line});

        var parser = Parser {.buf = line};

        while (parser.pos < parser.buf.len) {
            const start = if (parser.pos > 0) parser.pos - 1 else parser.pos;

            if (parser.number()) |as_usize| {
                var isPart = false;
                const num: u64 = @intCast(as_usize);

                const end = parser.pos;
                const endPlus1 = @min(end+1, parser.buf.len);

                const startChar = line[start];
                const endChar = line[@min(end, parser.buf.len - 1)];
                if (startChar != '.' and !isDigit(startChar)) {
                    isPart = true;
                }
                if (endChar != '.' and !isDigit(endChar)) {
                    isPart = true;
                }

                const prev = if (row > 0) lines.items[row - 1] else null;
                const next = if (row < lines.items.len - 1) lines.items[row + 1] else null;

                if (prev) |prevLine| {
                    for (prevLine[start..endPlus1]) |c| {
                        if (!isDigit(c) and c != '.') {
                            isPart = true;
                        }
                    }
                }

                if (next) |prevLine| {
                    for (prevLine[start..endPlus1]) |c| {
                        if (!isDigit(c) and c != '.') {
                            isPart = true;
                        }
                    }
                }
                if (isPart) {
                    std.log.debug("{}", .{num});
                    if (prev) |prevLine| {
                        std.log.debug("{s}", .{prevLine});
                    }
                    std.log.debug("{s}", .{line});
                    if (next) |prevLine| {
                        std.log.debug("{s}", .{prevLine});
                    }
                    std.log.debug("\n\n", .{});
                    sum += num;
                }
            } else {
                parser.pos += 1;
            }
        }
    }

    return sum;
}

const Pos = struct {
    x: usize,
    y: usize,
};
const GearInfo = struct {
    count: u8,
    product: u64,
};
const GearMap = std.AutoHashMap(Pos, GearInfo);

fn scanForGear(slice: []const u8) ?usize {
    for (slice, 0..) |c, n| {
        if (c == '*') return n;
    }

    return null;
}

pub fn part2(reader: Reader) !u64 {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var lines = std.ArrayList([]u8).init(arena);
    var gearMap = GearMap.init(arena);

    var sum: u64 = 0;

    while (try reader.readUntilDelimiterOrEofAlloc(arena, '\n', 256)) |line| {
        (try lines.addOne()).* = line;
    }

    for (lines.items, 0..) |line, row| {

        // std.log.debug("line: {s}", .{line});

        var parser = Parser {.buf = line};

        while (parser.pos < parser.buf.len) {
            const start = if (parser.pos > 0) parser.pos - 1 else parser.pos;

            if (parser.number()) |as_usize| {
                // can they be next to multiple gears?
                var gearOpt: ?Pos = null;
                const num: u64 = @intCast(as_usize);

                const end = parser.pos;
                const endPlus1 = @min(end+1, parser.buf.len);

                const startChar = line[start];
                const endChar = line[@min(end, parser.buf.len - 1)];
                if (startChar == '*') {
                    gearOpt = .{.x = start, .y = row};
                } else if (endChar == '*') {
                    gearOpt = .{.x = end, .y = row};
                }

                if (row > 0 and gearOpt == null) {
                    const prev = lines.items[row - 1][start..endPlus1];
                    if (scanForGear(prev)) |x_offset| {
                        gearOpt = .{.x = start + x_offset, .y = row - 1};
                    }
                }
                if (row < lines.items.len - 1 and gearOpt == null) {
                    const next = lines.items[row + 1][start..endPlus1];
                    if (scanForGear(next)) |x_offset| {
                        gearOpt = .{.x = start + x_offset, .y = row + 1};
                    }
                }

                if (gearOpt) |gear| {
                    const result = try gearMap.getOrPut(gear);
                    result.value_ptr.count = if (result.found_existing) result.value_ptr.count + 1 else 1;
                    result.value_ptr.product = if (result.found_existing) result.value_ptr.product * num else num;
                }
            } else {
                parser.pos += 1;
            }
        }
    }

    var gearItr = gearMap.valueIterator();
    while (gearItr.next()) |gearInfo| {
        if (gearInfo.count == 2) {
            sum += gearInfo.product;
        }
    }

    return sum;
}
