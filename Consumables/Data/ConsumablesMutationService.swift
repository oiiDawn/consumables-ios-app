import Foundation
import SwiftData

@MainActor
final class ConsumablesMutationService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    @discardableResult
    func createItem(
        name: String,
        defaultCycleDays: Int,
        remindBeforeDays: Int = ConsumableItem.defaultRemindBeforeDays,
        activatedAt: Date = .now,
        purchasedAt: Date? = nil,
        brandName: String? = nil,
        quantity: Int = 1,
        note: String? = nil,
        purchaseNote: String? = nil,
        createdAt: Date = .now
    ) throws -> ConsumableItem {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else {
            throw ValidationError.emptyName
        }

        let item = ConsumableItem(
            name: normalizedName,
            defaultCycleDays: defaultCycleDays,
            remindBeforeDays: remindBeforeDays,
            note: PurchaseRecord.cleanOptionalText(note),
            createdAt: createdAt,
            updatedAt: createdAt
        )
        context.insert(item)

        let firstRecord = PurchaseRecord(
            purchasedAt: purchasedAt ?? activatedAt,
            activatedAt: activatedAt,
            brandName: brandName,
            quantity: quantity,
            note: purchaseNote,
            item: item,
            createdAt: activatedAt
        )
        context.insert(firstRecord)
        item.addPurchaseRecord(firstRecord, touchAt: createdAt)

        try context.save()
        return item
    }

    func updateItem(
        _ item: ConsumableItem,
        name: String? = nil,
        defaultCycleDays: Int? = nil,
        remindBeforeDays: Int? = nil,
        note: String? = nil,
        updatedAt: Date = .now
    ) throws {
        var normalizedName: String?
        if let name {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw ValidationError.emptyName
            }
            normalizedName = trimmed
        }

        item.applyUpdate(
            name: normalizedName,
            defaultCycleDays: defaultCycleDays,
            remindBeforeDays: remindBeforeDays,
            note: PurchaseRecord.cleanOptionalText(note),
            updatedAt: updatedAt
        )
        try context.save()
    }

    func archiveItem(_ item: ConsumableItem, archivedAt: Date = .now) throws {
        item.archive(at: archivedAt)
        try context.save()
    }

    @discardableResult
    func logPurchase(
        for item: ConsumableItem,
        activatedAt: Date = .now,
        purchasedAt: Date = .now,
        brandName: String? = nil,
        quantity: Int = 1,
        note: String? = nil,
        createdAt: Date = .now
    ) throws -> PurchaseRecord {
        let record = PurchaseRecord(
            purchasedAt: purchasedAt,
            activatedAt: activatedAt,
            brandName: brandName,
            quantity: quantity,
            note: note,
            item: item,
            createdAt: createdAt
        )
        context.insert(record)
        item.addPurchaseRecord(record, touchAt: createdAt)
        try context.save()
        return record
    }
}

extension ConsumablesMutationService {
    enum ValidationError: LocalizedError {
        case emptyName

        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "名称不能为空。"
            }
        }
    }
}
