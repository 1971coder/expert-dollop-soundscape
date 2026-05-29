import XCTest

@testable import Soundscape

final class PulseModulatorTests: XCTestCase {
    func testDepthZeroAlwaysOne() {
        var pulse = PulseModulator()
        for _ in 0..<200 {
            let gain = pulse.nextGain(rateNorm: 0.5, depthNorm: 0, frameCount: 4096, sampleRate: 48_000)
            XCTAssertEqual(gain, 1.0, accuracy: 1e-6)
        }
    }

    func testDepthOneSwingsBetweenZeroAndOne() {
        var pulse = PulseModulator()
        var minGain: Float = .infinity
        var maxGain: Float = -.infinity
        for _ in 0..<2_000 {
            let gain = pulse.nextGain(rateNorm: 1.0, depthNorm: 1.0, frameCount: 256, sampleRate: 48_000)
            minGain = min(minGain, gain)
            maxGain = max(maxGain, gain)
        }
        XCTAssertLessThan(minGain, 0.05)
        XCTAssertGreaterThan(maxGain, 0.95)
    }

    func testNeverExceedsUnity() {
        var pulse = PulseModulator()
        for _ in 0..<5_000 {
            let gain = pulse.nextGain(rateNorm: 0.7, depthNorm: 0.6, frameCount: 512, sampleRate: 48_000)
            XCTAssertLessThanOrEqual(gain, 1.0)
            XCTAssertGreaterThanOrEqual(gain, 0.0)
            XCTAssertFalse(gain.isNaN)
        }
    }

    func testPhaseWrapsCleanly() {
        var pulse = PulseModulator()
        for _ in 0..<200_000 {
            _ = pulse.nextGain(rateNorm: 0.5, depthNorm: 0.5, frameCount: 4096, sampleRate: 48_000)
        }
        XCTAssertLessThan(pulse.phase, 2 * Float.pi)
        XCTAssertGreaterThanOrEqual(pulse.phase, 0)
    }
}
