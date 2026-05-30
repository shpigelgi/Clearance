import AppKit
import Combine
import Foundation
import SwiftData
import UniformTypeIdentifiers

@MainActor
final class DataExportManager: ObservableObject {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func exportMonthlyReviews() {
        do {
            let context = modelContainer.mainContext
            if context.hasChanges {
                try context.save()
            }

            let descriptor = FetchDescriptor<MonthlyReview>(
                sortBy: [SortDescriptor(\.monthKey, order: .forward)]
            )

            let reviews = try context.fetch(descriptor)
            let funds = try context.fetch(FetchDescriptor<Fund>(sortBy: [SortDescriptor(\.sortOrder)]))
            let ledger = FundLedger(
                contributions: try context.fetch(FetchDescriptor<RoutingCategory>()),
                withdrawals: try context.fetch(FetchDescriptor<SpendCategory>())
            )
            let payload = ClearanceExport(
                funds: funds.map { FundExportRecord(fund: $0, balance: ledger.balance(of: $0)) },
                months: reviews.map(MonthlyReviewExportRecord.init(review:))
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601

            let data = try encoder.encode(payload)
            guard let url = Self.destinationURL() else { return }
            try data.write(to: url, options: .atomic)
        } catch {
            Self.presentExportError(error)
        }
    }

    private static func destinationURL() -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = "Clearance-Export-\(Formatters.exportDateStamp()).json"
        panel.title = "Export Clearance Data"
        panel.message = "Choose where to save a readable JSON backup of your monthly reviews."

        return panel.runModal() == .OK ? panel.url : nil
    }

    private static func presentExportError(_ error: Error) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Export Failed"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}

/// Top-level export: the persistent funds (with current balances) plus every month.
struct ClearanceExport: Codable {
    let funds: [FundExportRecord]
    let months: [MonthlyReviewExportRecord]
}

struct FundExportRecord: Codable {
    let id: UUID
    let name: String
    let openingBalance: Double
    let defaultContribution: Double
    let defaultRate: Double
    let targetGoal: Double?
    let archived: Bool
    let balance: Double

    init(fund: Fund, balance: Double) {
        id = fund.id
        name = fund.name
        openingBalance = fund.openingBalance
        defaultContribution = fund.defaultContribution
        defaultRate = fund.defaultRate
        targetGoal = fund.targetGoal
        archived = fund.archived
        self.balance = balance
    }
}

struct MonthlyReviewExportRecord: Codable {
    struct SpendRecord: Codable {
        let name: String
        let target: Double
        let actual: Double
        let fundID: UUID?
    }

    struct RoutingRecord: Codable {
        let name: String
        let target: Double
        let didTransfer: Bool
        let annualRate: Double
        let fundID: UUID?
    }

    let monthKey: String
    let createdAt: Date
    let income: Double
    let effectiveIncome: Double
    let baselineWorkDays: Double
    let calculatesIncomeFromDays: Bool
    let daysWorked: Double
    let incomePerWorkday: Double
    let rent: Double
    let spendCategories: [SpendRecord]
    let routingCategories: [RoutingRecord]
    let remainingBuffer: Double
    let twelveMonthProjection: Double
    let totalWealthRouted: Double

    init(review: MonthlyReview) {
        monthKey = review.monthKey
        createdAt = review.createdAt
        income = review.income
        effectiveIncome = review.effectiveIncome
        baselineWorkDays = review.baselineWorkDays
        calculatesIncomeFromDays = review.calculatesIncomeFromDays
        daysWorked = review.daysWorked
        incomePerWorkday = review.incomePerWorkday
        rent = review.rent
        spendCategories = review.sortedSpendCategories.map {
            SpendRecord(name: $0.name, target: $0.target, actual: $0.actual, fundID: $0.fundID)
        }
        routingCategories = review.sortedRoutingCategories.map {
            RoutingRecord(name: $0.name, target: $0.target, didTransfer: $0.didTransfer, annualRate: $0.annualRate, fundID: $0.fundID)
        }
        remainingBuffer = review.remainingBuffer
        twelveMonthProjection = review.twelveMonthProjection
        totalWealthRouted = review.totalWealthRouted
    }
}
