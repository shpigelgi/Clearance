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
            let payload = reviews.map(MonthlyReviewExportRecord.init(review:))

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

struct MonthlyReviewExportRecord: Codable {
    let monthKey: String
    let createdAt: Date
    let income: Double
    let effectiveIncome: Double
    let baselineWorkDays: Double
    let calculatesIncomeFromDays: Bool
    let daysWorked: Double
    let incomePerWorkday: Double
    let rent: Double
    let targetMizrahi: Double
    let target1824: Double
    let targetIIT: Double
    let targetEmergencyFund: Double
    let targetAbarthFund: Double
    let targetHobbyFund: Double
    let iitTransferName: String
    let emergencyFundName: String
    let abarthFundName: String
    let hobbyFundName: String
    let iitAnnualRate: Double
    let kerenAnnualRate: Double
    let actualMizrahi: Double
    let actual1824: Double
    let didTransferIIT: Bool
    let didTransferEmergencyFund: Bool
    let didTransferAbarthFund: Bool
    let didTransferHobbyFund: Bool
    let remainingBuffer: Double
    let combinedKerenKaspitTransfers: Double
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
        targetMizrahi = review.targetMizrahi
        target1824 = review.target1824
        targetIIT = review.targetIIT
        targetEmergencyFund = review.targetEmergencyFund
        targetAbarthFund = review.targetAbarthFund
        targetHobbyFund = review.targetHobbyFund
        iitTransferName = review.resolvedIITTransferName
        emergencyFundName = review.resolvedEmergencyFundName
        abarthFundName = review.resolvedAbarthFundName
        hobbyFundName = review.resolvedHobbyFundName
        iitAnnualRate = review.iitAnnualRate
        kerenAnnualRate = review.kerenAnnualRate
        actualMizrahi = review.actualMizrahi
        actual1824 = review.actual1824
        didTransferIIT = review.didTransferIIT
        didTransferEmergencyFund = review.didTransferEmergencyFund
        didTransferAbarthFund = review.didTransferAbarthFund
        didTransferHobbyFund = review.didTransferHobbyFund
        remainingBuffer = review.remainingBuffer
        combinedKerenKaspitTransfers = review.combinedKerenKaspitTransfers
        twelveMonthProjection = review.twelveMonthProjection
        totalWealthRouted = review.totalWealthRouted
    }
}
