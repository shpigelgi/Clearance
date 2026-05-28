import SwiftUI

struct SettingsView: View {
    @AppStorage(ClearanceSettings.incomeKey) private var income = ClearanceSettings.defaultIncome
    @AppStorage(ClearanceSettings.baselineWorkDaysKey) private var baselineWorkDays = ClearanceSettings.defaultBaselineWorkDays
    @AppStorage(ClearanceSettings.rentKey) private var rent = ClearanceSettings.defaultRent
    @AppStorage(ClearanceSettings.targetMizrahiKey) private var targetMizrahi = ClearanceSettings.defaultTargetMizrahi
    @AppStorage(ClearanceSettings.target1824Key) private var target1824 = ClearanceSettings.defaultTarget1824
    @AppStorage(ClearanceSettings.targetIITKey) private var targetIIT = ClearanceSettings.defaultTargetIIT
    @AppStorage(ClearanceSettings.targetEmergencyFundKey) private var targetEmergencyFund = ClearanceSettings.defaultTargetEmergencyFund
    @AppStorage(ClearanceSettings.targetAbarthFundKey) private var targetAbarthFund = ClearanceSettings.defaultTargetAbarthFund
    @AppStorage(ClearanceSettings.targetHobbyFundKey) private var targetHobbyFund = ClearanceSettings.defaultTargetHobbyFund
    @AppStorage(ClearanceSettings.iitTransferNameKey) private var iitTransferName = ClearanceSettings.defaultIITTransferName
    @AppStorage(ClearanceSettings.emergencyFundNameKey) private var emergencyFundName = ClearanceSettings.defaultEmergencyFundName
    @AppStorage(ClearanceSettings.abarthFundNameKey) private var abarthFundName = ClearanceSettings.defaultAbarthFundName
    @AppStorage(ClearanceSettings.hobbyFundNameKey) private var hobbyFundName = ClearanceSettings.defaultHobbyFundName
    @AppStorage(ClearanceSettings.iitAnnualRateKey) private var iitAnnualRate = ClearanceSettings.defaultIITAnnualRate
    @AppStorage(ClearanceSettings.kerenAnnualRateKey) private var kerenAnnualRate = ClearanceSettings.defaultKerenAnnualRate

    var body: some View {
        Form {
            Section("Monthly Baseline") {
                CurrencyPreferenceField("Income", value: $income, defaultValue: ClearanceSettings.defaultIncome)
                NumberPreferenceField("Baseline Work Days", value: $baselineWorkDays, defaultValue: ClearanceSettings.defaultBaselineWorkDays)
                CurrencyPreferenceField("Rent", value: $rent, defaultValue: ClearanceSettings.defaultRent)
                CurrencyPreferenceField("Mizrahi Target", value: $targetMizrahi, defaultValue: ClearanceSettings.defaultTargetMizrahi)
                CurrencyPreferenceField("1824 Target", value: $target1824, defaultValue: ClearanceSettings.defaultTarget1824)
            }

            Section("Wealth Engine Labels") {
                TextPreferenceField("IIT Transfer Name", value: $iitTransferName, defaultValue: ClearanceSettings.defaultIITTransferName)
                TextPreferenceField("Emergency Fund Name", value: $emergencyFundName, defaultValue: ClearanceSettings.defaultEmergencyFundName)
                TextPreferenceField("Abarth Fund Name", value: $abarthFundName, defaultValue: ClearanceSettings.defaultAbarthFundName)
                TextPreferenceField("Hobby Fund Name", value: $hobbyFundName, defaultValue: ClearanceSettings.defaultHobbyFundName)
            }

            Section("Wealth Engine Targets") {
                CurrencyPreferenceField("IIT Transfer", value: $targetIIT, defaultValue: ClearanceSettings.defaultTargetIIT)
                CurrencyPreferenceField("Emergency Fund", value: $targetEmergencyFund, defaultValue: ClearanceSettings.defaultTargetEmergencyFund)
                CurrencyPreferenceField("Abarth Fund", value: $targetAbarthFund, defaultValue: ClearanceSettings.defaultTargetAbarthFund)
                CurrencyPreferenceField("Hobby Fund", value: $targetHobbyFund, defaultValue: ClearanceSettings.defaultTargetHobbyFund)
            }

            Section("Growth Assumptions") {
                PercentPreferenceField("IIT Annual Rate", value: $iitAnnualRate, defaultValue: ClearanceSettings.defaultIITAnnualRate)
                PercentPreferenceField("Keren Kaspit Annual Rate", value: $kerenAnnualRate, defaultValue: ClearanceSettings.defaultKerenAnnualRate)
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .frame(minWidth: 520, idealWidth: 600, maxWidth: 700, minHeight: 560, idealHeight: 640)
    }
}

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

private struct TextPreferenceField: View {
    let title: String
    @Binding var value: String
    let defaultValue: String

    init(_ title: String, value: Binding<String>, defaultValue: String) {
        self.title = title
        _value = value
        self.defaultValue = defaultValue
    }

    var body: some View {
        LabeledContent(title) {
            RevertableInputRow(
                title: title,
                isDefault: value == defaultValue,
                revert: { value = defaultValue }
            ) {
                TextField(title, text: $value)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
                    .accessibilityLabel(title)
                    .labelsHidden()
            }
        }
    }
}

private struct PercentPreferenceField: View {
    let title: String
    @Binding var value: Double
    let defaultValue: Double

    init(_ title: String, value: Binding<Double>, defaultValue: Double) {
        self.title = title
        _value = value
        self.defaultValue = defaultValue
    }

    private var percentBinding: Binding<Double> {
        Binding {
            value * 100
        } set: { newValue in
            value = newValue / 100
        }
    }

    var body: some View {
        LabeledContent(title) {
            RevertableInputRow(
                title: title,
                isDefault: ValueComparison.approximatelyEqual(value, defaultValue),
                revert: { value = defaultValue }
            ) {
                HStack(spacing: 6) {
                    TextField(title, value: percentBinding, format: Formatters.number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 96)
                        .accessibilityLabel(title)
                        .labelsHidden()
                    Text("%")
                        .foregroundStyle(.secondary)
                }
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
