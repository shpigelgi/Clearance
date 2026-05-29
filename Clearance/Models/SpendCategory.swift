import Foundation
import SwiftData

/// A Clearance-Check "card spend" line for a single month: a named outflow with a
/// planned target and the actual amount spent. Actuals reduce the month's remaining buffer.
@Model
final class SpendCategory {
    var id: UUID = UUID()
    var name: String = ""
    var target: Double = 0
    var actual: Double = 0
    var sortOrder: Int = 0
    /// If set, this spend row is a *withdrawal* from that `Fund`: its `actual` is deducted
    /// from the fund balance and excluded from the month's remaining buffer.
    var fundID: UUID?
    var review: MonthlyReview?

    init(name: String, target: Double, actual: Double, sortOrder: Int, fundID: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.target = target
        self.actual = actual
        self.sortOrder = sortOrder
        self.fundID = fundID
    }
}
