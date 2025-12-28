const std = @import("std");
const time = @import("time.zig");

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

    pub fn log(self: *Logger, lvl: Level, msg: []const u8, args: anytype) !void {
        const T = @TypeOf(args);
        const args_type_info = @typeInfo(T);
        if (args_type_info != .@"struct") {
            return error.InvalidArguments;
        }
        const args_struct_info = args_type_info.@"struct";

        // Timestamp
        const dt = try time.DateTime.now();
        try self.w.writeAll("timestamp=");
        try dt.writeFormatRFC3339(self.w);
        try self.w.writeAll(" ");

        // Level
        try self.w.writeAll("level=");
        try self.w.writeAll(lvl.asText());
        try self.w.writeAll(" ");

        // Message
        try self.w.writeAll(msg);
        try self.w.writeAll(" ");

        // Arguments
        var lhs: bool = true;
        inline for (args_struct_info.fields) |field| {
            const field_value = @field(args, field.name);
            if (lhs) {
                // Field name
                try self.w.writeAll(field_value);
                try self.w.writeAll("=");
                lhs = false;
            } else {
                // Field value
                try self.w.writeAll(field_value);
                lhs = true;
            }
        }

        if (!lhs) {
            // We ended on a field name without a value
            return error.InvalidArguments;
        }

        try self.w.writeAll("\n");
        try self.w.flush();
    }

    pub fn info(self: *Logger, msg: []const u8, args: anytype) !void {
        try self.log(Level.info, msg, args);
    }

    pub fn err(self: *Logger, msg: []const u8, args: anytype) !void {
        try self.log(Level.err, msg, args);
    }

    pub fn warn(self: *Logger, msg: []const u8, args: anytype) !void {
        try self.log(Level.warn, msg, args);
    }

    pub fn debug(self: *Logger, msg: []const u8, args: anytype) !void {
        try self.log(Level.debug, msg, args);
    }
};
