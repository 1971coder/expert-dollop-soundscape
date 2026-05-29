import Foundation
import Observation
import os

/// Reactive state for the currently-active session and the engine's health.
///
/// `EngineState` exists per the WP01 architecture-review finding (inherited
/// item #4): when route-change recovery fails, the UI must learn about it
/// rather than showing a phantom-playing button. `SessionStateManager` is
/// the single place that converts a raw `AudioEngineError` into a
/// user-actionable state transition.
public enum EngineState: Sendable, Equatable {
    case idle
    case starting
    case running
    case stopping
    case failed(reason: String)
}

/// Main-actor coordinator between UI intent, the audio engine, and the
/// session persistence layer. Owns the lifecycle of the active `Session`
/// and the post-session rating handoff.
@MainActor
@Observable
public final class SessionStateManager {
    public private(set) var engineState: EngineState = .idle
    public private(set) var activeSession: Session?
    public private(set) var pendingRating: Session?

    private let engine: AudioEngineControl
    private let sessionRepo: any SessionRepository
    private let logger = Logger(subsystem: "app.auralflow", category: "session.state")

    public init(engine: AudioEngineControl, sessionRepo: any SessionRepository) {
        self.engine = engine
        self.sessionRepo = sessionRepo
        observeRouteChangeFailures()
    }

    public func start(mode: ModeKind, targetDuration: Int? = nil) async {
        guard engineState == .idle else { return }
        engineState = .starting
        let preset = Self.preset(for: mode)
        let session = Session(
            modeKind: mode,
            presetId: preset.id,
            targetDurationSeconds: targetDuration
        )
        do {
            try await sessionRepo.create(session)
        } catch {
            logger.error("session create failed: \(String(describing: error), privacy: .private)")
            engineState = .failed(reason: "Couldn't create session.")
            return
        }
        do {
            try await engine.start(with: preset)
            activeSession = session
            engineState = .running
        } catch {
            logger.error("engine start failed: \(String(describing: error), privacy: .private)")
            try? await sessionRepo.finalize(id: session.id, endedAt: Date(), rating: nil)
            engineState = .failed(reason: "Couldn't start audio.")
        }
    }

    public func endCurrentSession() async {
        guard engineState == .running, let session = activeSession else { return }
        engineState = .stopping
        await engine.stop()
        let endedAt = Date()
        do {
            try await sessionRepo.finalize(id: session.id, endedAt: endedAt, rating: nil)
        } catch {
            logger.error("session finalize failed: \(String(describing: error), privacy: .private)")
        }
        activeSession = nil
        pendingRating = session
        engineState = .idle
    }

    public func submitRating(_ value: Int?) async {
        guard let session = pendingRating else { return }
        if let value {
            do {
                try await sessionRepo.finalize(
                    id: session.id,
                    endedAt: session.endedAt ?? Date(),
                    rating: value
                )
            } catch {
                logger.error("rating finalize failed: \(String(describing: error), privacy: .private)")
            }
        }
        pendingRating = nil
    }

    public func dismissRating() {
        pendingRating = nil
    }

    public func dismissFailure() {
        if case .failed = engineState {
            engineState = .idle
        }
    }

    public func applyIntensity(_ value: Float) {
        guard engineState == .running else { return }
        engine.ingest(ParameterDelta(target: .masterGain, value: value))
    }

    private static func preset(for mode: ModeKind) -> ModePreset {
        switch mode {
        case .focus: return FocusPresets.standard()
        case .sleep: return SleepPresets.standard()
        }
    }

    private func observeRouteChangeFailures() {
        let stream = engine.routeChangeFailures
        Task { @MainActor [weak self] in
            for await failure in stream {
                await self?.handleEngineFailure(failure)
            }
        }
    }

    private func handleEngineFailure(_ failure: AudioEngineError) async {
        switch failure {
        case .routeChangeRecoveryFailed:
            let session = activeSession
            activeSession = nil
            engineState = .failed(reason: "Audio route changed and couldn't be recovered. Tap Stop, then Start.")
            await engine.stop()
            if let session {
                do {
                    try await sessionRepo.finalize(id: session.id, endedAt: Date(), rating: nil)
                } catch {
                    logger.error("orphan session finalize failed: \(String(describing: error), privacy: .private)")
                }
            }
        case .sessionConfiguration, .engineStart:
            engineState = .failed(reason: "Audio engine error.")
        }
    }
}
