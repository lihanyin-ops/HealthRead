import SwiftUI

struct InsightView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var subscription: StoreKitManager
    @EnvironmentObject private var appState: AppStateStore
    let navigate: (VitlTab) -> Void

    @State private var expandedGroup: String?
    @State private var expandedMetric: String?
    @State private var showingSubscribe = false
    @State private var aiSummary = AIHealthSummary.fallback(for: VitlMockData.today)
    @State private var isLoadingAI = false
    @State private var aiError: String?
    @State private var loadingMetricKey: String?

    private var snapshot: DailyHealthSnapshot { appState.today }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                aiSummaryCard
                metricsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 18)
        }
        .background(Color.vitlBackground)
        .sheet(isPresented: $showingSubscribe) {
            SubscribeSheet(navigate: navigate)
                .environmentObject(subscription)
        }
        .task { await loadAISummaryIfNeeded() }
        .refreshable { await loadAISummary(force: true) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("2026年6月10日")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("健康洞察")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.vitlInk)
        }
    }

    private var aiSummaryCard: some View {
        VitlCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.vitlGreen, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("AI 健康分析")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.55))
                        Text(isLoadingAI ? "正在生成分析" : aiSummary.statusTitle)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    if isLoadingAI {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Button { Task { await loadAISummary(force: true) } } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white.opacity(0.75))
                                .frame(width: 34, height: 34)
                                .background(.white.opacity(0.12), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(18)
                .background(LinearGradient(colors: [Color.vitlInk, Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)], startPoint: .topLeading, endPoint: .bottomTrailing))

                if let aiError {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.vitlOrange)
                        Text(aiError)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                }

                InsightTextBlock(title: "核心洞察", bodyText: aiSummary.coreInsight)
                InsightTextBlock(title: "行动建议", bodyText: aiSummary.actionableAdvice)

                Group {
                    if subscription.isPro {
                        InsightTextBlock(title: "深度趋势分析", bodyText: aiSummary.deepTrend)
                            .background(Color.vitlBackground.opacity(0.8), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    } else {
                        Button { showingSubscribe = true } label: {
                            ZStack {
                                Text(aiSummary.deepTrend)
                                    .font(.system(size: 14))
                                    .lineSpacing(4)
                                    .foregroundStyle(.secondary)
                                    .padding(16)
                                    .blur(radius: 4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.vitlBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                VStack(spacing: 8) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 38, height: 38)
                                        .background(Color.vitlInk, in: Circle())
                                    Text("解锁深度分析")
                                        .font(.system(size: 14, weight: .bold))
                                    Text("升级 Vitl Pro 查看完整内容")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    @MainActor
    private func loadAISummaryIfNeeded() async {
        if let cached = appState.state.aiSummary {
            aiSummary = cached
            return
        }
        await loadAISummary(force: false)
    }

    @MainActor
    private func loadAISummary(force: Bool) async {
        guard force || AIConfiguration.apiKey != nil else {
            aiError = "未配置 API Key，当前展示本地示例分析。可在设置页完成 AI 分析接入。"
            return
        }

        isLoadingAI = true
        aiError = nil
        do {
            aiSummary = try await AIService.shared.summarize(
                snapshot: snapshot,
                history: appState.snapshots,
                age: preferences.age,
                height: preferences.height,
                weight: preferences.weight
            )
            appState.setAISummary(aiSummary)
        } catch {
            aiError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoadingAI = false
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("详细指标")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            ForEach(VitlMetricCatalog.groups) { group in
                MetricGroupCard(
                    group: group,
                    snapshot: snapshot,
                    metricInsights: appState.state.metricInsights,
                    loadingMetricKey: loadingMetricKey,
                    expandedGroup: $expandedGroup,
                    expandedMetric: $expandedMetric,
                    isPro: subscription.isPro,
                    showSubscribe: { showingSubscribe = true },
                    loadMetricInsight: loadMetricInsight
                )
            }
        }
    }

    @MainActor
    private func loadMetricInsight(group: MetricGroup, metric: MetricItem, key: String) {
        guard appState.state.metricInsights[key] == nil else { return }
        loadingMetricKey = key
        Task {
            do {
                let value = "\(formatMetric(metric.value(snapshot))) \(metric.unit)"
                let insight = try await AIService.shared.analyzeMetric(
                    label: "\(group.label) · \(metric.label)",
                    value: value,
                    snapshot: snapshot,
                    history: appState.snapshots
                )
                appState.setMetricInsight(insight, for: key)
            } catch {
                if let fallback = metric.insight {
                    appState.setMetricInsight(fallback, for: key)
                }
            }
            loadingMetricKey = nil
        }
    }

    private func formatMetric(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

private struct InsightTextBlock: View {
    let title: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(bodyText)
                .font(.system(size: 14))
                .foregroundStyle(Color.vitlInk.opacity(0.75))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 2)
    }
}

private struct MetricGroupCard: View {
    let group: MetricGroup
    let snapshot: DailyHealthSnapshot
    let metricInsights: [String: String]
    let loadingMetricKey: String?
    @Binding var expandedGroup: String?
    @Binding var expandedMetric: String?
    let isPro: Bool
    let showSubscribe: () -> Void
    let loadMetricInsight: (MetricGroup, MetricItem, String) -> Void

    var isExpanded: Bool { expandedGroup == group.id }

    var body: some View {
        VitlCard {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        expandedGroup = isExpanded ? nil : group.id
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: group.icon)
                            .foregroundStyle(group.color)
                            .frame(width: 34, height: 34)
                            .background(group.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Text(group.label)
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Text("\(group.metrics.count) 项")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .foregroundStyle(Color.vitlInk)
                    .padding(16)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    Divider().opacity(0.5)
                    VStack(spacing: 10) {
                        ForEach(group.metrics) { metric in
                            metricRow(metric)
                        }
                    }
                    .padding(14)
                }
            }
        }
    }

    private func metricRow(_ metric: MetricItem) -> some View {
        let value = metric.value(snapshot)
        let progress = value / metric.max
        let key = "\(group.id)-\(metric.id)"
        let isMetricExpanded = expandedMetric == key

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(metric.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(format(value))
                    .font(.system(size: 16, weight: .bold))
                + Text(" \(metric.unit)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            ProgressPill(value: progress, tint: metric.color)

            if let insight = metric.insight {
                Button {
                    guard isPro else {
                        showSubscribe()
                        return
                    }
                    withAnimation { expandedMetric = isMetricExpanded ? nil : key }
                    if isMetricExpanded == false {
                        loadMetricInsight(group, metric, key)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isPro ? (loadingMetricKey == key ? "sparkles" : "chevron.down") : "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(isPro ? (loadingMetricKey == key ? "生成中" : isMetricExpanded ? "收起分析" : "查看 AI 分析") : "解锁 AI 分析")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(isPro ? .secondary : Color.vitlOrange)
                }
                .buttonStyle(.plain)

                if isPro && isMetricExpanded {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.vitlGreen)
                        Text(metricInsights[key] ?? insight)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(14)
        .background(Color.vitlBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func format(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
    }
}
