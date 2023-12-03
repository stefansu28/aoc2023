const std = @import("std");
const solutions = @import("solutions.zig").solution_array;

// pub const SolutionDef = @import("solution_def.zig").SolutionDef;

fn runDay(day: u8) !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const example_path = try std.fmt.allocPrint(arena, "inputs/day{d}/example", .{ day });
    var example_file = try std.fs.cwd().openFile(example_path, .{});
    defer example_file.close();

    std.log.info("\nRunning day {d}\n", .{day});
    const part1_example_solution = try solutions[day - 1].part1(example_file.reader());

    std.log.info("example part1: {d}", .{part1_example_solution});

    const input_path = try std.fmt.allocPrint(arena, "inputs/day{d}/input", .{ day });
    var input_file = try std.fs.cwd().openFile(input_path, .{});
    defer input_file.close();

    const part1_solution = try solutions[day - 1].part1(input_file.reader());

    std.log.info("part1: {d}", .{part1_solution});

    try example_file.seekTo(0);
    const part2_example_solution = try solutions[day - 1].part2(example_file.reader());

    std.log.info("example part2: {d}", .{part2_example_solution});

    try input_file.seekTo(0);
    const part2_solution = try solutions[day - 1].part2(input_file.reader());

    std.log.info("part2: {d}", .{part2_solution});
}

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try std.process.argsAlloc(arena);

    if (args.len == 1) {
        for (0..solutions.len) |n| {
            try runDay(@intCast(n + 1));
        }
    } else if (args.len > 1) {
        const day = try std.fmt.parseUnsigned(u8, args[1], 10);
        if (day < 0 or day >= solutions.len + 1) @panic("Invalid day specified");
        try runDay(day);
    }
}
