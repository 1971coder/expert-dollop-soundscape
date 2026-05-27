/// Shared parameter store between the audio thread (reader) and the parameter
/// drainer (writer, also on the audio thread but called once per block in
/// `DroneSynth`'s render callback).
///
/// Values are normalised 0…1. Stored as plain `Float` on a final class — on
/// ARM64 aligned 32-bit loads/stores are single-instruction atomic; the brief
/// inter-block staleness window for non-drainer nodes (≤ ~6 ms) is below the
/// perceptual threshold for the parameter ramps these values feed.
nonisolated public final class EngineParameters: @unchecked Sendable {
    public var droneDetune: Float = 0.3
    public var droneGain: Float = 0.4
    public var noiseBalance: Float = 0.5
    public var masterGain: Float = 0.7

    public init() {}

    public func apply(_ delta: ParameterDelta) {
        switch delta.target {
        case .droneDetune: droneDetune = delta.value
        case .droneGain: droneGain = delta.value
        case .noiseBalance: noiseBalance = delta.value
        case .masterGain: masterGain = delta.value
        }
    }
}
