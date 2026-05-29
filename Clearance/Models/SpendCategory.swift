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
    var review: MonthlyReview?

    init(name: String, target: Double, actual: Double, sortOrder: Int) {
        self.id = UUID()
        self.name = name
        self.target = target
        self.actual = actual
        self.sortOrder = sortOrder
    }
}
