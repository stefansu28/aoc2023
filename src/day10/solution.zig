const std = @import("std");
const Reader = std.fs.File.Reader;

const Grid = @import("../utils.zig").Grid(128);

pub fn part1(reader: Reader) !u64 {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const grid = Grid.fromReader(arena, reader);
    defer grid.deinit();

    @panic("TODO");
}

pub fn part2(reader: Reader) !u64 {
    _ = reader;

    @panic("TODO");
}
