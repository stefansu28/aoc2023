const Reader = @import("std").fs.File.Reader;

pub const solution_part: type = *const fn (Reader) anyerror!u64;

pub const SolutionDef = struct {
    part1: solution_part,
    part2: solution_part,
};
