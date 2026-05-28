# Clearance

Clearance is a native macOS SwiftUI app for monthly zero-based cash-flow routing.

## Highlights

- SwiftData local persistence with no CloudKit or iCloud dependency.
- Settings window backed by `@AppStorage` for baseline routing targets.
- Native `NavigationSplitView` sidebar for historical months.
- File menu JSON export for readable local backups.
- Swift Charts insights for buffer trend, rolling 1824 average, and wealth velocity.

## Open

Open `Clearance.xcodeproj` in Xcode and run the `Clearance` scheme on macOS 14 or newer.

## UI tests

`ClearanceUITests` is an adversarial XCUITest suite that drives the real app
(against a throwaway in-memory store, so your data is never touched) and
screenshots each step. Run it with:

```sh
./run-ui-tests.sh
```

Screenshots and the result bundle land in `.qa-ui-review/`. The script keeps
build output outside `~/Documents` to avoid the macOS Documents-access prompt.
Three known issues are tracked as `XCTExpectFailure` markers in the tests:
the Month Routing summary is hidden in the narrow (single-column) layout, a
duplicate "View" menu appears in the menu bar, and the four Wealth-Engine amount
fields share the accessibility label "Amount".
