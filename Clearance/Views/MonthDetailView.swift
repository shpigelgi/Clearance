import SwiftData
import SwiftUI

struct MonthDetailView: View {
    @Environment(\.appZoomScale) private var appZoomScale
    @Bindable var review: MonthlyReview
    @FocusState private var focusedField: EntryField?
    @State private var hoveredTransferName: TransferName?
    @State private var editingTransferName: TransferName?

    @AppStorage(ClearanceSettings.incomeKey) private var settingsIncome = ClearanceSettings.defaultIncome
    @AppStorage(ClearanceSettings.baselineWorkDaysKey) private var settingsBaselineWorkDays = ClearanceSettings.defaultBaselineWorkDays
    @AppStorage(ClearanceSettings.rentKey) private var settingsRent = ClearanceSettings.defaultRent
    @AppStorage(ClearanceSettings.targetMizrahiKey) private var settingsTargetMizrahi = ClearanceSettings.defaultTargetMizrahi
    @AppStorage(ClearanceSettings.target1824Key) private var settingsTarget1824 = ClearanceSettings.defaultTarget1824
    @AppStorage(ClearanceSettings.targetIITKey) private var settingsTargetIIT = ClearanceSettings.defaultTargetIIT
    @AppStorage(ClearanceSettings.targetEmergencyFundKey) private var settingsTargetEmergencyFund = ClearanceSettings.defaultTargetEmergencyFund
    @AppStorage(ClearanceSettings.targetAbarthFundKey) private var settingsTargetAbarthFund = ClearanceSettings.defaultTargetAbarthFund
    @AppStorage(ClearanceSettings.targetHobbyFundKey) private var settingsTargetHobbyFund = ClearanceSettings.defaultTargetHobbyFund
    @AppStorage(ClearanceSettings.iitTransferNameKey) private var settingsIITTransferName = ClearanceSettings.defaultIITTransferName
    @AppStorage(ClearanceSettings.emergencyFundNameKey) private var settingsEmergencyFundName = ClearanceSettings.defaultEmergencyFundName
    @AppStorage(ClearanceSettings.abarthFundNameKey) private var settingsAbarthFundName = ClearanceSettings.defaultAbarthFundName
    @AppStorage(ClearanceSettings.hobbyFundNameKey) private var settingsHobbyFundName = ClearanceSettings.defaultHobbyFundName
    @AppStorage(ClearanceSettings.iitAnnualRateKey) private var settingsIITAnnualRate = ClearanceSettings.defaultIITAnnualRate
    @AppStorage(ClearanceSettings.kerenAnnualRateKey) private var settingsKerenAnnualRate = ClearanceSettings.defaultKerenAnnualRate

    private var settingsIncomePerWorkday: Double {
        guard settingsBaselineWorkDays > 0 else { return 0 }
        return settingsIncome / settingsBaselineWorkDays
    }

    private enum EntryField: Hashable {
        case income
        case daysWorked
        case incomePerWorkday
        case rent
        case baselineWorkDays
        case targetMizrahi
        case target1824
        case targetIIT
        case targetEmergencyFund
        case targetAbarthFund
        case targetHobbyFund
        case iitAnnualRate
        case kerenAnnualRate
        case actualMizrahi
        case actual1824
    }

    private enum TransferName: Hashable {
        case iit
        case emergency
        case abarth
        case hobby
    }

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding = zoomed(horizontalPadding(for: geometry.size.width))
            let availableWidth = max(0, geometry.size.width - (horizontalPadding * 2))

