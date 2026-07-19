import Foundation
import SwiftData

@Model
final class InventoryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var specificationText: String?
    var actualPriceAmount: Decimal?
    var actualCurrencyCode: String?
    var stockedAt: Date
    var note: String?
    var createdAt: Date
    var updatedAt: Date
    var category: InventoryCategory
    @Relationship(deleteRule: .cascade, inverse: \UsageRecord.inventoryItem)
    var usageRecord: UsageRecord?

    var state: InventoryState {
        guard let usageRecord else { return .stocked }
        return usageRecord.depletedAt == nil ? .inUse : .depleted
    }

    init(id: UUID = UUID(), category: InventoryCategory, name: String, brand: String? = nil, specificationText: String? = nil, actualPriceAmount: Decimal? = nil, actualCurrencyCode: String? = nil, stockedAt: Date = .now, note: String? = nil, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.category = category
        self.name = name
        self.brand = brand
        self.specificationText = specificationText
        self.actualPriceAmount = actualPriceAmount
        self.actualCurrencyCode = actualCurrencyCode
        self.stockedAt = stockedAt
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
