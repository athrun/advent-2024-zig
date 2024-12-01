const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    const input = @embedFile("01.input.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var it = std.mem.tokenizeAny(u8, input, " \n");
    var al1 = std.ArrayList(u32).init(allocator);
    var al2 = std.ArrayList(u32).init(allocator);
    defer al1.deinit();
    defer al2.deinit();

    var iter: u32 = 0;
    while (it.next()) |token| {
        const n = try std.fmt.parseInt(u32, token, 10);
        if (iter % 2 == 0) {
            try al1.append(n);
        } else {
            try al2.append(n);
        }
        iter += 1;
    }

    std.mem.sort(u32, al1.items, {}, std.sort.asc(u32));
    std.mem.sort(u32, al2.items, {}, std.sort.asc(u32));

    var dist: u32 = 0;
    for (al1.items, al2.items) |i, j| {
        dist += if (i > j) i - j else j - i;
    }
    print("Part1: {}\n", .{dist});

    var score: u32 = 0;
    for (al1.items) |i| {
        var match: u32 = 0;
        for (al2.items) |j| {
            if (i == j) match += 1;
        }
        score += i * match;
    }
    print("Part2: {}\n", .{score});
}
