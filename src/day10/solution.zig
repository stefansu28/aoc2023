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

fn getAdjacent(pos: Pos, grid: *Grid) ![2]Pos {
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

            var hasWest = false;
            var hasEast = false;
            var hasNorth = false;
            var hasSouth = false;

            if (west) |westVal| {
                if (westVal == '-' or westVal == 'L' or westVal == 'F') {
                    neighbors[count] = Pos{ .x = pos.x - 1, .y = pos.y};
                    count += 1;
                    hasWest = true;
                }
            }

            if (east) |eastVal| {
                if (eastVal == '-' or eastVal == '7' or eastVal == 'J') {
                    neighbors[count] = Pos{ .x = pos.x + 1, .y = pos.y};
                    count += 1;
                    hasEast = true;
                }
            }

            if (north) |northVal| {
                if (northVal == '|' or northVal == '7' or northVal == 'F') {
                    neighbors[count] = Pos{ .x = pos.x, .y = pos.y - 1};
                    count += 1;
                    hasNorth = true;
                }
            }

            if (south) |southVal| {
                if (southVal == '|' or southVal == 'J' or southVal == 'L') {
                    neighbors[count] = Pos{ .x = pos.x, .y = pos.y + 1};
                    count += 1;
                    hasSouth = true;
                }
            }

            if (hasNorth and hasSouth) try grid.set(pos.x, pos.y, '|');
            if (hasWest and hasEast) try grid.set(pos.x, pos.y, '-');
            if (hasWest and hasNorth) try grid.set(pos.x, pos.y, 'J');
            if (hasWest and hasSouth) try grid.set(pos.x, pos.y, '7');
            if (hasEast and hasNorth) try grid.set(pos.x, pos.y, 'L');
            if (hasEast and hasSouth) try grid.set(pos.x, pos.y, 'F');

            break :blk neighbors;
        },
        else => @panic("invalid position"),
    };
}

fn dijkstras(allocator: std.mem.Allocator, grid: *Grid, start: Pos) !PositionSet {
    var q = PosQueue.init(allocator);
    defer q.deinit();

    var visited = PositionSet.init(allocator);

    try q.append(start);
    try visited.put(start, {});

    while (q.items.len > 0) {
        const pos = q.orderedRemove(0);
        try visited.put(pos, {});

        const neighbors = try getAdjacent(pos, grid);
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

const CrossedResults = struct {
    crossed: bool,
    deltaX: usize,
};

fn crossedPipe(startingPos: Pos, row: []u8) CrossedResults {
    var pos = startingPos;

    if (row[pos.x] == '|') return .{.crossed = true, .deltaX = 0};

    const closing: u8 = switch (row[pos.x]) {
        'F' => 'J',
        'L' => '7',
        else => {
            std.log.debug("{any}: {}", .{pos, row[pos.x]});
            unreachable;
        },
    };

    pos.x += 1;

    while (row[pos.x] == '-') : (pos.x += 1) {}

    return .{
        .crossed = row[pos.x] == closing,
        .deltaX = pos.x - startingPos.x,
    };
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

    var insideCount: u64 = 0;

    for (0..grid.lines.items.len) |y| {
        const row = grid.lines.items[y];
        var x: usize = 0;
        var insideInc: u64 = 0;

        while (x < row.len) : (x += 1) {
            const pos = Pos { .x = x, .y = y };

            if (!pipe.contains(pos)) {
                insideCount += insideInc;
                if (insideInc == 1) {
                    row[x] = 'I';
                }
            } else {
                const results = crossedPipe(pos, row);
                // for (x..x + results.deltaX + 1) |_x| {
                //     row[_x] = 'P';
                // }
                x += results.deltaX;
                if (results.crossed) {
                    // row[x] = 'C';
                    insideInc = (insideInc + 1) % 2;
                }
            }
        }

        // std.log.debug("{s}", .{row});
    }

    return insideCount;
}
