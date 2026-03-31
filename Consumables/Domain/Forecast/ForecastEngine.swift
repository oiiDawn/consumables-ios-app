import Foundation

struct ForecastEngine {
    private let calendar: Calendar
    private let historyWeights: [Double]
    private let minimumHistoryCycles: Int

    init(
        calendar: Calendar = .current,
        historyWeights: [Double] = [0.6, 0.3, 0.1],
        minimumHistoryCycles: Int = 2
    ) {
        self.calendar = calendar
        self.historyWeights = historyWeights
        self.minimumHistoryCycles = max(1, minimumHistoryCycles)
    }

    func forecast(for item: ConsumableItem, now: Date = .now) -> ForecastSnapshot {
        let sortedRecords = item.purchaseRecords.sorted { $0.activatedAt < $1.activatedAt }
        let cycles = cycleLengths(from: sortedRecords)

        let estimatedCycleDays: Int
        let confidence: ForecastConfidence
        if cycles.count >= minimumHistoryCycles {
            estimatedCycleDays = weightedCycleEstimate(from: cycles)
            confidence = .historyBacked
        } else {
            estimatedCycleDays = clampCycleDays(item.defaultCycleDays)
            confidence = .manualOnly
        }

        let latestActivation = sortedRecords.last?.activatedAt ?? now
        let predictedOutDate = calendar.date(
            byAdding: .day,
            value: estimatedCycleDays,
            to: latestActivation
        ) ?? latestActivation
        let daysRemaining = dayDistance(from: now, to: predictedOutDate)

        return ForecastSnapshot(
            estimatedCycleDays: estimatedCycleDays,
            predictedOutDate: predictedOutDate,
            daysRemaining: daysRemaining,
            urgency: UrgencyLevel.from(
                daysRemaining: daysRemaining,
                thresholdDays: item.remindBeforeDays
            ),
            confidence: confidence,
            usableCycleCount: cycles.count
        )
    }

    private func cycleLengths(from records: [PurchaseRecord]) -> [Int] {
        guard records.count >= 2 else {
            return []
        }

        var output: [Int] = []
        output.reserveCapacity(records.count - 1)

        for (current, next) in zip(records, records.dropFirst()) {
            let cycle = dayDistance(from: current.activatedAt, to: next.activatedAt)
            if cycle > 0 {
                output.append(cycle)
            }
        }

        return output
    }

    private func weightedCycleEstimate(from cycles: [Int]) -> Int {
        let sampleSize = min(cycles.count, historyWeights.count)
        let latestCycles = Array(cycles.suffix(sampleSize).reversed())
        let activeWeights = Array(historyWeights.prefix(sampleSize))
        let weightTotal = activeWeights.reduce(0, +)
        let normalizedWeights: [Double]
        if weightTotal > 0 {
            normalizedWeights = activeWeights.map { $0 / weightTotal }
        } else {
            normalizedWeights = Array(repeating: 1.0 / Double(sampleSize), count: sampleSize)
        }

        let weightedValue = zip(latestCycles, normalizedWeights)
            .reduce(0.0) { partial, entry in
                partial + (Double(entry.0) * entry.1)
            }
        return clampCycleDays(Int(weightedValue.rounded()))
    }

    private func dayDistance(from start: Date, to end: Date) -> Int {
        let startOfDay = calendar.startOfDay(for: start)
        let endOfDay = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: startOfDay, to: endOfDay).day ?? 0
    }

    private func clampCycleDays(_ value: Int) -> Int {
        min(max(value, 1), 365)
    }
}
