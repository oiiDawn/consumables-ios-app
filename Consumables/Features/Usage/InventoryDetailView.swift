import SwiftData
import SwiftUI

struct InventoryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let item: InventoryItem
    @State private var editing = false
    @State private var error: Error?
    @State private var confirmDelete = false
    @State private var editingUsage = false
    var body: some View {
        List {
            Section("物品") { LabeledContent("名称", value: item.name); if let brand = item.brand { LabeledContent("品牌", value: brand) }; if let spec = item.specificationText { LabeledContent("规格", value: spec) }; LabeledContent("入库", value: item.stockedAt.consumablesDateText()) }
            Section("状态") { LabeledContent("当前", value: item.state.title); if let usage = item.usageRecord { LabeledContent("开始使用", value: usage.startedAt.consumablesDateText()); if let depleted = usage.depletedAt { LabeledContent("用尽", value: depleted.consumablesDateText()) }; Button("编辑生命周期日期") { editingUsage = true } } }
            Section("操作") { actions }
            Section { Button("永久删除库存", role: .destructive) { confirmDelete = true } }
        }
        .navigationTitle(item.name).toolbar { Button("编辑") { editing = true } }
        .sheet(isPresented: $editing) { InventoryEditorView(category: item.category, item: item) }
        .sheet(isPresented: $editingUsage) { UsageEditorView(item: item) }
        .confirmationDialog("永久删除这项库存及其使用记录？", isPresented: $confirmDelete) { Button("永久删除", role: .destructive) { remove() } }.errorAlert($error)
    }
    @ViewBuilder private var actions: some View {
        switch item.state {
        case .stocked: Button("开始使用", systemImage: "play.circle") { perform { try $0.startUsing(item) } }
        case .inUse:
            Button("标记用尽", systemImage: "checkmark.circle") { perform { try $0.markDepleted(item) } }
            Button("退回待使用", systemImage: "arrow.uturn.backward") { perform { try $0.returnToStock(item) } }
        case .depleted: Button("恢复为使用中", systemImage: "arrow.uturn.backward") { perform { try $0.reopen(item) } }
        }
    }
    private func perform(_ action: (InventoryCommands) throws -> Void) { do { try action(InventoryCommands(context: context)) } catch { self.error = error } }
    private func remove() { do { try InventoryCommands(context: context).deleteInventoryItem(item); dismiss() } catch { self.error = error } }
}

private struct UsageEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let item: InventoryItem
    @State private var startedAt: Date
    @State private var depletedAt: Date
    @State private var hasDepletedAt: Bool
    @State private var error: Error?

    init(item: InventoryItem) {
        self.item = item
        let usage = item.usageRecord
        _startedAt = State(initialValue: usage?.startedAt ?? .now)
        _depletedAt = State(initialValue: usage?.depletedAt ?? .now)
        _hasDepletedAt = State(initialValue: usage?.depletedAt != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("开始使用", selection: $startedAt, displayedComponents: .date)
                Toggle("已经用尽", isOn: $hasDepletedAt)
                if hasDepletedAt { DatePicker("用尽日期", selection: $depletedAt, displayedComponents: .date) }
            }
            .navigationTitle("生命周期日期")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("保存") { save() } } }
            .errorAlert($error)
        }
    }

    private func save() {
        do { try InventoryCommands(context: context).updateUsage(item, startedAt: startedAt, depletedAt: hasDepletedAt ? depletedAt : nil); dismiss() }
        catch { self.error = error }
    }
}
