// Dynamic - Static
// Mutex - Lockfree
// SingleProducer - MultiProducer
// SingleConsumer - SingleConsumer

const MutexStaticRingeBuffer = @import("Queue/Mutex/Static/RingBuffer.zig").RingBuffer;

pub const AllocationStrategy = enum {
    Dynamic,
    Static,
};

pub const MtStrategy = enum {
    Mutex,
    Lockfree,
};

pub const Producer = enum {
    Single,
    Multi,
};

pub const Consumer = enum {
    Single,
    Multi,
};

pub const QueueConfig = struct {
    allocation: AllocationStrategy,
    mt: MtStrategy,
    producer: Producer,
    consumer: Consumer,
};

pub fn Queue(comptime T: type, comptime config: QueueConfig, comptime size: ?usize) type {
    if (config.allocation == .Static) {
        if (size == null) @compileError("Size can't be null with static as allocation strategy\n");
        if (config.mt == .Mutex) {
            if (config.producer == .Multi and config.consumer == .Single) return MutexStaticRingeBuffer(T, false, size.?);
            if (config.producer == .Multi and config.consumer == .Multi) return MutexStaticRingeBuffer(T, true, size.?);
        }
    }
}
