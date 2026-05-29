import XCTest

final class CriticalPathTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testFocusSessionCriticalPath() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-uitest-clean-state"]
        app.launch()

        let focusButton = app.buttons["modeButton_focus"]
        XCTAssertTrue(focusButton.waitForExistence(timeout: 5), "Focus button missing")
        focusButton.tap()

        let endButton = app.buttons["endButton"]
        XCTAssertTrue(endButton.waitForExistence(timeout: 5), "End button missing — engine never started?")
        sleep(2)
        endButton.tap()

        let thumbsUp = app.buttons["ratingThumbsUp"]
        XCTAssertTrue(thumbsUp.waitForExistence(timeout: 5), "Rating prompt did not appear")
        thumbsUp.tap()

        let historyButton = app.buttons["Open session history"]
        XCTAssertTrue(historyButton.waitForExistence(timeout: 5), "History button missing")
        historyButton.tap()

        XCTAssertTrue(app.staticTexts["FOCUS"].waitForExistence(timeout: 5), "Completed Focus session missing from history")

        app.buttons["Done"].tap()
    }
}
