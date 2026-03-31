import Foundation

struct ConsumableForecastViewData: Identifiable {
    let item: ConsumableItem
    let snapshot: ForecastSnapshot

    var id: UUID { item.id }
    var name: String { item.name }
}

enum ConsumableForecastSort {
    static func prioritize(_ lhs: ConsumableForecastViewData, _ rhs: ConsumableForecastViewData) -> Bool {
        if lhs.snapshot.daysRemaining != rhs.snapshot.daysRemaining {
            return lhs.snapshot.daysRemaining < rhs.snapshot.daysRemaining
        }
        if lhs.item.updatedAt != rhs.item.updatedAt {
            return lhs.item.updatedAt > rhs.item.updatedAt
        }
        return lhs.item.name.localizedCaseInsensitiveCompare(rhs.item.name) == .orderedAscending
    }
}

struct ConsumableForecastBuilder {
    private let engine: ForecastEngine

    init(engine: ForecastEngine = ForecastEngine()) {
        self.engine = engine
    }

    func build(items: [ConsumableItem], now: Date = .now) -> [ConsumableForecastViewData] {
        items
            .map { ConsumableForecastViewData(item: $0, snapshot: engine.forecast(for: $0, now: now)) }
            .sorted(by: ConsumableForecastSort.prioritize)
    }
}
