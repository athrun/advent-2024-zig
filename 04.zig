const std = @import("std");
const print = std.debug.print;

const Point = struct { x: i32, y: i32 };

// Grid setup
const input = @embedFile("inputs/04.txt");
const input_xs = blk: {
    @setEvalBranchQuota(30_000); // so that compiler doesn't bail
    break :blk std.mem.count(u8, input, "\n") + 1;
};
const input_ys = std.mem.indexOf(u8, input, "\n").?;

fn posToPoint(pos: usize) Point {
    const x = @as(i32, @intCast(@mod(pos, input_xs)));
    const y = @as(i32, @intCast(@divFloor(pos, input_xs)));
    return .{ .x = x, .y = y };
}

fn lookup(comptime grid: []const u8, point: Point) ?u8 {
    if (point.x < 0 or point.y < 0)
        return null;
    const pos = @as(usize, @intCast(point.y * @as(i32, (@intCast(input_xs))) + point.x));
    if (pos >= grid.len)
        return null;
    return grid[pos];
}
fn matchWord(comptime grid: []const u8, pos: Point, word: []const Point, pattern: []const u8) bool {
    var matched = true;
    std.debug.assert(word.len <= pattern.len);

    for (word, 0..) |p, i| {
        const x = pos.x + p.x;
        const y = pos.y + p.y;
        const src = lookup(grid, .{ .x = x, .y = y }) orelse '.';
        if (src == pattern[i]) {
            continue;
        } else {
            matched = false;
            break;
        }
    }
    return matched;
}

pub fn main() !void {
    const p1Patterns = [_][4]Point{
        // horizontal
        [_]Point{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 0 }, .{ .x = 2, .y = 0 }, .{ .x = 3, .y = 0 } },
        // horizontal reverse
        [_]Point{ .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 0 }, .{ .x = -2, .y = 0 }, .{ .x = -3, .y = 0 } },
        // vertical
        [_]Point{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = 0, .y = 2 }, .{ .x = 0, .y = 3 } },
        // vertical reverse
        [_]Point{ .{ .x = 0, .y = 0 }, .{ .x = 0, .y = -1 }, .{ .x = 0, .y = -2 }, .{ .x = 0, .y = -3 } },
        // diagonal forward up
        [_]Point{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = -1 }, .{ .x = 2, .y = -2 }, .{ .x = 3, .y = -3 } },
        // diagonal forward down
        [_]Point{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 1 }, .{ .x = 2, .y = 2 }, .{ .x = 3, .y = 3 } },
        // diagonal reverse up
        [_]Point{ .{ .x = 0, .y = 0 }, .{ .x = -1, .y = -1 }, .{ .x = -2, .y = -2 }, .{ .x = -3, .y = -3 } },
        // diagonal reverse down
        [_]Point{ .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 1 }, .{ .x = -2, .y = 2 }, .{ .x = -3, .y = 3 } },
    };

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const p1Lookup = "XMAS";
    var total: i64 = 0;
    for (input, 0..) |u, pos| {
        if (u != p1Lookup[0]) continue;
        for (p1Patterns) |word| {
            if (matchWord(input, posToPoint(pos), &word, p1Lookup)) {
                total += 1;
            }
        }
    }

    const p1 = total;
    print("Part1: {}\n", .{p1});

    const p2Patterns = [_][3]Point{
        // diagonal up
        [_]Point{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = -1 }, .{ .x = 2, .y = -2 } },
        // diagonal up reverse
        [_]Point{ .{ .x = 0, .y = 0 }, .{ .x = -1, .y = 1 }, .{ .x = -2, .y = 2 } },
        // diagonal down
        [_]Point{ .{ .x = 0, .y = 0 }, .{ .x = 1, .y = 1 }, .{ .x = 2, .y = 2 } },
        // diagonal down reverse
        [_]Point{ .{ .x = 0, .y = 0 }, .{ .x = -1, .y = -1 }, .{ .x = -2, .y = -2 } },
    };

    const p2Lookup = "MAS";
    var map = std.AutoHashMap(Point, void).init(allocator);
    defer map.deinit();
    for (input, 0..) |u, pos| {
        if (u != p2Lookup[0]) continue;
        const point = posToPoint(pos);
        if (matchWord(input, point, &p2Patterns[0], p2Lookup)) {
            if (matchWord(
                input,
                .{ .x = point.x, .y = point.y - 2 },
                &p2Patterns[2],
                p2Lookup,
            ) or
                matchWord(
                input,
                .{ .x = point.x + 2, .y = point.y },
                &p2Patterns[3],
                p2Lookup,
            )) {
                try map.put(.{ .x = point.x + 1, .y = point.y - 1 }, {});
            }
        }
        if (matchWord(input, point, &p2Patterns[2], p2Lookup)) {
            if (matchWord(
                input,
                .{ .x = point.x, .y = point.y + 2 },
                &p2Patterns[0],
                p2Lookup,
            ) or
                matchWord(
                input,
                .{ .x = point.x + 2, .y = point.y },
                &p2Patterns[1],
                p2Lookup,
            )) {
                try map.put(.{ .x = point.x + 1, .y = point.y + 1 }, {});
            }
        }
        if (matchWord(input, point, &p2Patterns[3], p2Lookup)) {
            if (matchWord(
                input,
                .{ .x = point.x, .y = point.y - 2 },
                &p2Patterns[1],
                p2Lookup,
            ) or
                matchWord(
                input,
                .{ .x = point.x - 2, .y = point.y },
                &p2Patterns[0],
                p2Lookup,
            )) {
                try map.put(.{ .x = point.x - 1, .y = point.y - 1 }, {});
            }
        }
    }

    const p2 = map.count();
    print("Part2: {d}\n", .{p2});
}
