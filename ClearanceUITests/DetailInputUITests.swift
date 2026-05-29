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

    /// Type a value into a labeled financial field, clearing any existing/default value first.
    /// Self-verifying: ⌘A select-all is unreliable in these formatter-backed number fields, and
    /// under load the clear can race (the typed text gets prepended: "1000"+"10000" = 100,010,000).
    /// So we clear by moving to the end and backspacing the full length, then read the field back
    /// and retry until the field's digits match what we typed.
    /// Set `verifyNumeric: false` for adversarial garbage input (e.g. "abc!@#"), where the
    /// formatter is expected to reject the value, so reading the digits back won't match.
    private func setField(_ label: String, to text: String, verifyNumeric: Bool = true,
                          file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[label]
        guard field.waitForExistence(timeout: 5) else {
            XCTFail("Text field '\(label)' not found", file: file, line: line)
            return
        }
        let wantDigits = text.filter { $0.isNumber || $0 == "-" }
        let attempts = verifyNumeric ? 3 : 1
        for attempt in 1...attempts {
            field.click()
            Thread.sleep(forTimeInterval: 0.25)
            let existing = (field.value as? String) ?? ""
            let clearCount = max(existing.count + 2, 4)
            for _ in 0..<clearCount { app.typeKey(.rightArrow, modifierFlags: []) }
            for _ in 0..<clearCount { app.typeKey(.delete, modifierFlags: []) }
            app.typeText(text)
            app.typeKey(.return, modifierFlags: [])
            guard verifyNumeric else { return }
            Thread.sleep(forTimeInterval: 0.15)
            let after = ((field.value as? String) ?? "").filter { $0.isNumber || $0 == "-" }
            if after == wantDigits { return }
            if attempt == attempts {
                XCTFail("Field '\(label)' did not accept '\(text)' (got '\(after)')", file: file, line: line)
            }
        }
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
        setField("Rent", to: "abc!@#", verifyNumeric: false)
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
        // Spend categories (from the template) are labeled "<name> Target" / "<name> Actual".
        setField("Mizrahi Actual", to: "5000")
        setField("1824 Actual", to: "5000")
        snapshot(name: "deficit-buffer")
        // The buffer hero is a single combined accessibility element ("Remaining buffer")
        // whose value includes the status, so query the combined element rather than a
        // standalone "Deficit buffer" StaticText.
        let buffer = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Remaining buffer")).firstMatch
        XCTAssertTrue(buffer.waitForExistence(timeout: 3), "Buffer hero element should exist")
        XCTAssertTrue(
            (buffer.value as? String ?? "").contains("Deficit"),
            "A negative remaining buffer should report a Deficit status (got '\(buffer.value as? String ?? "")')"
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

    // MARK: - Customizable categories

    private func transferCheckboxes() -> [XCUIElement] {
        app.checkBoxes.allElementsBoundByIndex.filter { $0.label.hasPrefix("Mark ") }
    }

    func test_carFundIsDefaultRoutingCategory() throws {
        // The Abarth → "Car fund" rename: a fresh month (from the template) includes a Car fund.
        XCTAssertTrue(
            app.checkBoxes["Mark Car fund transferred"].waitForExistence(timeout: 5),
            "A new month should include the default 'Car fund' routing category"
        )
    }

    func test_addFund_appendsRoutingRow() throws {
        let before = transferCheckboxes().count
        XCTAssertGreaterThan(before, 0, "Template should seed routing funds")
        let addButton = app.buttons["Add fund"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Wealth Engine should offer an Add fund button")
        addButton.click()
        snapshot(name: "after-add-fund")
        // A new "New fund" row should appear, raising the routing count by one.
        XCTAssertTrue(
            app.checkBoxes["Mark New fund transferred"].waitForExistence(timeout: 3),
            "Adding a fund should append a 'New fund' row"
        )
        XCTAssertEqual(transferCheckboxes().count, before + 1)
    }

    func test_removeFund_viaHoverTrashAndConfirm() throws {
        let hobby = app.checkBoxes["Mark Hobby Keren Kaspit transferred"]
        guard hobby.waitForExistence(timeout: 5) else {
            throw XCTSkip("Hobby fund not present to remove")
        }
        // Reveal the row's remove control by hovering, then remove and confirm.
        hobby.hover()
        let remove = app.buttons["Remove Hobby Keren Kaspit"]
        guard remove.waitForExistence(timeout: 3) else {
            throw XCTSkip("Hover-revealed remove control not reachable in this environment")
        }
        remove.click()
        let confirm = app.buttons["Remove"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3), "A destructive confirmation should appear")
        snapshot(name: "remove-fund-confirm")
        confirm.click()
        XCTAssertFalse(
            app.checkBoxes["Mark Hobby Keren Kaspit transferred"].waitForExistence(timeout: 3),
            "Confirming removal should delete the fund row"
        )
    }
}
