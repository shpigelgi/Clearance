import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var templateStore: CategoryTemplateStore

    @Query(sort: [SortDescriptor(\Fund.sortOrder)]) private var funds: [Fund]
    @Query private var allRouting: [RoutingCategory]
    @Query private var allSpend: [SpendCategory]

    @AppStorage(ClearanceSettings.incomeKey) private var income = ClearanceSettings.defaultIncome
    @AppStorage(ClearanceSettings.baselineWorkDaysKey) private var baselineWorkDays = ClearanceSettings.defaultBaselineWorkDays
    @AppStorage(ClearanceSettings.rentKey) private var rent = ClearanceSettings.defaultRent

    private var ledger: FundLedger {
        FundLedger(contributions: allRouting, withdrawals: allSpend)
    }

    var body: some View {
        Form {
            Section("Monthly Baseline") {
                PreferenceField("Income", value: $income, defaultValue: ClearanceSettings.defaultIncome)
                PreferenceField("Baseline Work Days", value: $baselineWorkDays, defaultValue: ClearanceSettings.defaultBaselineWorkDays)
                PreferenceField("Rent", value: $rent, defaultValue: ClearanceSettings.defaultRent)
            }

            Section("Card Spend Categories") {
                ForEach($templateStore.spend) { $item in
                    SpendTemplateRow(item: $item) { remove(spend: item) }
                }
                .onMove { templateStore.spend.move(fromOffsets: $0, toOffset: $1) }

                Button {
                    templateStore.spend.append(SpendCategoryTemplate(name: "New category", target: 0))
                } label: {
                    Label("Add Spend Category", systemImage: "plus.circle")
                }
                .accessibilityLabel("Add spend category")
            }

            Section("Sinking Funds") {
                ForEach(funds) { fund in
                    FundRow(fund: fund, balance: ledger.balance(of: fund))
                }
                Button(action: addFund) {
                    Label("Add Fund", systemImage: "plus.circle")
                }
                .accessibilityLabel("Add fund")
            }

            Section {
                Text("Spend categories are defaults new months start from. Funds persist across months — each month routes into them and their balance carries over. Editing here affects new months; rename a fund inside a month to change past months.\n\nStart is the value a fund held before you began tracking it in Clearance. The displayed current balance is that starting point plus all confirmed contributions minus withdrawals — it reflects this fund only, not total liquid net worth.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 560, idealWidth: 660, maxWidth: 780, minHeight: 620, idealHeight: 760)
    }

    private func remove(spend item: SpendCategoryTemplate) {
        templateStore.spend.removeAll { $0.id == item.id }
    }

    private func addFund() {
        let order = (funds.map(\.sortOrder).max() ?? -1) + 1
        modelContext.insert(Fund(
            name: "New fund",
            defaultContribution: 0,
            defaultRate: ClearanceSettings.defaultKerenAnnualRate,
            sortOrder: order
        ))
    }
}

// MARK: - Fund row (persistent sinking fund)

private struct FundRow: View {
    @Bindable var fund: Fund
    let balance: Double

    private var ratePercent: Binding<Double> {
        Binding { fund.defaultRate * 100 } set: { fund.defaultRate = $0 / 100 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TextField("Name", text: $fund.name)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Fund name")

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 1) {
                    Text("Current balance")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(balance, format: Formatters.currency)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(balance >= 0 ? Color(.systemGreen) : Color(.systemRed))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(fund.name) current balance")
                .accessibilityValue(balance.formatted(Formatters.currency))
                .help("Starting balance + confirmed contributions − withdrawals")

                Button {
                    fund.archived.toggle()
                } label: {
                    Image(systemName: fund.archived ? "tray.and.arrow.up" : "archivebox")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(fund.archived ? "Unarchive (include in new months)" : "Archive (hide from new months)")
                .accessibilityLabel(fund.archived ? "Unarchive \(fund.name)" : "Archive \(fund.name)")
            }

            // Grid locks each column width to its widest cell, so caption labels
            // can never be compressed narrower than the field below them.
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 2) {
                GridRow {
                    Text("Monthly").font(.caption2).foregroundStyle(.secondary)
                    Text("Growth").font(.caption2).foregroundStyle(.secondary)
                    Text("Start").font(.caption2).foregroundStyle(.secondary)
                }
                GridRow {
                    TextField("Monthly", value: $fund.defaultContribution, format: Formatters.number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 96)
                        .labelsHidden()
                        .accessibilityLabel("\(fund.name) monthly contribution")

                    HStack(spacing: 4) {
                        TextField("Growth", value: ratePercent, format: Formatters.number)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 56)
                            .labelsHidden()
                            .accessibilityLabel("\(fund.name) growth rate")
                        Text("%")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    TextField("Start", value: $fund.openingBalance, format: Formatters.number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 96)
                        .labelsHidden()
                        .accessibilityLabel("\(fund.name) starting balance — value before Clearance began tracking this fund")
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(fund.archived ? 0.5 : 1)
    }
}

// MARK: - Spend template row

private struct SpendTemplateRow: View {
    @Binding var item: SpendCategoryTemplate
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            TextField("Name", text: $item.name)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Spend category name")

            TextField("Target", value: $item.target, format: Formatters.number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
                .accessibilityLabel("\(item.name) default target")

            RemoveTemplateButton(name: item.name, action: onRemove)
        }
    }
}

private struct RemoveTemplateButton: View {
    let name: String
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(Color(.systemRed))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove \(name.isEmpty ? "category" : name)")
        .help("Remove")
    }
}

// MARK: - Baseline preference fields

private struct PreferenceField: View {
    let title: String
    @Binding var value: Double
    let defaultValue: Double

    init(_ title: String, value: Binding<Double>, defaultValue: Double) {
        self.title = title
        _value = value
        self.defaultValue = defaultValue
    }

    var body: some View {
        LabeledContent(title) {
            RevertableInputRow(
                title: title,
                isDefault: ValueComparison.approximatelyEqual(value, defaultValue),
                revert: { value = defaultValue }
            ) {
                TextField(title, value: $value, format: Formatters.number)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 132)
                    .accessibilityLabel(title)
                    .labelsHidden()
            }
        }
    }
}
