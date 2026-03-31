import SwiftUI

struct ConsumableStatusBadge: View {
    let urgency: UrgencyLevel

    var body: some View {
        let style = urgency.style

        Circle()
            .fill(style.accentTint)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(style.cardBackground, lineWidth: 2)
            )
            .accessibilityLabel(Text(accessibilityText))
    }

    private var accessibilityText: String {
        switch urgency {
        case .red:
            return "缺货"
        case .yellow:
            return "即将耗尽"
        case .green:
            return "库存充足"
        }
    }
}
