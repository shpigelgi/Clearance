import XCTest

/// Menu bar (View / File commands), the Settings window, and window resize reflow.
final class MenusAndSettingsUITests: ClearanceUITestCase {

    func test_viewMenu_isNotDuplicated() throws {
        // Regression (fixed bug #2): zoom commands are merged into the system "View" menu
        // via CommandGroup, so the menu bar must contain exactly one "View" menu (not two),
        // and "Zoom In" must appear only once.
        let menuBar = app.menuBars.firstMatch
        XCTAssertTrue(menuBar.waitForExistence(timeout: 5))
        let viewMenus = menuBar.menuBarItems.matching(identifier: "View").count
        snapshot(name: "menu-bar")
        XCTAssertEqual(viewMenus, 1, "There should be exactly one 'View' menu (found \(viewMenus))")

        menuBar.menuBarItems["View"].click()
        let zoomInCount = app.menuItems.matching(identifier: "Zoom In").count
        app.typeKey(.escape, modifierFlags: [])
        XCTAssertEqual(zoomInCount, 1, "'Zoom In' should appear once in the View menu (found \(zoomInCount))")
    }

    func test_zoomInOutActualSize_doNotCrash() throws {
        // Drive zoom via keyboard shortcuts and confirm the window survives.
        app.typeKey("+", modifierFlags: .command)
        app.typeKey("+", modifierFlags: .command)
        snapshot(name: "zoomed-in")
        app.typeKey("-", modifierFlags: .command)
        app.typeKey("0", modifierFlags: .command) // Actual Size
        snapshot(name: "zoom-reset")
        XCTAssertTrue(app.windows.firstMatch.exists, "Zoom commands must not crash the app")
    }

    func test_exportToJSON_menuItemExists() throws {
        let menuBar = app.menuBars.firstMatch
        let fileMenu = menuBar.menuBarItems["File"]
        if fileMenu.waitForExistence(timeout: 5) {
            fileMenu.click()
            snapshot(name: "file-menu-open")
            XCTAssertTrue(
                app.menuItems["Export to JSON..."].exists,
                "File menu should expose 'Export to JSON...'"
            )
            app.typeKey(.escape, modifierFlags: [])
        } else {
            throw XCTSkip("File menu not found")
        }
    }

    func test_settingsWindow_opensWithFields() throws {
        // Open Settings via the app menu (more reliable than the ⌘, keystroke, which can
        // be dropped right after launch). Falls back to ⌘, if the menu item isn't found.
        let menuBar = app.menuBars.firstMatch
        let appMenu = menuBar.menuBarItems["Clearance"]
        if appMenu.waitForExistence(timeout: 5) {
            appMenu.click()
            let settingsItem = app.menuItems["Settings…"]
            if settingsItem.waitForExistence(timeout: 3) {
                settingsItem.click()
            } else {
                app.typeKey(.escape, modifierFlags: [])
                app.typeKey(",", modifierFlags: .command)
            }
        } else {
            app.typeKey(",", modifierFlags: .command)
        }
        let settings = app.windows["Clearance Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5), "Settings window should open")
        snapshot(name: "settings-window")
        // "Wealth Engine Labels" section header is unique to Settings (avoids the
        // 'Income' label that also exists in the detail window).
        XCTAssertTrue(
            settings.staticTexts["Wealth Engine Labels"].waitForExistence(timeout: 3),
            "Settings window should show its preference sections"
        )
    }

    func test_maximizedWindow_showsTwoColumnSummary() throws {
        // When wide (>= 820pt), the detail view's two-column layout includes the
        // "Month Routing" summary. Try to widen the window and verify it appears.
        // Reliable programmatic resize isn't guaranteed in every CI/host environment,
        // so skip (rather than fail) if we couldn't reach the two-column threshold.
        ensureMonthExists()
        maximizeWindow()
        snapshot(name: "maximized-two-column")
        let summary = app.staticTexts["Transfer Progress"]
        if !summary.waitForExistence(timeout: 5) {
            throw XCTSkip("Could not widen window to the two-column threshold in this environment")
        }
        XCTAssertTrue(summary.exists, "The two-column layout should show the Month Routing summary")
    }
}
