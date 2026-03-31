import SwiftUI
import SwiftData

struct ItemsView: View {
    let onAddItem: () -> Void

    @Query(sort: [SortDescriptor(\ConsumableItem.updatedAt, order: .reverse)])
    private var items: [ConsumableItem]

    @State private var searchText = ""
    @State private var loggingItem: ConsumableItem?

    private let forecastBuilder = ConsumableForecastBuilder()

    var body: some View {
        Group {
            if activeForecasts.isEmpty {
                ContentUnavailableView(
                    "还没有物品",
                    systemImage: "shippingbox",
                    description: Text("添加物品开始追踪库存")
                )
                .overlay(alignment: .bottom) {
                    Button(action: onAddItem) {
                        Label("添加物品", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 24)
                }
            } else if filteredForecasts.isEmpty {
                ContentUnavailableView.search(
                    text: searchText.isEmpty ? "无匹配物品" : searchText
                )
            } else {
                List {
                    Section {
                        listSummaryCard
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }

                    ForEach(groupedForecasts, id: \.urgency.rawValue) { group in
                        Section {
                            ForEach(group.items) { forecast in
                                itemRow(for: forecast)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowBackground(Color.clear)
                            }
                        } header: {
                            sectionHeader(for: group.urgency, count: group.items.count)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("物品")
        .searchable(text: $searchText, prompt: "搜索物品")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAddItem) {
                    Label("添加", systemImage: "plus")
                }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { loggingItem != nil },
                set: { show in
                    if !show {
                        loggingItem = nil
                    }
                }
            )
        ) {
            if let loggingItem {
                NavigationStack {
                    LogPurchaseSheet(item: loggingItem)
                }
            }
        }
        .animation(.snappy(duration: 0.25), value: groupingSignature)
    }

    private var activeForecasts: [ConsumableForecastViewData] {
        forecastBuilder.build(items: items.filter { !$0.isArchived })
    }

    private var filteredForecasts: [ConsumableForecastViewData] {
        activeForecasts.filter { forecast in
            let textMatches: Bool
            if searchText.isEmpty {
                textMatches = true
            } else {
                textMatches = forecast.name.localizedCaseInsensitiveContains(searchText)
            }
            return textMatches
        }
    }

    private var groupedForecasts: [(urgency: UrgencyLevel, items: [ConsumableForecastViewData])] {
        let grouped = Dictionary(grouping: filteredForecasts, by: { $0.snapshot.urgency })
        let urgencyOrder: [UrgencyLevel] = [.red, .yellow, .green]
        return urgencyOrder.compactMap { urgency in
            guard let values = grouped[urgency], !values.isEmpty else { return nil }
            return (urgency: urgency, items: values)
        }
    }

    private var groupingSignature: [String] {
        filteredForecasts.map { "\($0.id.uuidString)-\($0.snapshot.daysRemaining)-\($0.snapshot.urgency.rawValue)" }
    }

    private var listSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                summaryMetric(
                    title: "缺货",
                    value: filteredForecasts.filter { $0.snapshot.urgency == .red }.count,
                    style: UrgencyLevel.red.style
                )
                summaryMetric(
                    title: "即将耗尽",
                    value: filteredForecasts.filter { $0.snapshot.urgency == .yellow }.count,
                    style: UrgencyLevel.yellow.style
                )
                summaryMetric(
                    title: "库存充足",
                    value: filteredForecasts.filter { $0.snapshot.urgency == .green }.count,
                    style: UrgencyLevel.green.style
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func summaryMetric(title: String, value: Int, style: UrgencyStyle) -> some View {
        let isUrgent = (title == "缺货" || title == "即将耗尽") && value > 0

        return VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(isUrgent ? .title2.weight(.bold) : .title3.weight(.bold))
                .foregroundStyle(style.prominentTint)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isUrgent ? 12 : 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(style.softBackground)
        )
        .opacity(value == 0 && !isUrgent ? 0.7 : 1.0)
    }

    private func sectionHeader(for urgency: UrgencyLevel, count: Int) -> some View {
        let style = urgency.style

        return HStack {
            Label(urgency.sectionTitle, systemImage: style.symbolName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(style.accentTint)
            Spacer()
            Text("\(count)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(style.prominentTint)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func itemRow(for forecast: ConsumableForecastViewData) -> some View {
        NavigationLink {
            ItemDetailView(item: forecast.item)
        } label: {
            ConsumableRowCard(forecast: forecast)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("补货") {
                loggingItem = forecast.item
            }
            .tint(forecast.snapshot.urgency.style.prominentTint)
            .accessibilityLabel("记录 \(forecast.name) 的补货")
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint("双击查看详情，向左滑动快速补货")
    }
}

#Preview {
    NavigationStack {
        ItemsView(onAddItem: {})
    }
    .modelContainer(PreviewModelContainer.makeSeeded())
}
