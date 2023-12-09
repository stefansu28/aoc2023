const std = @import("std");
const Reader = std.fs.File.Reader;

const Parser = @import("../utils.zig").Parser;

const RaceParams = struct {
    time: u64,
    distance: u64,
};

const QuadraticSolutions = [2]?f64;
fn solveQuadratic(a: f64, b: f64, c: f64) QuadraticSolutions {
    const discriminate = b*b - 4 * a * c;

    // effectively zero
    if (@abs(discriminate) < 0.00001) return [_]?f64 {-(b/2)/a, null};

    if (discriminate < 0) return [_]?f64 {null, null};
    
    const discriminate_sqrt = @sqrt(discriminate);

    return [_]?f64 {
        (-b - discriminate_sqrt)/2/a,
        (-b + discriminate_sqrt)/2/a,
    };
}

pub fn part1(reader: Reader) !u64 {
    var raceBuf: [8]RaceParams = undefined;
    var races: []RaceParams = raceBuf[0..0];

    var buf: [64]u8 = undefined;
    const timeLine = (try reader.readUntilDelimiterOrEof(&buf, '\n')).?;
    var parser = Parser {.buf = timeLine };
    if (!parser.maybeSlice("Time:")) return error.ExpectedTime;
    parser.eatSpaces();

    while (parser.number()) |num| {
        var race = &raceBuf[races.len];
        races.len += 1;
        race.time = @intCast(num);
        parser.eatSpaces();
    }

    const distanceLine = (try reader.readUntilDelimiterOrEof(&buf, '\n')).?;
    parser = Parser {.buf = distanceLine };
    if (!parser.maybeSlice("Distance:")) return error.ExpectedDistance;

    for (races) |*race| {
        parser.eatSpaces();
        race.distance = @intCast(parser.number().?);
    }

    var product: u64 = 1;
    for (races) |race| {
        const a: f64 = -1;
        const b: f64 = @floatFromInt(race.time);
        const c: f64 = -@as(f64, @floatFromInt(race.distance));
        const solutions = solveQuadratic(a, b, c);
        // std.log.debug("Solutions for T={}, D={}: {any}", .{race.time, race.distance, solutions});
        // can assume solutions[0] > solutions[1] because a < 0
        var range = if (@abs(@ceil(solutions[0].?) - solutions[0].?) > 0.0001) @ceil(solutions[0].?) else @ceil(solutions[0].?) - 1;
        range -= @ceil(solutions[1].?);
        product *= @intFromFloat(@abs(range));
    }

    return product;
}

fn parseNumber(parser: *Parser) usize {
    parser.eatSpaces();

    var r: ?usize = null;

    while (parser.pos < parser.buf.len) : (parser.pos += 1) {
        switch (parser.buf[parser.pos]) {
            '0'...'9' => {
                if (r == null) r = 0;
                r.? *= 10;
                r.? += parser.buf[parser.pos] - '0';
            },
            ' ' => continue,
            else => break,
        }
    }

    return r.?;
}

pub fn part2(reader: Reader) !u64 {

    var buf: [64]u8 = undefined;
    const timeLine = (try reader.readUntilDelimiterOrEof(&buf, '\n')).?;
    var parser = Parser {.buf = timeLine };
    if (!parser.maybeSlice("Time:")) return error.ExpectedTime;
    const time: u64 = @intCast(parseNumber(&parser));

    const distanceLine = (try reader.readUntilDelimiterOrEof(&buf, '\n')).?;
    parser = Parser {.buf = distanceLine };
    if (!parser.maybeSlice("Distance:")) return error.ExpectedDistance;
    const distance: u64 = @intCast(parseNumber(&parser));
    
    const a: f64 = -1;
    const b: f64 = @floatFromInt(time);
    const c: f64 = -@as(f64, @floatFromInt(distance));
    const solutions = solveQuadratic(a, b, c);
    // can assume solutions[0] > solutions[1] because a < 0
    var range = if (@abs(@ceil(solutions[0].?) - solutions[0].?) > 0.0001) @ceil(solutions[0].?) else @ceil(solutions[0].?) - 1;
    range -= @ceil(solutions[1].?);
    return @intFromFloat(@abs(range));
}
