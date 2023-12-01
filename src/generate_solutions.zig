const std = @import("std");

fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

pub fn main() !void {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try std.process.argsAlloc(arena);

    if (args.len != 2) fatal("wrong number of arguments", .{});

    const output_file_path = args[1];

    const cwd = std.fs.cwd();

    var output_file = cwd.createFile(output_file_path, .{}) catch |err| {
        fatal("unable to open '{s}': {s}", .{ output_file_path, @errorName(err) });
    };
    defer output_file.close();

    try output_file.writeAll(
        \\const SolutionDef = @import("solution_def.zig").SolutionDef;
        \\
        \\pub const solution_array = [_]SolutionDef {
        \\
    );

    var src_dir = try cwd.openDir("src", .{ .iterate = true });
    defer src_dir.close();

    var daylist = std.ArrayList([]u8).init(arena);

    var iterator = src_dir.iterate();
    while (try iterator.next()) |src_entry| {
        if (!std.mem.startsWith(u8, src_entry.name, "day") or src_entry.kind != .directory) continue;
        const solution_path = try std.fmt.allocPrint(arena, "{s}/solution.zig", .{src_entry.name});

        const exists = if (src_dir.access(solution_path, .{})) true else |_| false;
        _ = exists;
        (try daylist.addOne()).* = solution_path;
    }
    const day_slice = daylist.items;
    std.mem.sort([]u8, day_slice, {}, compareStrings);

    for (day_slice) |day_solution| {
        const src = try std.fmt.allocPrint(
            arena,
            \\    .{{.part1 = @import("{s}").part1, .part2 = @import("{s}").part2}},
            \\
            , .{day_solution, day_solution});

        try output_file.writeAll(src);
    }

    try output_file.writeAll(
        \\};
    );
    return std.process.cleanExit();
}

fn fatal(comptime format: []const u8, args: anytype) noreturn {
    std.debug.print(format, args);
    std.process.exit(1);
}
