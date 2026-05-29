import XCTest

@testable import Soundscape

final class ParameterDeltaSanitiseTests: XCTestCase {
    func testNaNBecomesZero() {
        let delta = ParameterDelta(target: .masterGain, value: .nan)
        XCTAssertFalse(delta.value.isNaN)
        XCTAssertEqual(delta.value, 0)
    }

    func testPositiveInfinityBecomesOne() {
        let delta = ParameterDelta(target: .droneGain, value: .infinity)
        XCTAssertEqual(delta.value, 1)
    }

    func testNegativeInfinityBecomesZero() {
        let delta = ParameterDelta(target: .padCutoff, value: -.infinity)
        XCTAssertEqual(delta.value, 0)
    }

    func testNegativeValuesClampToZero() {
        let delta = ParameterDelta(target: .noiseBalance, value: -0.4)
        XCTAssertEqual(delta.value, 0)
    }

    func testValuesAboveOneClampToOne() {
        let delta = ParameterDelta(target: .filterCutoff, value: 1.5)
        XCTAssertEqual(delta.value, 1)
    }

    func testNormalValuesPassThrough() {
        let delta = ParameterDelta(target: .pulseRate, value: 0.42)
        XCTAssertEqual(delta.value, 0.42, accuracy: 1e-6)
    }

    func testEngineParametersApplyDoesNotProduceNaN() {
        let params = EngineParameters()
        let beforeMaster = params.masterGain
        params.apply(ParameterDelta(target: .masterGain, value: .nan))
        XCTAssertFalse(params.masterGain.isNaN)
        XCTAssertEqual(params.masterGain, 0)
        XCTAssertNotEqual(params.masterGain, beforeMaster)
    }
}