            ScrollView {
                detailContent(for: availableWidth)
                    .frame(maxWidth: contentWidth(for: availableWidth), alignment: .topLeading)
                    .padding(.vertical, zoomed(22))
                    .padding(.horizontal, horizontalPadding)
                    .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            focusedField = review.calculatesIncomeFromDays ? .daysWorked : .income
        }
    }

    private func zoomed(_ value: CGFloat) -> CGFloat {
        value * CGFloat(appZoomScale)
    }

    @ViewBuilder
    private func detailContent(for width: CGFloat) -> some View {
        if usesTwoColumns(for: width) {
            let spacing = zoomed(18)
            let cardSpacing = zoomed(16)
            let secondaryWidth = min(zoomed(340), max(zoomed(300), width * 0.38))
            let primaryWidth = min(zoomed(560), max(zoomed(460), width - secondaryWidth - spacing))

            VStack(alignment: .leading, spacing: zoomed(22)) {
                header

                HStack(alignment: .top, spacing: spacing) {
                    VStack(spacing: cardSpacing) {
                        clearanceCheckSection
                        wealthEngineSection
                        monthRoutingSummarySection
                    }
                    .frame(width: primaryWidth, alignment: .top)

                    VStack(spacing: cardSpacing) {
                        growthEstimatorSection
                        InsightsView(placement: .metricsOnly)
                    }
                    .frame(width: secondaryWidth, alignment: .top)
                }

                InsightsView(placement: .chartOnly)
            }
        } else {
            VStack(alignment: .leading, spacing: zoomed(22)) {
                header

                VStack(spacing: zoomed(16)) {
                    clearanceCheckSection
                    wealthEngineSection
                    monthRoutingSummarySection
                    growthEstimatorSection
                }

                InsightsView()
            }
        }
    }

    private func contentWidth(for width: CGFloat) -> CGFloat {
        if usesTwoColumns(for: width) {
            let spacing = zoomed(18)
            let secondaryWidth = min(zoomed(340), max(zoomed(300), width * 0.38))
            let primaryWidth = min(zoomed(560), max(zoomed(460), width - secondaryWidth - spacing))
            return primaryWidth + spacing + secondaryWidth
        }

        return min(zoomed(760), width)
    }

    private func usesTwoColumns(for width: CGFloat) -> Bool {
        width >= zoomed(820)
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<560:
            16
        case ..<820:
            24
        default:
            32
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: zoomed(6)) {
            Text(Formatters.monthTitle(from: review.monthKey))
                .font(.system(.largeTitle, weight: .semibold))
            Text("Route income with intent, then keep the historical record untouched.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var clearanceCheckSection: some View {
        ReviewCard(title: "The Clearance Check", systemImage: "checkmark.seal") {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: zoomed(14), verticalSpacing: zoomed(12)) {
                GridRow {
                    formLabel("Income Mode")
                    Toggle("Calculate from days worked", isOn: incomeModeBinding)
                        .toggleStyle(.checkbox)
                        .gridColumnAlignment(.leading)
                }

                if review.calculatesIncomeFromDays {
                    GridRow {
                        formLabel("Baseline Work Days")
                        numberField(
                            title: "Baseline Work Days",
                            value: $review.baselineWorkDays,
                            field: .baselineWorkDays,
                            width: 112,
                            defaultValue: settingsBaselineWorkDays
                        )
                    }

                    GridRow {
                        formLabel("Days Worked", detail: "Baseline \(review.baselineWorkDays.formatted(Formatters.number))")
                        numberField(
                            title: "Days Worked",
                            value: $review.daysWorked,
                            field: .daysWorked,
                            defaultValue: review.baselineWorkDays
                        )
                    }

                    GridRow {
                        formLabel("Income Per Day")
                        numberField(
                            title: "Income Per Day",
                            value: $review.incomePerWorkday,
                            field: .incomePerWorkday,
                            defaultValue: settingsIncomePerWorkday
                        )
                    }
                } else {
                    GridRow {
                        formLabel("Income")
                        numberField(title: "Income", value: $review.income, field: .income, defaultValue: settingsIncome)
                    }
                }

                GridRow {
                    formLabel("Rent")
                    numberField(title: "Rent", value: $review.rent, field: .rent, defaultValue: settingsRent)
                }

                Divider()
                    .gridCellColumns(2)

                GridRow {
                    formLabel("Mizrahi Target")
                    numberField(
                        title: "Mizrahi Target",
                        value: $review.targetMizrahi,
                        field: .targetMizrahi,
                        defaultValue: settingsTargetMizrahi
                    )
                }

                GridRow {
                    formLabel("Actual Mizrahi")
                    numberField(
                        title: "Actual Mizrahi",
                        value: $review.actualMizrahi,
                        field: .actualMizrahi,
                        defaultValue: review.targetMizrahi
                    )
                }

                GridRow {
                    formLabel("1824 Target")
                    numberField(
                        title: "1824 Target",
                        value: $review.target1824,
                        field: .target1824,
                        defaultValue: settingsTarget1824
                    )
                }

                GridRow {
                    formLabel("Actual 1824")
                    numberField(
                        title: "Actual 1824",
                        value: $review.actual1824,
                        field: .actual1824,
                        defaultValue: review.target1824
                    )
                }

                Divider()
                    .gridCellColumns(2)

                GridRow {
                    formLabel("Remaining Buffer", detail: "Income - rent - actual card spend")
                    VStack(alignment: .leading, spacing: zoomed(4)) {
                        Text(review.remainingBuffer, format: Formatters.currency)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(bufferStatusColor)
                        Label(bufferStatusLabel, systemImage: bufferStatusSystemImage)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(bufferStatusColor)
                    }
                    .frame(maxWidth: zoomed(180), alignment: .leading)
                    .padding(zoomed(12))
                    .background {
                        // Subtle state-reactive wash behind the bold colored number. (A tinted
                        // glassEffect renders near-solid and makes the same-colored text
                        // unreadable, so use a faint fill instead and keep glass for the cards.)
                        RoundedRectangle(cornerRadius: zoomed(16), style: .continuous)
                            .fill(bufferStatusColor.opacity(0.12))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Remaining buffer")
                    .accessibilityValue("\(review.remainingBuffer.formatted(Formatters.currency)), \(bufferStatusLabel)")
                }
            }
            .frame(maxWidth: zoomed(560), alignment: .leading)
        }
    }

    private var bufferStatusLabel: String {
        review.remainingBuffer >= 0 ? "Surplus buffer" : "Deficit buffer"
    }

    private var bufferStatusSystemImage: String {
        review.remainingBuffer >= 0 ? "arrow.up.circle.fill" : "exclamationmark.triangle.fill"
    }

    private var bufferStatusColor: Color {
        review.remainingBuffer >= 0 ? Color(.systemGreen) : Color(.systemRed)
    }

    private var incomeModeBinding: Binding<Bool> {
        Binding {
            review.calculatesIncomeFromDays
        } set: { isEnabled in
            review.calculatesIncomeFromDays = isEnabled
            if isEnabled {
                normalizeIncomeInputs()
                focusedField = .daysWorked
            } else {
                focusedField = .income
            }
        }
    }

    private func normalizeIncomeInputs() {
        if review.baselineWorkDays <= 0 {
            review.baselineWorkDays = ClearanceSettings.defaultBaselineWorkDays
        }

        if review.daysWorked <= 0 {
            review.daysWorked = review.baselineWorkDays
        }

        if review.incomePerWorkday <= 0, review.baselineWorkDays > 0 {
            review.incomePerWorkday = review.income / review.baselineWorkDays
        }
    }

    private func inputLabel(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: zoomed(3)) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func formLabel(_ title: String, detail: String? = nil) -> some View {
        VStack(alignment: .trailing, spacing: zoomed(3)) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            if let detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: zoomed(150), alignment: .trailing)
        .gridColumnAlignment(.trailing)
    }

    private func numberField(
        title: String,
        value: Binding<Double>,
        field: EntryField,
        width: CGFloat = 100,
        defaultValue: Double
    ) -> some View {
        RevertableInputRow(
            title: title,
            isDefault: ValueComparison.approximatelyEqual(value.wrappedValue, defaultValue),
            spacing: zoomed(4),
            revert: { value.wrappedValue = defaultValue }
        ) {
            TextField(title, value: value, format: Formatters.number)
                .focused($focusedField, equals: field)
                .financialFieldStyle(width: width)
                .accessibilityLabel(title)
        }
    }

    private func percentField(
        title: String,
        value: Binding<Double>,
        field: EntryField,
        width: CGFloat,
        defaultValue: Double
    ) -> some View {
        RevertableInputRow(
            title: title,
            isDefault: ValueComparison.approximatelyEqual(value.wrappedValue, defaultValue),
            spacing: zoomed(4),
            revert: { value.wrappedValue = defaultValue }
        ) {
            HStack(spacing: zoomed(6)) {
                TextField(title, value: percentBinding(value), format: Formatters.number)
                    .focused($focusedField, equals: field)
                    .financialFieldStyle(width: min(width, 100))
                    .accessibilityLabel(title)

                Text("%")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func percentBinding(_ value: Binding<Double>) -> Binding<Double> {
        Binding {
            value.wrappedValue * 100
        } set: { newValue in
            value.wrappedValue = newValue / 100
        }
    }

    private var wealthEngineSection: some View {
        ReviewCard(title: "The Wealth Engine", systemImage: "arrow.triangle.2.circlepath") {
            VStack(alignment: .leading, spacing: zoomed(12)) {
                transferConfigRow(
                    id: .iit,
                    name: $review.iitTransferName,
                    defaultName: settingsIITTransferName,
                    amount: $review.targetIIT,
                    defaultAmount: settingsTargetIIT,
                    field: .targetIIT,
                    isOn: $review.didTransferIIT
                )

                transferConfigRow(
                    id: .emergency,
                    name: $review.emergencyFundName,
                    defaultName: settingsEmergencyFundName,
                    amount: $review.targetEmergencyFund,
                    defaultAmount: settingsTargetEmergencyFund,
                    field: .targetEmergencyFund,
                    isOn: $review.didTransferEmergencyFund
                )

                transferConfigRow(
                    id: .abarth,
                    name: $review.abarthFundName,
                    defaultName: settingsAbarthFundName,
                    amount: $review.targetAbarthFund,
                    defaultAmount: settingsTargetAbarthFund,
                    field: .targetAbarthFund,
                    isOn: $review.didTransferAbarthFund
                )

                transferConfigRow(
                    id: .hobby,
                    name: $review.hobbyFundName,
                    defaultName: settingsHobbyFundName,
                    amount: $review.targetHobbyFund,
                    defaultAmount: settingsTargetHobbyFund,
                    field: .targetHobbyFund,
                    isOn: $review.didTransferHobbyFund
                )
            }
        }
    }

    private var monthRoutingSummarySection: some View {
        ReviewCard(title: "Month Routing", systemImage: "arrow.right.circle") {
            VStack(alignment: .leading, spacing: zoomed(14)) {
                summaryMetricRow(
                    title: "Effective Income",
                    value: review.effectiveIncome.formatted(Formatters.currency),
                    detail: review.calculatesIncomeFromDays
                        ? "\(review.daysWorked.formatted(Formatters.number)) days x \(review.incomePerWorkday.formatted(Formatters.currency))"
                        : "Manual income entry for this month"
                )

                summaryMetricRow(
                    title: "Planned Wealth Routing",
                    value: review.plannedWealthRoutingTotal.formatted(Formatters.currency),
                    detail: "Sum of this month's transfer targets"
                )

                summaryMetricRow(
                    title: "Confirmed Transfers",
                    value: review.totalWealthRouted.formatted(Formatters.currency),
                    detail: review.pendingWealthRoutingTotal > 0
                        ? "\(review.pendingWealthRoutingTotal.formatted(Formatters.currency)) still pending"
                        : "All planned transfers marked complete"
                )

                VStack(alignment: .leading, spacing: zoomed(8)) {
                    HStack {
                        Text("Transfer Progress")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(review.completedTransferCount) of \(MonthlyReview.totalTransferCount) complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(
                        value: Double(review.completedTransferCount),
                        total: Double(MonthlyReview.totalTransferCount)
                    )
                    .progressViewStyle(.linear)
                    .accessibilityLabel("Transfer progress")
                    .accessibilityValue("\(review.completedTransferCount) of \(MonthlyReview.totalTransferCount) complete")
                }
            }
        }
    }

    private func summaryMetricRow(title: String, value: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: zoomed(4)) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .monospacedDigit()
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(zoomed(12))
        .background {
            RoundedRectangle(cornerRadius: zoomed(12), style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.58))
        }
    }

    private func transferConfigRow(
        id: TransferName,
        name: Binding<String>,
        defaultName: String,
        amount: Binding<Double>,
        defaultAmount: Double,
        field: EntryField,
        isOn: Binding<Bool>
    ) -> some View {
        let displayName = name.wrappedValue.isEmpty ? defaultName : name.wrappedValue

        return HStack(spacing: zoomed(10)) {
            HStack(spacing: zoomed(8)) {
                Toggle(isOn: isOn) {
                    Text("Mark \(displayName) transferred")
                }
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    .accessibilityLabel("Mark \(displayName) transferred")
                    .help("Mark \(displayName) transferred")

                transferNameEditor(id: id, name: name, defaultName: defaultName)
                    .frame(width: zoomed(210), alignment: .leading)

                numberField(title: "\(displayName) amount", value: amount, field: field, defaultValue: defaultAmount)
            }
            .frame(maxWidth: zoomed(330), alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(.vertical, zoomed(8))
        .padding(.horizontal, zoomed(10))
        .frame(maxWidth: zoomed(560), alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: zoomed(14), style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.58))
        }
        .onHover { isHovering in
            hoveredTransferName = isHovering ? id : (hoveredTransferName == id ? nil : hoveredTransferName)
        }
    }

    private func transferNameEditor(
        id: TransferName,
        name: Binding<String>,
        defaultName: String
    ) -> some View {
        HStack(spacing: zoomed(6)) {
            if editingTransferName == id {
                TextField(defaultName, text: name)
                    .textFieldStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: zoomed(160), alignment: .leading)
                    .onSubmit {
                        editingTransferName = nil
                    }
            } else {
                Text(name.wrappedValue.isEmpty ? defaultName : name.wrappedValue)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }

            Button {
                editingTransferName = editingTransferName == id ? nil : id
            } label: {
                Image(systemName: editingTransferName == id ? "checkmark.circle" : "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(hoveredTransferName == id || editingTransferName == id ? 1 : 0.6)
            .accessibilityLabel(editingTransferName == id ? "Finish Editing Transfer Name" : "Edit Transfer Name")
            .help(editingTransferName == id ? "Finish editing transfer name" : "Edit transfer name")

            RevertToDefaultButton(
                title: "Transfer name",
                isDefault: name.wrappedValue == defaultName
            ) {
                name.wrappedValue = defaultName
                editingTransferName = nil
            }
            .opacity(hoveredTransferName == id || editingTransferName == id ? 1 : 0.6)
        }
        .frame(width: zoomed(210), alignment: .leading)
    }

    private var growthEstimatorSection: some View {
        ReviewCard(title: "Growth Estimator", systemImage: "chart.line.uptrend.xyaxis") {
            VStack(alignment: .leading, spacing: zoomed(14)) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: zoomed(14)) {
                        rateInputTile(
                            title: "\(review.resolvedIITTransferName) rate",
                            value: $review.iitAnnualRate,
                            field: .iitAnnualRate,
                            defaultValue: settingsIITAnnualRate
                        )

                        rateInputTile(
                            title: "Keren Kaspit rate",
                            value: $review.kerenAnnualRate,
                            field: .kerenAnnualRate,
                            defaultValue: settingsKerenAnnualRate
                        )
                    }

                    VStack(spacing: zoomed(12)) {
                        rateInputTile(
                            title: "\(review.resolvedIITTransferName) rate",
                            value: $review.iitAnnualRate,
                            field: .iitAnnualRate,
                            defaultValue: settingsIITAnnualRate
                        )

                        rateInputTile(
                            title: "Keren Kaspit rate",
                            value: $review.kerenAnnualRate,
                            field: .kerenAnnualRate,
                            defaultValue: settingsKerenAnnualRate
                        )
                    }
                }

                ViewThatFits(in: .horizontal) {
                    growthEstimatorContent(axis: .horizontal)
                    growthEstimatorContent(axis: .vertical)
                }
                .padding(zoomed(18))
                .background {
                    RoundedRectangle(cornerRadius: zoomed(18), style: .continuous)
                        .fill(.linearGradient(
                            colors: [
                                Color.accentColor.opacity(0.16),
                                Color(nsColor: .controlBackgroundColor)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
            }
        }
    }

    private func rateInputTile(
        title: String,
        value: Binding<Double>,
        field: EntryField,
        defaultValue: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: zoomed(10)) {
            inputLabel(title: title, subtitle: "Annual growth assumption")

            percentField(title: title, value: value, field: field, width: 82, defaultValue: defaultValue)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(zoomed(14))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: zoomed(14), style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.58))
        }
    }

    private func growthEstimatorContent(axis: Axis) -> some View {
        Group {
            if axis == .horizontal {
                HStack(alignment: .center, spacing: zoomed(22)) {
                    growthEstimatorCopy
                    Spacer(minLength: zoomed(18))
                    growthEstimatorValue
                }
            } else {
                VStack(alignment: .leading, spacing: zoomed(16)) {
                    growthEstimatorCopy
                    growthEstimatorValue
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var growthEstimatorCopy: some View {
        VStack(alignment: .leading, spacing: zoomed(8)) {
            Text("12-month projected value")
                .font(.subheadline.weight(.semibold))
            Text("\(review.resolvedIITTransferName) uses \(review.resolvedIITAnnualRate.formatted(Formatters.percent)). Keren Kaspit funds use \(review.resolvedKerenAnnualRate.formatted(Formatters.percent)).")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var growthEstimatorValue: some View {
        VStack(alignment: .trailing, spacing: zoomed(6)) {
            Text(review.twelveMonthProjection, format: Formatters.currency)
                .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                .minimumScaleFactor(0.75)
                .lineLimit(1)
            Text("Based on this month's copied targets")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ReviewCard<Content: View>: View {
    @Environment(\.appZoomScale) private var appZoomScale
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    private func zoomed(_ value: CGFloat) -> CGFloat {
        value * CGFloat(appZoomScale)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: zoomed(16)) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            content
        }
        .padding(zoomed(20))
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassSurface(cornerRadius: zoomed(20)) {
            RoundedRectangle(cornerRadius: zoomed(20), style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: zoomed(18), y: zoomed(8))
                .overlay {
                    RoundedRectangle(cornerRadius: zoomed(20), style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.08))
                }
        }
    }
}

private struct FinancialFieldStyle: ViewModifier {
    @Environment(\.appZoomScale) private var appZoomScale
    let width: CGFloat

    private var zoom: CGFloat {
        CGFloat(appZoomScale)
    }

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.roundedBorder)
            .font(.body)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .labelsHidden()
            .controlSize(appZoomScale >= 1.15 ? .large : appZoomScale <= 0.90 ? .small : .regular)
            .frame(width: width * zoom, alignment: .leading)
    }
}

private extension View {
    func financialFieldStyle(width: CGFloat) -> some View {
        modifier(FinancialFieldStyle(width: width))
    }
}
