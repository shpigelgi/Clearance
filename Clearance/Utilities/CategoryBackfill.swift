import Foundation
import SwiftData

/// One-time, idempotent migration: seeds the new dynamic `spendCategories` / `routingCategories`
/// from the legacy scalar fields for any month that doesn't have categories yet. The legacy
/// scalars are left intact, so this is non-destructive and safe to re-run.
@MainActor
enum CategoryBackfill {
    static func run(in context: ModelContext) {
        do {
            let reviews = try context.fetch(FetchDescriptor<MonthlyReview>())
            var didChange = false
            for review in reviews where review.spendCategories.isEmpty && review.routingCategories.isEmpty {
                seed(review, in: context)
                didChange = true
            }
            if didChange {
                try context.save()
            }
        } catch {
            // Non-fatal: legacy scalars remain the source of truth and we retry next launch.
            assertionFailure("Category backfill failed: \(error)")
        }
    }

    private static func seed(_ review: MonthlyReview, in context: ModelContext) {
        let spend = [
            SpendCategory(name: "Mizrahi", target: review.targetMizrahi, actual: review.actualMizrahi, sortOrder: 0),
            SpendCategory(name: "1824", target: review.target1824, actual: review.actual1824, sortOrder: 1),
        ]

        let iitRate = review.iitAnnualRate > 0 ? review.iitAnnualRate : 0.08
        let kerenRate = review.kerenAnnualRate > 0 ? review.kerenAnnualRate : 0.0375
        let routing = [
            RoutingCategory(name: name(review.iitTransferName, "IIT portfolio"), target: review.targetIIT, didTransfer: review.didTransferIIT, annualRate: iitRate, sortOrder: 0),
            RoutingCategory(name: name(review.emergencyFundName, "Emergency Keren Kaspit"), target: review.targetEmergencyFund, didTransfer: review.didTransferEmergencyFund, annualRate: kerenRate, sortOrder: 1),
            RoutingCategory(name: name(review.abarthFundName, "Abarth Keren Kaspit"), target: review.targetAbarthFund, didTransfer: review.didTransferAbarthFund, annualRate: kerenRate, sortOrder: 2),
            RoutingCategory(name: name(review.hobbyFundName, "Hobby Keren Kaspit"), target: review.targetHobbyFund, didTransfer: review.didTransferHobbyFund, annualRate: kerenRate, sortOrder: 3),
        ]

        spend.forEach(context.insert)
        routing.forEach(context.insert)
        review.spendCategories = spend
        review.routingCategories = routing
    }

    private static func name(_ value: String, _ fallback: String) -> String {
        value.isEmpty ? fallback : value
    }
}
