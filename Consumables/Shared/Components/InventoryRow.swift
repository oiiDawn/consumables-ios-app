import SwiftUI

struct InventoryRow: View {
    let item: InventoryItem
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.name).font(.headline)
            HStack {
                if let brand = item.brand { Text(brand) }
                if let specification = item.specificationText { Text(specification) }
                Spacer(); Text(item.state.title)
            }.font(.caption).foregroundStyle(.secondary)
        }.padding(.vertical, 3)
    }
}
