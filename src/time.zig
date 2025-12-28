const std = @import("std");

pub const DateTime = struct {
    unix_sec: u64,
    nsec: u32,

    pub fn now() !DateTime {
        const timespec = try std.posix.clock_gettime(std.posix.CLOCK.REALTIME);

        // timespec.sec contains the Unix timestamp in seconds (i64)
        // timespec.nsec contains additional nanoseconds (isize)

        const unix_seconds: u64 = @intCast(timespec.sec);
        const unix_nanos: u32 = @intCast(timespec.nsec);

        return DateTime{
            .unix_sec = unix_seconds,
            .nsec = unix_nanos,
        };
    }

    pub fn writeFormatRFC3339(self: DateTime, w: *std.Io.Writer) !void {
        const epoch_seconds = std.time.epoch.EpochSeconds{ .secs = @intCast(@max(0, self.unix_sec)) };
        const day_seconds = epoch_seconds.getDaySeconds();
        const year_day = epoch_seconds.getEpochDay().calculateYearDay();
        const month_day = year_day.calculateMonthDay();

        try w.print("{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}.{d:0>9}Z", .{
            year_day.year,
            month_day.month.numeric(),
            month_day.day_index + 1,
            day_seconds.getHoursIntoDay(),
            day_seconds.getMinutesIntoHour(),
            day_seconds.getSecondsIntoMinute(),
            self.nsec,
        });
    }
};

pub fn now() DateTime {
    return DateTime.now();
}
