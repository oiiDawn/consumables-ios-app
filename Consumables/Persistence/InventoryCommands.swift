import Foundation
import SwiftData

@MainActor
final class InventoryCommands {
    private let context: ModelContext

    init(context: ModelContext) { self.context = context }

    @discardableResult
    func createCategory(_ draft: CategoryDraft, now: Date = .now) throws -> InventoryCategory {
        let name = try InventoryRules.requiredText(draft.name)
        try ensureUniqueCategoryName(name)
        let count = try context.fetchCount(FetchDescriptor<InventoryCategory>())
        let category = InventoryCategory(name: name, sortOrder: count, createdAt: now, updatedAt: now)
        context.insert(category)
        try save()
        return category
    }

    func updateCategory(_ category: InventoryCategory, draft: CategoryDraft, now: Date = .now) throws {
        let name = try InventoryRules.requiredText(draft.name)
        try ensureUniqueCategoryName(name, excluding: category.id)
        category.name = name
        category.updatedAt = now
        try save()
    }

    func archiveCategory(_ category: InventoryCategory, now: Date = .now) throws {
        category.archivedAt = now; category.updatedAt = now; try save()
    }

    func restoreCategory(_ category: InventoryCategory, now: Date = .now) throws {
        category.archivedAt = nil; category.updatedAt = now; try save()
    }

    func deleteEmptyCategory(_ category: InventoryCategory) throws {
        guard category.templates.isEmpty, category.items.isEmpty else { throw InventoryValidationError.categoryIsNotEmpty }
        context.delete(category); try save()
    }

    @discardableResult
    func createTemplate(in category: InventoryCategory, draft: TemplateDraft, now: Date = .now) throws -> InventoryTemplate {
        let values = try normalized(draft)
        let template = InventoryTemplate(category: category, name: values.name, brand: values.brand, specificationText: values.specification, referencePriceAmount: values.money?.amount, referenceCurrencyCode: values.money?.currencyCode, note: values.note, createdAt: now, updatedAt: now)
        context.insert(template); try save(); return template
    }

    func updateTemplate(_ template: InventoryTemplate, draft: TemplateDraft, now: Date = .now) throws {
        let values = try normalized(draft)
        template.name = values.name; template.brand = values.brand; template.specificationText = values.specification
        template.referencePriceAmount = values.money?.amount; template.referenceCurrencyCode = values.money?.currencyCode
        template.note = values.note; template.updatedAt = now; try save()
    }

    func deleteTemplate(_ template: InventoryTemplate) throws { context.delete(template); try save() }

    @discardableResult
    func stock(in category: InventoryCategory, draft: InventoryDraft, now: Date = .now) throws -> [InventoryItem] {
        guard (1...999).contains(draft.count) else { throw InventoryValidationError.invalidCount }
        let values = try normalized(draft)
        let items = (0..<draft.count).map { _ in
            InventoryItem(category: category, name: values.name, brand: values.brand, specificationText: values.specification, actualPriceAmount: values.money?.amount, actualCurrencyCode: values.money?.currencyCode, stockedAt: draft.stockedAt, note: values.note, createdAt: now, updatedAt: now)
        }
        items.forEach(context.insert); try save(); return items
    }

    func updateInventoryItem(_ item: InventoryItem, draft: InventoryDraft, category: InventoryCategory? = nil, now: Date = .now) throws {
        let values = try normalized(draft)
        if let usage = item.usageRecord { try InventoryRules.validate(stockedAt: draft.stockedAt, startedAt: usage.startedAt, depletedAt: usage.depletedAt) }
        item.name = values.name; item.brand = values.brand; item.specificationText = values.specification
        item.actualPriceAmount = values.money?.amount; item.actualCurrencyCode = values.money?.currencyCode
        item.stockedAt = draft.stockedAt; item.note = values.note
        if let category { item.category = category }
        item.updatedAt = now; try save()
    }

    func deleteInventoryItem(_ item: InventoryItem) throws {
        if let usage = item.usageRecord {
            item.usageRecord = nil; usage.inventoryItem = nil; context.delete(usage)
        }
        context.delete(item); try save()
    }

    @discardableResult
    func startUsing(_ item: InventoryItem, startedAt: Date = .now, now: Date = .now) throws -> UsageRecord {
        guard item.usageRecord == nil else { throw InventoryValidationError.usageAlreadyExists }
        try InventoryRules.validate(stockedAt: item.stockedAt, startedAt: startedAt)
        let usage = UsageRecord(inventoryItem: item, startedAt: startedAt, createdAt: now, updatedAt: now)
        context.insert(usage); item.usageRecord = usage; item.updatedAt = now; try save(); return usage
    }

    func markDepleted(_ item: InventoryItem, depletedAt: Date = .now, now: Date = .now) throws {
        guard let usage = item.usageRecord else { throw InventoryValidationError.usageDoesNotExist }
        try InventoryRules.validate(stockedAt: item.stockedAt, startedAt: usage.startedAt, depletedAt: depletedAt)
        usage.depletedAt = depletedAt; usage.updatedAt = now; item.updatedAt = now; try save()
    }

    func reopen(_ item: InventoryItem, now: Date = .now) throws {
        guard let usage = item.usageRecord else { throw InventoryValidationError.usageDoesNotExist }
        usage.depletedAt = nil; usage.updatedAt = now; item.updatedAt = now; try save()
    }

    func updateUsage(_ item: InventoryItem, startedAt: Date, depletedAt: Date?, now: Date = .now) throws {
        guard let usage = item.usageRecord else { throw InventoryValidationError.usageDoesNotExist }
        try InventoryRules.validate(stockedAt: item.stockedAt, startedAt: startedAt, depletedAt: depletedAt)
        usage.startedAt = startedAt; usage.depletedAt = depletedAt; usage.updatedAt = now
        item.updatedAt = now; try save()
    }

    func returnToStock(_ item: InventoryItem, now: Date = .now) throws {
        guard let usage = item.usageRecord else { throw InventoryValidationError.usageDoesNotExist }
        item.usageRecord = nil; usage.inventoryItem = nil; context.delete(usage); item.updatedAt = now; try save()
    }

    private func ensureUniqueCategoryName(_ name: String, excluding id: UUID? = nil) throws {
        let normalized = name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let categories = try context.fetch(FetchDescriptor<InventoryCategory>())
        guard !categories.contains(where: { $0.id != id && $0.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current) == normalized }) else {
            throw InventoryValidationError.duplicateCategoryName
        }
    }

    private func normalized(_ draft: TemplateDraft) throws -> (name: String, brand: String?, specification: String?, money: Money?, note: String?) {
        (try InventoryRules.requiredText(draft.name), InventoryRules.optionalText(draft.brand), InventoryRules.optionalText(draft.specificationText), try InventoryRules.money(amount: draft.priceAmount, currencyCode: draft.priceAmount == nil ? nil : draft.currencyCode), InventoryRules.optionalText(draft.note))
    }

    private func normalized(_ draft: InventoryDraft) throws -> (name: String, brand: String?, specification: String?, money: Money?, note: String?) {
        (try InventoryRules.requiredText(draft.name), InventoryRules.optionalText(draft.brand), InventoryRules.optionalText(draft.specificationText), try InventoryRules.money(amount: draft.priceAmount, currencyCode: draft.priceAmount == nil ? nil : draft.currencyCode), InventoryRules.optionalText(draft.note))
    }

    private func save() throws {
        do { try context.save() } catch { context.rollback(); throw error }
    }
}
