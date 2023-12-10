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

    var dirBuf: [512]u8 = undefined;
    const dirs = try reader.readUntilDelimiter(&dirBuf, '\n');
    var dirIndex: usize = 0;

    // std.log.debug("{s}", .{dirs});

    var network = NodeNetwork.init(arena);

    var buf: [32]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;

        var parser = Parser { .buf = line };
        const idSlice = parser.until(' ');
        if (idSlice.len != 3) return error.ParseError;
        var id: ID = undefined;
        std.mem.copy(u8, &id, idSlice);
        if (!parser.maybeSlice(" = (")) return error.ParseError;

        const left = parser.until(',');
        _ = parser.char(); // consume ',';
        parser.eatSpaces();
        const right = parser.until(')');

        // std.log.debug("{s} = ({s} {s})", .{id, left, right});
        var node: Node = undefined;
        std.mem.copy(u8, &node.left, left);
        std.mem.copy(u8, &node.right, right);

        try network.put(id, node);
    }

    // var iter = network.iterator();
    // while (iter.next()) |entry| {
    //     const id = entry.key_ptr.*;
    //     const node = entry.value_ptr.*;
    //     std.log.debug("{s} = ({s} {s})", .{id, node.left, node.right});
    // }

    var currentNode: ID = undefined;
    std.mem.copy(u8, &currentNode, "AAA");
    while (!std.mem.eql(u8, &currentNode, "ZZZ")) {
        const node = network.get(currentNode).?;
        const dir = dirs[dirIndex % dirs.len];
        // std.log.debug("{s} = ({s} {s})", .{currentNode, node.left, node.right});
        // std.log.debug("dir: {s}, index: {}", .{if (dir == 'L') "left" else "right", dirIndex});
        if (dir == 'L') {
            currentNode = node.left;
        } else if (dir == 'R') {
            currentNode = node.right;
        } else {
            unreachable;
        }

        dirIndex += 1;
    }

    return @intCast(dirIndex);
}

pub fn part2(reader: Reader) !u64 {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var dirBuf: [512]u8 = undefined;
    const dirs = try reader.readUntilDelimiter(&dirBuf, '\n');
    // var dirIndex: usize = 0;

    // std.log.debug("{s}", .{dirs});

    var network = NodeNetwork.init(arena);

    var startNodesBuf: [8]ID = undefined;
    var currentNodes: []ID = &startNodesBuf;
    currentNodes.len = 0;

    var buf: [32]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) continue;

        var parser = Parser { .buf = line };
        const idSlice = parser.until(' ');
        if (idSlice.len != 3) return error.ParseError;
        var id: ID = undefined;
        std.mem.copy(u8, &id, idSlice);
        if (!parser.maybeSlice(" = (")) return error.ParseError;

        if (id[2] == 'A') {
            std.mem.copy(u8, &startNodesBuf[currentNodes.len], idSlice);
            currentNodes.len += 1;
        }

        const left = parser.until(',');
        _ = parser.char(); // consume ',';
        parser.eatSpaces();
        const right = parser.until(')');

        // std.log.debug("{s} = ({s} {s})", .{id, left, right});
        var node: Node = undefined;
        std.mem.copy(u8, &node.left, left);
        std.mem.copy(u8, &node.right, right);

        try network.put(id, node);
    }

    for (currentNodes) |current| {
        std.log.debug("{s}", .{current});
    }

    var steps: [8]usize = [_]usize {1} ** 8;
    for (currentNodes, 0..) |*currentNode, n| {
        var dirIndex: usize = 0;
        while (currentNode[2] != 'Z') {
            const node = network.get(currentNode.*).?;
            const dir = dirs[dirIndex % dirs.len];
            // std.log.debug("{s} = ({s} {s})", .{currentNode, node.left, node.right});
            // std.log.debug("dir: {s}, index: {}", .{if (dir == 'L') "left" else "right", dirIndex});
            if (dir == 'L') {
                currentNode.* = node.left;
            } else if (dir == 'R') {
                currentNode.* = node.right;
            } else {
                unreachable;
            }

            dirIndex += 1;
        }

        steps[n] = dirIndex;
    }

    // compute lcm...
    std.log.debug("{any}", .{steps});

    return 0;
}
