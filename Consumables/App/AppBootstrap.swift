import Foundation
import SwiftData

enum AppBootstrap {
    static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: ConsumablesSchemaV1.self)
        let baseURL = URL.applicationSupportDirectory.appending(path: "Consumables", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        let configuration = ModelConfiguration("ConsumablesV1", schema: schema, url: baseURL.appending(path: "ConsumablesV1.store"))
        return try ModelContainer(for: schema, migrationPlan: ConsumablesMigrationPlan.self, configurations: [configuration])
    }
}
