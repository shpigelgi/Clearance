import SwiftData
import SwiftUI

struct MonthDetailView: View {
    @Environment(\.appZoomScale) private var appZoomScale
    @Environment(\.modelContext) private var modelContext
    @Bindable var review: MonthlyReview
    @FocusState private var focusedField: EntryField?
    @State private var pendingDeletion: PendingDeletion?
    @State private var renameRequest: RenameRequest?

    @Query(sort: [SortDescriptor(\Fund.sortOrder)]) private var funds: [Fund]
    @Query private var allRouting: [RoutingCategory]
    @Query private var allSpend: [SpendCategory]
    @Query(sort: [SortDescriptor(\MonthlyReview.monthKey, order: .reverse)]) private var allReviews: [MonthlyReview]

    private var ledger: FundLedger { FundLedger(contributions: allRouting, withdrawals: allSpend) }
    private var activeFunds: [Fund] { funds.filter { !$0.archived } }
    /// Fund balances are cumulative/global, so only surface them in the most-recent month.
    private var isLatestMonth: Bool { review.monthKey == allReviews.first?.monthKey }

    private func fund(_ id: UUID?) -> Fund? {
        guard let id else { return nil }
        return funds.first { $0.id == id }
    }

    /// A spend row tagged to a fund is over-withdrawn if its actual exceeds what the fund held.
    private func isOverWithdrawn(_ category: SpendCategory) -> Bool {
        guard let f = fund(category.fundID) else { return false }
        return category.actual > ledger.availableBefore(category, of: f)
    }

