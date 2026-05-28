import SwiftData
import SwiftUI

@main
@MainActor
struct ClearanceApp: App {
    @StateObject private var appModel = ClearanceAppModel()
    @StateObject private var zoomController = AppZoomController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .dynamicTypeSize(zoomController.dynamicTypeSize)
                .environment(\.appZoomScale, zoomController.scale)
        }
        .modelContainer(appModel.modelContainer)
        .defaultSize(width: 1120, height: 780)
        .commands {
            CommandGroup(after: .saveItem) {
                Button("Export to JSON...") {
                    appModel.exportManager.exportMonthlyReviews()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }

            // Merge zoom commands into the system "View" menu. Using CommandMenu("View")
            // would append a SECOND "View" menu to the menu bar.
            CommandGroup(after: .toolbar) {
                Divider()
                Button("Zoom In") {
                    zoomController.zoomIn()
                }
                .keyboardShortcut("+", modifiers: [.command])

                Button("Zoom Out") {
                    zoomController.zoomOut()
                }
                .keyboardShortcut("-", modifiers: [.command])

                Button("Actual Size") {
                    zoomController.reset()
                }
                .keyboardShortcut("0", modifiers: [.command])
            }
        }

        Settings {
            SettingsView()
        }
    }
}
