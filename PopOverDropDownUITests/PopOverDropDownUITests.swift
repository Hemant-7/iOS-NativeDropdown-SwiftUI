import XCTest

final class PopOverDropDownUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testSingleSearchAndDisabledRows() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["example.basic"].tap()
        XCTAssertTrue(app.buttons["dropdown.item.bengaluru"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["dropdown.search"].exists)
        app.buttons["dropdown.item.bengaluru"].tap()
        XCTAssertTrue(app.buttons["example.basic"].label.contains("Bengaluru"))

        app.buttons["example.search"].tap()
        let search = app.textFields["dropdown.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("  mum")
        XCTAssertTrue(app.buttons["dropdown.item.mumbai"].exists)
        XCTAssertFalse(app.buttons["dropdown.item.delhi"].exists)
        app.buttons["dropdown.item.mumbai"].tap()
        XCTAssertTrue(app.buttons["example.search"].label.contains("Mumbai"))

        let disabledExample = app.buttons["example.disabled"]
        if !disabledExample.isHittable { app.swipeUp() }
        disabledExample.tap()
        XCTAssertTrue(app.buttons["dropdown.item.delhi"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["dropdown.item.delhi"].isEnabled)
    }

    @MainActor
    func testRequiredDraftApplyCancelAndSearchRetention() throws {
        let app = XCUIApplication()
        app.launch()
        let anchor = app.buttons["example.multiple"]
        if !anchor.isHittable { app.swipeUp() }
        anchor.tap()
        let apply = app.buttons["dropdown.complete"]
        XCTAssertTrue(apply.waitForExistence(timeout: 5))
        XCTAssertFalse(apply.isEnabled)
        app.buttons["dropdown.item.bengaluru"].tap()
        XCTAssertTrue(apply.isEnabled)
        app.buttons["dropdown.item.bengaluru"].tap()
        XCTAssertTrue(app.buttons["dropdown.item.bengaluru"].isSelected)
        app.buttons["dropdown.item.chennai"].tap()
        apply.tap()
        XCTAssertTrue(anchor.label.contains("2 selected"))

        anchor.tap()
        XCTAssertTrue(app.buttons["dropdown.item.chennai"].waitForExistence(timeout: 5))
        app.buttons["dropdown.item.chennai"].tap()
        let search = app.textFields["dropdown.search"]
        search.tap()
        search.typeText("zzzz")
        XCTAssertTrue(app.staticTexts["No results found"].exists)
        app.buttons["Clear search"].tap()
        XCTAssertTrue(app.buttons["dropdown.item.bengaluru"].isSelected)
        app.buttons["dropdown.cancel"].tap()
        XCTAssertTrue(anchor.label.contains("2 selected"))
    }
    @MainActor
    func testLargeDatasetSearchAndLazyScrolling() throws {
        let app = XCUIApplication()
        app.launch()
        let anchor = app.buttons["Browse 3,000 items"]
        for _ in 0..<8 {
            if anchor.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(anchor.isHittable)
        anchor.tap()
        let search = app.textFields["dropdown.search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        let visibleRow = app.buttons["dropdown.item.4"]
        XCTAssertTrue(visibleRow.waitForExistence(timeout: 5))
        // XCTest reports an empty visible frame for native popover swipe targets.
        // Use the observed row frame for the gesture instead.
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let start = origin.withOffset(CGVector(dx: visibleRow.frame.midX, dy: visibleRow.frame.midY))
        let end = origin.withOffset(CGVector(dx: visibleRow.frame.midX, dy: visibleRow.frame.midY - 120))
        start.press(forDuration: 0.05, thenDragTo: end)
        search.tap()
        search.typeText("Item 3000")
        let last = app.buttons["dropdown.item.3000"]
        XCTAssertTrue(last.waitForExistence(timeout: 5))
        XCTAssertTrue(last.isHittable)
        app.buttons["Clear search"].tap()
        XCTAssertTrue(app.buttons["dropdown.item.1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["dropdown.item.1"].isHittable)
        search.tap()
        search.typeText("Item 3000")
        last.tap()
        XCTAssertTrue(app.buttons["Item 3000"].waitForExistence(timeout: 5))
    }

}
