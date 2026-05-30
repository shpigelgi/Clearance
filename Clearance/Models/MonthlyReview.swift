import Foundation
import SwiftData

@Model
final class MonthlyReview {
    @Attribute(.unique) var monthKey: String
    var createdAt: Date

    var income: Double
    var rent: Double
    var targetMizrahi: Double
    var target1824: Double
    var targetIIT: Double
    var targetEmergencyFund: Double
    var targetAbarthFund: Double
    var targetHobbyFund: Double
    var iitTransferName: String = "IIT portfolio"
    var emergencyFundName: String = "Emergency Keren Kaspit"
    var abarthFundName: String = "Abarth Keren Kaspit"
    var hobbyFundName: String = "Hobby Keren Kaspit"
    var iitAnnualRate: Double = 0.08
    var kerenAnnualRate: Double = 0.0375
    var baselineWorkDays: Double = 22

    var calculatesIncomeFromDays: Bool = false
    var daysWorked: Double = 22
    var incomePerWorkday: Double = 0

    var actualMizrahi: Double
    var actual1824: Double

    var didTransferIIT: Bool
    var didTransferEmergencyFund: Bool
    var didTransferAbarthFund: Bool
    var didTransferHobbyFund: Bool

    // Dynamic, user-customizable categories. The scalar fields above are retained (deprecated)
    // only so existing stores migrate losslessly and CategoryBackfill can seed these from them.
    @Relationship(deleteRule: .cascade, inverse: \SpendCategory.review)
    var spendCategories: [SpendCategory] = []

    @Relationship(deleteRule: .cascade, inverse: \RoutingCategory.review)
    var routingCategories: [RoutingCategory] = []

    init(
        monthKey: String,
        createdAt: Date = .now,
        income: Double,
        rent: Double,
        targetMizrahi: Double = 0,
        target1824: Double = 0,
        targetIIT: Double = 0,
        targetEmergencyFund: Double = 0,
        targetAbarthFund: Double = 0,
        targetHobbyFund: Double = 0,
        iitTransferName: String = "IIT portfolio",
        emergencyFundName: String = "Emergency Keren Kaspit",
        abarthFundName: String = "Abarth Keren Kaspit",
        hobbyFundName: String = "Hobby Keren Kaspit",
        iitAnnualRate: Double = 0.08,
        kerenAnnualRate: Double = 0.0375,
        baselineWorkDays: Double = 22,
        calculatesIncomeFromDays: Bool = false,
        daysWorked: Double? = nil,
        incomePerWorkday: Double? = nil,
        actualMizrahi: Double? = nil,
        actual1824: Double? = nil,
        didTransferIIT: Bool = false,
        didTransferEmergencyFund: Bool = false,
        didTransferAbarthFund: Bool = false,
        didTransferHobbyFund: Bool = false
    ) {
        self.monthKey = monthKey
        self.createdAt = createdAt
        self.income = income
        self.rent = rent
        self.targetMizrahi = targetMizrahi
        self.target1824 = target1824
        self.targetIIT = targetIIT
        self.targetEmergencyFund = targetEmergencyFund
        self.targetAbarthFund = targetAbarthFund
        self.targetHobbyFund = targetHobbyFund
        self.iitTransferName = iitTransferName
        self.emergencyFundName = emergencyFundName
        self.abarthFundName = abarthFundName
        self.hobbyFundName = hobbyFundName
        self.iitAnnualRate = iitAnnualRate
        self.kerenAnnualRate = kerenAnnualRate
        self.baselineWorkDays = baselineWorkDays
        self.calculatesIncomeFromDays = calculatesIncomeFromDays
        self.daysWorked = daysWorked ?? baselineWorkDays
        self.incomePerWorkday = incomePerWorkday ?? (baselineWorkDays > 0 ? income / baselineWorkDays : 0)
        self.actualMizrahi = actualMizrahi ?? targetMizrahi
        self.actual1824 = actual1824 ?? target1824
        self.didTransferIIT = didTransferIIT
        self.didTransferEmergencyFund = didTransferEmergencyFund
        self.didTransferAbarthFund = didTransferAbarthFund
        self.didTransferHobbyFund = didTransferHobbyFund
    }
}

extension MonthlyReview {
    var effectiveIncome: Double {
        calculatesIncomeFromDays ? daysWorked * incomePerWorkday : income
    }

    // Categories sorted for stable display/iteration.
    var sortedSpendCategories: [SpendCategory] {
        spendCategories.sorted { $0.sortOrder < $1.sortOrder }
    }

    var sortedRoutingCategories: [RoutingCategory] {
        routingCategories.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Only spend funded by *this month's income* counts against the buffer. Rows tagged to a
    /// Fund (`fundID != nil`) are withdrawals from pre-saved money and are netted there instead.
    var totalActualSpend: Double {
        spendCategories.reduce(0) { $0 + ($1.fundID == nil ? $1.actual : 0) }
    }

    var remainingBuffer: Double {
        effectiveIncome - rent - totalActualSpend
    }

    var twelveMonthProjection: Double {
        routingCategories.reduce(0.0) { partial, category in
            let annual = category.target * 12.0
            return partial + annual * (1.0 + category.annualRate)
        }
    }

    var totalWealthRouted: Double {
        routingCategories.reduce(0.0) { partial, category in
            partial + (category.didTransfer ? category.target : 0)
        }
    }

    var plannedWealthRoutingTotal: Double {
        routingCategories.reduce(0.0) { $0 + $1.target }
    }

    var pendingWealthRoutingTotal: Double {
        max(0, plannedWealthRoutingTotal - totalWealthRouted)
    }

    var completedTransferCount: Int {
        routingCategories.filter(\.didTransfer).count
    }

    var totalTransferCount: Int {
        routingCategories.count
    }

    /// Next sort index for appending a new category to either collection.
    func nextSpendSortOrder() -> Int { (spendCategories.map(\.sortOrder).max() ?? -1) + 1 }
    func nextRoutingSortOrder() -> Int { (routingCategories.map(\.sortOrder).max() ?? -1) + 1 }

    static func monthKey(for date: Date = .now, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        let year = components.year ?? 1970
        let month = components.month ?? 1
        return monthKey(year: year, month: month)
    }

    static func monthKey(year: Int, month: Int) -> String {
        return String(format: "%04d-%02d", year, month)
    }
}
