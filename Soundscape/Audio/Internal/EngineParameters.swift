/// Shared parameter store between the audio thread (reader) and the parameter
/// drainer (writer, also on the audio thread but called once per block in
/// `DroneSynth`'s render callback).
///
/// Values are normalised 0…1. Stored as plain `Float` on a final class — on
/// ARM64 aligned 32-bit loads/stores are single-instruction atomic; the brief
/// inter-block staleness window for non-drainer nodes (≤ ~6 ms) is below the
/// perceptual threshold for the parameter ramps these values feed.
nonisolated final class EngineParameters: @unchecked Sendable {
    var droneDetune: Float = 0.3
    var droneGain: Float = 0.4
    var noiseBalance: Float = 0.5
    var masterGain: Float = 0.7
    var padCutoff: Float = 0.5
    var padResonance: Float = 0.3
    var pulseRate: Float = 0.3
    var pulseDepth: Float = 0.4
    var filterCutoff: Float = 0.6
    var noiseColour: Float = 0.5

    init() {}

    func apply(_ delta: ParameterDelta) {
        switch delta.target {
        case .droneDetune: droneDetune = delta.value
        case .droneGain: droneGain = delta.value
        case .noiseBalance: noiseBalance = delta.value
        case .masterGain: masterGain = delta.value
        case .padCutoff: padCutoff = delta.value
        case .padResonance: padResonance = delta.value
        case .pulseRate: pulseRate = delta.value
        case .pulseDepth: pulseDepth = delta.value
        case .filterCutoff: filterCutoff = delta.value
        case .noiseColour: noiseColour = delta.value
        }
    }

    func applyAll(_ snapshot: ParameterSnapshot) {
        droneDetune = snapshot.droneDetune
        droneGain = snapshot.droneGain
        noiseBalance = snapshot.noiseBalance
        masterGain = snapshot.masterGain
        padCutoff = snapshot.padCutoff
        padResonance = snapshot.padResonance
        pulseRate = snapshot.pulseRate
        pulseDepth = snapshot.pulseDepth
        filterCutoff = snapshot.filterCutoff
        noiseColour = snapshot.noiseColour
    }
}
