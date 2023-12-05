const std = @import("std");
const Reader = std.fs.File.Reader;

const Parser = @import("../utils.zig").Parser;

fn parseNumber(parser: *Parser) ?u64 {
    while (parser.maybe(' ')) {}

    return parser.number();
}

pub fn part1(reader: Reader) !u64 {
    var sum: u64 = 0;
    var buf: [256]u8 = undefined;

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var parser = Parser { .buf = line };
        if (!parser.maybeSlice("Card")) return error.ExpectedCard;
        if (parseNumber(&parser) == null) return error.ExpectedNumber;
        if (!parser.maybeSlice(": ")) return error.ExpectedColon;

        var winningNumbers: [16]u64 = undefined;
        var count: usize = 0;
        while (parseNumber(&parser)) |num| {
            winningNumbers[count] = num;
            count += 1;
        }

        if (!parser.maybeSlice("| ")) return error.ExpectedBar;

        var matches: u64 = 0;
        while (parseNumber(&parser)) |num| {
            if (std.mem.indexOfScalar(u64, winningNumbers[0..count], num) != null) matches += 1;
        }

        if (matches > 0) {
            sum += @as(u64, 1) << @intCast(matches - 1);
        }
    }

    return sum;
}

const CardCopies = std.ArrayList(u64);
fn getCopies(cardCopies: *CardCopies, cardIndex: u64) !*u64 {
    if (cardIndex < cardCopies.items.len) {
        return &cardCopies.items[cardIndex];
    } else {
        while (cardIndex >= cardCopies.items.len) {
            try cardCopies.append(1);
        }
        return &cardCopies.items[cardIndex];
    }
}

pub fn part2(reader: Reader) !u64 {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var sum: u64 = 0;
    var buf: [256]u8 = undefined;

    
    var cardCopies = CardCopies.init(arena);

    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var parser = Parser { .buf = line };
        if (!parser.maybeSlice("Card")) return error.ExpectedCard;

        const cardIndex = parseNumber(&parser).? - 1;

        if (!parser.maybeSlice(": ")) return error.ExpectedColon;

        var winningNumbers: [16]u64 = undefined;
        var count: usize = 0;
        while (parseNumber(&parser)) |num| {
            winningNumbers[count] = num;
            count += 1;
        }

        if (!parser.maybeSlice("| ")) return error.ExpectedBar;

        var matches: u64 = 0;
        while (parseNumber(&parser)) |num| {
            if (std.mem.indexOfScalar(u64, winningNumbers[0..count], num) != null) matches += 1;
        }

        const copies = (try getCopies(&cardCopies, cardIndex)).*;
        while (matches > 0) : (matches -= 1) {
            const toUpdate = try getCopies(&cardCopies, cardIndex + matches);
            toUpdate.* += copies;
        }
    }

    for (cardCopies.items) |copies| {
        sum += copies;
    }

    return sum;
}
