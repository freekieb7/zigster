const std = @import("std");
const assert = std.debug.assert;
const zigster = @import("./root.zig");
const http = @import("./http.zig");
const telemetry = @import("./telemetry.zig");

pub fn main() !void {
    // var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    // defer assert(debug_allocator.deinit() == .ok);
    // const allocator = debug_allocator.allocator();

    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // var buffer: [1024]u8 = undefined;

    var stdout = std.fs.File.Writer.init(std.fs.File.stdout(), &buffer);

    var logger: telemetry.Logger = .init(&stdout.interface);
    try logger.info("Starting zigster server...\n");

    var threaded: std.Io.Threaded = .init(allocator);
    defer threaded.deinit();

    var server = http.server{};
    try server.listenAndServe(threaded.io(), "127.0.0.1:8080");
}

// test "simple test" {
//     const gpa = std.testing.allocator;
//     var list: std.ArrayList(i32) = .empty;
//     defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
//     try list.append(gpa, 42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }

// test "fuzz example" {
//     const Context = struct {
//         fn testOne(context: @This(), input: []const u8) anyerror!void {
//             _ = context;
//             // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
//             try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
//         }
//     };
//     try std.testing.fuzz(Context{}, Context.testOne, .{});
// }
