import SwiftUI

private struct AppZoomScaleKey: EnvironmentKey {
    static let defaultValue = 1.0
}

extension EnvironmentValues {
    var appZoomScale: Double {
        get { self[AppZoomScaleKey.self] }
        set { self[AppZoomScaleKey.self] = newValue }
    }
}
