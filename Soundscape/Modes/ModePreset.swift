import Foundation

/// A named parameter snapshot for a mode (factory or user-created).
///
/// **Two roles, one type.** This struct is the in-memory contract between
/// `Modes/` and both (a) the audio engine — `AudioEngineControl.start(with:)`
/// seeds `EngineParameters` from `parameters` — and (b) the persistence layer,
/// which round-trips via `Persistence/Models/ModePreset+Model.swift`. The
/// value-type shape keeps it cheap to copy and trivially `Sendable`.
nonisolated public struct ModePreset: Sendable, Codable, Equatable, Identifiable {
    public let id: UUID
    public let modeKind: ModeKind
    public let name: String
    public var parameters: ParameterSnapshot
    public let isUserEditable: Bool
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID,
        modeKind: ModeKind,
        name: String,
        parameters: ParameterSnapshot,
        isUserEditable: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.modeKind = modeKind
        self.name = name
        self.parameters = parameters
        self.isUserEditable = isUserEditable
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// Concrete parameter values at full intensity.
///
/// Fields mirror `EngineParameters` exactly — the audio engine seeds itself
/// by copying field-for-field at `start(with:)`. Codable for SwiftData
/// persistence; `Sendable` for Adaptive ↔ audio handoff.
nonisolated public struct ParameterSnapshot: Sendable, Codable, Equatable {
    public var droneDetune: Float
    public var droneGain: Float
    public var noiseBalance: Float
    public var masterGain: Float
    public var padCutoff: Float
    public var padResonance: Float
    public var pulseRate: Float
    public var pulseDepth: Float
    public var filterCutoff: Float
    public var noiseColour: Float

    public init(
        droneDetune: Float,
        droneGain: Float,
        noiseBalance: Float,
        masterGain: Float,
        padCutoff: Float,
        padResonance: Float,
        pulseRate: Float,
        pulseDepth: Float,
        filterCutoff: Float,
        noiseColour: Float
    ) {
        self.droneDetune = droneDetune
        self.droneGain = droneGain
        self.noiseBalance = noiseBalance
        self.masterGain = masterGain
        self.padCutoff = padCutoff
        self.padResonance = padResonance
        self.pulseRate = pulseRate
        self.pulseDepth = pulseDepth
        self.filterCutoff = filterCutoff
        self.noiseColour = noiseColour
    }

    public static let neutral = ParameterSnapshot(
        droneDetune: 0.3,
        droneGain: 0.4,
        noiseBalance: 0.5,
        masterGain: 0.7,
        padCutoff: 0.5,
        padResonance: 0.3,
        pulseRate: 0.3,
        pulseDepth: 0.4,
        filterCutoff: 0.6,
        noiseColour: 0.5
    )
}
