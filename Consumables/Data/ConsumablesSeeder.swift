import Foundation
import SwiftData

enum ConsumablesSeeder {
    static func seedIfNeeded(in context: ModelContext, now: Date = .now) throws {
        var descriptor = FetchDescriptor<ConsumableItem>()
        descriptor.fetchLimit = 1

        if try !context.fetch(descriptor).isEmpty {
            return
        }

        try seedSampleData(in: context, now: now)
    }

    static func seedSampleData(in context: ModelContext, now: Date = .now) throws {
        let calendar = Calendar.current

        for sample in sampleItems {
            let item = ConsumableItem(
                name: sample.name,
                defaultCycleDays: sample.defaultCycleDays,
                note: sample.itemNote,
                createdAt: now,
                updatedAt: now
            )
            context.insert(item)

            for record in sample.records {
                let activatedAt = calendar.date(byAdding: .day, value: -record.activatedDaysAgo, to: now) ?? now
                let purchasedAt = calendar.date(byAdding: .day, value: -record.purchasedDaysAgo, to: now) ?? activatedAt
                let purchase = PurchaseRecord(
                    purchasedAt: purchasedAt,
                    activatedAt: activatedAt,
                    brandName: record.brandName,
                    quantity: record.quantity,
                    note: record.note,
                    item: item,
                    createdAt: activatedAt
                )
                context.insert(purchase)
                item.addPurchaseRecord(purchase, touchAt: activatedAt)
            }
        }

        try context.save()
    }
}

private extension ConsumablesSeeder {
    struct SeedRecord {
        let activatedDaysAgo: Int
        let purchasedDaysAgo: Int
        let brandName: String?
        let quantity: Int
        let note: String?

        init(
            activatedDaysAgo: Int,
            purchasedDaysAgo: Int? = nil,
            brandName: String? = nil,
            quantity: Int = 1,
            note: String? = nil
        ) {
            self.activatedDaysAgo = activatedDaysAgo
            self.purchasedDaysAgo = purchasedDaysAgo ?? activatedDaysAgo
            self.brandName = brandName
            self.quantity = quantity
            self.note = note
        }
    }

    struct SeedItem {
        let name: String
        let defaultCycleDays: Int
        let itemNote: String?
        let records: [SeedRecord]
    }

    static let sampleItems: [SeedItem] = [
        SeedItem(
            name: "卷纸",
            defaultCycleDays: 14,
            itemNote: nil,
            records: [
                SeedRecord(activatedDaysAgo: 70, brandName: "维达"),
                SeedRecord(activatedDaysAgo: 56, brandName: "清风"),
                SeedRecord(activatedDaysAgo: 42, brandName: "心相印"),
                SeedRecord(activatedDaysAgo: 29, brandName: "清风"),
                SeedRecord(activatedDaysAgo: 13, brandName: "维达")
            ]
        ),
        SeedItem(
            name: "抽纸",
            defaultCycleDays: 18,
            itemNote: nil,
            records: [
                SeedRecord(activatedDaysAgo: 72, brandName: "洁柔"),
                SeedRecord(activatedDaysAgo: 54, brandName: "洁柔"),
                SeedRecord(activatedDaysAgo: 36, brandName: "维达"),
                SeedRecord(activatedDaysAgo: 14, brandName: "维达")
            ]
        ),
        SeedItem(
            name: "洗衣液",
            defaultCycleDays: 30,
            itemNote: "大桶装",
            records: [
                SeedRecord(activatedDaysAgo: 120, purchasedDaysAgo: 121, brandName: "蓝月亮"),
                SeedRecord(activatedDaysAgo: 90, purchasedDaysAgo: 91, brandName: "蓝月亮"),
                SeedRecord(activatedDaysAgo: 58, purchasedDaysAgo: 59, brandName: "立白"),
                SeedRecord(activatedDaysAgo: 27, purchasedDaysAgo: 28, brandName: "立白")
            ]
        ),
        SeedItem(
            name: "洗洁精",
            defaultCycleDays: 24,
            itemNote: nil,
            records: [
                SeedRecord(activatedDaysAgo: 95, brandName: "白猫"),
                SeedRecord(activatedDaysAgo: 71, brandName: "白猫"),
                SeedRecord(activatedDaysAgo: 48, brandName: "雕牌"),
                SeedRecord(activatedDaysAgo: 26, brandName: "雕牌"),
                SeedRecord(activatedDaysAgo: 6, brandName: "雕牌")
            ]
        ),
        SeedItem(
            name: "牙膏",
            defaultCycleDays: 30,
            itemNote: nil,
            records: [
                SeedRecord(activatedDaysAgo: 110, brandName: "云南白药"),
                SeedRecord(activatedDaysAgo: 80, brandName: "云南白药"),
                SeedRecord(activatedDaysAgo: 52, brandName: "高露洁"),
                SeedRecord(activatedDaysAgo: 27, brandName: "云南白药"),
                SeedRecord(activatedDaysAgo: 8, brandName: "高露洁")
            ]
        ),
        SeedItem(
            name: "洗发水",
            defaultCycleDays: 45,
            itemNote: nil,
            records: [
                SeedRecord(activatedDaysAgo: 170, brandName: "海飞丝"),
                SeedRecord(activatedDaysAgo: 128, brandName: "清扬"),
                SeedRecord(activatedDaysAgo: 86, brandName: "阿道夫"),
                SeedRecord(activatedDaysAgo: 39, brandName: "清扬")
            ]
        ),
        SeedItem(
            name: "垃圾袋",
            defaultCycleDays: 28,
            itemNote: "每次补 2 卷",
            records: [
                SeedRecord(activatedDaysAgo: 112, brandName: "妙洁", quantity: 2),
                SeedRecord(activatedDaysAgo: 84, brandName: "妙洁", quantity: 2),
                SeedRecord(activatedDaysAgo: 57, brandName: "洁成", quantity: 2),
                SeedRecord(activatedDaysAgo: 20, brandName: "洁成", quantity: 2)
            ]
        ),
        SeedItem(
            name: "猫砂",
            defaultCycleDays: 20,
            itemNote: "两只猫",
            records: [
                SeedRecord(activatedDaysAgo: 80, brandName: "pidan"),
                SeedRecord(activatedDaysAgo: 60, brandName: "pidan"),
                SeedRecord(activatedDaysAgo: 40, brandName: "N1"),
                SeedRecord(activatedDaysAgo: 20, brandName: "N1")
            ]
        ),
        SeedItem(
            name: "猫粮",
            defaultCycleDays: 35,
            itemNote: nil,
            records: [
                SeedRecord(activatedDaysAgo: 140, purchasedDaysAgo: 145, brandName: "皇家", quantity: 2),
                SeedRecord(activatedDaysAgo: 103, purchasedDaysAgo: 110, brandName: "皇家", quantity: 2),
                SeedRecord(activatedDaysAgo: 68, purchasedDaysAgo: 70, brandName: "渴望", quantity: 1),
                SeedRecord(activatedDaysAgo: 24, purchasedDaysAgo: 28, brandName: "渴望", quantity: 1)
            ]
        ),
        SeedItem(
            name: "湿巾",
            defaultCycleDays: 22,
            itemNote: nil,
            records: [
                SeedRecord(activatedDaysAgo: 66, brandName: "全棉时代"),
                SeedRecord(activatedDaysAgo: 45, brandName: "全棉时代"),
                SeedRecord(activatedDaysAgo: 24, brandName: "德佑"),
                SeedRecord(activatedDaysAgo: 4, brandName: "德佑")
            ]
        )
    ]
}
