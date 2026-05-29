import SwiftUI

enum ValueComparison {
    static func approximatelyEqual(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 0.005
    }
}

struct RevertableInputRow<Content: View>: View {
    let title: String
    let isDefault: Bool
    let revert: () -> Void
    var spacing: CGFloat
    private let content: Content

    init(
        title: String,
        isDefault: Bool,
        spacing: CGFloat = 6,
        revert: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isDefault = isDefault
        self.spacing = spacing
        self.revert = revert
        self.content = content()
    }

    var body: some View {
        HStack(spacing: spacing) {
            content

            RevertToDefaultButton(
                title: title,
                isDefault: isDefault,
                action: revert
            )
        }
    }
}

struct RevertToDefaultButton: View {
    let title: String
    let isDefault: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.counterclockwise")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Revert \(title) to default")
        .accessibilityLabel("Revert \(title) to default")
        .opacity(isDefault ? 0.4 : 0.82)
        .disabled(isDefault)
    }
}
