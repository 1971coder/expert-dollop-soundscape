import XCTest

@testable import Soundscape

final class FilterControllerTests: XCTestCase {
    func testCutoffMappingMonotonic() {
        let a = FilterController.cutoffHz(fromNorm: 0.1, minHz: 200, maxHz: 5_000)
        let b = FilterController.cutoffHz(fromNorm: 0.5, minHz: 200, maxHz: 5_000)
        let c = FilterController.cutoffHz(fromNorm: 0.9, minHz: 200, maxHz: 5_000)
        XCTAssertLessThan(a, b)
        XCTAssertLessThan(b, c)
        XCTAssertGreaterThan(a, 199)
        XCTAssertLessThan(c, 5_001)
    }

    func testCutoffClampedToValidNormRange() {
        let low = FilterController.cutoffHz(fromNorm: -0.5, minHz: 200, maxHz: 5_000)
        let high = FilterController.cutoffHz(fromNorm: 1.5, minHz: 200, maxHz: 5_000)
        XCTAssertEqual(low, 200, accuracy: 1)
        XCTAssertEqual(high, 5_000, accuracy: 1)
    }

    func testQMapping() {
        XCTAssertEqual(FilterController.qFromNorm(0), 0.7, accuracy: 1e-3)
        XCTAssertEqual(FilterController.qFromNorm(1), 5.0, accuracy: 1e-3)
    }

    func testSVFLowPassRemainsBoundedOnDC() {
        var filter = StateVariableFilter()
        var maxAbs: Float = 0
        for _ in 0..<10_000 {
            let out = filter.processLowPass(0.5, cutoffHz: 1_000, q: 1.0, sampleRate: 48_000)
            maxAbs = max(maxAbs, abs(out))
            XCTAssertFalse(out.isNaN)
        }
        XCTAssertLessThan(maxAbs, 2.0)
    }

    func testSVFDoesNotBlowUpAtHighCutoffOrResonance() {
        var filter = StateVariableFilter()
        var maxAbs: Float = 0
        for index in 0..<10_000 {
            let sample = sinf(Float(index) * 0.01)
            let out = filter.processLowPass(sample, cutoffHz: 9_000, q: 5, sampleRate: 48_000)
            maxAbs = max(maxAbs, abs(out))
            XCTAssertFalse(out.isNaN)
            XCTAssertFalse(out.isInfinite)
        }
        XCTAssertLessThan(maxAbs, 10.0, "SVF blew up: max=\(maxAbs)")
    }
}
