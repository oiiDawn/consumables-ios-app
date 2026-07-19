import Foundation

struct CategoryDraft {
    var name = ""
}

struct TemplateDraft {
    var name = ""
    var brand = ""
    var specificationText = ""
    var priceAmount: Decimal?
    var currencyCode = Locale.current.currency?.identifier ?? "CNY"
    var note = ""
}

struct InventoryDraft {
    var name = ""
    var brand = ""
    var specificationText = ""
    var priceAmount: Decimal?
    var currencyCode = Locale.current.currency?.identifier ?? "CNY"
    var stockedAt = Date.now
    var note = ""
    var count = 1

    init() {}

    init(template: InventoryTemplate) {
        name = template.name
        brand = template.brand ?? ""
        specificationText = template.specificationText ?? ""
        priceAmount = template.referencePriceAmount
        currencyCode = template.referenceCurrencyCode ?? Locale.current.currency?.identifier ?? "CNY"
        note = template.note ?? ""
    }

    init(item: InventoryItem) {
        name = item.name
        brand = item.brand ?? ""
        specificationText = item.specificationText ?? ""
        priceAmount = item.actualPriceAmount
        currencyCode = item.actualCurrencyCode ?? Locale.current.currency?.identifier ?? "CNY"
        stockedAt = item.stockedAt
        note = item.note ?? ""
    }
}
