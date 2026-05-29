import Foundation
import SwiftData
import XCTest

@testable import Soundscape

@MainActor
final class SessionRepositoryTests: XCTestCase {
    func testCreatePersistsSession() async throws {
        let container = try InMemoryModelContainer.make()
        let repo = SwiftDataSessionRepository(container: container)
        let session = Session(modeKind: .focus, targetDurationSeconds: 1_500)
        try await repo.create(session)
        let listed = try await repo.list(limit: 10, offset: 0)
        XCTAssertEqual(listed.count, 1)
        XCTAssertEqual(listed.first?.modeKind, .focus)
    }

    func testFinalizeUpdatesEndedAtAndRating() async throws {
        let container = try InMemoryModelContainer.make()
        let repo = SwiftDataSessionRepository(container: container)
        let session = Session(modeKind: .sleep, startedAt: Date(timeIntervalSinceNow: -120))
        try await repo.create(session)
        let endedAt = Date()
        try await repo.finalize(id: session.id, endedAt: endedAt, rating: 5)
        let listed = try await repo.list(limit: 1, offset: 0)
        let saved = try XCTUnwrap(listed.first)
        XCTAssertEqual(saved.endedAt?.timeIntervalSince1970 ?? 0, endedAt.timeIntervalSince1970, accuracy: 1e-3)
        XCTAssertEqual(saved.rating, 5)
        XCTAssertGreaterThan(saved.actualDurationSeconds ?? 0, 0)
    }

    func testFinalizeUnknownIdThrows() async throws {
        let container = try InMemoryModelContainer.make()
        let repo = SwiftDataSessionRepository(container: container)
        do {
            try await repo.finalize(id: UUID(), endedAt: Date(), rating: 1)
            XCTFail("expected throw")
        } catch let error as SessionRepositoryError {
            guard case .notFound = error else {
                XCTFail("expected .notFound, got \(error)")
                return
            }
        }
    }

    func testListIsSortedNewestFirst() async throws {
        let container = try InMemoryModelContainer.make()
        let repo = SwiftDataSessionRepository(container: container)
        let older = Session(modeKind: .focus, startedAt: Date(timeIntervalSinceNow: -3600))
        let newer = Session(modeKind: .sleep, startedAt: Date())
        try await repo.create(older)
        try await repo.create(newer)
        let list = try await repo.list(limit: 10, offset: 0)
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list.first?.id, newer.id)
        XCTAssertEqual(list.last?.id, older.id)
    }

    func testFinalizeClampsNegativeDurationToZero() async throws {
        let container = try InMemoryModelContainer.make()
        let repo = SwiftDataSessionRepository(container: container)
        let started = Date()
        let session = Session(modeKind: .focus, startedAt: started)
        try await repo.create(session)
        let earlier = started.addingTimeInterval(-30)
        try await repo.finalize(id: session.id, endedAt: earlier, rating: nil)
        let listed = try await repo.list(limit: 1, offset: 0)
        XCTAssertEqual(listed.first?.actualDurationSeconds, 0, "negative duration was not clamped to zero")
    }

    func testPurgeAllRemovesEverything() async throws {
        let container = try InMemoryModelContainer.make()
        let repo = SwiftDataSessionRepository(container: container)
        try await repo.create(Session(modeKind: .focus))
        try await repo.create(Session(modeKind: .sleep))
        try await repo.purgeAll()
        let listed = try await repo.list(limit: 10, offset: 0)
        XCTAssertEqual(listed.count, 0)
    }
}
