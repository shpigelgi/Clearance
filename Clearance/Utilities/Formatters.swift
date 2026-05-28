import Foundation

enum Formatters {
    static let currency: FloatingPointFormatStyle<Double>.Currency = .currency(code: "ILS")
        .precision(.fractionLength(0...2))

    static let number: FloatingPointFormatStyle<Double> = .number
        .precision(.fractionLength(0...2))

    static let percent: FloatingPointFormatStyle<Double>.Percent = .percent
        .precision(.fractionLength(0...2))

    static func monthTitle(from monthKey: String) -> String {
        let parts = monthKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return monthKey }

        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = 1

        guard let date = Calendar.current.date(from: components) else { return monthKey }
        return date.formatted(.dateTime.month(.wide).year())
    }

    static func exportDateStamp(for date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        return formatter.string(from: date)
    }
}
