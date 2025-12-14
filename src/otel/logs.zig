const common = @import("common.zig");
const resource = @import("resource.zig");

pub const LogsData = struct {
    resource_logs: []const ResourceLogs,
};

pub const ResourceLogs = struct {
    resource: resource.Resource,
    scope_logs: []const ScopeLogs,
    schema_url: []const u8,
};

pub const ScopeLogs = struct {
    scope: common.InstrumentationScope,
    log_records: []const LogRecord,
    schema_url: []const u8,
};

pub const SeverityNumber = enum(u8) {
    SEVERITY_NUMBER_UNSPECIFIED = 0,
    SEVERITY_NUMBER_TRACE = 1,
    SEVERITY_NUMBER_TRACE2 = 2,
    SEVERITY_NUMBER_TRACE3 = 3,
    SEVERITY_NUMBER_TRACE4 = 4,
    SEVERITY_NUMBER_DEBUG = 5,
    SEVERITY_NUMBER_DEBUG2 = 6,
    SEVERITY_NUMBER_DEBUG3 = 7,
    SEVERITY_NUMBER_DEBUG4 = 8,
    SEVERITY_NUMBER_INFO = 9,
    SEVERITY_NUMBER_INFO2 = 10,
    SEVERITY_NUMBER_INFO3 = 11,
    SEVERITY_NUMBER_INFO4 = 12,
    SEVERITY_NUMBER_WARN = 13,
    SEVERITY_NUMBER_WARN2 = 14,
    SEVERITY_NUMBER_WARN3 = 15,
    SEVERITY_NUMBER_WARN4 = 16,
    SEVERITY_NUMBER_ERROR = 17,
    SEVERITY_NUMBER_ERROR2 = 18,
    SEVERITY_NUMBER_ERROR3 = 19,
    SEVERITY_NUMBER_ERROR4 = 20,
    SEVERITY_NUMBER_FATAL = 21,
    SEVERITY_NUMBER_FATAL2 = 22,
    SEVERITY_NUMBER_FATAL3 = 23,
    SEVERITY_NUMBER_FATAL4 = 24,
};

pub const LogRecordFlags = enum(u8) {
    LOG_RECORD_FLAGS_DO_NOT_USE = 0,
    LOG_RECORD_FLAGS_TRACE_FLAGS_MASK = 255,
};

pub const LogRecord = struct {
    time_unix_nano: u64,
    observed_time_unix_nano: u64,
    severity_number: SeverityNumber,
    severity_text: []const u8,
    body: common.AnyValue,
    attributes: []const common.KeyValue,
    dropped_attributes_count: u32,
    flags: u32,
    trace_id: [16]u8,
    span_id: [8]u8,
    event_name: []const u8,
};
