import SwiftData
import SwiftUI

struct RootView: View {
    @Query(sort: [SortDescriptor(\InventoryCategory.sortOrder), SortDescriptor(\InventoryCategory.name)]) private var categories: [InventoryCategory]
    @State private var showingCreate = false
    @State private var showingArchived = false
    private var activeCategories: [InventoryCategory] { categories.filter { $0.archivedAt == nil } }

    var body: some View {
        NavigationStack {
            Group {
                if activeCategories.isEmpty {
                    ContentUnavailableView("还没有类别", systemImage: "square.grid.2x2", description: Text("先建立一个类别，再添加模板或库存。"))
                } else {
                    List(activeCategories) { category in NavigationLink(value: category) { CategoryRow(category: category) } }
                }
            }
            .navigationTitle("类别")
            .navigationDestination(for: InventoryCategory.self) { CategoryDetailView(category: $0) }
            .navigationDestination(for: InventoryRoute.self) { InventoryDetailView(item: $0.item) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("已归档", systemImage: "archivebox") { showingArchived = true } }
                ToolbarItem(placement: .primaryAction) { Button("添加类别", systemImage: "plus") { showingCreate = true } }
            }
            .sheet(isPresented: $showingCreate) { CategoryEditorView() }
            .sheet(isPresented: $showingArchived) { ArchivedCategoriesView() }
        }
    }
}

private struct CategoryRow: View {
    let category: InventoryCategory
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.name).font(.headline)
            HStack(spacing: 14) {
                count("待使用", .stocked); count("使用中", .inUse); count("已用尽", .depleted)
            }.font(.caption).foregroundStyle(.secondary)
        }.padding(.vertical, 4)
    }
    private func count(_ label: String, _ state: InventoryState) -> some View { Text("\(label) \(category.items.filter { $0.state == state }.count)") }
}

#Preview { RootView().modelContainer(PreviewModelContainer.makeSeeded()) }
