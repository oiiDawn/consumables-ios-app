import Foundation

struct ForecastViewData: Equatable, Sendable {
    let daysRemainingText: String
    let predictedOutDateText: String
    let urgencyText: String
    let confidenceText: String
}

struct ForecastViewDataMapper {
    private let formatter: DateFormatter

    init(formatter: DateFormatter = ForecastViewDataMapper.defaultFormatter()) {
        self.formatter = formatter
    }

    func map(_ snapshot: ForecastSnapshot) -> ForecastViewData {
        ForecastViewData(
            daysRemainingText: daysRemainingText(snapshot.daysRemaining),
            predictedOutDateText: formatter.string(from: snapshot.predictedOutDate),
            urgencyText: label(for: snapshot.urgency),
            confidenceText: label(for: snapshot.confidence)
        )
    }

    private func daysRemainingText(_ days: Int) -> String {
        if days < 0 {
            return "缺货 \(abs(days)) 天"
        }
        if days == 0 {
            return "今天缺货"
        }
        return "\(days) 天"
    }

    private func label(for urgency: UrgencyLevel) -> String {
        switch urgency {
        case .red:
            return "缺货"
        case .yellow:
            return "即将耗尽"
        case .green:
            return "库存充足"
        }
    }

    private func label(for confidence: ForecastConfidence) -> String {
        switch confidence {
        case .manualOnly:
            return "手动周期"
        case .historyBacked:
            return "历史推断"
        }
    }

    static func defaultFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
