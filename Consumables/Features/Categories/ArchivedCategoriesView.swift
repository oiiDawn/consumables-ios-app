import SwiftData
import SwiftUI

struct ArchivedCategoriesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \InventoryCategory.name) private var categories: [InventoryCategory]
    @State private var error: Error?
    private var archived: [InventoryCategory] { categories.filter { $0.archivedAt != nil } }
    var body: some View {
        NavigationStack {
            List(archived) { category in HStack { Text(category.name); Spacer(); Button("恢复") { restore(category) } } }
                .overlay { if archived.isEmpty { ContentUnavailableView("没有已归档类别", systemImage: "archivebox") } }
                .navigationTitle("已归档").toolbar { Button("完成") { dismiss() } }.errorAlert($error)
        }
    }
    private func restore(_ category: InventoryCategory) { do { try InventoryCommands(context: context).restoreCategory(category) } catch { self.error = error } }
}
