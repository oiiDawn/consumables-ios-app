import SwiftData

enum ConsumablesMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [ConsumablesSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
