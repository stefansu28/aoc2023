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

const PositionSet = std.AutoHashMap(Pos, void);
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

fn dijkstras(allocator: std.mem.Allocator, grid: *const Grid, start: Pos) !PositionSet {
    var q = PosQueue.init(allocator);
    defer q.deinit();

    var visited = PositionSet.init(allocator);

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

    return visited;
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

    var visited = try dijkstras(arena, &grid, Pos.fromEntry(start));
    defer visited.deinit();

    return (visited.unmanaged.size) / 2;
}

fn getAdjacentEmpty(pos: Pos, grid: *const Grid) [4]?Pos {
    var adjacent = [_]?Pos {
        if (pos.x > 0) Pos {.x = pos.x - 1, .y = pos.y } else null,
        if (grid.get(pos.x + 1, pos.y) != null) Pos {.x = pos.x + 1, .y = pos.y } else null,
        if (pos.y > 0) Pos { .x = pos.x, .y = pos.y - 1 } else null,
        if (grid.get(pos.x, pos.y + 1) != null)  Pos {.x = pos.x, .y = pos.y + 1 } else null,
    };

    for (0..adjacent.len) |n| {
        const posOpt = adjacent[n];
        if (posOpt == null) continue;
        const adjPos = posOpt.?;

        if (grid.get(adjPos.x, adjPos.y).? != '.') {
            adjacent[n] = null;
            continue;
        }
    }

    return adjacent;
}

const FillSearchResults = struct {
    visited: PositionSet,
    inside: bool,
};

fn fillSearch(allocator: std.mem.Allocator, grid: *const Grid, outside: *PositionSet, start: Pos) !FillSearchResults {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var q = PosQueue.init(arena);
    defer q.deinit();

    var visited = PositionSet.init(allocator);
    var inside = true;

    try q.append(start);
    try visited.put(start, {});

    while (q.items.len > 0) {
        const pos = q.orderedRemove(0);
        try visited.put(pos, {});

        const neighbors = getAdjacentEmpty(pos, grid);
        for (neighbors) |neighborOpt| {
            if (neighborOpt) |neighbor| {
                if (outside.contains(neighbor)) inside = false;

                if (!visited.contains(neighbor)) {
                    try q.append(neighbor);
                }
            }
        }
    }

    return .{.visited = visited, .inside = inside};
}

pub fn part2(reader: Reader) !u64 {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var grid = try Grid.fromReader(arena, reader);
    defer grid.deinit();

    var iter = grid.searchIterator('S');
    const start = iter.next().?;

    var pipe = try dijkstras(arena, &grid, Pos.fromEntry(start));
    defer pipe.deinit();

    var outside = PositionSet.init(arena);
    defer outside.deinit();

    for ([_]usize {0, grid.lines.items.len - 1}) |y| {
        const row = grid.lines.items[y];
        for (0..row.len) |x| {
            if (grid.get(x, y).? == '.') try outside.put(.{.x = x, .y = y}, {});
        }
    }

    for (0..grid.lines.items.len) |y| {
        const row = grid.lines.items[y];
        for ([_]usize{0,row.len-1}) |x| {
            if (grid.get(x, y).? == '.') try outside.put(.{.x = x, .y = y}, {});
        }
    }

    for (0..grid.lines.items.len) |y| {
        const row = grid.lines.items[y];
        var buf: [256]u8 = undefined;
        for (0..row.len) |x| {
            if (false and outside.contains(.{.x = x, .y = y })) {
                buf[x] = 'O';
            } else {
                buf[x] = row[x];
            }
        }
        std.log.debug("{s}", .{buf[0..row.len]});
    }

    var inside: u64 = 0;

    for (1..grid.lines.items.len-1) |y| {
        const row = grid.lines.items[y];
        for (0..row.len) |x| {
            if (pipe.contains(.{.x = x, .y = y})) continue;
            if (outside.contains(.{.x = x, .y = y})) continue;

            var fillResults = try fillSearch(arena, &grid, &outside, .{ .x = x, .y = y });
            defer fillResults.visited.deinit();

            if (fillResults.inside) {
                inside += fillResults.visited.unmanaged.size;
            } else {
                var posIter = fillResults.visited.keyIterator();
                while (posIter.next()) |pos| {
                    try outside.put(pos.*, {});
                }
            }
        }
    }

    return inside;
}
