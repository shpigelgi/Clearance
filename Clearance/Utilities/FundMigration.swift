import Foundation
import SwiftData

/// Establishes the persistent `Fund` list and links existing routing rows to it. Idempotent:
/// seeds Funds from the routing defaults only when none exist, then links any unlinked
/// `RoutingCategory` to a Fund by name (creating one for unmatched historical names).
/// Runs once per launch after `CategoryBackfill`.
@MainActor
enum FundMigration {
    static func run(in context: ModelContext) {
        do {
            let existing = try context.fetch(FetchDescriptor<Fund>())
            if existing.isEmpty {
                for (index, template) in CategoryTemplateStore.defaultRouting.enumerated() {
                    context.insert(Fund(
                        name: template.name,
                        defaultContribution: template.target,
                        defaultRate: template.annualRate,
                        sortOrder: index
                    ))
                }
            }

            var byName = Dictionary(
                try context.fetch(FetchDescriptor<Fund>()).map { ($0.name, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            var nextSort = (byName.values.map(\.sortOrder).max() ?? -1) + 1

            let rows = try context.fetch(FetchDescriptor<RoutingCategory>())
            var didChange = existing.isEmpty
            for row in rows where row.fundID == nil {
                let fund: Fund
                if let match = byName[row.name] {
                    fund = match
                } else {
                    fund = Fund(name: row.name, defaultContribution: row.target, defaultRate: row.annualRate, sortOrder: nextSort)
                    nextSort += 1
                    context.insert(fund)
                    byName[row.name] = fund
                }
                row.fundID = fund.id
                didChange = true
            }

            if didChange { try context.save() }
        } catch {
            assertionFailure("Fund migration failed: \(error)")
        }
    }
}
