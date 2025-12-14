const common = @import("common.zig");
const resource = @import("resource.zig");

pub const TracesData = struct {
    resource_spans: []const ResourceSpans,
};

pub const ResourceSpans = struct {
    resource: resource.Resource,
    scope_spans: []const ScopeSpans,
    schema_url: []const u8,
};

pub const ScopeSpans = struct {
    scope: common.InstrumentationScope,
    spans: []const Span,
    schema_url: []const u8,
};

pub const Span = struct {
    trace_id: [16]u8,
    span_id: [8]u8,
    parent_span_id: [8]u8,
    trace_state: []const u8,
    flags: u32,
    name: []const u8,
    kind: SpanKind,
    start_time_unix_nano: u64,
    end_time_unix_nano: u64,
    attributes: []const common.KeyValue,
    dropped_attributes_count: u32,
    events: []const Event,
    dropped_events_count: u32,
    links: []const Link,
    dropped_links_count: u32,
    status: Status,

    pub const SpanKind = enum(u8) {
        SPAN_KIND_UNSPECIFIED = 0,
        SPAN_KIND_INTERNAL = 1,
        SPAN_KIND_SERVER = 2,
        SPAN_KIND_CLIENT = 3,
        SPAN_KIND_PRODUCER = 4,
        SPAN_KIND_CONSUMER = 5,
    };

    pub const Event = struct {
        time_unix_nano: u64,
        name: []const u8,
        attributes: []const common.KeyValue,
        dropped_attributes_count: u32,
    };

    pub const Link = struct {
        trace_id: [16]u8,
        span_id: [8]u8,
        trace_state: []const u8,
        attributes: []const common.KeyValue,
        dropped_attributes_count: u32,
    };
};

pub const Status = struct {
    code: StatusCode,
    message: []const u8,

    pub const StatusCode = enum(u8) {
        STATUS_CODE_UNSET = 0,
        STATUS_CODE_OK = 1,
        STATUS_CODE_ERROR = 2,
    };
};

pub const SpanFlags = enum(u8) {
    SPAN_FLAGS_DO_NOT_USE = 0,

    // Bits 0-7 are used for trace flags.
    SPAN_FLAGS_TRACE_FLAGS_MASK = 0x000000FF,

    // Bits 8 and 9 are used to indicate that the parent span or link span is remote.
    // Bit 8 (`HAS_IS_REMOTE`) indicates whether the value is known.
    // Bit 9 (`IS_REMOTE`) indicates whether the span or link is remote.
    SPAN_FLAGS_CONTEXT_HAS_IS_REMOTE_MASK = 0x00000100,
    SPAN_FLAGS_CONTEXT_IS_REMOTE_MASK = 0x00000200,
};
