const std = @import("std");

pub fn RingBuffer(comptime T: type, comptime multi_consumer: bool, comptime size: usize) type {
    return struct {
        const Self = @This();
        pub const Reader = std.io.Reader(*Self, error{}, readMultiple);
        pub const Writer = std.io.Writer(*Self, error{}, writeMultiple);

        allocator: std.mem.Allocator,
        msgs: []T,
        head: usize = 0,
        tail: usize = 0,
        capacity: usize = size,
        size: usize = 0,
        mutex: std.Thread.RwLock = .{},

        pub fn init(allocator: std.mem.Allocator) error{OutOfMemory}!Self {
            return Self{
                .allocator = allocator,
                .msgs = allocator.alloc(T, size) catch return error.OutOfMemory,
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.msgs);
        }

        pub fn count(self: *Self) usize {
            return self.size;
        }

        pub fn freePlace(self: *Self) usize {
            return self.capacity - self.count();
        }

        fn readMultiple(self: *Self, dest: []T) error{}!usize {
            if (multi_consumer) {
                self.mutex.lock();
                defer self.mutex.unlock();
            } else {
                self.mutex.lockShared();
                defer self.mutex.unlockShared();
            }

            if (self.head <= self.tail) {
                const i = if (self.count() < dest.len) self.count() else dest.len;
                @memcpy(dest[0..i], self.msgs[self.head .. self.head + i]);
                self.size -= i;
                self.head += i;
                return i;
            }

            if (self.capacity - self.head >= dest.len) {
                @memcpy(dest[0..dest.len], self.msgs[self.head .. self.head + dest.len]);
                self.size -= dest.len;
                self.head += dest.len;
                return dest.len;
            }

            const i = if (self.count() < dest.len) self.count() else dest.len;
            const first_part = self.capacity - self.head;
            @memcpy(dest[0..first_part], self.msgs[self.head..self.capacity]);
            const second_part = i - first_part;
            @memcpy(dest[first_part..i], self.msgs[0..second_part]);
            self.head = @mod(self.head + i, self.capacity);
            self.size -= i;
            return i;
        }

        fn writeMultiple(self: *Self, src: []T) error{}!usize {
            self.mutex.lock();
            defer self.mutex.unlock();
            const l_size = if (self.freePlace() >= src.len) src.len else self.freePlace();
            const first_part = if (self.tail >= self.head) @min(l_size, self.capacity - self.tail) else @min(l_size, self.head - self.tail);
            @memcpy(self.msgs[self.tail .. self.tail + first_part], src[0..first_part]);

            if (first_part < l_size) {
                const second_part = @min(size - first_part, self.head);
                @memcpy(self.msgs[0..second_part], src[first_part..second_part]);
            }
            self.tail = @mod(self.tail + l_size, self.capacity);
            self.size += l_size;
            return l_size;
        }

        pub fn read(self: *Self) ?T {
            if (multi_consumer) {
                self.mutex.lock();
                defer self.mutex.unlock();
            } else {
                self.mutex.lockShared();
                defer self.mutex.unlockShared();
            }
            if (self.count() == 0) return null;
            const data: T = self.msgs[self.head];
            self.head = @mod(self.head + 1, self.capacity);
            self.size -= 1;
            return data;
        }

        pub fn write(self: *Self, msg: T) bool {
            self.mutex.lock();
            defer self.mutex.unlock();
            if (self.capacity == self.count()) return false;
            self.msgs[self.tail] = msg;
            self.tail = @mod(self.tail + 1, self.capacity);
            self.size += 1;
            return true;
        }
    };
}
