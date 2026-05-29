/// Load-bearing shared identifier between Audio and Adaptive. Adding a value is
/// minor and additive; removing or renumbering is breaking and must update every
/// consumer in the same WP.
///
/// WP02 extends the set with the parameters introduced by `PadSynth`,
/// `PulseModulator`, `FilterController`, and the `noiseColour` axis. All values
/// are normalised `0...1` (see `ParameterDelta` and `EngineParameters`).
nonisolated public enum ParameterId: UInt32, Sendable, CaseIterable {
    case droneDetune = 0
    case droneGain = 1
    case noiseBalance = 2
    case masterGain = 3
    case padCutoff = 4
    case padResonance = 5
    case pulseRate = 6
    case pulseDepth = 7
    case filterCutoff = 8
    case noiseColour = 9
}
