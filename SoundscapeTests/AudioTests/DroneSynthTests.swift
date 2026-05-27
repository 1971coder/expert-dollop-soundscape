import AVFoundation
import XCTest

@testable import Soundscape

final class DroneSynthTests: XCTestCase {
    private let format = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 48_000,
        channels: 1,
        interleaved: false
    )!

    func testProducesBoundedRMSOverFiveSeconds() throws {
        let parameters = EngineParameters()
        parameters.droneGain = 1.0
        parameters.masterGain = 1.0
        let ringBuffer = ParameterRingBuffer()
        let drone = DroneSynth(format: format, parameters: parameters, ringBuffer: ringBuffer)
        let engine = AVAudioEngine()
        engine.attach(drone.node)
        engine.connect(drone.node, to: engine.mainMixerNode, format: format)

        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
        try engine.start()
        defer { engine.stop() }

        let outputBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 4096)!
        let totalFrames = AVAudioFrameCount(format.sampleRate * 5)
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
                XCTAssertFalse(sample.isNaN, "NaN at frame \(frame)")
                XCTAssertFalse(sample.isInfinite, "Inf at frame \(frame)")
            }
            rendered += outputBuffer.frameLength
        }

        let rms = sqrt(sumSquares / Double(count))
        XCTAssertGreaterThan(rms, 0.01, "drone too quiet (rms=\(rms))")
        XCTAssertLessThan(maxAbs, 1.0, "drone clipped at \(maxAbs)")
    }

    func testIngestedMasterGainAffectsOutput() throws {
        let parameters = EngineParameters()
        parameters.droneGain = 1.0
        parameters.masterGain = 1.0
        let ringBuffer = ParameterRingBuffer()
        let drone = DroneSynth(format: format, parameters: parameters, ringBuffer: ringBuffer)
        let engine = AVAudioEngine()
        engine.attach(drone.node)
        engine.connect(drone.node, to: engine.mainMixerNode, format: format)

        try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
        try engine.start()
        defer { engine.stop() }

        let outputBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: 4096)!

        func rmsOver(blocks: Int) throws -> Double {
            var sumSquares: Double = 0
            var count = 0
            for _ in 0..<blocks {
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

        let loud = try rmsOver(blocks: 8)
        XCTAssertTrue(ringBuffer.tryPush(ParameterDelta(target: .masterGain, value: 0.1)))
        let quiet = try rmsOver(blocks: 8)
        XCTAssertLessThan(quiet, loud * 0.5, "master gain ingest did not reduce RMS: loud=\(loud) quiet=\(quiet)")
    }
}
