// this file needs to link in the regexp.h at comptime
// zig run:    zig run 03.zig -I.
// zig build:  add the following to build.zig:
//               step.addIncludePath(".");
//             where step is the test/exe step
const std = @import("std");
const print = std.debug.print;
const re = @cImport(@cInclude("03.h"));
const REGEX_T_SIZEOF = re.sizeof_regex_t;
const REGEX_T_ALIGNOF = re.alignof_regex_t;

pub fn findMatches(allocator: std.mem.Allocator, input: [:0]const u8, pattern: [:0]const u8) std.ArrayList([]const u8) {
    // regex interop setup
    const slice = allocator.alignedAlloc(u8, REGEX_T_ALIGNOF, REGEX_T_SIZEOF) catch unreachable;
    defer allocator.free(slice);
    const regex: [*]re.regex_t = @ptrCast(slice.ptr);

    // regex compile
    if (re.regcomp(regex, pattern, re.REG_EXTENDED | re.REG_ICASE) != 0) unreachable;
    defer re.regfree(regex); // because re doesn't use Zig's allocator

    var matches = std.ArrayList([]const u8).init(allocator);
    var match: [1]re.regmatch_t = undefined;
    var start: usize = 0;

    while (true) {
        // get all matches
        const status: i64 = re.regexec(regex, input[start..], 1, &match, 0);
        if (status == re.REG_NOMATCH) break else if (status != 0) {
            print("Regex match failed!\n", .{});
            break;
        }

        const match_start: usize = start + @as(usize, @intCast(match[0].rm_so));
        const match_end: usize = start + @as(usize, @intCast(match[0].rm_eo));
        matches.append(input[match_start..match_end]) catch unreachable;

        start += @as(usize, @intCast(match[0].rm_eo));

        // if regex matches empty string, keep moving along the input
        if (match[0].rm_so == match[0].rm_eo) start += 1;

        if (start >= input.len) break;
    }
    return matches;
}

fn toCSlice(allocator: std.mem.Allocator, source: []const u8) [:0]u8 {
    // convert []u8 slice into [:0]u8 sentinel slice (null terminated C string)
    return allocator.dupeZ(u8, source) catch unreachable;
}

fn execOps(allocator: std.mem.Allocator, items: [][]const u8) i64 {
    var result: i64 = 0;
    for (items) |op| {
        const ab = findMatches(
            allocator,
            toCSlice(allocator, op),
            "[0-9]+",
        );
        const a = std.fmt.parseInt(i64, ab.items[0], 10) catch unreachable;
        const b = std.fmt.parseInt(i64, ab.items[1], 10) catch unreachable;
        result += a * b;
    }
    return result;
}

pub fn main() !void {
    // const input = @embedFile("inputs/03.sample.2.txt");
    const input = @embedFile("inputs/03.txt");

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const pattern = "mul\\([0-9]+,[0-9]+\\)";
    const ops_p1 = findMatches(allocator, input, pattern);

    const p1: i64 = execOps(allocator, ops_p1.items);
    print("Part1: {}\n", .{p1});

    const do = "do()";
    const dont = "don't()";
    var start: usize = 0;
    var enabled = true;
    var ops_p2 = std.ArrayList([]const u8).init(allocator);
    while (start < input.len) {
        if (enabled) {
            if (std.mem.indexOfPos(u8, input, start, dont)) |next| {
                const o = findMatches(
                    allocator,
                    toCSlice(allocator, input[start..next]),
                    pattern,
                );
                ops_p2.appendSlice(o.items) catch unreachable;
                enabled = false;
                start = next + dont.len;
            } else {
                const o = findMatches(
                    allocator,
                    toCSlice(allocator, input[start..input.len]),
                    pattern,
                );
                ops_p2.appendSlice(o.items) catch unreachable;
                break;
            }
        } else {
            if (std.mem.indexOfPos(u8, input, start, do)) |next| {
                enabled = true;
                start = next + do.len;
            } else break;
        }
    }
    const p2: i64 = execOps(allocator, ops_p2.items);
    print("Part2: {d}\n", .{p2});
}
