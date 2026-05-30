import Foundation
import SwiftUI

/// Default definition of one Clearance-Check spend category for new months.
struct SpendCategoryTemplate: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var target: Double
}

/// Default definition of one Wealth-Engine routing fund for new months.
struct RoutingCategoryTemplate: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var target: Double
    var annualRate: Double
}

/// The user-editable template that brand-new months inherit. Persisted as JSON in
/// UserDefaults and shared app-wide (Settings edits it; SidebarView.createMonth reads it).
/// Editing the template only affects future months — existing months are edited per-month.
/// Spend categories are still a UserDefaults template that new months inherit. Routing funds
/// are no longer a template here — they're persistent `Fund` entities (see `FundMigration`),
/// though `defaultRouting` is kept as the seed for first-run funds.
@MainActor
final class CategoryTemplateStore: ObservableObject {
    @Published var spend: [SpendCategoryTemplate] { didSet { persist() } }

    private let spendKey = "spendCategoryTemplate"
    private let defaults: UserDefaults
    private let isVolatile: Bool

    init(defaults: UserDefaults = .standard) {
        // Under UI tests, keep the template deterministic (always the seeded defaults) and
        // never read or write the user's real template — without touching disk at all.
        isVolatile = ProcessInfo.processInfo.environment["CLEARANCE_UITEST_INMEMORY"] == "1"
        self.defaults = defaults
        if isVolatile {
            spend = Self.defaultSpend
        } else {
            spend = Self.load(spendKey, from: defaults) ?? Self.defaultSpend
            persist() // ensure first-run seed is saved (didSet doesn't fire during init)
        }
    }

    private static func load<T: Decodable>(_ key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func persist() {
        guard !isVolatile else { return } // never write the real template during UI tests
        if let data = try? JSONEncoder().encode(spend) { defaults.set(data, forKey: spendKey) }
    }

    // First-run defaults — note "Car fund" in place of the former "Abarth Keren Kaspit".
    static let defaultSpend: [SpendCategoryTemplate] = [
        .init(name: "Mizrahi", target: 3_544),
        .init(name: "1824", target: 3_250),
    ]

    static let defaultRouting: [RoutingCategoryTemplate] = [
        .init(name: "IIT portfolio", target: 1_506, annualRate: 0.08),
        .init(name: "Emergency Keren Kaspit", target: 1_000, annualRate: 0.0375),
        .init(name: "Car fund", target: 400, annualRate: 0.0375),
        .init(name: "Hobby Keren Kaspit", target: 300, annualRate: 0.0375),
    ]
}
