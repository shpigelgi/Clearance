import SwiftData
import SwiftUI

struct RootView: View {
    @Query(sort: [SortDescriptor(\MonthlyReview.monthKey, order: .reverse)])
    private var reviews: [MonthlyReview]

    @State private var selectedMonthKey: String?

    private var selectedReview: MonthlyReview? {
        if let selectedMonthKey,
           let review = reviews.first(where: { $0.monthKey == selectedMonthKey }) {
            return review
        }

        return reviews.first
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedMonthKey)
        } detail: {
            if let selectedReview {
                MonthDetailView(review: selectedReview)
            } else {
                ContentUnavailableView {
                    Label("No Monthly Review", systemImage: "calendar.badge.plus")
                } description: {
                    Text("Start a new month from the sidebar to begin routing your cash flow.")
                }
            }
        }
        .navigationTitle("Clearance")
        .toolbarBackground(.hidden, for: .windowToolbar)
        .background(WindowChromeConfigurator())
        .onAppear(perform: selectDefaultReviewIfNeeded)
        .onChange(of: reviews.map(\.monthKey)) { _, _ in
            selectDefaultReviewIfNeeded()
        }
    }

    private func selectDefaultReviewIfNeeded() {
        guard selectedMonthKey == nil || !reviews.contains(where: { $0.monthKey == selectedMonthKey }) else {
            return
        }

        selectedMonthKey = reviews.first?.monthKey
    }
}
