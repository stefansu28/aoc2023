const std = @import("std");
const Reader = std.fs.File.Reader;

const Parser = @import("../utils.zig").Parser;

const ID = [3]u8;
const Node = struct {
    left: ID,
    right: ID,
};
const NodeNetwork = std.AutoHashMap(ID, Node);

pub fn part1(reader: Reader) !u64 {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    _ = arena;

    var dirBuf: [512]u8 = undefined;
    const dirs = try reader.readUntilDelimiter(dirBuf, '\n');
    _ = dirs;
    var dirIndex: usize = 0;
    _ = dirIndex;

    var buf: [32]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        _ = line;
    
        
    }

    @panic("TODO");
}

pub fn part2(reader: Reader) !u64 {
    _ = reader;

    @panic("TODO");
}
