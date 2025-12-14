const std = @import("std");

pub const Logger = struct {
    w: *std.Io.Writer,

    const Level = enum {
        info,
        err,
        warn,
        debug,

        pub fn asText(self: Level) []const u8 {
            return switch (self) {
                .info => "INFO",
                .err => "ERROR",
                .warn => "WARN",
                .debug => "DEBUG",
            };
        }
    };

    pub fn init(w: *std.Io.Writer) Logger {
        return Logger{
            .w = w,
        };
    }

    pub fn log(self: *Logger, lvl: Level, msg: []const u8) !void {
        try self.w.writeAll("[");
        try self.w.writeAll(lvl.asText());
        try self.w.writeAll("]: ");
        try self.w.writeAll(msg);
        try self.w.flush();
    }

    pub fn info(self: *Logger, msg: []const u8) !void {
        try self.log(Level.info, msg);
    }

    pub fn err(self: *Logger, msg: []const u8) !void {
        try self.log(Level.err, msg);
    }

    pub fn warn(self: *Logger, msg: []const u8) !void {
        try self.log(Level.warn, msg);
    }

    pub fn debug(self: *Logger, msg: []const u8) !void {
        try self.log(Level.debug, msg);
    }
};
