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

                const end = @min(parser.pos, parser.buf.len - 1);

                if (line[start] != '.' or line[end] != '.') {
                    isPart = true;
                }

                const prev = if (row > 0) lines.items[row - 1] else null;
                const next = if (row < lines.items.len - 1) lines.items[row + 1] else null;

                if (prev) |prevLine| {
                    for (prevLine[start..end]) |c| {
                        if (!isDigit(c) and c != '.') {
                            isPart = true;
                        }
                    }
                }

                if (next) |prevLine| {
                    for (prevLine[start..end]) |c| {
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

pub fn part2(reader: Reader) !u64 {
    _ = reader;

    @panic("TODO");
}
