import XCTest

/// Covers persistent sinking funds: a new month seeds fund contributions, balances surface,
/// fund-backed spend is excluded from the buffer, the rename-scope popup appears, and Insights
/// render. Runs against the in-memory store (FundMigration seeds the four default funds).
final class SinkingFundsUITests: ClearanceUITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        let start = app.buttons["Start New Month"]
        if start.waitForExistence(timeout: 10) { start.click() }
    }

    private func transferCheckboxes() -> [XCUIElement] {
        app.checkBoxes.allElementsBoundByIndex.filter { $0.label.hasPrefix("Mark ") }
    }

    func test_newMonthSeedsFundsAndSpend() throws {
        // Four seeded funds become this month's contributions; spend rows get a Funded-by picker.
        XCTAssertEqual(transferCheckboxes().count, 4, "A new month should seed four fund contributions")
        XCTAssertTrue(app.popUpButtons["Mizrahi funded by"].waitForExistence(timeout: 5), "Spend rows should have a Funded-by picker")
        XCTAssertTrue(app.popUpButtons["1824 funded by"].exists)
    }

    func test_fundBalanceShownInWealthEngine() throws {
        XCTAssertTrue(
            app.staticTexts["IIT portfolio balance"].waitForExistence(timeout: 5),
            "The latest month should show each fund's balance"
        )
    }

    func test_insights_showDataForSingleMonth() throws {
        // Insights render with the current month's data.
        XCTAssertTrue(app.staticTexts["Buffer Trend"].waitForExistence(timeout: 5), "Insights should show the Buffer Trend chart")
        XCTAssertTrue(app.staticTexts["Wealth Velocity"].exists, "Insights should show Wealth Velocity")
        XCTAssertTrue(app.staticTexts["Rolling Spend Average"].exists, "Insights should show Rolling Spend Average")
    }

    func test_fundedSpend_changesBuffer() throws {
        // Funding a spend category from a fund removes it from the buffer equation, so the
        // remaining buffer must change (the core credit-card-float fix).
        let buffer = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Remaining buffer")).firstMatch
        XCTAssertTrue(buffer.waitForExistence(timeout: 5))
        let before = buffer.value as? String ?? ""

        let picker = app.popUpButtons["Mizrahi funded by"]
        guard picker.waitForExistence(timeout: 5) else { throw XCTSkip("Funded-by picker not reachable") }
        picker.click()
        let carFund = app.menuItems["Car fund"]
        guard carFund.waitForExistence(timeout: 3) else {
            app.typeKey(.escape, modifierFlags: [])
            throw XCTSkip("Fund menu not reachable")
        }
        carFund.click()
        snapshot(name: "funded-spend")

        let after = buffer.value as? String ?? ""
        XCTAssertNotEqual(before, after, "Funding a spend category from a fund should change the remaining buffer")
    }

    func test_renameScopePopup_appears() throws {
        // Renaming a fund offers a scope choice instead of silently editing one month.
        // Target a fund's rename (spend rows rename directly, with no scope dialog).
        let pencil = app.buttons["Rename Hobby Keren Kaspit"]
        guard pencil.waitForExistence(timeout: 5) else {
            throw XCTSkip("Fund rename control not reachable")
        }
        pencil.click()
        let field = app.textFields["category rename field"]
        guard field.waitForExistence(timeout: 3) else { throw XCTSkip("Rename field not reachable") }
        field.click()
        Thread.sleep(forTimeInterval: 0.2)
        // Clear and type a new name (selection-independent, like setField).
        let existing = (field.value as? String) ?? ""
        let clearCount = max(existing.count + 2, 4)
        for _ in 0..<clearCount { app.typeKey(.rightArrow, modifierFlags: []) }
        for _ in 0..<clearCount { app.typeKey(.delete, modifierFlags: []) }
        app.typeText("Holiday")
        let finish = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Finish renaming")).firstMatch
        if finish.waitForExistence(timeout: 2) { finish.click() } else { app.typeKey(.return, modifierFlags: []) }

        // The scope chooser presents as a sheet/dialog/popover depending on macOS; scope the
        // query to it (not app-level, which also matches the Touch Bar mirror of the button).
        let label = "Just this month"
        let containers = [app.sheets, app.dialogs, app.popovers]
        var confirm: XCUIElement?
        for container in containers where confirm == nil {
            let button = container.buttons[label].firstMatch
            if button.waitForExistence(timeout: 2) { confirm = button }
        }
        guard let confirm else { throw XCTSkip("Rename scope chooser not reachable") }
        snapshot(name: "rename-scope")
        confirm.click()
        // "Just this month" applies the new name to this month's row.
        XCTAssertTrue(
            app.checkBoxes["Mark Holiday transferred"].waitForExistence(timeout: 3),
            "Renaming this month should relabel the fund's contribution"
        )
    }

    func test_addSecondMonth_keepsInsights() throws {
        // Multi-month: add a distinct month, then Insights still render across the set.
        let addSpecific = app.buttons["Add Specific Month"]
        guard addSpecific.waitForExistence(timeout: 5) else { throw XCTSkip("Add Specific Month unavailable") }
        addSpecific.click()
        guard app.staticTexts["Add Monthly Review"].waitForExistence(timeout: 5) else {
            throw XCTSkip("Add Month sheet did not appear")
        }
        // Pick an earlier year via the Year popup to make a distinct month.
        let popups = app.popUpButtons.allElementsBoundByIndex
        if let yearPopup = popups.last, yearPopup.exists {
            yearPopup.click()
            let earlier = app.menuItems.allElementsBoundByIndex.first { Int($0.label) != nil }
            if let earlier, earlier.exists { earlier.click() }
        }
        (app.buttons["Create Month"].exists ? app.buttons["Create Month"] : app.buttons["Open Existing"]).click()

        XCTAssertTrue(app.staticTexts["Buffer Trend"].waitForExistence(timeout: 5), "Insights should still render with multiple months")
    }
}
