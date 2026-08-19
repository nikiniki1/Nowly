import XCTest

final class CurrentActivityFlowUITests: XCTestCase {
    @MainActor
    func testCurrentActivityScreenExposesNativeQuickActions() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Сейчас"].waitForExistence(timeout: 5))
        let quickActivity = app.descendants(matching: .any).matching(identifier: "quick-activity").firstMatch
        XCTAssertTrue(quickActivity.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "refine-activity").count, 0)

        quickActivity.press(forDuration: 0.5)
        let refinementCard = app.descendants(matching: .any).matching(identifier: "activity-refinement-card").firstMatch
        XCTAssertTrue(refinementCard.waitForExistence(timeout: 2))
        XCTAssertGreaterThan(refinementCard.frame.minY, quickActivity.frame.maxY)
    }

    @MainActor
    func testSettingsExposesProfileActivitiesAndDataExport() {
        let app = XCUIApplication()
        app.launch()

        let settings = app.buttons["Настройки"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        XCTAssertTrue(app.navigationBars["Настройки"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Информация о себе"].exists)
        XCTAssertTrue(app.staticTexts["Все активности"].exists)
        XCTAssertTrue(app.staticTexts["Выгрузить историю"].exists)
    }
}
