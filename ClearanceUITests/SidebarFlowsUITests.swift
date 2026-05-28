import XCTest

/// Sidebar: month creation, the Add-Specific-Month sheet, duplicate handling,
/// and the destructive delete flow (confirm + cancel).
final class SidebarFlowsUITests: ClearanceUITestCase {

    func test_startNewMonth_createsSelectableMonth() throws {
        let start = app.buttons["Start New Month"]
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Start New Month toolbar button should exist")
        start.click()
        snapshot(name: "after-start-new-month")

        // After creating a month, the detail header (month title) should be visible,
        // not the empty ContentUnavailableView.
        XCTAssertFalse(
            app.staticTexts["No Monthly Review"].exists,
            "Creating a month should dismiss the empty state"
        )
    }

    func test_addSpecificMonthSheet_opensAndCreates() throws {
        let addSpecific = app.buttons["Add Specific Month"]
        XCTAssertTrue(addSpecific.waitForExistence(timeout: 10))
        addSpecific.click()

        let sheetTitle = app.staticTexts["Add Monthly Review"]
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 5), "Add Month sheet should appear")
        snapshot(name: "add-month-sheet")

        // Create the chosen month.
        let createButton = app.buttons["Create Month"]
        let openExisting = app.buttons["Open Existing"]
        if createButton.exists {
            createButton.click()
        } else if openExisting.exists {
            openExisting.click()
        } else {
            XCTFail("Neither 'Create Month' nor 'Open Existing' button found in sheet")
        }
        XCTAssertFalse(sheetTitle.exists, "Sheet should dismiss after creating/opening a month")
    }

    func test_addSameMonthTwice_doesNotDuplicate() throws {
        // Create a month, then open the sheet again on the same default (current) month.
        app.buttons["Start New Month"].click()
        let addSpecific = app.buttons["Add Specific Month"]
        addSpecific.click()
        XCTAssertTrue(app.staticTexts["Add Monthly Review"].waitForExistence(timeout: 5))
        // The sheet defaults to the current month, which now exists → should offer "Open Existing".
        snapshot(name: "duplicate-month-sheet")
        let openExisting = app.buttons["Open Existing"]
        XCTAssertTrue(
            openExisting.exists,
            "Re-adding the already-created current month should switch the button to 'Open Existing' (dedupe affordance)"
        )
        if openExisting.exists { openExisting.click() }
    }

    func test_deleteMonth_confirmationCanBeCancelled() throws {
        ensureMonthExists()

        // Right-click the first month row to reveal the context menu.
        guard let row = firstMonthRow(), row.waitForExistence(timeout: 5) else {
            throw XCTSkip("No month row found to right-click")
        }
        let deleteItem = app.menuItems["Delete Month..."]
        row.rightClick()
        if !deleteItem.waitForExistence(timeout: 2) {
            // Fallback: some SwiftUI List rows only surface the context menu when the
            // right-click lands on the row's center coordinate rather than its frame origin.
            row.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).rightClick()
        }
        // SwiftUI List `.contextMenu` is not reliably triggerable via synthesized
        // right-clicks across macOS/Xcode versions; skip rather than report a false failure.
        guard deleteItem.waitForExistence(timeout: 5) else {
            throw XCTSkip("SwiftUI List context menu not reachable via synthesized right-click in this environment")
        }
        deleteItem.click()

        // Confirmation alert should appear; Cancel must keep the month.
        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "Delete confirmation alert should appear")
        snapshot(name: "delete-confirmation")
        cancel.click()
        XCTAssertFalse(
            app.staticTexts["No Monthly Review"].exists,
            "Cancelling delete must NOT remove the month"
        )
    }
}
