const std = @import("std");
pub const Request = @import("request.zig").Request;
pub const Server = @import("server.zig").Server;
// const Io = std.Io;
// const Allocator = std.mem.Allocator;
// const IpAddress = std.Io.net.IpAddress;

pub const protocol_http10: []const u8 = "HTTP/1.0";
pub const protocol_http11: []const u8 = "HTTP/1.1";
pub const header_content_length: []const u8 = "content-length";
pub const header_transfer_encoding: []const u8 = "transfer-encoding";
pub const header_connection: []const u8 = "connection";
pub const header_keep_alive: []const u8 = "keep-alive";
pub const header_content_type: []const u8 = "content-type";
pub const header_close: []const u8 = "close";
// Pre computed common responses
pub const http_200_ok: []const u8 = "HTTP/1.1 200 OK\r\n";
pub const connection_keep_alive: []const u8 = "connection: keep-alive\r\n";
pub const connection_close: []const u8 = "connection: close\r\n";
pub const content_type_text_plain: []const u8 = "content-type: text/plain\r\n";
pub const content_type_application_json: []const u8 = "content-type: application/json\r\n";
// Pre-computed complete responses for common cases
pub const response_200_empty: []const u8 = "HTTP/1.1 200 OK\r\nconnection: keep-alive\r\ncontent-length: 0\r\n\r\n";
pub const response_200_close: []const u8 = "HTTP/1.1 200 OK\r\nconnection: close\r\ncontent-length: 0\r\n\r\n";
pub const response_404_not_found: []const u8 = "HTTP/1.1 404 Not Found\r\nconnection: close\r\ncontent-length: 0\r\n\r\n";

pub const Header = struct {
    name: [64]u8,
    value: [256]u8,
    name_len: usize,
    value_len: usize,
};

pub const QueryParam = struct {
    name: [64]u8,
    value: [256]u8,
    name_len: usize,
    value_len: usize,
};
