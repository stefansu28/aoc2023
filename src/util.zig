const std = @import("std");

// Most of this is stolen from std.fmt.Parser;
pub const Parser = struct {
    buf: []const u8,
    pos: usize = 0,

    // Returns a decimal number or null if the current character is not a
    // digit
    pub fn number(self: *@This()) ?usize {
        var r: ?usize = null;

        while (self.pos < self.buf.len) : (self.pos += 1) {
            switch (self.buf[self.pos]) {
                '0'...'9' => {
                    if (r == null) r = 0;
                    r.? *= 10;
                    r.? += self.buf[self.pos] - '0';
                },
                else => break,
            }
        }

        return r;
    }

    // Returns a substring of the input starting from the current position
    // and ending where `ch` is found or until the end if not found
    pub fn until(self: *@This(), ch: u8) []const u8 {
        const start = self.pos;

        if (start >= self.buf.len)
            return &[_]u8{};

        while (self.pos < self.buf.len) : (self.pos += 1) {
            if (self.buf[self.pos] == ch) break;
        }
        return self.buf[start..self.pos];
    }

    // Returns one character, if available
    pub fn char(self: *@This()) ?u8 {
        if (self.pos < self.buf.len) {
            const ch = self.buf[self.pos];
            self.pos += 1;
            return ch;
        }
        return null;
    }

    pub fn maybe(self: *@This(), val: u8) bool {
        if (self.pos < self.buf.len and self.buf[self.pos] == val) {
            self.pos += 1;
            return true;
        }
        return false;
    }

    // Returns the n-th next character or null if that's past the end
    pub fn peek(self: *@This(), n: usize) ?u8 {
        return if (self.pos + n < self.buf.len) self.buf[self.pos + n] else null;
    }

    // I added the following functions for convinience

    pub fn maybeSlice(self: *@This(), s: []const u8) bool {
        if (std.mem.startsWith(u8, self.buf[self.pos..], s)) {
            self.pos += s.len;
            return true;
        }
        return false;
    }

    pub fn untilSet(self: *@This(), set: []const u8) []const u8 {
        const start = self.pos;

        if (start >= self.buf.len)
            return &[_]u8{};

        outer: while (self.pos < self.buf.len) : (self.pos += 1) {
            for (set) |ch| {
                if (self.buf[self.pos] == ch) break :outer;
            }
        }
        return self.buf[start..self.pos];
    }
};

test "maybeSlice" {
    const text = \\var x = "some string"
    ;
    var parser = Parser { .buf = text };

    try std.testing.expect(parser.maybeSlice("var"));
    try std.testing.expect(parser.maybe(' '));
    try std.testing.expect(parser.maybeSlice("x = "));
    try std.testing.expect(parser.maybe('"'));
    try std.testing.expect(parser.maybeSlice("some "));
    try std.testing.expect(!parser.maybeSlice("thing"));
    try std.testing.expect(parser.maybeSlice("string\""));
    try std.testing.expect(parser.pos >= parser.buf.len);
    try std.testing.expect(!parser.maybeSlice("more"));
}

test "untilSet" {
    const text = "thing, another; more";
    var parser = Parser { .buf = text };

    try std.testing.expectEqualSlices(u8, "thing", parser.untilSet(",;"));
    try std.testing.expect(parser.maybeSlice(", "));
    try std.testing.expectEqualSlices(u8, "another", parser.untilSet(",;"));
    try std.testing.expect(parser.maybeSlice("; "));
    try std.testing.expectEqualSlices(u8, "more", parser.untilSet(",;"));
    try std.testing.expect(parser.pos >= parser.buf.len);
}