import AVFoundation
import XCTest

@testable import Soundscape

final class PadSynthTests: XCTestCase {
    private let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 48_000,
        channels: 1,
        interleaved: false
    )!

    func testProducesBoundedSignalOverThreeSeconds() throws {
        let parameters = EngineParameters()
        parameters.padCutoff = 0.7
        parameters.padResonance = 0.3
        parameters.pulseRate = 0.4
        parameters.pulseDepth = 0.0
        parameters.masterGain = 1.0
        let pad = PadSynth(format: format, parameters: parameters)
        let engine = AVAudioEngine()
        engine.attach(pad.node)
        engine.connect(pad.node, to: engine.mainMixerNode, format: format)

        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
        try engine.start()
        defer { engine.stop() }

        let outputBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 4096)!
        let totalFrames = AVAudioFrameCount(format.sampleRate * 3)
        var sumSquares: Double = 0
        var count = 0
        var maxAbs: Float = 0
        var rendered: AVAudioFrameCount = 0

        while rendered < totalFrames {
            let toRender = min(AVAudioFrameCount(4096), totalFrames - rendered)
            outputBuffer.frameLength = 0
            let status = try engine.renderOffline(toRender, to: outputBuffer)
            XCTAssertEqual(status, .success)
            guard let chData = outputBuffer.floatChannelData else { continue }
            for frame in 0..<Int(outputBuffer.frameLength) {
                let sample = chData[0][frame]
                sumSquares += Double(sample * sample)
                count += 1
                if abs(sample) > maxAbs { maxAbs = abs(sample) }
                XCTAssertFalse(sample.isNaN)
                XCTAssertFalse(sample.isInfinite)
            }
            rendered += outputBuffer.frameLength
        }

        let rms = sqrt(sumSquares / Double(count))
        XCTAssertGreaterThan(rms, 0.005, "pad too quiet (rms=\(rms))")
        XCTAssertLessThan(maxAbs, 1.0, "pad clipped at \(maxAbs)")
    }

    func testLowerCutoffReducesEnergy() throws {
        func rmsForCutoff(_ cutoff: Float) throws -> Double {
            let parameters = EngineParameters()
            parameters.padCutoff = cutoff
            parameters.padResonance = 0
            parameters.pulseDepth = 0
            parameters.masterGain = 1.0
            let pad = PadSynth(format: format, parameters: parameters)
            let engine = AVAudioEngine()
            engine.attach(pad.node)
            engine.connect(pad.node, to: engine.mainMixerNode, format: format)
            try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
            try engine.start()
            defer { engine.stop() }
            let outputBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 4096)!
            var sumSquares: Double = 0
            var count = 0
            for _ in 0..<24 {
                outputBuffer.frameLength = 0
                let status = try engine.renderOffline(4096, to: outputBuffer)
                XCTAssertEqual(status, .success)
                guard let chData = outputBuffer.floatChannelData else { continue }
                for frame in 0..<Int(outputBuffer.frameLength) {
                    let sample = chData[0][frame]
                    sumSquares += Double(sample * sample)
                    count += 1
                }
            }
            return sqrt(sumSquares / Double(count))
        }

        let bright = try rmsForCutoff(0.9)
        let dark = try rmsForCutoff(0.1)
        XCTAssertLessThan(dark, bright, "dark cutoff did not reduce energy: dark=\(dark) bright=\(bright)")
    }
}
