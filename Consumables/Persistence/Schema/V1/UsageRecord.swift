import Foundation
import SwiftData

@Model
final class UsageRecord {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var depletedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var inventoryItem: InventoryItem?

    init(id: UUID = UUID(), inventoryItem: InventoryItem, startedAt: Date, depletedAt: Date? = nil, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.inventoryItem = inventoryItem
        self.startedAt = startedAt
        self.depletedAt = depletedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
