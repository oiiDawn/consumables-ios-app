import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Bindable var item: ConsumableItem

    @State private var showLogPurchaseSheet = false
    @State private var showEditSheet = false

    private let engine = ForecastEngine()
    private let mapper = ForecastViewDataMapper()

    init(item: ConsumableItem) {
        self.item = item
    }

    var body: some View {
        let snapshot = engine.forecast(for: item)
        let mapped = mapper.map(snapshot)
        let style = snapshot.urgency.style

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                forecastHeroCard(snapshot: snapshot, mapped: mapped, style: style)
                currentCycleCard
                historyCard
            }
            .padding(16)
            .padding(.bottom, 88)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                ItemEditorView(mode: .edit(item))
            }
        }
        .sheet(isPresented: $showLogPurchaseSheet) {
            NavigationStack {
                LogPurchaseSheet(item: item)
            }
        }
        .animation(.snappy(duration: 0.25), value: item.updatedAt)
    }

    private var latestRecord: PurchaseRecord? {
        item.purchaseRecords.max(by: { $0.activatedAt < $1.activatedAt })
    }

    private var sortedHistory: [PurchaseRecord] {
        item.purchaseRecords.sorted(by: { $0.activatedAt > $1.activatedAt })
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button("编辑") {
                showEditSheet = true
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("编辑物品")
            .accessibilityHint("双击打开编辑界面")

            Button {
                showLogPurchaseSheet = true
            } label: {
                Label("记一笔补货", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("记录补货")
            .accessibilityHint("双击记录新的补货信息")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.thinMaterial)
    }

    private func forecastHeroCard(
        snapshot: ForecastSnapshot,
        mapped: ForecastViewData,
        style: UrgencyStyle
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("预测")
                    .font(.headline)
                Spacer()
                ConsumableStatusBadge(urgency: snapshot.urgency)
            }

            ConsumableProgressIndicator(snapshot: snapshot, style: style)

            Label(mapped.predictedOutDateText, systemImage: "calendar")
                .font(.subheadline.weight(.medium))
            infoRow(title: "估算周期", value: "\(snapshot.estimatedCycleDays) 天")
            infoRow(title: "即将耗尽阈值", value: "\(item.remindBeforeDays) 天")
            infoRow(title: "预测依据", value: mapped.confidenceText)
            infoRow(title: "有效历史", value: "\(snapshot.usableCycleCount) 个周期")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(style.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(style.cardBorder, lineWidth: 1)
        )
    }

    private var currentCycleCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("当前周期")
                .font(.headline)

            if let latest = latestRecord {
                infoRow(title: "开始使用", value: latest.activatedAt.consumablesDateText())
                infoRow(title: "购买日期", value: latest.purchasedAt.consumablesDateText())
                infoRow(title: "数量", value: "\(latest.quantity)")
                infoRow(title: "品牌", value: latest.brandName ?? "未填写")
            } else {
                Text("还没有补货记录")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("补货历史")
                    .font(.headline)
                Spacer()
                Text("最近 \(min(sortedHistory.count, 12)) 条")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if sortedHistory.isEmpty {
                Text("暂无历史记录")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(sortedHistory.prefix(12).enumerated()), id: \.element.id) { index, record in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(index == 0 ? Color.accentColor : Color(.separator))
                            .frame(width: 7, height: 7)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.activatedAt.consumablesDateText())
                                .font(.subheadline.weight(.semibold))
                            Text("数量 \(record.quantity) · 购买 \(record.purchasedAt.consumablesDateText())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let brand = record.brandName {
                                Text("品牌：\(brand)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .truncationMode(.tail)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)：\(value)")
    }
}

private let itemDetailPreviewItem: ConsumableItem = {
    let item = ConsumableItem(
        name: "卷纸",
        defaultCycleDays: 14
    )
    let record = PurchaseRecord(
        purchasedAt: .now,
        activatedAt: .now,
        brandName: "维达",
        quantity: 1,
        item: item
    )
    item.addPurchaseRecord(record)
    return item
}()

#Preview {
    NavigationStack {
        ItemDetailView(item: itemDetailPreviewItem)
    }
}
