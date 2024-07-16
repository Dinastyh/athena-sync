# athena-sync

Collection of zig multithreaded/lockfree data structure and io tools

## How to use

1. Add `athena-sync` to your `build.zig.zon`.

```zig
{
    .name = "my_project",
    .version = "0.0.1",
    .paths = .{""},
    .dependencies = .{
        .@"athena-sync" = .{
            .url = "https://github.com/Dinastyh/athena-sync/archive/<some-commit-sha>.tar.gz",
            .hash = "12ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
            // leave the hash as is, the build system will tell you which hash to put here based on your commit
        },
    }
}
```

2. Use the `athena-sync` module

```zig
pub fn build(b: *std.Build) !void {
    // first create a build for the dependency
    const athenasync_dep = b.dependency("athena-sync", .{
        .target = target,
        .optimize = optimize,
    });

    // and lastly use the dependency as a module
    exe.root_module.addImport("athena-sync", athenasync_dep.module("athena-sync"));
}
```
