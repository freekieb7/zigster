const std = @import("std");
const http = @import("http.zig");

pub const Server = struct {
    router: *Router,

    pub fn init(allocator: std.mem.Allocator) !Server {
        const router = allocator.create(Router) catch return error.OutOfMemory;
        router.* = Router.init(allocator);
        return Server{
            .router = router,
        };
    }

    pub fn deinit(self: *Server, allocator: std.mem.Allocator) void {
        self.router.deinit();
        allocator.destroy(self.router);
    }

    pub fn listenAndServe(self: *Server, io: std.Io, address: []const u8) !void {
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
            io, &queue, self.router,
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

    fn serve(io: std.Io, queue: *std.Io.Queue(std.Io.net.Stream), _: *Router) !void {
        var recv_buffer: [1024]u8 = undefined;
        var send_buffer: [1024]u8 = undefined;

        // var request: http.Request = undefined;

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

    fn serve2(io: std.Io, queue: *std.Io.Queue(std.Io.net.Stream), _: *Router) !void {
        var recv_buffer: [1024]u8 = undefined;
        var send_buffer: [1024]u8 = undefined;

        var request: http.Request = undefined;

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

            try request.parse(&connection_br.interface);

            // _ = connection_br.interface.buffered();
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

pub const Router = struct {
    routes: std.StringHashMap(std.StringHashMap(Handler)),

    pub fn init(allocator: std.mem.Allocator) Router {
        return .{
            .routes = std.StringHashMap(std.StringHashMap(Handler)).init(allocator),
        };
    }

    pub fn deinit(self: *Router) void {
        self.routes.deinit();
    }

    pub fn addRoute(self: *Router, path: []const u8, handler: Handler) !void {
        try self.routes.put(path, handler);
    }
};

pub const Handler = fn (req: *std.Io.net.Stream.Reader, res: *std.Io.net.Stream.Writer) void;
