const std = @import("std");
// const Io = std.Io;
// const Allocator = std.mem.Allocator;
// const IpAddress = std.Io.net.IpAddress;

pub const server = struct {
    pub fn listenAndServe(_: *server, io: std.Io, address: []const u8) !void {
        const addr = try std.Io.net.IpAddress.parseLiteral(address);

        var listener = try addr.listen(io, .{ .reuse_address = true });
        defer listener.deinit(io);

        var stream_buf: [1024]std.Io.net.Stream = undefined;
        var queue: std.Io.Queue(std.Io.net.Stream) = .init(&stream_buf);

        var producer_task = try io.concurrent(listen, .{
            io, &queue, &listener,
        });
        defer producer_task.cancel(io) catch {};

        var consumer_task = try io.concurrent(serve, .{
            io, &queue,
        });
        defer consumer_task.cancel(io) catch {};

        try consumer_task.await(io);

        // // inline for (0..16) |i| {
        // //     var val = io.async(work, .{ i, io, &queue });
        // //     defer val.cancel(io) catch {};
        // // }

        // // const selector: std.Io.Select(std.Io.net.Stream) = .init(io, &stream_buf);

        // while (true) {
        //     const stream = try listener.accept(io);
        //     try selector.queue.put(stream);
        // }
    }

    fn listen(io: std.Io, queue: *std.Io.Queue(std.Io.net.Stream), listener: *std.Io.net.Server) !void {
        while (true) {
            const stream = try listener.accept(io);
            try queue.putOne(io, stream);
        }
    }

    fn serve(io: std.Io, queue: *std.Io.Queue(std.Io.net.Stream)) !void {
        var recv_buffer: [1024]u8 = undefined;
        var send_buffer: [1024]u8 = undefined;

        // while (selector.async(comptime field: (unknown type), function: anytype, args: (unknown type)))

        while (true) {
            // std.debug.print("Worker {} waiting for connection...\n", .{i});

            const stream = queue.getOne(io) catch |err| {
                std.debug.print("Failed to get connection from queue: {}\n", .{err});
                continue;
            };
            defer stream.close(io);

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
                continue;
            };
            connection_bw.interface.flush() catch |err| {
                std.debug.print("Failed to flush connection: {}\n", .{err});
            };
        }
    }
};
