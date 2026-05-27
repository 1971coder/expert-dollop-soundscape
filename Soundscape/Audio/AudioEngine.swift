import AVFoundation
import Foundation
import os

/// Placeholder for `ModePreset`. The real type lives under `Soundscape/Modes/`
/// (WP02). WP01 doesn't have modes yet but the `AudioEngineControl` protocol
/// (api-contract.md §1) references the type, so a stub keeps the public
/// surface honest. WP02 deletes this declaration and moves the real
/// `ModePreset` into `Modes/ModePreset.swift`.
public struct ModePreset: Sendable {
    public init() {}
}

/// The narrow public surface from `Audio/` to the rest of the app.
/// See `docs/api-contract.md` §1.
public protocol AudioEngineControl: Sendable {
    func start(with preset: ModePreset) async throws
    func stop() async
    func ingest(_ delta: ParameterDelta)
    var routeIsHeadphones: Bool { get }
}

public enum AudioEngineError: Error {
    case sessionConfiguration(Error)
    case engineStart(Error)
}

nonisolated public final class AudioEngine: AudioEngineControl, @unchecked Sendable {
    private static let logger = Logger(subsystem: "app.auralflow", category: "audio.engine")
    private static let sampleRate: Double = 48_000

    private let engine = AVAudioEngine()
    private let format: AVAudioFormat
    private let parameters = EngineParameters()
    private let ringBuffer = ParameterRingBuffer()
    private let drone: DroneSynth
    private let noise: NoiseGenerator
    private let mixer: Mixer

    private var routeChangeObserver: NSObjectProtocol?
    private var isRunning = false

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
        self.mixer = Mixer()

        engine.attach(drone.node)
        engine.attach(noise.node)
        engine.attach(mixer.node)
        engine.connect(drone.node, to: mixer.node, format: format)
        engine.connect(noise.node, to: mixer.node, format: format)
        engine.connect(mixer.node, to: engine.outputNode, format: nil)
    }

    deinit {
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if engine.isRunning {
            engine.stop()
        }
    }

    public func start(with preset: ModePreset) async throws {
        _ = preset
        guard !isRunning else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true, options: [])
        } catch {
            Self.logger.error("audio session activation failed")
            throw AudioEngineError.sessionConfiguration(error)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            Self.logger.error("AVAudioEngine.start() failed")
            throw AudioEngineError.engineStart(error)
        }

        subscribeToRouteChanges()
        isRunning = true
        Self.logger.info("audio engine started")
    }

    public func stop() async {
        guard isRunning else { return }
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        unsubscribeFromRouteChanges()
        isRunning = false
        Self.logger.info("audio engine stopped")
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

    private func subscribeToRouteChanges() {
        guard routeChangeObserver == nil else { return }
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
    }

    private func unsubscribeFromRouteChanges() {
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
            Self.logger.notice("route change: reconfiguring engine")
            engine.pause()
            engine.prepare()
            do {
                try engine.start()
            } catch {
                Self.logger.error("engine restart after route change failed")
            }
        default:
            break
        }
    }
}
