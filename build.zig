const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule(
        "athena-sync",
        .{
            .root_source_file = b.path("src/athena-sync.zig"),
        },
    );
}
