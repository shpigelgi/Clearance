import Foundation

struct InsightsViewModel {
    let reviews: [MonthlyReview]

    var chronologicallySortedReviews: [MonthlyReview] {
        reviews.sorted {
            if $0.monthKey == $1.monthKey {
                return $0.createdAt < $1.createdAt
            }
            return $0.monthKey < $1.monthKey
        }
    }

    var recentThree: [MonthlyReview] {
        Array(chronologicallySortedReviews.suffix(3))
    }

    var recentSix: [MonthlyReview] {
        Array(chronologicallySortedReviews.suffix(6))
    }

    var rollingAverage1824: Double {
        guard !recentThree.isEmpty else { return 0 }
        let total = recentThree.reduce(0) { $0 + $1.actual1824 }
        return total / Double(recentThree.count)
    }

    var totalWealthVelocity: Double {
        chronologicallySortedReviews.reduce(0) { $0 + $1.totalWealthRouted }
    }
}
