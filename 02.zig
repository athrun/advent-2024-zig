const std = @import("std");
const print = std.debug.print;

fn isSafe(items: []u32) bool {
    var dir: i8 = 0;
    return for (0..items.len - 1) |i| {
        const a = items[i];
        const b = items[i + 1];
        if (a == b) break false;
        if ((a > b) and (dir <= 0) and (a - b <= 3)) {
            dir = -1;
            continue;
        } else if ((a < b) and (dir >= 0) and (b - a <= 3)) {
            dir = 1;
            continue;
        } else {
            break false;
        }
    } else true;
}

fn removeAt(list: std.ArrayList(u32), index: usize) std.ArrayList(u32) {
    var filtered = list.clone() catch unreachable;
    _ = filtered.orderedRemove(index);
    return filtered;
}

pub fn main() !void {
    const input = @embedFile("inputs/02.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var it1 = std.mem.tokenizeAny(u8, input, "\n");
    var lines = std.ArrayList(std.ArrayList(u32)).init(allocator);
    defer lines.deinit();

    while (it1.next()) |lineb| {
        var it2 = std.mem.tokenizeAny(u8, lineb, " ");
        var line = std.ArrayList(u32).init(allocator);
        while (it2.next()) |valb| {
            const n = try std.fmt.parseInt(u32, valb, 10);
            try line.append(n);
        }
        try lines.append(line);
    }

    var p1: u32 = 0;
    for (lines.items) |n| {
        const res = isSafe(n.items);
        if (res) p1 += 1;
    }
    print("Part1: {}\n", .{p1});

    var p2: u32 = 0;
    for (lines.items) |n| {
        const res = isSafe(n.items);
        if (res) p2 += 1 else {
            for (0..n.items.len) |i| {
                const filtered = removeAt(n, i);
                defer filtered.deinit();

                if (isSafe(filtered.items)) {
                    p2 += 1;
                    break;
                }
            }
        }
    }
    print("Part2: {d}\n", .{p2});
}
