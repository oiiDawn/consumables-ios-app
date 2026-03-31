import SwiftUI
import SwiftData

struct ItemEditorView: View {
    enum Mode {
        case create
        case edit(ConsumableItem)

        var title: String {
            switch self {
            case .create:
                return "新增物品"
            case .edit:
                return "编辑物品"
            }
        }

        var ctaTitle: String {
            switch self {
            case .create:
                return "开始追踪"
            case .edit:
                return "保存修改"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage(AppSettingsKey.defaultRemindBeforeDays)
    private var defaultRemindBeforeDays = ConsumableItem.defaultRemindBeforeDays

    let mode: Mode

    @State private var name: String
    @State private var defaultCycleDays: Int
    @State private var remindBeforeDays: Int
    @State private var activatedAt: Date
    @State private var purchasedAt: Date
    @State private var quantity: Int
    @State private var brandName: String
    @State private var note: String
    @State private var showAdvanced = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isSaving = false

    private let quickCycleOptions = [7, 14, 21, 30, 45, 60]
    private let today = Date()

    init(mode: Mode) {
        self.mode = mode

        switch mode {
        case .create:
            let now = Date()
            _name = State(initialValue: "")
            _defaultCycleDays = State(initialValue: 30)
            _remindBeforeDays = State(initialValue: ConsumableItem.defaultRemindBeforeDays)
            _activatedAt = State(initialValue: now)
            _purchasedAt = State(initialValue: now)
            _quantity = State(initialValue: 1)
            _brandName = State(initialValue: "")
            _note = State(initialValue: "")
        case .edit(let item):
            _name = State(initialValue: item.name)
            _defaultCycleDays = State(initialValue: item.defaultCycleDays)
            _remindBeforeDays = State(initialValue: item.remindBeforeDays)
            _activatedAt = State(initialValue: item.latestPurchaseRecord?.activatedAt ?? .now)
            _purchasedAt = State(initialValue: item.latestPurchaseRecord?.purchasedAt ?? .now)
            _quantity = State(initialValue: item.latestPurchaseRecord?.quantity ?? 1)
            _brandName = State(initialValue: item.latestPurchaseRecord?.brandName ?? "")
            _note = State(initialValue: item.note ?? "")
        }
    }

    var body: some View {
        editorForm
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                editorToolbar
            }
            .animation(.snappy(duration: 0.25), value: showAdvanced)
            .onAppear {
                if isCreateMode {
                    remindBeforeDays = ConsumableItem.clampRemindBeforeDays(defaultRemindBeforeDays)
                }
            }
            .onChange(of: activatedAt) { _, newValue in
                if purchasedAt > newValue {
                    purchasedAt = newValue
                }
            }
            .alert("保存失败", isPresented: $showError, actions: {
                Button("知道了", role: .cancel) {}
            }, message: {
                Text(errorMessage)
            })
    }

    private var editorForm: some View {
        Form {
            basicInfoSection
            modeSpecificSection
        }
    }

    private var isCreateMode: Bool {
        if case .create = mode {
            return true
        }
        return false
    }

    private var basicInfoSection: some View {
        Section {
            TextField("名称", text: $name)
                .onChange(of: name) { _, newValue in
                    // Limit name length to prevent UI issues
                    if newValue.count > 50 {
                        name = String(newValue.prefix(50))
                    }
                }
                .accessibilityHint("输入物品名称，最多50个字符")
            cycleDaysEditor
            if isCreateMode {
                createStartDatePicker
            }
        } header: {
            Text("基础信息")
        } footer: {
            basicInfoFooter
        }
    }

    private var cycleDaysEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("默认周期天数")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            quickCycleButtons
            Stepper("\(defaultCycleDays) 天", value: $defaultCycleDays, in: 1...365)
        }
    }

