import Foundation
import SwiftData
import XCTest

@testable import Soundscape

@MainActor
final class PresetRepositoryTests: XCTestCase {
    func testSaveAndListNewPreset() async throws {
        let container = try InMemoryModelContainer.make()
        let repo = SwiftDataPresetRepository(container: container)
        let preset = FocusPresets.standard()
        try await repo.save(preset)
        let listed = try await repo.list(for: .focus)
        XCTAssertEqual(listed.count, 1)
        XCTAssertEqual(listed.first, preset)
    }

    func testSavingSameIdUpdatesInPlace() async throws {
        let container = try InMemoryModelContainer.make()
        let repo = SwiftDataPresetRepository(container: container)
        let original = FocusPresets.standard()
        try await repo.save(original)
        var updated = original
        updated.parameters.masterGain = 0.95
        updated.updatedAt = Date()
        try await repo.save(updated)
        let listed = try await repo.list(for: .focus)
        XCTAssertEqual(listed.count, 1)
        XCTAssertEqual(listed.first?.parameters.masterGain, 0.95)
    }

    func testListIsFilteredByMode() async throws {
        let container = try InMemoryModelContainer.make()
        let repo = SwiftDataPresetRepository(container: container)
        try await repo.save(FocusPresets.standard())
        try await repo.save(SleepPresets.standard())
        let focusOnly = try await repo.list(for: .focus)
        XCTAssertEqual(focusOnly.count, 1)
        XCTAssertEqual(focusOnly.first?.modeKind, .focus)
        let sleepOnly = try await repo.list(for: .sleep)
        XCTAssertEqual(sleepOnly.count, 1)
        XCTAssertEqual(sleepOnly.first?.modeKind, .sleep)
    }

    func testDeleteRemovesByIdAndThrowsForUnknown() async throws {
        let container = try InMemoryModelContainer.make()
        let repo = SwiftDataPresetRepository(container: container)
        let preset = FocusPresets.standard()
        try await repo.save(preset)
        try await repo.delete(id: preset.id)
        let remaining = try await repo.list(for: .focus)
        XCTAssertEqual(remaining.count, 0)

        do {
            try await repo.delete(id: UUID())
            XCTFail("expected throw")
        } catch let error as PresetRepositoryError {
            guard case .notFound = error else {
                XCTFail("expected .notFound, got \(error)")
                return
            }
        }
    }
}
