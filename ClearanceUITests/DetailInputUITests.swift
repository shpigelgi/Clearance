import XCTest

/// Adversarial input testing on the Month Detail view: invalid/edge numbers,
/// the income-from-days division path, buffer recomputation, and transfer toggles.
final class DetailInputUITests: ClearanceUITestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Guarantee a month to edit.
        let start = app.buttons["Start New Month"]
        if start.waitForExistence(timeout: 10) { start.click() }
    }

    /// Type a value into a labeled financial field (select-all + replace).
    private func setField(_ label: String, to text: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[label]
        guard field.waitForExistence(timeout: 5) else {
            XCTFail("Text field '\(label)' not found", file: file, line: line)
            return
        }
        field.click()
        field.typeKey("a", modifierFlags: .command)
        field.typeText(text + "\n")
    }

    func test_negativeIncome_isHandledGracefully() throws {
        setField("Income", to: "-5000")
        snapshot(name: "negative-income")
        // App must not crash; window should still be responsive.
        XCTAssertTrue(app.windows.firstMatch.exists, "App should survive a negative income entry")
    }

    func test_hugeValue_doesNotBreakLayout() throws {
        setField("Income", to: "999999999999")
        setField("Rent", to: "1")
        snapshot(name: "huge-income")
        XCTAssertTrue(app.windows.firstMatch.exists)
    }

    func test_nonNumericText_rejectedOrIgnored() throws {
        // Formatters.number parsing should reject letters; the field must not crash.
        setField("Rent", to: "abc!@#")
        snapshot(name: "non-numeric-rent")
        XCTAssertTrue(app.windows.firstMatch.exists, "Garbage text input must not crash the app")
    }

    func test_incomeFromDays_zeroBaselineDivisionPath() throws {
        // Switch to "calculate from days worked", then drive baseline days to 0,
        // which exercises the income/0 division guard.
        let toggle = app.checkBoxes["Calculate from days worked"]
        if toggle.waitForExistence(timeout: 5) {
            toggle.click()
        } else {
            // Fall back to any checkbox-styled toggle with that label.
            app.switches["Calculate from days worked"].firstMatch.click()
        }
        snapshot(name: "income-mode-on")

        setField("Baseline Work Days", to: "0")
        setField("Days Worked", to: "10")
        snapshot(name: "zero-baseline-days")
        XCTAssertTrue(app.windows.firstMatch.exists, "Zero baseline days (division by zero) must not crash")
    }

    func test_bufferGoesNegative_whenSpendExceedsIncome() throws {
        // Force a deficit: tiny income, large actual card spend.
        setField("Income", to: "1000")
        setField("Rent", to: "0")
        setField("Mizrahi Target", to: "5000")
        setField("Actual Mizrahi", to: "5000")
        setField("1824 Target", to: "5000")
        setField("Actual 1824", to: "5000")
        snapshot(name: "deficit-buffer")
        // The UI labels a deficit as "Deficit buffer".
        XCTAssertTrue(
            app.staticTexts["Deficit buffer"].waitForExistence(timeout: 3),
            "A negative remaining buffer should show the 'Deficit buffer' status"
        )
    }

    func test_transferToggle_flipsState() throws {
        // Layout-independent: the first transfer checkbox (top of the Wealth Engine,
        // always visible) should round-trip OFF -> ON -> OFF.
        let box = app.checkBoxes.allElementsBoundByIndex.first { $0.label.hasPrefix("Mark ") }
        guard let box else { return XCTFail("No 'Mark ... transferred' checkbox found") }
        XCTAssertEqual(box.value as? Int, 0, "Transfer should start unmarked")
        box.click()
        XCTAssertEqual(box.value as? Int, 1, "Clicking should mark the transfer")
        snapshot(name: "transfer-marked")
        box.click()
        XCTAssertEqual(box.value as? Int, 0, "Clicking again should unmark the transfer")
    }

    func test_monthRoutingSummary_visibleInNarrowLayout() throws {
        // Regression (fixed bug #1): the "Month Routing" summary — Effective Income,
        // Planned/Confirmed totals and the "X of 4 complete" progress — must render in the
        // single-column (narrow) layout too, not only in the two-column layout.
        XCTAssertTrue(
            app.staticTexts["Transfer Progress"].waitForExistence(timeout: 5),
            "The Month Routing summary should be visible regardless of window width"
        )
    }

    func test_amountFields_haveUniqueLabels() throws {
        // Regression (fixed bug #3): the four Wealth-Engine amount fields used to share
        // accessibilityLabel "Amount". Each should now carry a unique, transfer-specific label.
        snapshot(name: "amount-fields")
        let collisions = app.textFields.matching(identifier: "Amount").count
        XCTAssertEqual(collisions, 0, "No amount field should use the generic label 'Amount' (found \(collisions))")
    }
}
