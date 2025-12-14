pub const AnyValue = struct {
    value: union(enum) {
        string_value: []const u8,
        int_value: i64,
        double_value: f64,
        bool_value: bool,
        array_value: ArrayValue,
        kvlist_value: KeyValueList,
        bytes_value: []const u8,
    },
};

pub const ArrayValue = struct {
    values: []const AnyValue,
};

pub const KeyValueList = struct {
    values: []const KeyValue,
};

pub const KeyValue = struct {
    key: []const u8,
    value: AnyValue,
};

pub const InstrumentationScope = struct {
    name: []const u8,
    version: []const u8,
    attributes: []const KeyValue,
    dropped_attributes_count: u32,
};

pub const EntityRef = struct {
    schema_url: []const u8,
    type: []const u8,
    id_keys: [][]const u8,
    description_keys: [][]const u8,
};
