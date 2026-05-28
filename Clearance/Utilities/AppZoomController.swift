import Foundation
import SwiftUI

@MainActor
final class AppZoomController: ObservableObject {
    private static let zoomScaleKey = "appZoomScale"
    private let minimumScale = 0.75
    private let maximumScale = 1.50
    private let step = 0.15

    @Published var scale: Double {
        didSet {
            UserDefaults.standard.set(scale, forKey: Self.zoomScaleKey)
        }
    }

    init() {
        let storedScale = UserDefaults.standard.double(forKey: Self.zoomScaleKey)
        scale = storedScale == 0 ? 1.0 : min(max(storedScale, minimumScale), maximumScale)
    }

    var dynamicTypeSize: DynamicTypeSize {
        switch scale {
        case ..<0.85:
            .small
        case ..<1.10:
            .medium
        case ..<1.25:
            .large
        case ..<1.40:
            .xLarge
        default:
            .xxLarge
        }
    }

    func zoomIn() {
        scale = min(maximumScale, rounded(scale + step))
    }

    func zoomOut() {
        scale = max(minimumScale, rounded(scale - step))
    }

    func reset() {
        scale = 1.0
    }

    private func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}
