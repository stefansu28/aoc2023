const std = @import("std");
const Reader = std.fs.File.Reader;

const Parser = @import("../utils.zig").Parser;

fn extrapolateFwd(seq: []i64) i64 {
    var subseq = seq;
    while (true) {
        var noDiff = true;

        for (0..(subseq.len - 1)) |n| {
            const next = subseq[n + 1];
            noDiff = noDiff and subseq[n] == next;
            subseq[n] = next - subseq[n];
        }

        if (noDiff) break;
        subseq.len -= 1;
    }

    // std.log.debug("{any}", .{seq});

    var next: i64 = 0;
    for (seq) |n| {
        next += n;
    }

    // std.log.debug("{}", .{next});

    return next;
}

fn extrapolateBkwd(seq: []i64) i64 {
    var subseq = seq;
    while (true) {
        var noDiff = true;

        // std.log.debug("{any}", .{subseq});

        var n: usize = subseq.len - 1;
        while (n > 0) : (n -= 1) {
            const prev = subseq[n - 1];
            noDiff = noDiff and subseq[n] == prev;
            subseq[n] = subseq[n] - prev;
        }

        if (noDiff) break;
        subseq.len -= 1;
        subseq.ptr += 1;
    }

    subseq = seq[0..(seq.len - subseq.len + 2)];

    // std.log.debug("{any}", .{seq});
    // std.log.debug("{any}", .{subseq});

    var prev: i64 = 0;
    var n: usize = subseq.len;
    while (n > 0) : (n -= 1){
        prev = seq[n-1] - prev;
    }

    // std.log.debug("{}", .{prev});

    return prev;
}

fn runner(reader: Reader, comptime extrapolate: fn ([]i64) i64) !u64 {
    var buf: [256]u8 = undefined;
    var sum: i64 = 0;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var parser = Parser { .buf = line };
        var sequenceBuf: [32] i64 = undefined;
        var size: usize = 0;

        while (parser.pos < parser.buf.len) {
            parser.eatSpaces();

            sequenceBuf[size] = if (parser.maybe('-')) -1 else 1;
            sequenceBuf[size] *= @intCast(parser.number().?);
            size += 1;
        }

        const seq = sequenceBuf[0..size];

        sum += extrapolate(seq);
    }

    // std.log.debug("{}", .{sum});

    return @intCast(sum);
}

pub fn part1(reader: Reader) !u64 {
    return runner(reader, extrapolateFwd);
}

pub fn part2(reader: Reader) !u64 {
    return runner(reader, extrapolateBkwd);
}
