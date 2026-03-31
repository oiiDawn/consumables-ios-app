import Foundation
import SwiftData

@Model
final class PurchaseRecord {
    @Attribute(.unique) var id: UUID
    var purchasedAt: Date
    var activatedAt: Date
    var brandName: String?
    var quantity: Int
    var note: String?
    var createdAt: Date

    var item: ConsumableItem?

    init(
        id: UUID = UUID(),
        purchasedAt: Date,
        activatedAt: Date,
        brandName: String? = nil,
        quantity: Int = 1,
        note: String? = nil,
        item: ConsumableItem? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.purchasedAt = purchasedAt
        self.activatedAt = activatedAt
        self.brandName = PurchaseRecord.cleanOptionalText(brandName)
        self.quantity = max(quantity, 1)
        self.note = PurchaseRecord.cleanOptionalText(note)
        self.item = item
        self.createdAt = createdAt
    }

    static func cleanOptionalText(_ value: String?) -> String? {
        guard let value else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
