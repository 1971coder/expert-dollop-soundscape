/// A single parameter change crossing the Audio module boundary.
///
/// **Realtime contract.** Values are normalised `0...1`; the consumer (`EngineParameters`)
/// trusts that invariant on the render thread and does no per-sample bounds checks.
/// The init clamps `value` and replaces non-finite inputs with bounded substitutes so
/// a buggy upstream caller cannot push NaN/Inf into render-thread arithmetic and
/// produce silent (or popping) output samples. `coding-standards.md §4` authorises
/// this engine-internal clamp as defence-in-depth.
///
/// **Threading.** `Sendable` and `nonisolated` so it crosses the Adaptive ↔ audio-render
/// isolation boundary cleanly under Swift 6 strict concurrency. The struct itself is
/// pure data; the buffer that carries it (`ParameterRingBuffer`) owns the ordering
/// guarantees.
nonisolated public struct ParameterDelta: Sendable {
    public let target: ParameterId
    public let value: Float
    public let rampMilliseconds: UInt32

    public init(target: ParameterId, value: Float, rampMilliseconds: UInt32 = 80) {
        self.target = target
        self.value = Self.sanitise(value)
        self.rampMilliseconds = rampMilliseconds
    }

    @inline(__always)
    private static func sanitise(_ raw: Float) -> Float {
        if raw.isNaN { return 0 }
        if raw == .infinity { return 1 }
        if raw == -.infinity { return 0 }
        return min(max(raw, 0), 1)
    }
}
