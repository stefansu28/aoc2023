const std = @import("std");

// Most of this is stolen from std.fmt.Parser;
// TODO: Composition over inheritence
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

    pub fn eatSpaces(self: *@This()) void {
        while (self.maybe(' ')) {}
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

/// Grid abstraction over strings
pub fn Grid(comptime MAX_ROW_LENGTH: comptime_int) type {

    const LinesList = std.ArrayList([]u8);
    const Allocator = std.mem.Allocator;
    return struct {
        allocator: Allocator,
        lines: LinesList,

        const SearchIterator = struct {
            lines: *LinesList,
            x: usize,
            y: usize,
            ch: u8,

            const Entry = struct {
                x: usize,
                y: usize,
            };

            // pub fn next(self: *@This()) ?Entry {
            //     if (self.y >= self.lines.items.len) return null;
            //     const line = self.lines.items[self.y];
            //     const entry = Entry {
            //         .x = self.x,
            //         .y = self.y,
            //     };
            //     self.x += 1;
            //     if (self.x >= line.len) {
            //         self.y += 1;
            //         self.x = 0;
            //     }

            //     return entry;
            // }
        };

        /// Return an optional character at the specified coordinates, if the coordinates are out of bound
        pub fn get(self: *@This(), x: usize, y: usize) ?u8 {
            if (y >= self.lines.items.len) return null;
            const line = self.lines.items[y];
            if (x >= line.len) return null;
            return line[x];
        }

        /// Iterator that will return the coordinates of each instance of the specified character until the end of the grid.
        /// Searches from left to right, top to bottom
        pub fn searchIterator(self: *@This(), ch: u8) SearchIterator {
            return .{
                .lines = &self.lines,
                .x = 0,
                .y = 0,
                .ch = ch,
            };
        }

        //pub fn fromReader(allocator: Allocator, reader: std.fs.File.Reader) !@This() {
        pub fn fromReader(allocator: Allocator, reader: anytype) !@This() {
            var grid = @This() {
                .allocator = allocator,
                .lines = LinesList.init(allocator),
            };

            while (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', MAX_ROW_LENGTH)) |line| {
                (try grid.lines.addOne()).* = line;
            }

            return grid;
        }

        pub fn deinit(self: *@This()) void {
            for (self.lines.items) |line| {
                self.allocator.free(line);
            }
            self.lines.deinit();
        }
    };
}

const SliceReaderContext = struct {
    slice: []const u8,
    pos: usize = 0,
};

fn sliceReadFn(context: *SliceReaderContext, buf: []u8) !usize {
    if (context.pos >= context.slice.len) return 0;
    var n: usize = 0;
    while (n < buf.len and context.pos + n < context.slice.len) : (n += 1) {
        buf[n] = context.slice[context.pos + n];
    }

    context.pos += n;
    return n;
}

pub const SliceReader = std.io.GenericReader(*SliceReaderContext, anyerror, sliceReadFn);

test "Grid.get" {
    const text =
        \\123
        \\456
        \\789
    ;
    var context = SliceReaderContext { .slice = text };
    const reader = SliceReader {
        .context = &context,
    };

    var grid = try Grid(5).fromReader(std.testing.allocator, reader);
    defer grid.deinit();

    try std.testing.expectEqual(@as(?u8, '6'), grid.get(2, 1));
    try std.testing.expectEqual(@as(?u8, null), grid.get(3, 1));
    try std.testing.expectEqual(@as(?u8, '5'), grid.get(1, 1));
    try std.testing.expectEqual(@as(?u8, null), grid.get(2, 10));
}
