const std = @import("std");
const Reader = std.fs.File.Reader;

const Parser = @import("../utils.zig").Parser;

const Card = enum(u4) {
    TWO,
    THREE,
    FOUR,
    FIVE,
    SIX,
    SEVEN,
    EIGHT,
    NINE,
    TEN,
    JACK,
    QUEEN,
    KING,
    ACE,

    fn fromChar(ch: u8) ?Card {
        return switch (ch) {
            '2'...'9' => @enumFromInt(ch - '2'),
            'T' => .TEN,
            'J' => .JACK,
            'Q' => .QUEEN,
            'K' => .KING,
            'A' => .ACE,
            else => null,
        };
    }

    fn value(self: @This(), jokers: bool) i8 {
        if (!jokers) {
            return @intFromEnum(self);
        } else {
            return if (self == .JACK) -1 else @intFromEnum(self);
        }
    }
};

const Hand = struct {
    cards: [5]Card,
    bid: u64,
    value: u4,

    fn parse(parser: *Parser, jokers: bool) !Hand {
        var cardCounts = [_]u8{0} ** (@intFromEnum(Card.ACE) + 1);
        var jokerCount: u8 = 0;
        var hand: Hand = undefined;
        for (&hand.cards) |*card| {
            card.* = Card.fromChar(parser.char().?).?;
            if (card.* == .JACK and jokers) {
                jokerCount += 1;
                continue;
            }
            cardCounts[@intFromEnum(card.*)] += 1;
        }

        parser.eatSpaces();

        hand.bid = parser.number().?;

        std.mem.sort(u8, &cardCounts, {}, std.sort.desc(u8));

        switch (cardCounts[0] + jokerCount) {
            1 => hand.value = 0,
            2 => hand.value = if (cardCounts[1] == 1) 1 else 2,
            3 => hand.value = if (cardCounts[1] == 1) 3 else 4,
            4 => hand.value = 5,
            5 => hand.value = 6,
            else => unreachable,
        }

        return hand;
    }

    fn parseNoJokers(parser: *Parser) !Hand {
        return try parse(parser, false);
    }

    fn parseJokers(parser: *Parser) !Hand {
        return try parse(parser, true);
    }

    fn lessThan(jokers: bool, lhs: @This(), rhs: @This()) bool {
        if (lhs.value != rhs.value) return lhs.value < rhs.value;

        for (0..5) |n| {
            const left = Card.value(lhs.cards[n], jokers);
            const right = Card.value(rhs.cards[n], jokers);

            if (left != right) return left < right;
        }

        return false;
    }
};

const HandList = std.ArrayList(Hand);

fn parseInput(reader: Reader, hands: *HandList, comptime parseHand: fn (*Parser) anyerror!Hand) !void {
    var buf: [16]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var parser = Parser { .buf = line };
        const newHand = try parseHand(&parser);
        try hands.append(newHand);
    }
}

pub fn part1(reader: Reader) !u64 {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var hands = HandList.init(arena);
    defer hands.deinit();

    try parseInput(reader, &hands, Hand.parseNoJokers);

    std.mem.sort(Hand, hands.items, false, Hand.lessThan);

    var sum: u64 = 0;
    for (0..hands.items.len) |n| {
        // std.log.debug("hand: {any}", .{hand});
        sum += @as(u64, n + 1) * hands.items[n].bid;
    }

    return sum;
}

pub fn part2(reader: Reader) !u64 {
    var arena_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var hands = HandList.init(arena);
    defer hands.deinit();

    try parseInput(reader, &hands, Hand.parseJokers);

    std.mem.sort(Hand, hands.items, true, Hand.lessThan);

    var sum: u64 = 0;
    for (0..hands.items.len) |n| {
        // std.log.debug("hand: {any}", .{hand});
        sum += @as(u64, n + 1) * hands.items[n].bid;
    }

    return sum;
}