    @AppStorage(ClearanceSettings.incomeKey) private var settingsIncome = ClearanceSettings.defaultIncome
    @AppStorage(ClearanceSettings.baselineWorkDaysKey) private var settingsBaselineWorkDays = ClearanceSettings.defaultBaselineWorkDays
    @AppStorage(ClearanceSettings.rentKey) private var settingsRent = ClearanceSettings.defaultRent

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
    }

    /// A queued category removal, surfaced as a destructive confirmation alert.
    private struct PendingDeletion: Identifiable {
        let id = UUID()
        let name: String
        let perform: () -> Void
    }

    /// A pending fund rename awaiting a scope choice (this month / future / everywhere).
    private struct RenameRequest: Identifiable {
        let id = UUID()
        let category: RoutingCategory
        let newName: String
    }

    private enum RenameScope { case thisMonth, future, everywhere }

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
        .alert(item: $pendingDeletion) { deletion in
            Alert(
                title: Text("Remove \(deletion.name)?"),
                message: Text("This removes the category from \(Formatters.monthTitle(from: review.monthKey)) only. Other months are unaffected."),
                primaryButton: .destructive(Text("Remove"), action: deletion.perform),
                secondaryButton: .cancel()
            )
        }
        .confirmationDialog(
            "Rename to \u{201C}\(renameRequest?.newName ?? "")\u{201D}",
            isPresented: Binding(get: { renameRequest != nil }, set: { if !$0 { renameRequest = nil } }),
            titleVisibility: .visible,
            presenting: renameRequest
        ) { request in
            Button("Just this month") { applyRename(request, scope: .thisMonth) }
            Button("This and future months") { applyRename(request, scope: .future) }
            Button("All months") { applyRename(request, scope: .everywhere) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Where should this fund's new name apply?")
        }
    }

    private func applyRename(_ request: RenameRequest, scope: RenameScope) {
        let newName = request.newName
        let fundID = request.category.fundID
        switch scope {
        case .thisMonth:
            request.category.name = newName
        case .future:
            request.category.name = newName
            fund(fundID)?.name = newName
        case .everywhere:
            fund(fundID)?.name = newName
            if let fundID {
                for row in allRouting where row.fundID == fundID { row.name = newName }
            } else {
                request.category.name = newName
            }
        }
        renameRequest = nil
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

                    // Buffer Trend lives in the secondary column and stretches to fill the
                    // leftover height, so the (shorter) right column bottom-aligns with the
                    // left one instead of leaving an awkward gap above a full-width chart.
                    VStack(spacing: cardSpacing) {
                        growthEstimatorSection
                        InsightsView(placement: .metricsOnly)
                        InsightsView(placement: .chartOnly)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: secondaryWidth)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
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

    // MARK: - Clearance Check

    private var clearanceCheckSection: some View {
        ReviewCard(title: "The Clearance Check", systemImage: "checkmark.seal") {
            VStack(alignment: .leading, spacing: zoomed(14)) {
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
                            numberField(title: "Baseline Work Days", value: $review.baselineWorkDays, field: .baselineWorkDays, width: 112, defaultValue: settingsBaselineWorkDays)
                        }
                        GridRow {
                            formLabel("Days Worked", detail: "Baseline \(review.baselineWorkDays.formatted(Formatters.number))")
                            numberField(title: "Days Worked", value: $review.daysWorked, field: .daysWorked, defaultValue: review.baselineWorkDays)
                        }
                        GridRow {
                            formLabel("Income Per Day")
                            numberField(title: "Income Per Day", value: $review.incomePerWorkday, field: .incomePerWorkday, defaultValue: settingsIncomePerWorkday)
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
                }

                Divider()

                // Dynamic card-spend categories.
                VStack(alignment: .leading, spacing: zoomed(8)) {
                    sectionCaption("Card Spend")
                    if review.spendCategories.isEmpty {
                        emptyHint("No spend categories yet — add one to track card spend.")
                    } else {
                        ForEach(review.sortedSpendCategories) { category in
                            SpendCategoryRow(
                                category: category,
                                funds: activeFunds,
                                overWithdrawn: isOverWithdrawn(category),
                                onRemove: { requestRemoval(of: category.name) { delete(spend: category) } }
                            )
                        }
                    }
                    AddCategoryButton(title: "Add spend category", action: addSpendCategory)
                }

                Divider()

                bufferHero
            }
            .frame(maxWidth: zoomed(560), alignment: .leading)
        }
    }

    private var bufferHero: some View {
        HStack(alignment: .top, spacing: zoomed(14)) {
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
                RoundedRectangle(cornerRadius: zoomed(16), style: .continuous)
                    .fill(bufferStatusColor.opacity(0.12))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Remaining buffer")
            .accessibilityValue("\(review.remainingBuffer.formatted(Formatters.currency)), \(bufferStatusLabel)")

            Spacer(minLength: 0)
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

    // MARK: - Wealth Engine

    private var wealthEngineSection: some View {
        ReviewCard(title: "The Wealth Engine", systemImage: "arrow.triangle.2.circlepath") {
            VStack(alignment: .leading, spacing: zoomed(12)) {
                if review.routingCategories.isEmpty {
                    emptyHint("No funds yet — add one to start routing.")
                } else {
                    ForEach(review.sortedRoutingCategories) { category in
                        RoutingCategoryRow(
                            category: category,
                            balance: isLatestMonth ? fund(category.fundID).map { ledger.balance(of: $0) } : nil,
                            onRename: { newName in renameRequest = RenameRequest(category: category, newName: newName) },
                            onRemove: { requestRemoval(of: category.name) { delete(routing: category) } }
                        )
                    }
                }
                AddCategoryButton(title: "Add fund", action: addRoutingCategory)
            }
        }
    }

    // MARK: - Month Routing summary

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
                        Text("\(review.completedTransferCount) of \(review.totalTransferCount) complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(
                        value: Double(review.completedTransferCount),
                        total: Double(max(review.totalTransferCount, 1))
                    )
                    .progressViewStyle(.linear)
                    .accessibilityLabel("Transfer progress")
                    .accessibilityValue("\(review.completedTransferCount) of \(review.totalTransferCount) complete")
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

    // MARK: - Growth Estimator

    private var growthEstimatorSection: some View {
        ReviewCard(title: "Growth Estimator", systemImage: "chart.line.uptrend.xyaxis") {
            VStack(alignment: .leading, spacing: zoomed(14)) {
                if review.routingCategories.isEmpty {
                    emptyHint("Add a fund to project 12-month growth.")
                } else {
                    VStack(spacing: zoomed(10)) {
                        ForEach(review.sortedRoutingCategories) { category in
                            RateRow(category: category)
                        }
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
                            colors: [Color.accentColor.opacity(0.16), Color(nsColor: .controlBackgroundColor)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
            }
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
            Text("Projects this month's targets a year out, each at its own annual rate.")
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
            Text("Based on this month's targets")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Shared field helpers

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

    private func numberField(title: String, value: Binding<Double>, field: EntryField, width: CGFloat = 100, defaultValue: Double) -> some View {
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

    private func sectionCaption(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityAddTraits(.isHeader)
    }

    private func emptyHint(_ text: String) -> some View {
        Text(text)
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, zoomed(6))
    }

    // MARK: - Add / remove

    private func addSpendCategory() {
        let category = SpendCategory(name: "New category", target: 0, actual: 0, sortOrder: review.nextSpendSortOrder())
        modelContext.insert(category)
        review.spendCategories.append(category)
    }

    private func addRoutingCategory() {
        let category = RoutingCategory(name: "New fund", target: 0, annualRate: ClearanceSettings.defaultKerenAnnualRate, sortOrder: review.nextRoutingSortOrder())
        modelContext.insert(category)
        review.routingCategories.append(category)
    }

    private func requestRemoval(of name: String, perform: @escaping () -> Void) {
        let display = name.isEmpty ? "this category" : name
        pendingDeletion = PendingDeletion(name: display, perform: perform)
    }

    private func delete(spend category: SpendCategory) {
        review.spendCategories.removeAll { $0.id == category.id }
        modelContext.delete(category)
    }

    private func delete(routing category: RoutingCategory) {
        review.routingCategories.removeAll { $0.id == category.id }
        modelContext.delete(category)
    }
}

// MARK: - Inline rename field (shared by spend & routing rows)

private struct InlineRenameField: View {
    @Binding var name: String
    let placeholder: String
    let revealControl: Bool
    /// If provided, edits a draft and reports the new name on commit (the caller decides scope)
    /// instead of binding `name` live. Used for funds, where a rename may span months.
    var onCommit: ((String) -> Void)? = nil
    @State private var isEditing = false
    @State private var draft = ""

    private var display: String { name.isEmpty ? placeholder : name }

    var body: some View {
        HStack(spacing: 6) {
            if isEditing {
                TextField(placeholder, text: onCommit == nil ? $name : $draft)
                    .textFieldStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .onSubmit { commit() }
            } else {
                Text(display)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }

            Button {
                if isEditing { commit() } else { draft = name; isEditing = true }
            } label: {
                Image(systemName: isEditing ? "checkmark.circle" : "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .opacity(revealControl || isEditing ? 1 : 0.6)
            .accessibilityLabel(isEditing ? "Finish renaming \(display)" : "Rename \(display)")
            .help(isEditing ? "Finish renaming" : "Rename")
        }
    }

    private func commit() {
        isEditing = false
        guard let onCommit else { return } // live binding already updated `name`
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed != name { onCommit(trimmed) }
    }
}

// MARK: - Remove control (hover-revealed, destructive)

private struct RemoveCategoryButton: View {
    let categoryName: String
    let revealed: Bool
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Image(systemName: "trash")
                .font(.caption)
                .foregroundStyle(revealed ? Color(.systemRed) : .secondary)
        }
        .buttonStyle(.plain)
        .opacity(revealed ? 1 : 0.6)
        .accessibilityLabel("Remove \(categoryName.isEmpty ? "category" : categoryName)")
        .help("Remove")
    }
}

// MARK: - Ghost "Add" button

private struct AddCategoryButton: View {
    @Environment(\.appZoomScale) private var appZoomScale
    let title: String
    let action: () -> Void

    private var zoom: CGFloat { CGFloat(appZoomScale) }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "plus.circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8 * zoom)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .ghostAddBackground(cornerRadius: 14 * zoom)
    }
}

private extension View {
    /// A dashed ghost outline, upgraded to interactive Liquid Glass on macOS 26+.
    @ViewBuilder
    func ghostAddBackground(cornerRadius: CGFloat) -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
        } else {
            overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(Color.secondary.opacity(0.4))
            }
        }
    }
}

// MARK: - Spend category row

private struct SpendCategoryRow: View {
    @Environment(\.appZoomScale) private var appZoomScale
    @Bindable var category: SpendCategory
    let funds: [Fund]
    let overWithdrawn: Bool
    let onRemove: () -> Void
    @State private var isHovering = false

    private func zoomed(_ value: CGFloat) -> CGFloat { value * CGFloat(appZoomScale) }

    var body: some View {
        HStack(spacing: zoomed(10)) {
            InlineRenameField(name: $category.name, placeholder: "Category", revealControl: isHovering)
                .frame(width: zoomed(140), alignment: .leading)

            Spacer(minLength: zoomed(6))

            labeledField("Target", value: $category.target)
            labeledField("Actual", value: $category.actual)
            fundedByPicker

            RemoveCategoryButton(categoryName: category.name, revealed: isHovering, action: onRemove)
        }
        .padding(.vertical, zoomed(8))
        .padding(.horizontal, zoomed(10))
        .frame(maxWidth: zoomed(560), alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: zoomed(14), style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.58))
        }
        .overlay {
            if overWithdrawn {
                RoundedRectangle(cornerRadius: zoomed(14), style: .continuous)
                    .strokeBorder(Color(.systemRed), lineWidth: 1)
            }
        }
        .onHover { isHovering = $0 }
    }

    private var fundedByPicker: some View {
        VStack(alignment: .leading, spacing: zoomed(3)) {
            HStack(spacing: 3) {
                Text("Funded by")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if overWithdrawn {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(Color(.systemRed))
                        .help("This withdrawal exceeds the fund's balance — unbacked spend")
                }
            }
            Picker("Funded by", selection: $category.fundID) {
                Text("Income").tag(Optional<UUID>.none)
                ForEach(funds) { fund in
                    Text(fund.name).tag(Optional(fund.id))
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: zoomed(118))
            .accessibilityLabel("\(category.name) funded by")
        }
    }

    private func labeledField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: zoomed(3)) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: Formatters.number)
                .financialFieldStyle(width: 76)
                .accessibilityLabel("\(category.name) \(title)")
        }
    }
}

