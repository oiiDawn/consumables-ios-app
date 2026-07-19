import SwiftData

enum ConsumablesSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [InventoryCategory.self, InventoryTemplate.self, InventoryItem.self, UsageRecord.self]
    }
}
