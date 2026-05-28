import Charts
import SwiftData
import SwiftUI

enum InsightsPlacement {
    case combined
    case metricsOnly
    case chartOnly
}

struct InsightsView: View {
    @Environment(\.appZoomScale) private var appZoomScale
    @Query(sort: [SortDescriptor(\MonthlyReview.monthKey, order: .forward)])
    private var reviews: [MonthlyReview]

    var placement: InsightsPlacement = .combined

    private var viewModel: InsightsViewModel {
        InsightsViewModel(reviews: reviews)
    }

    private func zoomed(_ value: CGFloat) -> CGFloat {
        value * CGFloat(appZoomScale)
    }

    var body: some View {
        switch placement {
        case .combined:
            ReviewAnalyticsCard {
                VStack(alignment: .leading, spacing: zoomed(18)) {
                    metricsSection
                    chartSection
                }
            }
        case .metricsOnly:
            ReviewAnalyticsCard(title: "Historical Signals", systemImage: "chart.bar") {
                metricsSection
            }
        case .chartOnly:
            ReviewAnalyticsCard {
                chartSection
            }
        }
    }

    private var metricsSection: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: zoomed(16)) {
                rollingAverageTile
                wealthVelocityTile
            }

            VStack(alignment: .leading, spacing: zoomed(12)) {
                rollingAverageTile
                wealthVelocityTile
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: zoomed(10)) {
            Text("Buffer Trend")
                .font(.system(size: zoomed(13), weight: .semibold))
            Text("Last \(viewModel.recentSix.count) month\(viewModel.recentSix.count == 1 ? "" : "s"), sorted by month key")
                .font(.system(size: zoomed(10)))
                .foregroundStyle(.secondary)

            Chart(viewModel.recentSix) { review in
                LineMark(
                    x: .value("Month", review.monthKey),
                    y: .value("Remaining Buffer", review.remainingBuffer)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.accentColor)

                PointMark(
                    x: .value("Month", review.monthKey),
                    y: .value("Remaining Buffer", review.remainingBuffer)
                )
                .foregroundStyle(review.remainingBuffer >= 0 ? Color.green : Color.red)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(maxWidth: .infinity)
            .frame(height: zoomed(placement == .chartOnly ? 200 : 180))
            .accessibilityLabel("Buffer Trend")
            .accessibilityValue(bufferTrendAccessibilityValue)
        }
    }

    private var bufferTrendAccessibilityValue: String {
        guard let latest = viewModel.recentSix.last else {
            return "No monthly buffer data yet."
        }

        let status = latest.remainingBuffer >= 0 ? "surplus" : "deficit"
        return "Latest month \(latest.monthKey) has a \(status) of \(latest.remainingBuffer.formatted(Formatters.currency))."
    }

    private var rollingAverageTile: some View {
        MetricTile(
            title: "Rolling 1824 Average",
            value: viewModel.rollingAverage1824.formatted(Formatters.currency),
            subtitle: "Last \(viewModel.recentThree.count) month\(viewModel.recentThree.count == 1 ? "" : "s")"
        )
    }

    private var wealthVelocityTile: some View {
        MetricTile(
            title: "Wealth Velocity",
            value: viewModel.totalWealthVelocity.formatted(Formatters.currency),
            subtitle: "Confirmed IIT + Keren Kaspit routing"
        )
    }
}

private struct ReviewAnalyticsCard<Content: View>: View {
    @Environment(\.appZoomScale) private var appZoomScale
    let title: String?
    let systemImage: String?
    @ViewBuilder var content: Content

    init(
        title: String? = "Insights & Analytics",
        systemImage: String? = "waveform.path.ecg",
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    private func zoomed(_ value: CGFloat) -> CGFloat {
        value * CGFloat(appZoomScale)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: zoomed(16)) {
            if let title, let systemImage {
                Label(title, systemImage: systemImage)
                    .font(.system(size: zoomed(17), weight: .semibold))
            }

            content
        }
        .padding(zoomed(20))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: zoomed(20), style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: zoomed(18), y: zoomed(8))
        }
        .overlay {
            RoundedRectangle(cornerRadius: zoomed(20), style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.08))
        }
    }
}

private struct MetricTile: View {
    @Environment(\.appZoomScale) private var appZoomScale
    let title: String
    let value: String
    let subtitle: String

    private func zoomed(_ value: CGFloat) -> CGFloat {
        value * CGFloat(appZoomScale)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: zoomed(8)) {
            Text(title)
                .font(.system(size: zoomed(10), weight: .semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: zoomed(24), weight: .semibold, design: .rounded))
            Text(subtitle)
                .font(.system(size: zoomed(10)))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(zoomed(16))
        .background {
            RoundedRectangle(cornerRadius: zoomed(16), style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        }
    }
}
