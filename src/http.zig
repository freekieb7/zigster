const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const IpAddress = std.Io.net.IpAddress;

pub const server = struct {
    pub fn listenAndServe(_: *server, io: Io, address: []const u8) !void {
        const addr = try IpAddress.parseLiteral(address);

        var listener = try addr.listen(io, .{ .reuse_address = true });
        defer listener.deinit(io);

        // var queue: Io.Queue(void) = .init(&.{});

        while (true) {
            const stream = try listener.accept(io);

            _ = io.async(serve, .{ io, stream });
        }
    }

    fn serve(io: Io, stream: std.Io.net.Stream) void {
        defer stream.close(io);

        var recv_buffer: [1024]u8 = undefined;
        var send_buffer: [1024]u8 = undefined;

        var connection_br = stream.reader(io, &recv_buffer);
        var connection_bw = stream.writer(io, &send_buffer);

        _ = connection_br.interface.buffered();
        // std.debug.print("Received request:\n{any}\n", .{recv_bytes});

        _ = connection_bw.interface.write("HTTP/1.1 200 OK\r\n" ++
            "connection: close\r\n" ++
            "content-length: 21\r\n" ++
            "content-type: text/plain\r\n" ++
            "\r\n" ++
            "message from server!\n") catch |err| {
            std.debug.print("Failed to write to connection: {}\n", .{err});
            return;
        };
        connection_bw.interface.flush() catch |err| {
            std.debug.print("Failed to flush connection: {}\n", .{err});
        };
    }
};
