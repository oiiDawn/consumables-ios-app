import SwiftUI

struct UrgencyStyle {
    let prominentTint: Color
    let accentTint: Color
    let softBackground: Color
    let cardBackground: Color
    let cardBorder: Color
    let badgeForeground: Color
    let badgeBackground: Color
    let badgeBorder: Color
    let label: String
    let symbolName: String
}

extension UrgencyLevel {
    var style: UrgencyStyle {
        switch self {
        case .red:
            return UrgencyStyle(
                prominentTint: .red,
                accentTint: .red,
                softBackground: .red.opacity(0.12),
                cardBackground: .red.opacity(0.08),
                cardBorder: .red.opacity(0.24),
                badgeForeground: .white,
                badgeBackground: .red,
                badgeBorder: .red,
                label: "缺货",
                symbolName: "xmark.octagon.fill"
            )
        case .yellow:
            return UrgencyStyle(
                prominentTint: .orange,
                accentTint: .yellow,
                softBackground: .yellow.opacity(0.18),
                cardBackground: .yellow.opacity(0.10),
                cardBorder: .yellow.opacity(0.40),
                badgeForeground: .orange,
                badgeBackground: .yellow.opacity(0.26),
                badgeBorder: .yellow.opacity(0.7),
                label: "即将耗尽",
                symbolName: "exclamationmark.triangle.fill"
            )
        case .green:
            return UrgencyStyle(
                prominentTint: .green,
                accentTint: .green,
                softBackground: .green.opacity(0.10),
                cardBackground: .green.opacity(0.06),
                cardBorder: .green.opacity(0.24),
                badgeForeground: .green,
                badgeBackground: .green.opacity(0.16),
                badgeBorder: .green.opacity(0.4),
                label: "库存充足",
                symbolName: "checkmark.circle.fill"
            )
        }
    }

    var sectionTitle: String {
        switch self {
        case .red:
            return "缺货"
        case .yellow:
            return "即将耗尽"
        case .green:
            return "库存充足"
        }
    }
}
