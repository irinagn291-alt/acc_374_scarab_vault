import XCTest

final class ExpeditionUITests: XCTestCase {
    override func setUp() { super.setUp(); continueAfterFailure = false }
    @MainActor func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    @MainActor func reveal(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<6 { if element.isHittable { return }; app.swipeUp() }
    }
    @MainActor func testExpeditionJourney() async throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-progress"]
        app.launch()
        XCTAssertTrue(app.buttons["resume"].waitForExistence(timeout: 15))
        capture("01-map")
        app.descendants(matching: .any).matching(identifier: "Museum").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Your first discovery awaits"].waitForExistence(timeout: 5))
        capture("02-empty-museum")
        app.descendants(matching: .any).matching(identifier: "Map").firstMatch.tap()
        app.buttons["temple-0"].tap()
        XCTAssertTrue(app.buttons["explore"].waitForExistence(timeout: 5))
        capture("03-temple")
        app.buttons["explore"].tap()
        XCTAssertTrue(app.buttons["forward"].waitForExistence(timeout: 5))
        capture("04-mechanism")
        app.buttons["open-gate"].tap()
        XCTAssertTrue(app.otherElements["gate-message"].exists || app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'The gate is still'")).firstMatch.exists)
        let hint = app.buttons["hint"]; reveal(hint, app: app)
        hint.tap(); hint.tap(); hint.tap()
        XCTAssertTrue(app.staticTexts["next-move"].waitForExistence(timeout: 5))
        capture("05-hint")
        app.buttons["reset"].tap()
        app.buttons["Reset room"].tap()
        app.swipeDown(); app.swipeDown()
        app.buttons["forward"].tap()
        app.buttons["open-gate"].tap()
        XCTAssertTrue(app.staticTexts["reward-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["reward-title"].label, "Dawn Scarab")
        capture("06-discovery")
        app.descendants(matching: .any).matching(identifier: "Museum").firstMatch.tap()
        XCTAssertTrue(app.buttons["artefact-0"].waitForExistence(timeout: 5))
        capture("07-museum")
        app.buttons["artefact-0"].tap()
        capture("08-artefact")
        app.descendants(matching: .any).matching(identifier: "Journal").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Expedition journal"].waitForExistence(timeout: 5))
        capture("09-symbols")
        app.segmentedControls.buttons["Schemes"].tap(); capture("10-schemes")
        app.segmentedControls.buttons["Records"].tap()
        XCTAssertTrue(app.staticTexts["Dawn Scarab"].exists)
        capture("11-records")
        app.descendants(matching: .any).matching(identifier: "Museum").firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Artefact story"].exists)
        app.descendants(matching: .any).matching(identifier: "Journal").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Dawn Scarab"].exists)
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["resume"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["1 / 15 rooms"].exists)
        app.buttons["resume"].tap()
        XCTAssertTrue(app.staticTexts["The keeper’s passage"].waitForExistence(timeout: 5))
        capture("12-restored-progress")
        XCUIDevice.shared.orientation = .landscapeLeft
        try await Task.sleep(for: .seconds(1))
        XCTAssertGreaterThan(app.windows.firstMatch.frame.width, app.windows.firstMatch.frame.height)
        capture("13-landscape")
        XCTAssertTrue(app.buttons["forward"].exists)
        XCUIDevice.shared.orientation = .portrait
    }
    @MainActor func testAllTemplesAndFiveCylinders() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset-progress"]
        app.launch()
        XCTAssertTrue(app.buttons["resume"].waitForExistence(timeout: 15))
        app.buttons["resume"].tap()
        let rewards = ["Dawn Scarab", "River Compass", "Lotus Seal", "Reed Pendant", "Bronze Axle", "Keeper’s Tablet", "Twin Falcons", "Stillwater Lens", "Mirror Diadem", "Tide Vessel", "Balance Feather", "Moon Sundial", "Golden Spine", "Sun Cartouche", "Heart of the Vault"]
        for id in 0..<15 {
            let temple = id / 3, number = id % 3, count = temple >= 3 ? 5 : 3
            XCTAssertTrue(app.buttons["cylinder-0"].waitForExistence(timeout: 5))
            if id == 9 || id == 12 { capture("five-cylinders-temple-\(temple + 1)") }
            let scramble = [(0, -1), (temple == 2 ? 1 : count - 1, 1), (temple == 2 ? 0 : 1, -1)]
            for (index, direction) in scramble.prefix(number + 1).reversed() {
                let cylinder = app.buttons["cylinder-\(index)"]
                for _ in 0..<3 { if cylinder.isHittable { break }; app.swipeDown() }
                cylinder.tap()
                let turn = app.buttons[direction == -1 ? "forward" : "backward"]
                reveal(turn, app: app); turn.tap()
            }
            let open = app.buttons["open-gate"]; reveal(open, app: app); open.tap()
            XCTAssertTrue(app.staticTexts["reward-title"].waitForExistence(timeout: 5), "Room \(id)")
            XCTAssertEqual(app.staticTexts["reward-title"].label, rewards[id])
            if number == 2 { capture("chapter-\(temple + 1)-complete") }
            if id < 14 {
                let next = app.buttons["next-room"]; reveal(next, app: app); next.tap()
            }
        }
        app.descendants(matching: .any).matching(identifier: "Museum").firstMatch.tap()
        XCTAssertTrue(app.staticTexts["15 of 15 artefacts recovered"].waitForExistence(timeout: 5))
        capture("complete-museum")
        app.terminate()
    }

}
