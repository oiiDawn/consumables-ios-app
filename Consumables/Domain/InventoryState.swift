enum InventoryState: String, CaseIterable, Sendable {
    case stocked
    case inUse
    case depleted

    var title: String {
        switch self {
        case .stocked: "待使用"
        case .inUse: "使用中"
        case .depleted: "已用尽"
        }
    }
}
