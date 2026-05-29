import Foundation
import os

@testable import Soundscape

/// Test double matching the `AudioEngineControl` contract. Records every call
/// for assertions; mirrors the real `AudioEngine`'s nonisolated declaration so
/// it can satisfy `nonisolated` protocol requirements without isolation churn.
nonisolated final class FakeAudioEngine: AudioEngineControl, @unchecked Sendable {
    struct State {
        var startCalls: [ModePreset] = []
        var stopCalls = 0
        var ingestCalls: [ParameterDelta] = []
        var shouldStartThrow: AudioEngineError?
    }

    private let lock = OSAllocatedUnfairLock<State>(initialState: State())
    nonisolated let routeChangeFailures: AsyncStream<AudioEngineError>
    private let failureContinuation: AsyncStream<AudioEngineError>.Continuation

    var startCalls: [ModePreset] { lock.withLock { $0.startCalls } }
    var stopCalls: Int { lock.withLock { $0.stopCalls } }
    var ingestCalls: [ParameterDelta] { lock.withLock { $0.ingestCalls } }

    init() {
        var continuation: AsyncStream<AudioEngineError>.Continuation!
        self.routeChangeFailures = AsyncStream { continuation = $0 }
        self.failureContinuation = continuation
    }

    nonisolated var routeIsHeadphones: Bool { false }

    func setStartThrow(_ error: AudioEngineError?) {
        lock.withLock { $0.shouldStartThrow = error }
    }

    func simulateRouteChangeFailure(_ error: AudioEngineError = .routeChangeRecoveryFailed("test")) {
        failureContinuation.yield(error)
    }

    func start(with preset: ModePreset) async throws {
        let toThrow: AudioEngineError? = lock.withLock { state in
            state.startCalls.append(preset)
            return state.shouldStartThrow
        }
        if let toThrow { throw toThrow }
    }

    func stop() async {
        lock.withLock { $0.stopCalls += 1 }
    }

    func ingest(_ delta: ParameterDelta) {
        lock.withLock { $0.ingestCalls.append(delta) }
    }
}
