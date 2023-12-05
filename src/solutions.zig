const SolutionDef = @import("solution_def.zig").SolutionDef;

pub const solution_array = [_]SolutionDef {
    .{.part1 = @import("day1/solution.zig").part1, .part2 = @import("day1/solution.zig").part2},
    .{.part1 = @import("day2/solution.zig").part1, .part2 = @import("day2/solution.zig").part2},
    .{.part1 = @import("day3/solution.zig").part1, .part2 = @import("day3/solution.zig").part2},
    .{.part1 = @import("day4/solution.zig").part1, .part2 = @import("day4/solution.zig").part2},
    .{.part1 = @import("day5/solution.zig").part1, .part2 = @import("day5/solution.zig").part2},
};