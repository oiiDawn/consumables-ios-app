import SwiftUI

struct ConsumableRowCard: View {
    let forecast: ConsumableForecastViewData

    var body: some View {
        let style = forecast.snapshot.urgency.style

        VStack(alignment: .leading, spacing: 12) {
            Text(forecast.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(forecast.name)

            ConsumableProgressIndicator(
                snapshot: forecast.snapshot,
                style: style,
                compact: true
            )

            Label(forecast.snapshot.predictedOutDate.consumablesDateText(), systemImage: "calendar")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .accessibilityLabel("预计耗尽日期：\(forecast.snapshot.predictedOutDate.consumablesDateText())")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(style.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(style.cardBorder, lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(style.accentTint)
                .frame(width: 4)
                .padding(.vertical, 10)
        }
        .animation(.snappy(duration: 0.25), value: forecast.snapshot.daysRemaining)
        .accessibilityElement(children: .combine)
        .accessibilityHint("双击查看详情")
    }
}

struct ConsumableProgressIndicator: View {
    let snapshot: ForecastSnapshot
    let style: UrgencyStyle
    var compact: Bool = false

    var body: some View {
        ProgressBarView(
            percentage: snapshot.remainingPercentage,
            tint: style.prominentTint,
            label: "\(snapshot.remainingPercentage)%",
            compact: compact
        )
        .frame(width: compact ? 92 : 126, height: compact ? 20 : 26)
        .accessibilityLabel("剩余库存")
        .accessibilityValue(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        let percentText = "\(snapshot.remainingPercentage)%"
        let daysText = snapshot.daysRemaining < 0
            ? "已缺货 \(abs(snapshot.daysRemaining)) 天"
            : snapshot.daysRemaining == 0
                ? "今日缺货"
                : "剩余 \(snapshot.daysRemaining) 天"
        return "\(percentText)，\(daysText)"
    }
}

private struct ProgressBarView: View {
    let percentage: Int
    let tint: Color
    let label: String
    var compact: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let clampedWidth = max(geometry.size.width, 0)
            let fillWidth = clampedWidth * CGFloat(percentage) / 100

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.tertiarySystemFill))

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tint.opacity(0.85))
                    .frame(width: percentage == 0 ? 0 : max(fillWidth, 2))

                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(tint.opacity(0.5), lineWidth: 1)

                Text(label)
                    .font(.system(size: compact ? 10 : 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(percentage >= 45 ? Color.white.opacity(0.95) : tint)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .contentTransition(.numericText())
            }
        }
    }
}

extension ForecastSnapshot {
    var remainingPercentage: Int {
        let safeDaysRemaining = max(daysRemaining, 0)
        let safeCycleDays = max(estimatedCycleDays, 1)
        let raw = (Double(safeDaysRemaining) / Double(safeCycleDays)) * 100
        return max(0, min(100, Int(raw.rounded())))
    }

    var remainingDaysSupportText: String {
        if daysRemaining < 0 {
            return "缺货 \(abs(daysRemaining)) 天 · 周期 \(estimatedCycleDays) 天"
        }
        if daysRemaining == 0 {
            return "今日缺货 · 周期 \(estimatedCycleDays) 天"
        }
        return "剩余 \(daysRemaining) 天 · 周期 \(estimatedCycleDays) 天"
    }
}
