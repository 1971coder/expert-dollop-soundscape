import AVFoundation
import Foundation
import os

/// The narrow public surface from `Audio/` to the rest of the app.
/// See `docs/api-contract.md` §1.
///
/// Conforming types are `Sendable` because callers cross actor boundaries
/// (main-actor `SessionStateManager`, off-main `AdaptiveController` in WP03)
/// and Swift 6 strict concurrency requires it.
public protocol AudioEngineControl: Sendable {
    func start(with preset: ModePreset) async throws
    func stop() async
    func ingest(_ delta: ParameterDelta)
    nonisolated var routeIsHeadphones: Bool { get }
    nonisolated var routeChangeFailures: AsyncStream<AudioEngineError> { get }
}

public enum AudioEngineError: Error, Sendable {
    case sessionConfiguration(String)
    case engineStart(String)
    case routeChangeRecoveryFailed(String)
}

/// Owns the AVAudioEngine graph and serialises lifecycle transitions.
///
/// **Why a lock, not an actor.** Apple's AVFoundation types are not yet
/// `Sendable`-annotated, and the project's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
/// pushes actor inits to main-actor isolation. The combination makes a true
/// `actor` declaration generate a wall of false-positive isolation warnings without
/// improving safety. An `OSAllocatedUnfairLock` around `start`/`stop`/`handleRouteChange`
/// gives us the same serialisation guarantee at lower cost. The hot path —
/// `ingest(_:)` — never touches the lock; it goes straight to the lock-free
/// SPSC ring buffer.
nonisolated public final class AudioEngine: AudioEngineControl, @unchecked Sendable {
    nonisolated private static let logger = Logger(subsystem: "app.auralflow", category: "audio.engine")
    nonisolated private static let sampleRate: Double = 48_000

    private let engine = AVAudioEngine()
    private let format: AVAudioFormat
    private let parameters = EngineParameters()
    private let ringBuffer = ParameterRingBuffer()
    private let drone: DroneSynth
    private let noise: NoiseGenerator
    private let pad: PadSynth
    private let mixer: Mixer

    private let lifecycleLock = OSAllocatedUnfairLock()
    private var routeChangeObserver: NSObjectProtocol?
    private var isRunning = false

    public let routeChangeFailures: AsyncStream<AudioEngineError>
    private let failureContinuation: AsyncStream<AudioEngineError>.Continuation

    public init() {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Self.sampleRate,
            channels: 1,
            interleaved: false
        )!
        self.format = format
        self.drone = DroneSynth(format: format, parameters: parameters, ringBuffer: ringBuffer)
        self.noise = NoiseGenerator(format: format, parameters: parameters)
        self.pad = PadSynth(format: format, parameters: parameters)
        self.mixer = Mixer()

        var continuation: AsyncStream<AudioEngineError>.Continuation!
        self.routeChangeFailures = AsyncStream { continuation = $0 }
        self.failureContinuation = continuation

        engine.attach(drone.node)
        engine.attach(noise.node)
        engine.attach(pad.node)
        engine.attach(mixer.node)
        engine.connect(drone.node, to: mixer.node, format: format)
        engine.connect(noise.node, to: mixer.node, format: format)
        engine.connect(pad.node, to: mixer.node, format: format)
        engine.connect(mixer.node, to: engine.outputNode, format: nil)
    }

    deinit {
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if engine.isRunning {
            engine.stop()
        }
        failureContinuation.finish()
    }

    public func start(with preset: ModePreset) async throws {
        try lifecycleLock.withLockUnchecked { () -> Void in
            guard !isRunning else { return }

            parameters.applyAll(preset.parameters)

            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [])
                try session.setActive(true, options: [])
            } catch {
                Self.logger.error("audio session activation failed")
                throw AudioEngineError.sessionConfiguration(String(describing: error))
            }

            engine.prepare()
            do {
                try engine.start()
            } catch {
                Self.logger.error("AVAudioEngine.start() failed")
                throw AudioEngineError.engineStart(String(describing: error))
            }

            subscribeToRouteChangesLocked()
            isRunning = true
            Self.logger.info("audio engine started")
        }
    }

    public func stop() async {
        lifecycleLock.withLockUnchecked { () -> Void in
            guard isRunning else { return }
            engine.stop()
            try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
            unsubscribeFromRouteChangesLocked()
            isRunning = false
            Self.logger.info("audio engine stopped")
        }
    }

    public func ingest(_ delta: ParameterDelta) {
        ringBuffer.tryPush(delta)
    }

    public var routeIsHeadphones: Bool {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        return outputs.contains { output in
            switch output.portType {
            case .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE, .airPlay:
                return true
            default:
                return false
            }
        }
    }

    private func subscribeToRouteChangesLocked() {
        guard routeChangeObserver == nil else { return }
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
    }

    private func unsubscribeFromRouteChangesLocked() {
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            routeChangeObserver = nil
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else {
            return
        }
        switch reason {
        case .oldDeviceUnavailable, .newDeviceAvailable, .categoryChange:
            lifecycleLock.withLockUnchecked { () -> Void in
                guard isRunning else { return }
                Self.logger.notice("route change: reconfiguring engine")
                engine.pause()
                engine.prepare()
                do {
                    try engine.start()
                } catch {
                    Self.logger.error("engine restart after route change failed")
                    failureContinuation.yield(.routeChangeRecoveryFailed(String(describing: error)))
                }
            }
        default:
            break
        }
    }
}
