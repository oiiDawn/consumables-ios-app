import Foundation
import SwiftData

@Model
final class ConsumableItem {
    static let defaultRemindBeforeDays = 7

    @Attribute(.unique) var id: UUID
    var name: String
    var defaultCycleDays: Int
    var remindBeforeDays: Int = ConsumableItem.defaultRemindBeforeDays
    var note: String?
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PurchaseRecord.item)
    var purchaseRecords: [PurchaseRecord]

    init(
        id: UUID = UUID(),
        name: String,
        defaultCycleDays: Int,
        remindBeforeDays: Int = ConsumableItem.defaultRemindBeforeDays,
        note: String? = nil,
        isArchived: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        purchaseRecords: [PurchaseRecord] = []
    ) {
        self.id = id
        self.name = name
        self.defaultCycleDays = Self.clampCycleDays(defaultCycleDays)
        self.remindBeforeDays = Self.clampRemindBeforeDays(remindBeforeDays)
        self.note = note
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.purchaseRecords = purchaseRecords
    }

    func applyUpdate(
        name: String? = nil,
        defaultCycleDays: Int? = nil,
        remindBeforeDays: Int? = nil,
        note: String? = nil,
        updatedAt: Date = .now
    ) {
        if let name {
            self.name = name
        }
        if let defaultCycleDays {
            self.defaultCycleDays = Self.clampCycleDays(defaultCycleDays)
        }
        if let remindBeforeDays {
            self.remindBeforeDays = Self.clampRemindBeforeDays(remindBeforeDays)
        }
        self.note = note
        self.updatedAt = updatedAt
    }

    func archive(at date: Date = .now) {
        isArchived = true
        updatedAt = date
    }

    @discardableResult
    func addPurchaseRecord(_ record: PurchaseRecord, touchAt date: Date = .now) -> PurchaseRecord {
        if !purchaseRecords.contains(where: { $0.id == record.id }) {
            purchaseRecords.append(record)
        }
        if record.item !== self {
            record.item = self
        }
        updatedAt = date
        return record
    }

    static func clampCycleDays(_ value: Int) -> Int {
        min(max(value, 1), 365)
    }

    static func clampRemindBeforeDays(_ value: Int) -> Int {
        min(max(value, 1), 60)
    }

    var latestPurchaseRecord: PurchaseRecord? {
        purchaseRecords.max(by: { $0.activatedAt < $1.activatedAt })
    }
}
