import Foundation
import SwiftData

public enum PresetRepositoryError: Error, Sendable, Equatable {
    case notFound(UUID)
}

@MainActor
public protocol PresetRepository: Sendable {
    func list(for mode: ModeKind) async throws -> [ModePreset]
    func save(_ preset: ModePreset) async throws
    func delete(id: UUID) async throws
}

@MainActor
public final class SwiftDataPresetRepository: PresetRepository {
    private let container: ModelContainer
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(container: ModelContainer) {
        self.container = container
    }

    public func list(for mode: ModeKind) async throws -> [ModePreset] {
        let context = container.mainContext
        let raw = mode.rawValue
        let descriptor = FetchDescriptor<ModePresetRecord>(
            predicate: #Predicate { $0.modeKindRaw == raw },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        let records = try context.fetch(descriptor)
        return try records.map { try $0.toDomain(decoder: decoder) }
    }

    public func save(_ preset: ModePreset) async throws {
        let context = container.mainContext
        let id = preset.id
        var descriptor = FetchDescriptor<ModePresetRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            existing.modeKindRaw = preset.modeKind.rawValue
            existing.name = preset.name
            existing.parametersData = try encoder.encode(preset.parameters)
            existing.isUserEditable = preset.isUserEditable
            existing.updatedAt = preset.updatedAt
        } else {
            let record = try ModePresetRecord.from(preset, encoder: encoder)
            context.insert(record)
        }
        try context.save()
    }

    public func delete(id: UUID) async throws {
        let context = container.mainContext
        var descriptor = FetchDescriptor<ModePresetRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else {
            throw PresetRepositoryError.notFound(id)
        }
        context.delete(record)
        try context.save()
    }
}
