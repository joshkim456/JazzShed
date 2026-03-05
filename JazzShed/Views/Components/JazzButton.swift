import SwiftUI

/// Reusable button styled with the jazz theme.
struct JazzButton: View {
    let title: String
    let icon: String?
    let style: Style
    let action: () -> Void

    enum Style {
        case primary, secondary, destructive
    }

    init(_ title: String, icon: String? = nil, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(tintColor)
    }

    private var tintColor: Color {
        switch style {
        case .primary:     return JazzColors.gold
        case .secondary:   return JazzColors.blue
        case .destructive: return JazzColors.accent
        }
    }
}
