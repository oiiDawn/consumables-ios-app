import Foundation
import SwiftData
import XCTest
@testable import Consumables

@MainActor
final class InventoryCommandsTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private var commands: InventoryCommands!

    override func setUpWithError() throws {
        let schema = Schema(versionedSchema: ConsumablesSchemaV1.self)
        container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        context = container.mainContext
        commands = InventoryCommands(context: context)
    }

    override func tearDown() {
        commands = nil; context = nil; container = nil
    }

    func testManualStockAndLifecycleDeriveThreeStates() throws {
        let category = try commands.createCategory(CategoryDraft(name: "洗护"))
        XCTAssertThrowsError(try commands.stock(in: category, draft: InventoryDraft()))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<InventoryItem>()), 0)

        var draft = InventoryDraft(); draft.name = "洗发水"; draft.stockedAt = date(1)
        let saved = try XCTUnwrap(commands.stock(in: category, draft: draft).first)
        XCTAssertEqual(saved.state, .stocked)
        try commands.startUsing(saved, startedAt: date(2), now: date(2))
        XCTAssertEqual(saved.state, .inUse)
        try commands.markDepleted(saved, depletedAt: date(3), now: date(3))
        XCTAssertEqual(saved.state, .depleted)
        try commands.reopen(saved, now: date(4)); XCTAssertEqual(saved.state, .inUse)
        try commands.returnToStock(saved, now: date(5)); XCTAssertEqual(saved.state, .stocked)
    }

    func testTemplateStockIsIndependentAndBatchCreatesDistinctItems() throws {
        let category = try commands.createCategory(CategoryDraft(name: "纸品"))
        var templateDraft = TemplateDraft(); templateDraft.name = "卷纸"; templateDraft.brand = "品牌 A"; templateDraft.specificationText = "12 卷"
        let template = try commands.createTemplate(in: category, draft: templateDraft)
        var stockDraft = InventoryDraft(template: template); stockDraft.count = 3
        let items = try commands.stock(in: category, draft: stockDraft)
        XCTAssertEqual(Set(items.map(\.id)).count, 3)
        template.name = "已修改"
        XCTAssertTrue(items.allSatisfy { $0.name == "卷纸" })
        try commands.deleteTemplate(template)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<InventoryItem>()), 3)
    }

    func testMultipleItemsCanBeInUseButOneItemCannotHaveSecondUsage() throws {
        let category = try commands.createCategory(CategoryDraft(name: "浴室"))
        var draft = InventoryDraft(); draft.name = "毛巾"; draft.count = 2; draft.stockedAt = date(1)
        let items = try commands.stock(in: category, draft: draft)
        try commands.startUsing(items[0], startedAt: date(2)); try commands.startUsing(items[1], startedAt: date(2))
        XCTAssertEqual(items.filter { $0.state == .inUse }.count, 2)
        XCTAssertThrowsError(try commands.startUsing(items[0], startedAt: date(3)))
    }

    func testNonemptyCategoryCannotBeDeletedAndCanBeArchived() throws {
        let category = try commands.createCategory(CategoryDraft(name: "厨房"))
        var draft = InventoryDraft(); draft.name = "洗洁精"
        try commands.stock(in: category, draft: draft)
        XCTAssertThrowsError(try commands.deleteEmptyCategory(category))
        try commands.archiveCategory(category, now: date(2)); XCTAssertNotNil(category.archivedAt)
        try commands.restoreCategory(category, now: date(3)); XCTAssertNil(category.archivedAt)
    }

    func testDeletingInventoryCascadesUsage() throws {
        let category = try commands.createCategory(CategoryDraft(name: "清洁"))
        var draft = InventoryDraft(); draft.name = "清洁剂"; draft.stockedAt = date(1)
        let item = try XCTUnwrap(commands.stock(in: category, draft: draft).first)
        try commands.startUsing(item, startedAt: date(2))
        try commands.deleteInventoryItem(item)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<InventoryItem>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<UsageRecord>()), 0)
    }

    func testDuplicateCategoryNameIsRejectedIgnoringCaseAndWhitespace() throws {
        try commands.createCategory(CategoryDraft(name: "Kitchen"))
        XCTAssertThrowsError(try commands.createCategory(CategoryDraft(name: " kitchen ")))
    }

    private func date(_ day: TimeInterval) -> Date { Date(timeIntervalSince1970: day * 86_400) }
}
