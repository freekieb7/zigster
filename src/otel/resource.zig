const common = @import("common.zig");

pub const Resource = struct {
    attributes: []const common.KeyValue,
    dropped_attributes_count: u32,
    entity_refs: []const common.EntityRef,
};
