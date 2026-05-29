import SwiftUI

extension View {
    /// Applies an Apple Liquid Glass surface on macOS 26+ (Tahoe), falling back to the
    /// supplied material background on earlier systems. Centralizes the `#available` gate
    /// so call sites stay clean and keep working on macOS 14–25.
    ///
    /// - Parameters:
    ///   - cornerRadius: corner radius for the glass (and the fallback shape).
    ///   - tint: optional tint for stateful emphasis (e.g. surplus/deficit).
    ///   - fallback: the pre-Tahoe background view (the app's existing card material).
    @ViewBuilder
    func glassSurface<Fallback: View>(
        cornerRadius: CGFloat,
        tint: Color? = nil,
        @ViewBuilder fallback: () -> Fallback
    ) -> some View {
        if #available(macOS 26.0, *) {
            if let tint {
                glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
            } else {
                glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            background { fallback() }
        }
    }
}
