/// Load-bearing shared identifier between Audio and Adaptive. Adding a value is
/// minor and additive; removing or renumbering is breaking and must update every
/// consumer in the same WP. WP01 ships the minimum set; later WPs extend.
public enum ParameterId: UInt32, Sendable, CaseIterable {
    case droneDetune = 0
    case droneGain = 1
    case noiseBalance = 2
    case masterGain = 3
}
