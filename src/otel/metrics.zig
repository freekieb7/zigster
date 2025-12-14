const common = @import("common.zig");
const resource = @import("resource.zig");

pub const MetricsData = struct {
    resource_metrics: []const ResourceMetrics,
};

pub const ResourceMetrics = struct {
    resource: resource.Resource,
    scope_metrics: []const ScopeMetrics,
    schema_url: []const u8,
};

pub const ScopeMetrics = struct {
    scope: common.InstrumentationScope,
    metrics: []const Metric,
    schema_url: []const u8,
};

pub const Metric = struct {
    name: []const u8,
    description: []const u8,
    unit: []const u8,
    data: union(enum) {
        gauge: Gauge,
        sum: Sum,
        histogram: Histogram,
        summary: Summary,
    },
    metadata: []common.KeyValue,
};

pub const Gauge = struct {
    data_points: []const NumberDataPoint,
};

pub const Sum = struct {
    data_points: []const NumberDataPoint,
    aggregation_temporality: AggregationTemporality,
    is_monotonic: bool,
};

pub const Histogram = struct {
    data_points: []const HistogramDataPoint,
    aggregation_temporality: AggregationTemporality,
};

pub const Summary = struct {
    data_points: []const SummaryDataPoint,
};

pub const AggregationTemporality = enum(u8) {
    AGGREGATION_TEMPORALITY_UNSPECIFIED = 0,
    AGGREGATION_TEMPORALITY_DELTA = 1,
    AGGREGATION_TEMPORALITY_CUMULATIVE = 2,
};

pub const DataPointFlags = enum(u8) {
    DATA_POINT_FLAGS_NONE = 0,
    DATA_POINT_FLAGS_NO_RECORDED_VALUE = 1,
};

pub const NumberDataPoint = struct {
    attributes: []const common.KeyValue,
    exemplars: []const Exemplar,
    start_time_unix_nano: u64,
    time_unix_nano: u64,
    value: union(enum) {
        as_double: f64,
        as_int: i64,
    },
    flags: u32,
};

pub const HistogramDataPoint = struct {
    attributes: []const common.KeyValue,
    exemplars: []const Exemplar,
    bucket_counts: []const u64,
    explicit_bounds: []const f64,
    start_time_unix_nano: u64,
    time_unix_nano: u64,
    count: u64,
    flags: u32,
    sum: ?f64,
    min: ?f64,
    max: ?f64,
};

pub const ExponentialHistogramDataPoint = struct {
    attributes: []const common.KeyValue,
    exemplars: []const Exemplar,
    positive: Buckets,
    negative: Buckets,
    zero_count: u64,
    start_time_unix_nano: u64,
    time_unix_nano: u64,
    count: u64,
    sum: ?f64,
    min: ?f64,
    max: ?f64,
    scale: i32,
    flags: u32,

    pub const Buckets = struct {
        bucket_counts: []const u64,
        offset: i32,
    };
};

pub const SummaryDataPoint = struct {
    attributes: []const common.KeyValue,
    quantile_values: []const QuantileValue,
    start_time_unix_nano: u64,
    time_unix_nano: u64,
    count: u64,
    sum: f64,
    flags: u32,

    pub const QuantileValue = struct {
        quantile: f64,
        value: f64,
    };
};

pub const Exemplar = struct {
    filtered_attributes: []const common.KeyValue,
    time_unix_nano: u64,
    value: union(enum) {
        as_double: f64,
        as_int: i64,
    },
    trace_id: [16]u8,
    span_id: [8]u8,
};
