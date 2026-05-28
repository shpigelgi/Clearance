import XCTest

/// Base class: launches Clearance against a throwaway in-memory SwiftData store
/// (CLEARANCE_UITEST_INMEMORY=1) so adversarial tests never touch real data.
/// Captures a screenshot attachment after every test for visual review.
class ClearanceUITestCase: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchEnvironment["CLEARANCE_UITEST_INMEMORY"] = "1"
        app.launch()
    }

    override func tearDownWithError() throws {
        snapshot(name: "final-\(self.name)")
        app.terminate()
    }

    /// Attach a full-window screenshot to the test results.
    @discardableResult
    func snapshot(name: String) -> XCTAttachment {
        let shot = app.windows.firstMatch.exists
            ? app.windows.firstMatch.screenshot()
            : XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        return attachment
    }

    /// Ensure at least one month exists and is selected.
    @discardableResult
    func ensureMonthExists() -> Bool {
        let startButton = app.buttons["Start New Month"]
        guard startButton.waitForExistence(timeout: 10) else { return false }
        if firstMonthRow() == nil {
            startButton.click()
        }
        return true
    }

    /// Widen the main window so the detail view uses its two-column layout.
    /// The detail reflows to a single column below ~820pt (hiding the "Month Routing"
    /// summary), so tests that need the full layout must run wide. The green zoom
    /// button is unreliable (the window restores a saved frame), so drag the
    /// bottom-right resize corner outward deterministically.
    func maximizeWindow() {
        let window = app.windows.firstMatch
        guard window.waitForExistence(timeout: 5) else { return }
        let corner = window.coordinate(withNormalizedOffset: CGVector(dx: 1.0, dy: 1.0))
        let target = corner.withOffset(CGVector(dx: 600, dy: 250))
        corner.press(forDuration: 0.3, thenDragTo: target)
    }

    /// Best-effort lookup of the first sidebar month row across possible AX containers.
    func firstMonthRow() -> XCUIElement? {
        for query in [app.outlines.firstMatch.cells,
                      app.tables.firstMatch.cells,
                      app.cells] {
            if query.count > 0 { return query.element(boundBy: 0) }
        }
        return nil
    }
}
