import SwiftUI
import SwiftData

@main
struct ConsumablesApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(
                for: ConsumableItem.self,
                PurchaseRecord.self
            )
            try ConsumablesSeeder.seedIfNeeded(in: modelContainer.mainContext)
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(modelContainer)
    }
}
