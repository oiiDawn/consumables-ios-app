import SwiftUI

enum AppSettingsKey {
    static let defaultRemindBeforeDays = "app.settings.defaultRemindBeforeDays"
    static let cardDisplayPreference = "app.settings.cardDisplayPreference"
}

struct RootTabView: View {
    enum Tab {
        case overview
        case items
        case settings
    }

    @State private var selectedTab: Tab = .overview
    @State private var showAddItemSheet = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                OverviewView(onAddItem: { showAddItemSheet = true })
            }
            .tabItem {
                Label("总览", systemImage: "list.bullet.clipboard")
            }
            .tag(Tab.overview)

            NavigationStack {
                ItemsView(onAddItem: { showAddItemSheet = true })
            }
            .tabItem {
                Label("物品", systemImage: "shippingbox.fill")
            }
            .tag(Tab.items)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gearshape")
            }
            .tag(Tab.settings)
        }
        .sheet(isPresented: $showAddItemSheet) {
            NavigationStack {
                ItemEditorView(mode: .create)
            }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(PreviewModelContainer.makeSeeded())
}

struct SettingsView: View {
    @AppStorage(AppSettingsKey.defaultRemindBeforeDays)
    private var defaultRemindBeforeDays = ConsumableItem.defaultRemindBeforeDays

    @AppStorage(AppSettingsKey.cardDisplayPreference)
    private var cardDisplayPreference = "percentageWithDays"

    var body: some View {
        Form {
            Section {
                Stepper(
                    "马上缺货阈值：\(safeDefaultRemindBeforeDays) 天",
                    value: defaultRemindBeforeDaysBinding,
                    in: 1...60
                )
            } header: {
                Text("新增物品默认值")
            } footer: {
                Text("用于新增物品的默认提醒阈值；已有物品仍可单独编辑。")
            }

            Section("显示偏好") {
                Picker("主卡片显示", selection: $cardDisplayPreference) {
                    Text("百分比 + 天数").tag("percentageWithDays")
                    Text("仅百分比（预留）").tag("percentageOnly")
                }
                .pickerStyle(.menu)

                Text("后续会在这里扩展更多全局显示选项。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
        .onAppear {
            defaultRemindBeforeDays = safeDefaultRemindBeforeDays
        }
    }

    private var safeDefaultRemindBeforeDays: Int {
        ConsumableItem.clampRemindBeforeDays(defaultRemindBeforeDays)
    }

    private var defaultRemindBeforeDaysBinding: Binding<Int> {
        Binding(
            get: { safeDefaultRemindBeforeDays },
            set: { defaultRemindBeforeDays = ConsumableItem.clampRemindBeforeDays($0) }
        )
    }
}