    private var quickCycleButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickCycleOptions, id: \.self) { option in
                    cycleOptionButton(option)
                }
            }
        }
    }

    private func cycleOptionButton(_ option: Int) -> some View {
        Button("\(option)") {
            defaultCycleDays = option
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(defaultCycleDays == option ? Color.accentColor.opacity(0.2) : Color(.tertiarySystemFill))
        )
        .accessibilityAddTraits(defaultCycleDays == option ? [.isSelected] : [])
        .accessibilityLabel("\(option) 天")
        .accessibilityHint(defaultCycleDays == option ? "已选择" : "双击选择此周期")
    }

    private var createStartDatePicker: some View {
        DatePicker(
            "开始使用日期",
            selection: $activatedAt,
            in: ...today,
            displayedComponents: [.date]
        )
    }

    @ViewBuilder
    private var basicInfoFooter: some View {
        if isCreateMode {
            Text("只需这 3 项即可开始追踪，其他信息都可以后补。")
        } else {
            Text("名称和周期会直接影响首页优先级排序。")
        }
    }

    @ViewBuilder
    private var modeSpecificSection: some View {
        if isCreateMode {
            createAdvancedSection
        } else {
            editAdvancedSection
            editNoteSection
        }
    }

    private var createAdvancedSection: some View {
        Section {
            DisclosureGroup("更多选项（可选）", isExpanded: $showAdvanced) {
                DatePicker(
                    "购买日期",
                    selection: $purchasedAt,
                    in: ...activatedAt,
                    displayedComponents: [.date]
                )
                Stepper("数量：\(quantity)", value: $quantity, in: 1...20)
                TextField("品牌（可选）", text: $brandName)
                    .onChange(of: brandName) { _, newValue in
                        if newValue.count > 30 {
                            brandName = String(newValue.prefix(30))
                        }
                    }
                TextField("备注（可选）", text: $note, axis: .vertical)
                    .lineLimit(3...5)
                    .onChange(of: note) { _, newValue in
                        if newValue.count > 200 {
                            note = String(newValue.prefix(200))
                        }
                    }
            }
        } footer: {
            Text("默认：购买日期=开始使用日期，数量=1，品牌为空")
        }
    }

    private var editNoteSection: some View {
        Section("备注") {
            TextField("备注（可选）", text: $note, axis: .vertical)
                .lineLimit(3...5)
                .onChange(of: note) { _, newValue in
                    if newValue.count > 200 {
                        note = String(newValue.prefix(200))
                    }
                }
        }
    }

    private var editAdvancedSection: some View {
        Section {
            DisclosureGroup("高级选项", isExpanded: $showAdvanced) {
                Stepper("即将耗尽阈值：\(remindBeforeDays) 天", value: $remindBeforeDays, in: 1...60)
            }
        } footer: {
            Text("当剩余天数在 1...\(remindBeforeDays) 天时，会标记为\"即将耗尽\"。")
        }
    }

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("取消") { dismiss() }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button(mode.ctaTitle) {
                save()
            }
            .fontWeight(.semibold)
            .disabled(isPrimaryActionDisabled || isSaving)
            .opacity(isSaving ? 0.6 : 1.0)
        }
    }

    private var isPrimaryActionDisabled: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true

        let service = ConsumablesMutationService(context: modelContext)

        do {
            switch mode {
            case .create:
                let safePurchasedAt = showAdvanced ? purchasedAt : activatedAt
                try service.createItem(
                    name: name,
                    defaultCycleDays: defaultCycleDays,
                    remindBeforeDays: remindBeforeDays,
                    activatedAt: activatedAt,
                    purchasedAt: safePurchasedAt,
                    brandName: showAdvanced ? brandName : nil,
                    quantity: showAdvanced ? quantity : 1,
                    note: showAdvanced ? note : nil
                )
            case .edit(let item):
                try service.updateItem(
                    item,
                    name: name,
                    defaultCycleDays: defaultCycleDays,
                    remindBeforeDays: remindBeforeDays,
                    note: note
                )
            }
            successHaptic()
            dismiss()
        } catch {
            isSaving = false
            errorMessage = userFriendlyErrorMessage(for: error)
            showError = true
            errorHaptic()
        }
    }

    private func userFriendlyErrorMessage(for error: Error) -> String {
        // Map technical errors to user-friendly messages
        let errorDescription = error.localizedDescription.lowercased()

        if errorDescription.contains("duplicate") || errorDescription.contains("unique") {
            return "已存在同名物品，请使用不同的名称。"
        } else if errorDescription.contains("validation") {
            return "输入信息有误，请检查后重试。"
        } else if errorDescription.contains("network") || errorDescription.contains("connection") {
            return "网络连接失败，请检查网络后重试。"
        } else if errorDescription.contains("permission") || errorDescription.contains("access") {
            return "没有权限执行此操作。"
        } else {
            return "保存失败：\(error.localizedDescription)\n\n如果问题持续，请联系支持。"
        }
    }
}

