import Foundation
import SwiftData

@Model
final class InventoryTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var specificationText: String?
    var referencePriceAmount: Decimal?
    var referenceCurrencyCode: String?
    var note: String?
    var createdAt: Date
    var updatedAt: Date
    var category: InventoryCategory

    init(id: UUID = UUID(), category: InventoryCategory, name: String, brand: String? = nil, specificationText: String? = nil, referencePriceAmount: Decimal? = nil, referenceCurrencyCode: String? = nil, note: String? = nil, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.category = category
        self.name = name
        self.brand = brand
        self.specificationText = specificationText
        self.referencePriceAmount = referencePriceAmount
        self.referenceCurrencyCode = referenceCurrencyCode
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
