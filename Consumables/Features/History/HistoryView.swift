import SwiftUI

struct HistoryView: View {
    let category: InventoryCategory
    private var items: [InventoryItem] { category.items.filter { $0.state == .depleted }.sorted { ($0.usageRecord?.depletedAt ?? .distantPast) > ($1.usageRecord?.depletedAt ?? .distantPast) } }
    var body: some View {
        List(items) { item in
            NavigationLink(value: InventoryRoute(item: item)) { InventoryRow(item: item) }
        }
        .overlay { if items.isEmpty { ContentUnavailableView("还没有历史记录", systemImage: "clock") } }
        .navigationTitle("历史记录")
    }
}
