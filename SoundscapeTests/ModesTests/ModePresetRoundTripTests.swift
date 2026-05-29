import XCTest

@testable import Soundscape

final class ModePresetRoundTripTests: XCTestCase {
    func testParameterSnapshotIsCodable() throws {
        let original = FocusPresets.standard().parameters
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ParameterSnapshot.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testFocusPresetRoundTripsThroughRecord() throws {
        let original = FocusPresets.standard()
        let record = try ModePresetRecord.from(original)
        let recovered = try record.toDomain()
        XCTAssertEqual(recovered, original)
    }

    func testSleepPresetRoundTripsThroughRecord() throws {
        let original = SleepPresets.standard()
        let record = try ModePresetRecord.from(original)
        let recovered = try record.toDomain()
        XCTAssertEqual(recovered, original)
    }

    func testUnknownModeKindRawDecodesAsError() throws {
        let original = FocusPresets.standard()
        let record = try ModePresetRecord.from(original)
        record.modeKindRaw = "yodeling"
        XCTAssertThrowsError(try record.toDomain()) { error in
            guard case PresetDecodingError.unknownModeKind(let raw) = error else {
                XCTFail("expected unknownModeKind, got \(error)")
                return
            }
            XCTAssertEqual(raw, "yodeling")
        }
    }
}