// MARK: - Routing category row

private struct RoutingCategoryRow: View {
    @Environment(\.appZoomScale) private var appZoomScale
    @Bindable var category: RoutingCategory
    let balance: Double?
    let onRename: (String) -> Void
    let onRemove: () -> Void
    @State private var isHovering = false

    private func zoomed(_ value: CGFloat) -> CGFloat { value * CGFloat(appZoomScale) }
    private var displayName: String { category.name.isEmpty ? "Fund" : category.name }

    var body: some View {
        HStack(spacing: zoomed(10)) {
            Toggle(isOn: $category.didTransfer) {
                Text("Mark \(displayName) transferred")
            }
            .toggleStyle(.checkbox)
            .labelsHidden()
            .accessibilityLabel("Mark \(displayName) transferred")
            .help("Mark \(displayName) transferred")

            InlineRenameField(name: $category.name, placeholder: "Fund", revealControl: isHovering, onCommit: onRename)
                .frame(width: zoomed(190), alignment: .leading)

            if let balance {
                Text(balance, format: Formatters.currency)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(balance >= 0 ? Color(.systemGreen) : Color(.systemRed))
                    .help("Current fund balance")
                    .accessibilityLabel("\(displayName) balance \(balance.formatted(Formatters.currency))")
            }

            Spacer(minLength: zoomed(8))

            TextField("\(displayName) amount", value: $category.target, format: Formatters.number)
                .financialFieldStyle(width: 100)
                .accessibilityLabel("\(displayName) amount")

            RemoveCategoryButton(categoryName: category.name, revealed: isHovering, action: onRemove)
        }
        .padding(.vertical, zoomed(8))
        .padding(.horizontal, zoomed(10))
        .frame(maxWidth: zoomed(560), alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: zoomed(14), style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.58))
        }
        .onHover { isHovering = $0 }
    }
}

// MARK: - Per-fund growth-rate row

private struct RateRow: View {
    @Environment(\.appZoomScale) private var appZoomScale
    @Bindable var category: RoutingCategory

    private func zoomed(_ value: CGFloat) -> CGFloat { value * CGFloat(appZoomScale) }
    private var displayName: String { category.name.isEmpty ? "Fund" : category.name }

    private var percentBinding: Binding<Double> {
        Binding {
            category.annualRate * 100
        } set: { newValue in
            category.annualRate = newValue / 100
        }
    }

    var body: some View {
        HStack(spacing: zoomed(10)) {
            VStack(alignment: .leading, spacing: zoomed(2)) {
                Text(displayName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text("Annual growth assumption")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: zoomed(8))

            HStack(spacing: zoomed(6)) {
                TextField("Rate", value: percentBinding, format: Formatters.number)
                    .financialFieldStyle(width: 72)
                    .accessibilityLabel("\(displayName) annual rate")
                Text("%")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(zoomed(12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: zoomed(14), style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.58))
        }
    }
}

// MARK: - Card container (Liquid Glass on macOS 26+)

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
