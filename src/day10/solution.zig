const std = @import("std");
const Reader = std.fs.File.Reader;

const Grid = @import("../utils.zig").Grid(256);

const Pos = struct {
    x: usize,
    y: usize,

    fn fromEntry(entry: Grid.SearchIterator.Entry) @This() {
        return .{
            .x = entry.x,
            .y = entry.y,
        };
    }
};

const Visited = std.AutoHashMap(Pos, void);
const PosQueue = std.ArrayList(Pos);

fn getAdjacent(pos: Pos, grid: *const Grid) [2]Pos {
    const ch = grid.get(pos.x, pos.y).?;

    return switch (ch) {
        '|' => [_]Pos {
            .{.x = pos.x, .y = pos.y - 1},
            .{.x = pos.x, .y = pos.y + 1},
        },
        '-' => [_]Pos {
            .{.x = pos.x - 1, .y = pos.y},
            .{.x = pos.x + 1, .y = pos.y},
        },
        'L' => [_]Pos {
            .{.x = pos.x, .y = pos.y - 1},
            .{.x = pos.x + 1, .y = pos.y},
        },
        'J' => [_]Pos {
            .{.x = pos.x, .y = pos.y - 1},
            .{.x = pos.x - 1, .y = pos.y},
        },
        '7' => [_]Pos {
            .{.x = pos.x, .y = pos.y + 1},
            .{.x = pos.x - 1, .y = pos.y},
        },
        'F' => [_]Pos {
            .{.x = pos.x, .y = pos.y + 1},
            .{.x = pos.x + 1, .y = pos.y},
        },
        'S' => blk: {
            var neighbors: [2]Pos = undefined;
            var count: usize = 0;

            const west = if (pos.x > 0) grid.get(pos.x - 1, pos.y) else null;
            const east = grid.get(pos.x + 1, pos.y);
            const north = if (pos.y > 0) grid.get(pos.x, pos.y - 1) else null;
            const south = grid.get(pos.x, pos.y + 1);

            if (west) |westVal| {
                if (westVal == '-' or westVal == 'L' or westVal == 'F') {
                    neighbors[count] = Pos{ .x = pos.x - 1, .y = pos.y};
                    count += 1;
                }
            }

            if (east) |eastVal| {
                if (eastVal == '-' or eastVal == '7' or eastVal == 'J') {
                    neighbors[count] = Pos{ .x = pos.x + 1, .y = pos.y};
                    count += 1;
                }
            }

            if (north) |northVal| {
                if (northVal == '|' or northVal == '7' or northVal == 'F') {
                    neighbors[count] = Pos{ .x = pos.x, .y = pos.y - 1};
                    count += 1;
                }
            }

            if (south) |southVal| {
                if (southVal == '|' or southVal == 'J' or southVal == 'L') {
                    neighbors[count] = Pos{ .x = pos.x, .y = pos.y + 1};
                    count += 1;
                }
            }

            break :blk neighbors;
        },
        else => @panic("invalid position"),
    };
}

fn dijkstras(allocator: std.mem.Allocator, grid: *const Grid, start: Pos) !usize {
    var q = PosQueue.init(allocator);
    defer q.deinit();

    var visited = Visited.init(allocator);
    defer visited.deinit();

    try q.append(start);
    try visited.put(start, {});

    while (q.items.len > 0) {
        const pos = q.orderedRemove(0);
        try visited.put(pos, {});

        const neighbors = getAdjacent(pos, grid);
        for (neighbors) |neighbor| {
            if (!visited.contains(neighbor)) {
                try q.append(neighbor);
            }
        }
    }

    return visited.unmanaged.size;
}

pub fn part1(reader: Reader) !u64 {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var grid = try Grid.fromReader(arena, reader);
    defer grid.deinit();

    // for (grid.lines.items) |line| {
    //     std.log.debug("{s}", .{line});
    // }

    var iter = grid.searchIterator('S');
    const start = iter.next().?;

    // std.log.debug("start: {any}", .{start});

    return (try dijkstras(arena, &grid, Pos.fromEntry(start))) / 2;
}

pub fn part2(reader: Reader) !u64 {
    _ = reader;

    @panic("TODO");
}
