import Foundation
import SwiftData

enum PreviewModelContainer {
    @MainActor
    static func makeSeeded(now: Date = .now) -> ModelContainer {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(
                for: ConsumableItem.self,
                PurchaseRecord.self,
                configurations: configuration
            )
            try ConsumablesSeeder.seedIfNeeded(in: container.mainContext, now: now)
            return container
        } catch {
            fatalError("Failed to build preview model container: \(error)")
        }
    }
}
