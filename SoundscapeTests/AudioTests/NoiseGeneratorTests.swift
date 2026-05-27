import AVFoundation
import XCTest

@testable import Soundscape

final class NoiseGeneratorTests: XCTestCase {
    private let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 48_000,
        channels: 1,
        interleaved: false
    )!

    func testBrownNoiseRemainsBounded() throws {
        let parameters = EngineParameters()
        parameters.noiseBalance = 1.0
        parameters.masterGain = 1.0
        let noise = NoiseGenerator(format: format, parameters: parameters, rngSeed: 0xCAFE_BABE)
        let engine = AVAudioEngine()
        engine.attach(noise.node)
        engine.connect(noise.node, to: engine.mainMixerNode, format: format)

        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
        try engine.start()
        defer { engine.stop() }

        let outputBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 4096)!
        let totalFrames = AVAudioFrameCount(format.sampleRate * 30)
        var sum: Double = 0
        var count = 0
        var sawNonZero = false
        var rendered: AVAudioFrameCount = 0

        while rendered < totalFrames {
            let toRender = min(AVAudioFrameCount(4096), totalFrames - rendered)
            outputBuffer.frameLength = 0
            let status = try engine.renderOffline(toRender, to: outputBuffer)
            XCTAssertEqual(status, .success)
            guard let chData = outputBuffer.floatChannelData else { continue }
            for frame in 0..<Int(outputBuffer.frameLength) {
                let sample = chData[0][frame]
                sum += Double(sample)
                count += 1
                if abs(sample) > 1e-6 { sawNonZero = true }
                XCTAssertFalse(sample.isNaN, "NaN at frame \(frame)")
                XCTAssertFalse(sample.isInfinite, "Inf at frame \(frame)")
            }
            rendered += outputBuffer.frameLength
        }

        XCTAssertTrue(sawNonZero, "brown noise produced silence")
        let mean = Float(sum / Double(count))
        XCTAssertLessThan(abs(mean), 0.1, "brown noise mean drifted to \(mean) — leaky integrator broken")
    }

    func testPinkNoiseIsBoundedAndNonSilent() throws {
        let parameters = EngineParameters()
        parameters.noiseBalance = 0.0
        parameters.masterGain = 1.0
        let noise = NoiseGenerator(format: format, parameters: parameters, rngSeed: 0xFEED_FACE)
        let engine = AVAudioEngine()
        engine.attach(noise.node)
        engine.connect(noise.node, to: engine.mainMixerNode, format: format)

        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
        try engine.start()
        defer { engine.stop() }

        let outputBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 4096)!
        let totalFrames = AVAudioFrameCount(format.sampleRate * 2)
        var maxAbs: Float = 0
        var rendered: AVAudioFrameCount = 0

        while rendered < totalFrames {
            let toRender = min(AVAudioFrameCount(4096), totalFrames - rendered)
            outputBuffer.frameLength = 0
            let status = try engine.renderOffline(toRender, to: outputBuffer)
            XCTAssertEqual(status, .success)
            if let chData = outputBuffer.floatChannelData {
                for frame in 0..<Int(outputBuffer.frameLength) {
                    let absSample = abs(chData[0][frame])
                    if absSample > maxAbs { maxAbs = absSample }
                }
            }
            rendered += outputBuffer.frameLength
        }

        XCTAssertGreaterThan(maxAbs, 0.01, "pink noise too quiet")
        XCTAssertLessThan(maxAbs, 1.0, "pink noise clipped at \(maxAbs)")
    }
}
