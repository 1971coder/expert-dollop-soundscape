import AVFoundation
import XCTest

@testable import Soundscape

final class AudioEngineSmokeTests: XCTestCase {
    private let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 48_000,
        channels: 1,
        interleaved: false
    )!

    func testGraphRendersNonSilentOneSecond() throws {
        let parameters = EngineParameters()
        parameters.droneGain = 0.6
        parameters.masterGain = 0.8
        let ringBuffer = ParameterRingBuffer()
        let drone = DroneSynth(format: format, parameters: parameters, ringBuffer: ringBuffer)
        let noise = NoiseGenerator(format: format, parameters: parameters, rngSeed: 0xDEAD_BEEF)
        let mixer = Mixer()

        let engine = AVAudioEngine()
        engine.attach(drone.node)
        engine.attach(noise.node)
        engine.attach(mixer.node)
        engine.connect(drone.node, to: mixer.node, format: format)
        engine.connect(noise.node, to: mixer.node, format: format)
        engine.connect(mixer.node, to: engine.mainMixerNode, format: format)

        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
        try engine.start()
        defer { engine.stop() }

        let outputBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 4096)!
        let totalFrames = AVAudioFrameCount(format.sampleRate)
        var rendered: AVAudioFrameCount = 0
        var sawNonZero = false

        while rendered < totalFrames {
            let toRender = min(AVAudioFrameCount(4096), totalFrames - rendered)
            outputBuffer.frameLength = 0
            let status = try engine.renderOffline(toRender, to: outputBuffer)
            XCTAssertEqual(status, .success)
            if let chData = outputBuffer.floatChannelData {
                for frame in 0..<Int(outputBuffer.frameLength) where abs(chData[0][frame]) > 1e-6 {
                    sawNonZero = true
                    break
                }
            }
            rendered += outputBuffer.frameLength
        }

        XCTAssertTrue(sawNonZero, "engine graph rendered silence — drone/noise didn't reach mixer")
    }

    func testAudioEngineConstructionAndIngestDoesNotCrash() {
        let engine = AudioEngine()
        engine.ingest(ParameterDelta(target: .masterGain, value: 0.5))
        engine.ingest(ParameterDelta(target: .droneGain, value: 0.6))
        engine.ingest(ParameterDelta(target: .noiseBalance, value: 0.3))
        engine.ingest(ParameterDelta(target: .droneDetune, value: 0.4))
    }
}
