import SwiftUI

struct AddInventoryChooserView: View {
    @Environment(\.dismiss) private var dismiss
    let category: InventoryCategory
    @State private var selection: InventoryTemplate?
    @State private var manual = false
    var body: some View {
        NavigationStack {
            List {
                Section { Button("手工添加", systemImage: "square.and.pencil") { manual = true } }
                Section("从模板添加") {
                    if category.templates.isEmpty { Text("还没有模板").foregroundStyle(.secondary) }
                    ForEach(category.templates.sorted { $0.name < $1.name }) { template in Button(template.name) { selection = template } }
                }
            }.navigationTitle("添加库存").toolbar { Button("取消") { dismiss() } }
                .sheet(isPresented: $manual) { InventoryEditorView(category: category) }
                .sheet(item: $selection) { InventoryEditorView(category: category, template: $0) }
        }
    }
}
