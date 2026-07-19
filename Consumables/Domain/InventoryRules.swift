import Foundation

enum InventoryValidationError: LocalizedError, Equatable {
    case emptyName
    case duplicateCategoryName
    case negativePrice
    case invalidCurrencyCode
    case incompletePrice
    case invalidCount
    case invalidLifecycleDates
    case usageAlreadyExists
    case usageDoesNotExist
    case categoryIsNotEmpty

    var errorDescription: String? {
        switch self {
        case .emptyName: "名称不能为空。"
        case .duplicateCategoryName: "已存在同名类别。"
        case .negativePrice: "价格不能小于零。"
        case .invalidCurrencyCode: "币种代码无效。"
        case .incompletePrice: "金额和币种必须同时填写。"
        case .invalidCount: "添加数量必须在 1 到 999 之间。"
        case .invalidLifecycleDates: "日期必须满足入库日期 ≤ 开始使用日期 ≤ 用尽日期。"
        case .usageAlreadyExists: "这项库存已经有使用记录。"
        case .usageDoesNotExist: "这项库存尚未开始使用。"
        case .categoryIsNotEmpty: "包含模板或库存的类别只能归档。"
        }
    }
}

enum InventoryRules {
    static func requiredText(_ value: String) throws -> String {
        guard let value = optionalText(value) else { throw InventoryValidationError.emptyName }
        return value
    }

    static func optionalText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func money(amount: Decimal?, currencyCode: String?) throws -> Money? {
        switch (amount, optionalText(currencyCode)) {
        case (nil, nil): return nil
        case let (amount?, code?): return try Money(amount: amount, currencyCode: code)
        default: throw InventoryValidationError.incompletePrice
        }
    }

    static func validate(stockedAt: Date, startedAt: Date, depletedAt: Date? = nil) throws {
        guard stockedAt <= startedAt, depletedAt.map({ startedAt <= $0 }) ?? true else {
            throw InventoryValidationError.invalidLifecycleDates
        }
    }
}
