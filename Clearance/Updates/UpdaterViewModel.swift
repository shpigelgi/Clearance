import Sparkle
import SwiftUI

/// Owns the Sparkle updater controller and exposes its state to SwiftUI.
///
/// `SPUStandardUpdaterController(startingUpdater: true)` reads `SUFeedURL` and
/// `SUPublicEDKey` from the app's Info.plist, begins scheduled background checks,
/// and presents Sparkle's standard update UI — so the app writes no update UI itself.
@MainActor
final class UpdaterViewModel: ObservableObject {
    private let controller: SPUStandardUpdaterController

    /// Mirrors `updater.canCheckForUpdates` so menu items / buttons can disable
    /// themselves while a check is already in flight.
    @Published var canCheckForUpdates = false

    init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        controller.updater.checkForUpdates()
    }
}
