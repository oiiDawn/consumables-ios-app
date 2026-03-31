import SwiftUI
import SwiftData

struct OverviewView: View {
    let onAddItem: () -> Void

    @Query(sort: [SortDescriptor(\ConsumableItem.updatedAt, order: .reverse)])
    private var items: [ConsumableItem]

    @State private var loggingItem: ConsumableItem?

    private let forecastBuilder = ConsumableForecastBuilder()

    var body: some View {
        Group {
            if activeForecasts.isEmpty {
                ContentUnavailableView(
                    "还没添加物品呢",
                    systemImage: "cart.badge.plus",
                    description: Text("添加第一个物品，开始追踪库存")
                )
                .overlay(alignment: .bottom) {
                    Button(action: onAddItem) {
                        Label("添加物品", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 24)
                }
            } else if urgentForecasts.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        calmStateCard
                    }
                    .padding(16)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        urgencySnapshotBar

                        VStack(spacing: 10) {
                            ForEach(Array(urgentForecasts.prefix(6))) { forecast in
                                actionCard(for: forecast)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("总览")
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
        .animation(.snappy(duration: 0.25), value: forecastSignature)
    }

    private var activeForecasts: [ConsumableForecastViewData] {
        forecastBuilder.build(items: items.filter { !$0.isArchived })
    }

    private var urgentForecasts: [ConsumableForecastViewData] {
        activeForecasts.filter { $0.snapshot.urgency == .red || $0.snapshot.urgency == .yellow }
    }

    private var outOfStockItems: [ConsumableForecastViewData] {
        urgentForecasts.filter { $0.snapshot.urgency == .red }
    }

    private var runningLowItems: [ConsumableForecastViewData] {
        urgentForecasts.filter { $0.snapshot.urgency == .yellow }
    }

    private var forecastSignature: [String] {
        urgentForecasts.map { "\($0.id.uuidString)-\($0.snapshot.daysRemaining)" }
    }

    private var calmStateCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
            VStack(alignment: .leading, spacing: 4) {
                Text("一切正常")
                    .font(.subheadline.weight(.semibold))
                Text("所有物品库存充足")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.green.opacity(0.1))
        )
    }

    private var urgencySnapshotBar: some View {
        HStack(spacing: 10) {
            overviewMetric(
                title: "缺货",
                value: outOfStockItems.count,
                style: UrgencyLevel.red.style
            )
            overviewMetric(
                title: "即将耗尽",
                value: runningLowItems.count,
                style: UrgencyLevel.yellow.style
            )
        }
    }

    private func overviewMetric(title: String, value: Int, style: UrgencyStyle) -> some View {
        let isUrgent = (title == "缺货" || title == "即将耗尽") && value > 0

        return VStack(alignment: .leading, spacing: 4) {
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

    private func actionCard(for forecast: ConsumableForecastViewData) -> some View {
        let style = forecast.snapshot.urgency.style

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(forecast.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(forecast.name)

                    Text(forecast.snapshot.remainingDaysSupportText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 8)
            }

            ConsumableProgressIndicator(
                snapshot: forecast.snapshot,
                style: style,
                compact: true
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(style.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(style.cardBorder, lineWidth: 1)
        )
    }

}

#Preview {
    NavigationStack {
        OverviewView(onAddItem: {})
    }
    .modelContainer(PreviewModelContainer.makeSeeded())
}
