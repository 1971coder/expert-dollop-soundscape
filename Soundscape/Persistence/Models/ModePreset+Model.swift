import Foundation
import SwiftData

/// SwiftData record for a `ModePreset`. The value-type `ModePreset` is the
/// in-memory contract used by the audio engine and the UI; `ModePresetRecord`
/// is the on-disk shape. The repository (`PresetRepository`) converts between
/// the two so the persistence layer is the only place that knows about
/// SwiftData's reference semantics and the JSON encoding of `parameters`.
@Model
final class ModePresetRecord {
    @Attribute(.unique) var id: UUID
    var modeKindRaw: String
    var name: String
    var parametersData: Data
    var isUserEditable: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        modeKindRaw: String,
        name: String,
        parametersData: Data,
        isUserEditable: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.modeKindRaw = modeKindRaw
        self.name = name
        self.parametersData = parametersData
        self.isUserEditable = isUserEditable
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension ModePresetRecord {
    static func from(_ preset: ModePreset, encoder: JSONEncoder = JSONEncoder()) throws -> ModePresetRecord {
        let data = try encoder.encode(preset.parameters)
        return ModePresetRecord(
            id: preset.id,
            modeKindRaw: preset.modeKind.rawValue,
            name: preset.name,
            parametersData: data,
            isUserEditable: preset.isUserEditable,
            createdAt: preset.createdAt,
            updatedAt: preset.updatedAt
        )
    }

    func toDomain(decoder: JSONDecoder = JSONDecoder()) throws -> ModePreset {
        let parameters = try decoder.decode(ParameterSnapshot.self, from: parametersData)
        guard let kind = ModeKind(rawValue: modeKindRaw) else {
            throw PresetDecodingError.unknownModeKind(modeKindRaw)
        }
        return ModePreset(
            id: id,
            modeKind: kind,
            name: name,
            parameters: parameters,
            isUserEditable: isUserEditable,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

public enum PresetDecodingError: Error, Sendable, Equatable {
    case unknownModeKind(String)
}
