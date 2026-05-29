import Foundation
import SwiftData

/// A persistent sinking fund that spans months. Monthly routing rows (`RoutingCategory`)
/// contribute to it; spend rows (`SpendCategory`) can withdraw from it. Its balance is always
/// *derived* from that ledger — never snapshotted — so editing any month stays consistent:
///
///   balance = openingBalance
///           + Σ(contribution.target where fundID == id && didTransfer)
///           − Σ(withdrawal.actual  where fundID == id)
///
/// The fund holds the *canonical* name/rate that new months inherit; each month's row keeps its
/// own snapshot of name/rate, so renaming never rewrites history unless the user opts in.
@Model
final class Fund {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String = ""
    var openingBalance: Double = 0
    /// Default monthly contribution target that new months inherit.
    var defaultContribution: Double = 0
    var defaultRate: Double = 0
    /// Optional ultimate goal (for a progress indicator); nil = open-ended.
    var targetGoal: Double?
    /// Archived funds are hidden from new months but retained for historical balance math.
    var archived: Bool = false
    var sortOrder: Int = 0

    init(
        name: String,
        openingBalance: Double = 0,
        defaultContribution: Double,
        defaultRate: Double,
        targetGoal: Double? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.openingBalance = openingBalance
        self.defaultContribution = defaultContribution
        self.defaultRate = defaultRate
        self.targetGoal = targetGoal
        self.archived = false
        self.sortOrder = sortOrder
    }
}
