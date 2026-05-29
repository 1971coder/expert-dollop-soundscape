import Foundation
import XCTest

@testable import Soundscape

@MainActor
final class SessionStateManagerTests: XCTestCase {
    private func makeManager() async throws -> (SessionStateManager, FakeAudioEngine, SwiftDataSessionRepository) {
        let container = try InMemoryModelContainer.make()
        let repo = SwiftDataSessionRepository(container: container)
        let engine = FakeAudioEngine()
        let manager = SessionStateManager(engine: engine, sessionRepo: repo)
        return (manager, engine, repo)
    }

    func testInitialStateIsIdle() async throws {
        let (manager, _, _) = try await makeManager()
        XCTAssertEqual(manager.engineState, .idle)
        XCTAssertNil(manager.activeSession)
        XCTAssertNil(manager.pendingRating)
    }

    func testStartTransitionsToRunningAndIngestsPreset() async throws {
        let (manager, engine, _) = try await makeManager()
        await manager.start(mode: .focus)
        XCTAssertEqual(manager.engineState, .running)
        XCTAssertEqual(engine.startCalls.count, 1)
        XCTAssertEqual(engine.startCalls.first?.modeKind, .focus)
        XCTAssertNotNil(manager.activeSession)
        XCTAssertEqual(manager.activeSession?.modeKind, .focus)
    }

    func testStartFailureSurfacesAsFailedState() async throws {
        let (manager, engine, _) = try await makeManager()
        engine.setStartThrow(.engineStart("boom"))
        await manager.start(mode: .focus)
        guard case .failed = manager.engineState else {
            XCTFail("expected .failed, got \(manager.engineState)")
            return
        }
        XCTAssertNil(manager.activeSession)
    }

    func testStartFailureFinalizesOrphanSession() async throws {
        let (manager, engine, repo) = try await makeManager()
        engine.setStartThrow(.engineStart("boom"))
        await manager.start(mode: .focus)
        let listed = try await repo.list(limit: 10, offset: 0)
        XCTAssertEqual(listed.count, 1, "orphan session was deleted; expected finalized row")
        XCTAssertNotNil(listed.first?.endedAt, "orphan session not finalized")
    }

    func testStartPassesTargetDurationThrough() async throws {
        let (manager, _, _) = try await makeManager()
        await manager.start(mode: .focus, targetDuration: 25 * 60)
        XCTAssertEqual(manager.activeSession?.targetDurationSeconds, 25 * 60)
    }

    func testRouteChangeFailureClearsActiveSessionAndFinalizes() async throws {
        let (manager, engine, repo) = try await makeManager()
        await manager.start(mode: .sleep)
        XCTAssertNotNil(manager.activeSession)
        engine.simulateRouteChangeFailure()
        // Allow the AsyncStream observation Task + handleEngineFailure await chain to drain.
        for _ in 0..<20 where manager.activeSession != nil {
            try await Task.sleep(nanoseconds: 25_000_000)
        }
        XCTAssertNil(manager.activeSession, "activeSession was not cleared on route-change failure")
        guard case .failed = manager.engineState else {
            XCTFail("expected .failed after route-change failure, got \(manager.engineState)")
            return
        }
        let listed = try await repo.list(limit: 10, offset: 0)
        XCTAssertEqual(listed.first?.endedAt != nil, true, "session row not finalized after route-change failure")
    }

    func testEndCurrentSessionStopsEngineAndSetsPendingRating() async throws {
        let (manager, engine, repo) = try await makeManager()
        await manager.start(mode: .focus)
        await manager.endCurrentSession()
        XCTAssertEqual(manager.engineState, .idle)
        XCTAssertNil(manager.activeSession)
        XCTAssertNotNil(manager.pendingRating)
        XCTAssertEqual(engine.stopCalls, 1)
        let listed = try await repo.list(limit: 10, offset: 0)
        XCTAssertEqual(listed.first?.endedAt != nil, true)
    }

    func testSubmitRatingPersistsValue() async throws {
        let (manager, _, repo) = try await makeManager()
        await manager.start(mode: .focus)
        await manager.endCurrentSession()
        await manager.submitRating(5)
        XCTAssertNil(manager.pendingRating)
        let listed = try await repo.list(limit: 10, offset: 0)
        XCTAssertEqual(listed.first?.rating, 5)
    }

    func testSubmitRatingNilPreservesNilRating() async throws {
        let (manager, _, repo) = try await makeManager()
        await manager.start(mode: .focus)
        await manager.endCurrentSession()
        await manager.submitRating(nil)
        XCTAssertNil(manager.pendingRating)
        let listed = try await repo.list(limit: 10, offset: 0)
        XCTAssertNil(listed.first?.rating)
    }

    func testIngestIgnoredWhenIdle() async throws {
        let (manager, engine, _) = try await makeManager()
        manager.applyIntensity(0.5)
        XCTAssertEqual(engine.ingestCalls.count, 0)
    }

    func testIngestForwardedWhenRunning() async throws {
        let (manager, engine, _) = try await makeManager()
        await manager.start(mode: .focus)
        manager.applyIntensity(0.42)
        XCTAssertEqual(engine.ingestCalls.count, 1)
        XCTAssertEqual(engine.ingestCalls.first?.target, .masterGain)
        let firstValue = try XCTUnwrap(engine.ingestCalls.first?.value)
        XCTAssertEqual(firstValue, 0.42, accuracy: 1e-6)
    }

    func testRouteChangeFailureTransitionsToFailed() async throws {
        let (manager, engine, _) = try await makeManager()
        await manager.start(mode: .sleep)
        engine.simulateRouteChangeFailure()
        try await Task.sleep(nanoseconds: 50_000_000)
        guard case .failed = manager.engineState else {
            XCTFail("expected .failed, got \(manager.engineState)")
            return
        }
    }

    func testDismissFailureReturnsToIdle() async throws {
        let (manager, engine, _) = try await makeManager()
        engine.setStartThrow(.engineStart("boom"))
        await manager.start(mode: .focus)
        manager.dismissFailure()
        XCTAssertEqual(manager.engineState, .idle)
    }
}
