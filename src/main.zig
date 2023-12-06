const std = @import("std");
const solutions = @import("solutions.zig").solution_array;

pub const solution_part = @import("solution_def.zig").solution_part;

fn runDay(day: u8) !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const solution = solutions[day - 1];

    const CombinationTuple = struct {solution_part, u2, []const u8 };
    const combinationTuple = [_]CombinationTuple {
        .{ solution.part1, 1, "example" },
        .{ solution.part1, 1, "input" },
        .{ solution.part2, 2, "example" },
        .{ solution.part2, 2, "input" },
    };

    std.log.info("\nRunning day {d}\n", .{day});
    for (combinationTuple) |tuple| {
        const input_path = try std.fmt.allocPrint(arena, "inputs/day{d}/{s}", .{ day, tuple[2] });
        var input_file = try std.fs.cwd().openFile(input_path, .{});
        defer input_file.close();

        const answer = try tuple[0](input_file.reader());

        std.log.info("part{d} {s}: {d}", .{tuple[1], tuple[2], answer});
    }
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
