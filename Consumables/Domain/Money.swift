import Foundation

struct Money: Equatable, Sendable {
    let amount: Decimal
    let currencyCode: String

    init(amount: Decimal, currencyCode: String) throws {
        guard amount >= 0 else { throw InventoryValidationError.negativePrice }
        let code = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard Locale.commonISOCurrencyCodes.contains(code) else {
            throw InventoryValidationError.invalidCurrencyCode
        }
        self.amount = amount
        self.currencyCode = code
    }
}
