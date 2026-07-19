import SwiftData
import SwiftUI

struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let category: InventoryCategory?
    @State private var draft: CategoryDraft
    @State private var error: Error?
    init(category: InventoryCategory? = nil) {
        self.category = category
        _draft = State(initialValue: CategoryDraft(name: category?.name ?? ""))
    }
    var body: some View {
        NavigationStack {
            Form { TextField("类别名称", text: $draft.name) }
                .navigationTitle(category == nil ? "新建类别" : "编辑类别")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("保存") { save() }.disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
                }.errorAlert($error)
        }
    }
    private func save() {
        do {
            let commands = InventoryCommands(context: context)
            if let category { try commands.updateCategory(category, draft: draft) } else { try commands.createCategory(draft) }
            dismiss()
        } catch { self.error = error }
    }
}
