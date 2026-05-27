/// Single-producer / single-consumer ring buffer for parameter deltas.
///
/// **Threading contract.** Producer side (`tryPush`) is invoked by
/// `AudioEngineControl.ingest(_:)`; callers serialise externally (in WP01 only
/// the main actor pushes). Consumer side (`tryPop`) is the audio render thread —
/// never allocates, never locks.
///
/// **Ordering.** Indices are plain `UInt32` reads/writes on naturally-aligned
/// storage; on ARM64 (every supported iOS device) those are single-instruction
/// atomic. Memory ordering is relaxed — a delta arriving one render block late
/// (≤ ~6 ms at 256 frames / 44.1 kHz) is inaudible; ramp times absorb the
/// latency. When the project's deployment target moves to iOS 18+ this becomes
/// `Synchronization.Atomic<UInt32>` with explicit acquire/release.
nonisolated public final class ParameterRingBuffer: @unchecked Sendable {
    public let capacity: UInt32
    private let mask: UInt32
    private let buffer: UnsafeMutablePointer<ParameterDelta>
    private let head: UnsafeMutablePointer<UInt32>
    private let tail: UnsafeMutablePointer<UInt32>

    public init(capacity: UInt32 = 1024) {
        precondition(capacity >= 2 && (capacity & (capacity - 1)) == 0, "capacity must be a power of two")
        self.capacity = capacity
        self.mask = capacity - 1
        self.buffer = .allocate(capacity: Int(capacity))
        self.head = .allocate(capacity: 1)
        self.tail = .allocate(capacity: 1)
        let sentinel = ParameterDelta(target: .masterGain, value: 0, rampMilliseconds: 0)
        self.buffer.initialize(repeating: sentinel, count: Int(capacity))
        self.head.initialize(to: 0)
        self.tail.initialize(to: 0)
    }

    deinit {
        buffer.deinitialize(count: Int(capacity))
        buffer.deallocate()
        head.deallocate()
        tail.deallocate()
    }

    @discardableResult
    public func tryPush(_ value: ParameterDelta) -> Bool {
        let h = head.pointee
        let t = tail.pointee
        if h &- t >= capacity { return false }
        buffer.advanced(by: Int(h & mask)).pointee = value
        head.pointee = h &+ 1
        return true
    }

    public func tryPop() -> ParameterDelta? {
        let t = tail.pointee
        let h = head.pointee
        if t == h { return nil }
        let value = buffer.advanced(by: Int(t & mask)).pointee
        tail.pointee = t &+ 1
        return value
    }
}
