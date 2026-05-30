import Foundation
import SwiftData
import SwiftUI

@MainActor
final class ClearanceAppModel: ObservableObject {
    let modelContainer: ModelContainer
    let exportManager: DataExportManager

    init() {
        do {
            let schema = Schema([MonthlyReview.self, SpendCategory.self, RoutingCategory.self, Fund.self])
            // UI tests launch with CLEARANCE_UITEST_INMEMORY=1 so the suite runs
            // against a throwaway in-memory store and never touches real data.
            let inMemoryOnly = ProcessInfo.processInfo.environment["CLEARANCE_UITEST_INMEMORY"] == "1"
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: inMemoryOnly,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])

            modelContainer = container
            exportManager = DataExportManager(modelContainer: container)

            // Seed dynamic categories for any pre-existing months (idempotent, non-destructive),
            // then establish the persistent Fund list and link routing rows to it.
            CategoryBackfill.run(in: container.mainContext)
            FundMigration.run(in: container.mainContext)
        } catch {
            fatalError("Unable to create SwiftData model container: \(error)")
        }
    }
}
