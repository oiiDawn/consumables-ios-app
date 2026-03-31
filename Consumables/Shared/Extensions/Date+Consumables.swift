import Foundation

extension Date {
    func consumablesDateText() -> String {
        DateFormatter.consumablesDisplay.string(from: self)
    }
}

private extension DateFormatter {
    static let consumablesDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
