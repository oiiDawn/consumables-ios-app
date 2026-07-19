import SwiftUI

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let category: InventoryCategory
    @State private var sheet: Sheet?
    @State private var error: Error?
    @State private var confirmArchive = false
    enum Sheet: Identifiable { case edit, add, templates; var id: Self { self } }
    private var activeItems: [InventoryItem] { category.items.filter { $0.state == .inUse }.sorted { $0.updatedAt > $1.updatedAt } }
    private var stockedItems: [InventoryItem] { category.items.filter { $0.state == .stocked }.sorted { $0.stockedAt > $1.stockedAt } }
    var body: some View {
        List {
            Section("使用中") { itemSection(activeItems, empty: "没有正在使用的库存") }
            Section("待使用") { itemSection(stockedItems, empty: "没有待使用库存") }
            Section {
                Button("添加库存", systemImage: "plus.circle") { sheet = .add }
                Button("管理模板", systemImage: "doc.on.doc") { sheet = .templates }
                NavigationLink("历史记录", destination: HistoryView(category: category))
            }
        }
        .navigationTitle(category.name)
        .toolbar { ToolbarItem(placement: .primaryAction) { Menu("更多", systemImage: "ellipsis.circle") { Button("编辑类别") { sheet = .edit }; Button(category.items.isEmpty && category.templates.isEmpty ? "永久删除类别" : "归档类别", role: .destructive) { confirmArchive = true } } } }
        .sheet(item: $sheet) { value in
            switch value {
            case .edit: CategoryEditorView(category: category)
            case .add: AddInventoryChooserView(category: category)
            case .templates: TemplateListView(category: category)
            }
        }
        .confirmationDialog(category.items.isEmpty && category.templates.isEmpty ? "永久删除“\(category.name)”？" : "归档“\(category.name)”？", isPresented: $confirmArchive) { Button(category.items.isEmpty && category.templates.isEmpty ? "永久删除" : "归档", role: .destructive) { archiveOrDelete() } }
        .errorAlert($error)
    }
    @ViewBuilder private func itemSection(_ items: [InventoryItem], empty: String) -> some View {
        if items.isEmpty { Text(empty).foregroundStyle(.secondary) }
        else {
            ForEach(items) { item in
                NavigationLink(value: InventoryRoute(item: item)) { InventoryRow(item: item) }
            }
        }
    }
    private func archiveOrDelete() { do { let commands = InventoryCommands(context: context); if category.items.isEmpty && category.templates.isEmpty { try commands.deleteEmptyCategory(category) } else { try commands.archiveCategory(category) }; dismiss() } catch { self.error = error } }
}

struct InventoryRoute: Hashable {
    let id: UUID
    let item: InventoryItem
    init(item: InventoryItem) { id = item.id; self.item = item }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
