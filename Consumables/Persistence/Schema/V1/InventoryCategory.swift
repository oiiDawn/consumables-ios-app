import Foundation
import SwiftData

@Model
final class InventoryCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
    var archivedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \InventoryTemplate.category)
    var templates: [InventoryTemplate]
    @Relationship(deleteRule: .cascade, inverse: \InventoryItem.category)
    var items: [InventoryItem]

    init(id: UUID = UUID(), name: String, sortOrder: Int = 0, archivedAt: Date? = nil, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.archivedAt = archivedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.templates = []
        self.items = []
    }
}
