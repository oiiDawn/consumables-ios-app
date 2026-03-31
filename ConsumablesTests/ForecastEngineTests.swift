import Foundation
import XCTest
@testable import Consumables

final class ForecastEngineTests: XCTestCase {
    private var calendar: Calendar!
    private var engine: ForecastEngine!
    private var referenceDate: Date!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        engine = ForecastEngine(calendar: calendar)
        referenceDate = calendar.date(from: DateComponents(year: 2026, month: 3, day: 12))!
    }

    func testColdStartFallsBackToManualCycleWhenOnlyOneRecord() {
        let item = makeItem(
            name: "牙膏",
            defaultCycleDays: 30,
            recordDaysAgo: [12]
        )

        let snapshot = engine.forecast(for: item, now: referenceDate)

        XCTAssertEqual(snapshot.confidence, .manualOnly)
        XCTAssertEqual(snapshot.estimatedCycleDays, 30)
        XCTAssertEqual(snapshot.daysRemaining, 18)
        XCTAssertEqual(snapshot.urgency, .green)
    }

    func testInsufficientHistoryFallsBackToManualCycle() {
        let item = makeItem(
            name: "洗发水",
            defaultCycleDays: 45,
            recordDaysAgo: [70, 40]
        )

        let snapshot = engine.forecast(for: item, now: referenceDate)

        XCTAssertEqual(snapshot.usableCycleCount, 1)
        XCTAssertEqual(snapshot.confidence, .manualOnly)
        XCTAssertEqual(snapshot.estimatedCycleDays, 45)
        XCTAssertEqual(snapshot.daysRemaining, 5)
        XCTAssertEqual(snapshot.urgency, .yellow)
    }

    func testBoundaryClassificationUsesRedYellowGreen() {
        let outTodayItem = makeItem(
            name: "当天耗尽",
            defaultCycleDays: 12,
            recordDaysAgo: [12]
        )
        let oneDayLeftItem = makeItem(
            name: "仅剩一天",
            defaultCycleDays: 13,
            recordDaysAgo: [12]
        )
        let enoughStockItem = makeItem(
            name: "库存充足",
            defaultCycleDays: 20,
            recordDaysAgo: [12]
        )

        let outTodaySnapshot = engine.forecast(for: outTodayItem, now: referenceDate)
        let oneDayLeftSnapshot = engine.forecast(for: oneDayLeftItem, now: referenceDate)
        let enoughStockSnapshot = engine.forecast(for: enoughStockItem, now: referenceDate)

        XCTAssertEqual(outTodaySnapshot.daysRemaining, 0)
        XCTAssertEqual(outTodaySnapshot.urgency, .red)
        XCTAssertEqual(oneDayLeftSnapshot.daysRemaining, 1)
        XCTAssertEqual(oneDayLeftSnapshot.urgency, .yellow)
        XCTAssertEqual(enoughStockSnapshot.daysRemaining, 8)
        XCTAssertEqual(enoughStockSnapshot.urgency, .green)
    }

    func testWeightedHistoryUsesThreeMostRecentCycles() {
        let item = makeItem(
            name: "洗衣液",
            defaultCycleDays: 35,
            recordDaysAgo: [90, 60, 35, 15]
        )

        let snapshot = engine.forecast(for: item, now: referenceDate)

        // Cycles: 30, 25, 20 -> weighted: 20*0.6 + 25*0.3 + 30*0.1 = 22.5 -> 23
        XCTAssertEqual(snapshot.usableCycleCount, 3)
        XCTAssertEqual(snapshot.confidence, .historyBacked)
        XCTAssertEqual(snapshot.estimatedCycleDays, 23)
        XCTAssertEqual(snapshot.daysRemaining, 8)
        XCTAssertEqual(snapshot.urgency, .green)
    }

    func testCycleEstimateClampsToSupportedRange() {
        let highOutlierItem = makeItem(
            name: "长周期测试",
            defaultCycleDays: 30,
            recordDaysAgo: [2500, 1600, 800, 100]
        )
        let highSnapshot = engine.forecast(for: highOutlierItem, now: referenceDate)
        XCTAssertEqual(highSnapshot.confidence, .historyBacked)
        XCTAssertEqual(highSnapshot.estimatedCycleDays, 365)

        let lowOutlierItem = makeItem(
            name: "低周期测试",
            defaultCycleDays: 0,
            recordDaysAgo: [3]
        )
        let lowSnapshot = engine.forecast(for: lowOutlierItem, now: referenceDate)
        XCTAssertEqual(lowSnapshot.confidence, .manualOnly)
        XCTAssertEqual(lowSnapshot.estimatedCycleDays, 1)
        XCTAssertEqual(lowSnapshot.daysRemaining, -2)
        XCTAssertEqual(lowSnapshot.urgency, .red)
    }

    func testThresholdIsConfigurablePerItem() {
        let defaultThresholdItem = makeItem(
            name: "默认阈值",
            defaultCycleDays: 45,
            recordDaysAgo: [40]
        )
        let customThresholdItem = makeItem(
            name: "自定义阈值",
            defaultCycleDays: 45,
            remindBeforeDays: 3,
            recordDaysAgo: [40]
        )

        let defaultSnapshot = engine.forecast(for: defaultThresholdItem, now: referenceDate)
        let customSnapshot = engine.forecast(for: customThresholdItem, now: referenceDate)

        XCTAssertEqual(defaultSnapshot.daysRemaining, 5)
        XCTAssertEqual(defaultSnapshot.urgency, .yellow)
        XCTAssertEqual(customSnapshot.daysRemaining, 5)
        XCTAssertEqual(customSnapshot.urgency, .green)
    }

    private func makeItem(
        name: String,
        defaultCycleDays: Int,
        remindBeforeDays: Int = ConsumableItem.defaultRemindBeforeDays,
        recordDaysAgo: [Int]
    ) -> ConsumableItem {
        let calendar = self.calendar!
        let referenceDate = self.referenceDate!

        let item = ConsumableItem(
            name: name,
            defaultCycleDays: defaultCycleDays,
            remindBeforeDays: remindBeforeDays,
            createdAt: referenceDate,
            updatedAt: referenceDate
        )

        for daysAgo in recordDaysAgo.sorted(by: >) {
            let activatedAt = calendar.date(byAdding: .day, value: -daysAgo, to: referenceDate) ?? referenceDate
            let record = PurchaseRecord(
                purchasedAt: activatedAt,
                activatedAt: activatedAt,
                brandName: nil,
                quantity: 1,
                note: nil,
                item: item,
                createdAt: activatedAt
            )
            item.addPurchaseRecord(record, touchAt: activatedAt)
        }

        return item
    }
}
