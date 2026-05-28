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

    init(
        monthKey: String,
        createdAt: Date = .now,
        income: Double,
        rent: Double,
        targetMizrahi: Double,
        target1824: Double,
        targetIIT: Double,
        targetEmergencyFund: Double,
        targetAbarthFund: Double,
        targetHobbyFund: Double,
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

    var remainingBuffer: Double {
        effectiveIncome - rent - actualMizrahi - actual1824
    }

    var combinedKerenKaspitTransfers: Double {
        targetEmergencyFund + targetAbarthFund + targetHobbyFund
    }

    var twelveMonthProjection: Double {
        (targetIIT * 12 * (1 + resolvedIITAnnualRate)) + (combinedKerenKaspitTransfers * 12 * (1 + resolvedKerenAnnualRate))
    }

    var resolvedIITAnnualRate: Double {
        iitAnnualRate > 0 ? iitAnnualRate : 0.08
    }

    var resolvedKerenAnnualRate: Double {
        kerenAnnualRate > 0 ? kerenAnnualRate : 0.0375
    }

    var resolvedIITTransferName: String {
        iitTransferName.isEmpty ? "IIT portfolio" : iitTransferName
    }

    var resolvedEmergencyFundName: String {
        emergencyFundName.isEmpty ? "Emergency Keren Kaspit" : emergencyFundName
    }

    var resolvedAbarthFundName: String {
        abarthFundName.isEmpty ? "Abarth Keren Kaspit" : abarthFundName
    }

    var resolvedHobbyFundName: String {
        hobbyFundName.isEmpty ? "Hobby Keren Kaspit" : hobbyFundName
    }

    var totalWealthRouted: Double {
        let iit = didTransferIIT ? targetIIT : 0
        let emergency = didTransferEmergencyFund ? targetEmergencyFund : 0
        let abarth = didTransferAbarthFund ? targetAbarthFund : 0
        let hobby = didTransferHobbyFund ? targetHobbyFund : 0
        return iit + emergency + abarth + hobby
    }

    var plannedWealthRoutingTotal: Double {
        targetIIT + targetEmergencyFund + targetAbarthFund + targetHobbyFund
    }

    var pendingWealthRoutingTotal: Double {
        max(0, plannedWealthRoutingTotal - totalWealthRouted)
    }

    var completedTransferCount: Int {
        [didTransferIIT, didTransferEmergencyFund, didTransferAbarthFund, didTransferHobbyFund]
            .filter { $0 }
            .count
    }

    static let totalTransferCount = 4

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
