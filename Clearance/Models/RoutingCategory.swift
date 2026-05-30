import Foundation
import SwiftData

/// A Wealth-Engine routing fund for a single month: a named target to transfer, whether it
/// has been transferred yet, and its own annual growth-rate assumption for the projection.
@Model
final class RoutingCategory {
    var id: UUID = UUID()
    var name: String = ""
    var target: Double = 0
    var didTransfer: Bool = false
    var annualRate: Double = 0
    var sortOrder: Int = 0
    /// Links this monthly contribution to its persistent `Fund` (nil before sinking funds existed).
    var fundID: UUID?
    var review: MonthlyReview?

    init(name: String, target: Double, didTransfer: Bool = false, annualRate: Double, sortOrder: Int, fundID: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.target = target
        self.didTransfer = didTransfer
        self.annualRate = annualRate
        self.sortOrder = sortOrder
        self.fundID = fundID
    }
}
