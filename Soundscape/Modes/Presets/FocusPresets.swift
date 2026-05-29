import Foundation

/// Factory Focus presets. Tuned to requirements.md §3.1: soft pulses, moderate
/// brightness, minimal harmonic movement, light rhythmic motion at sub-audible
/// to ~0.2 Hz.
public enum FocusPresets {
    public static let standardId = UUID(uuidString: "F0CC5001-0000-4000-8000-000000000001")!

    public static func standard() -> ModePreset {
        ModePreset(
            id: standardId,
            modeKind: .focus,
            name: "Focus",
            parameters: ParameterSnapshot(
                droneDetune: 0.35,
                droneGain: 0.5,
                noiseBalance: 0.25,
                masterGain: 0.7,
                padCutoff: 0.65,
                padResonance: 0.25,
                pulseRate: 0.4,
                pulseDepth: 0.55,
                filterCutoff: 0.75,
                noiseColour: 0.3
            ),
            isUserEditable: false,
            createdAt: factoryEpoch,
            updatedAt: factoryEpoch
        )
    }

    public static var all: [ModePreset] { [standard()] }
}

private let factoryEpoch = Date(timeIntervalSince1970: 1_748_563_200)
