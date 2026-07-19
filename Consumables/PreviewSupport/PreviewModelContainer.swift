import SwiftData

enum PreviewModelContainer {
    @MainActor static func makeSeeded() -> ModelContainer {
        do {
            let schema = Schema(versionedSchema: ConsumablesSchemaV1.self)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
            let category = InventoryCategory(name: "洗护用品")
            container.mainContext.insert(category)
            container.mainContext.insert(InventoryTemplate(category: category, name: "洗发水", brand: "示例品牌", specificationText: "500ml"))
            let stocked = InventoryItem(category: category, name: "洗发水", brand: "示例品牌", specificationText: "500ml")
            let active = InventoryItem(category: category, name: "护发素", specificationText: "400ml")
            container.mainContext.insert(stocked); container.mainContext.insert(active)
            let usage = UsageRecord(inventoryItem: active, startedAt: .now)
            container.mainContext.insert(usage); active.usageRecord = usage
            try container.mainContext.save(); return container
        } catch { fatalError("Failed to build preview container: \(error)") }
    }
}
