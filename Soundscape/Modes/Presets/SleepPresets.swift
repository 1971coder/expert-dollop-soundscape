import Foundation

/// Factory Sleep presets. Tuned to requirements.md §3.2: dark tonal palette,
/// heavy low-mid emphasis, slow evolving drones, brown/pink noise dominant,
/// reduced treble (low-pass at ~3 kHz mapped to a filterCutoff well below the
/// Focus value).
public enum SleepPresets {
    public static let standardId = UUID(uuidString: "57EE9001-0000-4000-8000-000000000001")!

    public static func standard() -> ModePreset {
        ModePreset(
            id: standardId,
            modeKind: .sleep,
            name: "Sleep",
            parameters: ParameterSnapshot(
                droneDetune: 0.18,
                droneGain: 0.42,
                noiseBalance: 0.7,
                masterGain: 0.55,
                padCutoff: 0.3,
                padResonance: 0.2,
                pulseRate: 0.08,
                pulseDepth: 0.2,
                filterCutoff: 0.25,
                noiseColour: 0.75
            ),
            isUserEditable: false,
            createdAt: factoryEpoch,
            updatedAt: factoryEpoch
        )
    }

    public static var all: [ModePreset] { [standard()] }
}

private let factoryEpoch = Date(timeIntervalSince1970: 1_748_563_200)
