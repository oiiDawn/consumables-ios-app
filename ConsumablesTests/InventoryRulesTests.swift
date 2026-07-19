import Foundation
import XCTest
@testable import Consumables

final class InventoryRulesTests: XCTestCase {
    func testTextNormalizationAndValidation() throws {
        XCTAssertEqual(try InventoryRules.requiredText("  洗发水 \n"), "洗发水")
        XCTAssertNil(InventoryRules.optionalText("  \n"))
        XCTAssertThrowsError(try InventoryRules.requiredText("  "))
    }

    func testMoneyRequiresNonnegativeAmountAndISOCurrency() throws {
        let expected = try Money(amount: 39.9, currencyCode: "CNY")
        XCTAssertEqual(try Money(amount: 39.9, currencyCode: " cny "), expected)
        XCTAssertThrowsError(try Money(amount: -1, currencyCode: "CNY"))
        XCTAssertThrowsError(try Money(amount: 1, currencyCode: "NOPE"))
        XCTAssertThrowsError(try InventoryRules.money(amount: 1, currencyCode: nil))
    }

    func testLifecycleDatesMustBeOrdered() throws {
        let stockedAt = Date(timeIntervalSince1970: 100)
        let startedAt = Date(timeIntervalSince1970: 200)
        let depletedAt = Date(timeIntervalSince1970: 300)
        XCTAssertNoThrow(try InventoryRules.validate(stockedAt: stockedAt, startedAt: startedAt, depletedAt: depletedAt))
        XCTAssertThrowsError(try InventoryRules.validate(stockedAt: startedAt, startedAt: stockedAt))
        XCTAssertThrowsError(try InventoryRules.validate(stockedAt: stockedAt, startedAt: depletedAt, depletedAt: startedAt))
    }
}
