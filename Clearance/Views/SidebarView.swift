import SwiftData
import SwiftUI

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\MonthlyReview.monthKey, order: .reverse)])
    private var reviews: [MonthlyReview]

    @Query(sort: [SortDescriptor(\Fund.sortOrder)])
    private var funds: [Fund]

    @Binding var selection: String?

    @AppStorage(ClearanceSettings.incomeKey) private var income = ClearanceSettings.defaultIncome
    @AppStorage(ClearanceSettings.baselineWorkDaysKey) private var baselineWorkDays = ClearanceSettings.defaultBaselineWorkDays
    @AppStorage(ClearanceSettings.rentKey) private var rent = ClearanceSettings.defaultRent

    @EnvironmentObject private var templateStore: CategoryTemplateStore

    @State private var isAddingMonth = false
    @State private var retroactiveMonth = Calendar.current.component(.month, from: .now)
    @State private var retroactiveYear = Calendar.current.component(.year, from: .now)
    @State private var reviewPendingDeletion: MonthlyReview?
    @State private var sidebarError: SidebarError?

    var body: some View {
        List(selection: $selection) {
            Section("Months") {
                ForEach(reviews) { review in
                    MonthRow(review: review)
                        .tag(review.monthKey)
                        .contextMenu {
                            Button("Delete Month...", role: .destructive) {
                                reviewPendingDeletion = review
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: startNewMonth) {
                    Label("Start New Month", systemImage: "plus")
                }
                .help("Start New Month")

                Button(action: showAddMonthSheet) {
                    Label("Add Specific Month", systemImage: "calendar.badge.plus")
                }
                .help("Add Specific Month")
            }
        }
        .alert(
            "Delete \(reviewPendingDeletion.map { Formatters.monthTitle(from: $0.monthKey) } ?? "Month")?",
            isPresented: deleteConfirmationBinding,
            presenting: reviewPendingDeletion
        ) { review in
            Button("Delete", role: .destructive) {
                delete(review)
            }
            Button("Cancel", role: .cancel) {
                reviewPendingDeletion = nil
            }
        } message: { _ in
            Text("This permanently removes the monthly review from local SwiftData storage. Export JSON first if you need a backup.")
        }
        .alert(item: $sidebarError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $isAddingMonth) {
            AddMonthSheet(
                selectedMonth: $retroactiveMonth,
                selectedYear: $retroactiveYear,
                monthExists: reviews.contains(where: { $0.monthKey == MonthlyReview.monthKey(year: retroactiveYear, month: retroactiveMonth) }),
                onCancel: {
                    isAddingMonth = false
                },
                onCreate: {
                    createMonth(monthKey: MonthlyReview.monthKey(year: retroactiveYear, month: retroactiveMonth))
                    isAddingMonth = false
                }
            )
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding {
            reviewPendingDeletion != nil
        } set: { isPresented in
            if !isPresented {
                reviewPendingDeletion = nil
            }
        }
    }

    private func startNewMonth() {
        createMonth(monthKey: MonthlyReview.monthKey())
    }

    private func showAddMonthSheet() {
        let components = Calendar.current.dateComponents([.year, .month], from: .now)
        retroactiveMonth = components.month ?? retroactiveMonth
        retroactiveYear = components.year ?? retroactiveYear
        isAddingMonth = true
    }

    private func createMonth(monthKey: String) {
        if reviews.contains(where: { $0.monthKey == monthKey }) {
            selection = monthKey
            return
        }

        let review = MonthlyReview(
            monthKey: monthKey,
            income: income,
            rent: rent,
            baselineWorkDays: baselineWorkDays
        )

        // New months inherit spend categories from the template and one routing contribution
        // per active Fund (snapshotting the fund's current name/rate, linked by fundID).
        let spend = templateStore.spend.enumerated().map { index, template in
            SpendCategory(name: template.name, target: template.target, actual: template.target, sortOrder: index)
        }
        let routing = funds.filter { !$0.archived }.enumerated().map { index, fund in
            RoutingCategory(name: fund.name, target: fund.defaultContribution, annualRate: fund.defaultRate, sortOrder: index, fundID: fund.id)
        }

        modelContext.insert(review)
        spend.forEach(modelContext.insert)
        routing.forEach(modelContext.insert)
        review.spendCategories = spend
        review.routingCategories = routing

        do {
            try modelContext.save()
            selection = monthKey
        } catch {
            modelContext.rollback()
            presentCreationError(error)
        }
    }

    private func delete(_ review: MonthlyReview) {
        let deletedMonthKey = review.monthKey
        modelContext.delete(review)

        do {
            try modelContext.save()
            reviewPendingDeletion = nil

            if selection == deletedMonthKey {
                selection = reviews.first { $0.monthKey != deletedMonthKey }?.monthKey
            }
        } catch {
            modelContext.rollback()
            reviewPendingDeletion = nil
            presentDeletionError(error)
        }
    }

    private func presentCreationError(_ error: Error) {
        sidebarError = SidebarError(title: "Could Not Start New Month", message: error.localizedDescription)
    }

    private func presentDeletionError(_ error: Error) {
        sidebarError = SidebarError(title: "Could Not Delete Month", message: error.localizedDescription)
    }
}

private struct SidebarError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

private struct AddMonthSheet: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    let monthExists: Bool
    let onCancel: () -> Void
    let onCreate: () -> Void

    private let months = Array(1...12)
    private let years = Array((Calendar.current.component(.year, from: .now) - 10)...(Calendar.current.component(.year, from: .now) + 1))

    private var monthKey: String {
        MonthlyReview.monthKey(year: selectedYear, month: selectedMonth)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Add Monthly Review")
                    .font(.title2.weight(.semibold))
                Text("Pick the month and year to create. Clearance stores it as \(monthKey).")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Text("Month")
                        .font(.headline)
                        .gridColumnAlignment(.trailing)

                    Picker("Month", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { month in
                            Text(monthName(for: month)).tag(month)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 180, alignment: .leading)
                }

                GridRow {
                    Text("Year")
                        .font(.headline)

                    Picker("Year", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 120, alignment: .leading)
                }
            }

            if monthExists {
                Label("This month already exists. Creating will simply open it.", systemImage: "checkmark.circle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()

                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button(monthExists ? "Open Existing" : "Create Month", action: onCreate)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 360, idealWidth: 390)
    }

    private func monthName(for month: Int) -> String {
        Calendar.current.monthSymbols[month - 1]
    }
}

private struct MonthRow: View {
    let review: MonthlyReview

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Formatters.monthTitle(from: review.monthKey))
                .font(.headline)
            Text("\(review.remainingBuffer >= 0 ? "Surplus" : "Deficit"): \(review.remainingBuffer.formatted(Formatters.currency))")
                .font(.caption)
                .foregroundStyle(review.remainingBuffer >= 0 ? Color(.systemGreen) : Color(.systemRed))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
