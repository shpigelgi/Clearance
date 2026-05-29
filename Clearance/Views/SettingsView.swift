import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var templateStore: CategoryTemplateStore

    @AppStorage(ClearanceSettings.incomeKey) private var income = ClearanceSettings.defaultIncome
    @AppStorage(ClearanceSettings.baselineWorkDaysKey) private var baselineWorkDays = ClearanceSettings.defaultBaselineWorkDays
    @AppStorage(ClearanceSettings.rentKey) private var rent = ClearanceSettings.defaultRent

    var body: some View {
        Form {
            Section("Monthly Baseline") {
                CurrencyPreferenceField("Income", value: $income, defaultValue: ClearanceSettings.defaultIncome)
                NumberPreferenceField("Baseline Work Days", value: $baselineWorkDays, defaultValue: ClearanceSettings.defaultBaselineWorkDays)
                CurrencyPreferenceField("Rent", value: $rent, defaultValue: ClearanceSettings.defaultRent)
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

            Section("Wealth Routing Categories") {
                ForEach($templateStore.routing) { $item in
                    RoutingTemplateRow(item: $item) { remove(routing: item) }
                }
                .onMove { templateStore.routing.move(fromOffsets: $0, toOffset: $1) }

                Button {
                    templateStore.routing.append(RoutingCategoryTemplate(name: "New fund", target: 0, annualRate: ClearanceSettings.defaultKerenAnnualRate))
                } label: {
                    Label("Add Fund", systemImage: "plus.circle")
                }
                .accessibilityLabel("Add fund")
            }

            Section {
                Text("These are the defaults new months start from. Editing them affects new months only — existing months keep their own categories, which you edit from each month.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .frame(minWidth: 560, idealWidth: 640, maxWidth: 760, minHeight: 600, idealHeight: 720)
    }

    private func remove(spend item: SpendCategoryTemplate) {
        templateStore.spend.removeAll { $0.id == item.id }
    }

    private func remove(routing item: RoutingCategoryTemplate) {
        templateStore.routing.removeAll { $0.id == item.id }
    }
}

// MARK: - Template rows

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

private struct RoutingTemplateRow: View {
    @Binding var item: RoutingCategoryTemplate
    let onRemove: () -> Void

    private var percentBinding: Binding<Double> {
        Binding {
            item.annualRate * 100
        } set: { newValue in
            item.annualRate = newValue / 100
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            TextField("Name", text: $item.name)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Fund name")

            TextField("Target", value: $item.target, format: Formatters.number)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .accessibilityLabel("\(item.name) default target")

            HStack(spacing: 4) {
                TextField("Rate", value: percentBinding, format: Formatters.number)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                    .accessibilityLabel("\(item.name) default annual rate")
                Text("%").foregroundStyle(.secondary)
            }

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

private struct CurrencyPreferenceField: View {
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

private struct NumberPreferenceField: View {
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
