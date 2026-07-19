import SwiftData
import SwiftUI

struct TemplateListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let category: InventoryCategory
    @State private var editing: InventoryTemplate?
    @State private var creating = false
    @State private var error: Error?
    var body: some View {
        NavigationStack {
            List {
                ForEach(category.templates.sorted { $0.name < $1.name }) { template in
                    Button { editing = template } label: { VStack(alignment: .leading) { Text(template.name); if let brand = template.brand { Text(brand).font(.caption).foregroundStyle(.secondary) } } }
                        .swipeActions { Button("删除", role: .destructive) { remove(template) } }
                }
            }.overlay { if category.templates.isEmpty { ContentUnavailableView("还没有模板", systemImage: "doc.on.doc") } }
                .navigationTitle("库存模板")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("完成") { dismiss() } }; ToolbarItem(placement: .primaryAction) { Button("添加", systemImage: "plus") { creating = true } } }
                .sheet(isPresented: $creating) { TemplateEditorView(category: category) }
                .sheet(item: $editing) { TemplateEditorView(category: category, template: $0) }.errorAlert($error)
        }
    }
    private func remove(_ template: InventoryTemplate) { do { try InventoryCommands(context: context).deleteTemplate(template) } catch { self.error = error } }
}

private struct TemplateEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let category: InventoryCategory
    let template: InventoryTemplate?
    @State private var draft: TemplateDraft
    @State private var error: Error?
    init(category: InventoryCategory, template: InventoryTemplate? = nil) {
        self.category = category; self.template = template
        _draft = State(initialValue: TemplateDraft(name: template?.name ?? "", brand: template?.brand ?? "", specificationText: template?.specificationText ?? "", priceAmount: template?.referencePriceAmount, currencyCode: template?.referenceCurrencyCode ?? Locale.current.currency?.identifier ?? "CNY", note: template?.note ?? ""))
    }
    var body: some View {
        NavigationStack {
            Form {
                TextField("名称", text: $draft.name); TextField("品牌（可选）", text: $draft.brand); TextField("规格（可选）", text: $draft.specificationText)
                TextField("参考价格（可选）", value: $draft.priceAmount, format: .number).keyboardType(.decimalPad)
                if draft.priceAmount != nil { TextField("币种", text: $draft.currencyCode).textInputAutocapitalization(.characters) }
                TextField("备注（可选）", text: $draft.note, axis: .vertical)
            }.navigationTitle(template == nil ? "新建模板" : "编辑模板")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("保存") { save() } } }.errorAlert($error)
        }
    }
    private func save() { do { let commands = InventoryCommands(context: context); if let template { try commands.updateTemplate(template, draft: draft) } else { try commands.createTemplate(in: category, draft: draft) }; dismiss() } catch { self.error = error } }
}