struct LogPurchaseSheet: View {
    let item: ConsumableItem

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var activatedAt: Date = .now
    @State private var purchasedAt: Date = .now
    @State private var quantity: Int = 1
    @State private var brandName: String = ""
    @State private var note: String = ""
    @State private var showAdvanced = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var isSaving = false

    private let today = Date()

    var body: some View {
        Form {
            Section {
                DatePicker(
                    "开始使用日期",
                    selection: $activatedAt,
                    in: ...today,
                    displayedComponents: [.date]
                )
            } header: {
                Text("快速补货")
            } footer: {
                Text("只需选择开始使用日期，然后点\"记好了\"即可。")
            }

            Section {
                DisclosureGroup("补充详细信息（可选）", isExpanded: $showAdvanced) {
                    DatePicker(
                        "购买日期",
                        selection: $purchasedAt,
                        in: ...activatedAt,
                        displayedComponents: [.date]
                    )
                    Stepper("数量：\(quantity)", value: $quantity, in: 1...20)
                    TextField("品牌（可选）", text: $brandName)
                        .onChange(of: brandName) { _, newValue in
                            if newValue.count > 30 {
                                brandName = String(newValue.prefix(30))
                            }
                        }
                    TextField("备注（可选）", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                        .onChange(of: note) { _, newValue in
                            if newValue.count > 200 {
                                note = String(newValue.prefix(200))
                            }
                        }
                }
            } footer: {
                Text("默认：购买日期=开始使用日期，数量=1")
            }
        }
        .navigationTitle("补货 · \(item.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("取消") { dismiss() }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("记好了") {
                    save()
                }
                .fontWeight(.semibold)
                .disabled(isSaving)
                .opacity(isSaving ? 0.6 : 1.0)
            }
        }
        .onAppear {
            activatedAt = today
            purchasedAt = today
            quantity = 1
        }
        .onChange(of: activatedAt) { _, newValue in
            if !showAdvanced || purchasedAt > newValue {
                purchasedAt = newValue
            }
        }
        .animation(.snappy(duration: 0.25), value: showAdvanced)
        .alert("保存失败", isPresented: $showError) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var displayPurchasedAt: Date {
        showAdvanced ? purchasedAt : activatedAt
    }

    private var displayQuantity: Int {
        showAdvanced ? quantity : 1
    }

    private var displayBrandText: String {
        if !showAdvanced {
            return "未填写"
        }
        return brandName.isEmpty ? "未填写" : brandName
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true

        let service = ConsumablesMutationService(context: modelContext)

        do {
            let finalPurchasedAt = showAdvanced ? purchasedAt : activatedAt
            try service.logPurchase(
                for: item,
                activatedAt: activatedAt,
                purchasedAt: finalPurchasedAt,
                brandName: showAdvanced ? brandName : nil,
                quantity: showAdvanced ? quantity : 1,
                note: showAdvanced ? note : nil
            )
            successHaptic()
            dismiss()
        } catch {
            isSaving = false
            errorMessage = userFriendlyErrorMessage(for: error)
            showError = true
            errorHaptic()
        }
    }

    private func userFriendlyErrorMessage(for error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()

        if errorDescription.contains("duplicate") {
            return "该日期已有补货记录，请选择其他日期。"
        } else if errorDescription.contains("validation") {
            return "输入信息有误，请检查后重试。"
        } else if errorDescription.contains("network") || errorDescription.contains("connection") {
            return "网络连接失败，请检查网络后重试。"
        } else {
            return "保存失败：\(error.localizedDescription)\n\n如果问题持续，请联系支持。"
        }
    }
}

private func successHaptic() {
    #if canImport(UIKit)
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    #endif
}

private func errorHaptic() {
    #if canImport(UIKit)
    UINotificationFeedbackGenerator().notificationOccurred(.error)
    #endif
}

#Preview {
    NavigationStack {
        ItemEditorView(mode: .create)
    }
    .modelContainer(PreviewModelContainer.makeSeeded())
}
