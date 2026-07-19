import SwiftData
import SwiftUI

struct InventoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \InventoryCategory.name) private var categories: [InventoryCategory]
    let category: InventoryCategory
    let item: InventoryItem?
    @State private var draft: InventoryDraft
    @State private var error: Error?
    @State private var selectedCategoryID: UUID
    init(category: InventoryCategory, template: InventoryTemplate? = nil, item: InventoryItem? = nil) {
        self.category = category; self.item = item
        _draft = State(initialValue: item.map(InventoryDraft.init(item:)) ?? template.map(InventoryDraft.init(template:)) ?? InventoryDraft())
        _selectedCategoryID = State(initialValue: item?.category.id ?? category.id)
    }
    var body: some View {
        NavigationStack {
            Form {
                Section("物品") { TextField("名称", text: $draft.name); TextField("品牌（可选）", text: $draft.brand); TextField("规格（可选）", text: $draft.specificationText) }
                if item != nil {
                    Section("类别") {
                        Picker("所属类别", selection: $selectedCategoryID) {
                            ForEach(categories.filter { $0.archivedAt == nil }) { Text($0.name).tag($0.id) }
                        }
                    }
                }
                Section("本次入库") {
                    TextField("单件价格（可选）", value: $draft.priceAmount, format: .number).keyboardType(.decimalPad)
                    if draft.priceAmount != nil { TextField("币种", text: $draft.currencyCode).textInputAutocapitalization(.characters) }
                    DatePicker("入库日期", selection: $draft.stockedAt, displayedComponents: .date)
                    if item == nil { Stepper("数量：\(draft.count)", value: $draft.count, in: 1...999) }
                }
                Section("备注") { TextField("备注（可选）", text: $draft.note, axis: .vertical) }
            }
            .navigationTitle(item == nil ? "添加库存" : "编辑库存")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { save() }.disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }.errorAlert($error)
        }
    }
    private func save() {
        do {
            let commands = InventoryCommands(context: context)
            if let item { try commands.updateInventoryItem(item, draft: draft, category: categories.first { $0.id == selectedCategoryID }) }
            else { try commands.stock(in: category, draft: draft) }
            dismiss()
        } catch { self.error = error }
    }
}
