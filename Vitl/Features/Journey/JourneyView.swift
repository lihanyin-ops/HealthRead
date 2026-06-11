import SwiftUI

struct JourneyView: View {
    @EnvironmentObject private var subscription: StoreKitManager
    @EnvironmentObject private var appState: AppStateStore
    @EnvironmentObject private var healthKit: HealthKitManager
    let navigate: (VitlTab) -> Void

    @State private var period: Period = .week
    @State private var expandedGroup: String? = "rings"
    @State private var showingSubscribe = false
    @State private var isLoadingJourney = false
    @State private var journeyError: String?

    enum Period: String, CaseIterable, Identifiable {
        case week
        case month
        case year
        var id: String { rawValue }
        var title: String { self == .week ? "本周" : self == .month ? "本月" : "本年" }
        var days: Int { self == .week ? 7 : self == .month ? 30 : 365 }
    }

    private var visibleSnapshots: [DailyHealthSnapshot] {
        Array(appState.snapshots.suffix(min(period.days, appState.snapshots.count)))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                periodSelector
                energyOverview
                if subscription.isPro {
                    proContent
                } else {
                    lockedPreview
                }
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
        .task { await loadPeriodData() }
        .onChange(of: period) { _, _ in Task { await loadPeriodData() } }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("健康历程")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("趋势追踪")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.vitlInk)
        }
    }

    private var periodSelector: some View {
        HStack(spacing: 4) {
            ForEach(Period.allCases) { item in
                Button {
                    period = item
                } label: {
                    Text(item.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(period == item ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(period == item ? Color.vitlInk : .clear, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.035), radius: 8, y: 2)
    }

    private var energyOverview: some View {
        VitlCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("能量趋势")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("7日能量变化")
                            .font(.system(size: 17, weight: .bold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("均值")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text("\(averageEnergy)")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(Color.vitlGreen)
                    }
                }
                MiniChart(values: visibleSnapshots.map { Double($0.energyScore) }, color: .vitlGreen, style: .area)
                    .frame(height: 124)
            }
            .padding(16)
        }
    }

    private var proContent: some View {
        VStack(spacing: 12) {
            VitlCard {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.vitlPurple, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 5) {
                        Text(isLoadingJourney ? "正在生成趋势洞察..." : appState.state.journeyInsight ?? "过去7天，你的整体健康状态呈上升趋势，关键驱动因素是睡眠质量改善。")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                        if let journeyError {
                            Text(journeyError)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.vitlOrange)
                        }
                    }
                    Spacer(minLength: 0)
                    if isLoadingJourney {
                        ProgressView()
                    } else {
                        Button { Task { await loadJourneyInsight(force: true) } } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }

            ForEach(chartGroups) { group in
                ChartGroupCard(group: group, expandedGroup: $expandedGroup)
            }
        }
    }

    private var lockedPreview: some View {
        Button { showingSubscribe = true } label: {
            ZStack {
                VStack(spacing: 12) {
                    VitlCard { Text("过去7天，你的整体健康状态呈上升趋势。").font(.system(size: 14)).padding(16) }
                    previewChart(title: "步数趋势", values: visibleSnapshots.map { Double($0.steps) }, color: .vitlOrange, style: .bar)
                    previewChart(title: "睡眠趋势", values: visibleSnapshots.map { $0.sleepTotal }, color: .vitlPurple, style: .bar)
                }
                .blur(radius: 5)
                LockOverlay(title: "历程功能需要 Pro", subtitle: "升级后解锁全部趋势图表、AI 规律洞察和历史数据对比")
            }
        }
        .buttonStyle(.plain)
    }

    private func previewChart(title: String, values: [Double], color: Color, style: MiniChart.Style) -> some View {
        VitlCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(.system(size: 15, weight: .bold))
                MiniChart(values: values, color: color, style: style).frame(height: 92)
            }
            .padding(16)
        }
    }

    private var averageEnergy: Int {
        guard visibleSnapshots.isEmpty == false else { return 0 }
        return Int((visibleSnapshots.map { $0.energyScore }.reduce(0, +) / visibleSnapshots.count))
    }

    private var chartGroups: [ChartGroup] {
        [
            .init(id: "rings", title: "活动圆环", icon: "circle.hexagongrid.fill", color: .vitlRed, charts: [
                .init(title: "活动消耗（Move）", unit: "千卡", color: .vitlRed, style: .bar, values: visibleSnapshots.map { $0.moveCalories }),
                .init(title: "锻炼时长（Exercise）", unit: "分钟", color: .green, style: .bar, values: visibleSnapshots.map { $0.exerciseMinutes }),
                .init(title: "站立时长（Stand）", unit: "小时", color: .cyan, style: .bar, values: visibleSnapshots.map { Double($0.standHours) })
            ]),
            .init(id: "steps", title: "步数与距离", icon: "figure.walk", color: .vitlGreen, charts: [
                .init(title: "步数", unit: "步", color: .vitlGreen, style: .bar, values: visibleSnapshots.map { Double($0.steps) }),
                .init(title: "步行+跑步距离", unit: "km", color: .green, style: .line, values: visibleSnapshots.map { $0.walkingRunningDistance })
            ]),
            .init(id: "heart", title: "心率", icon: "heart.fill", color: .vitlRed, charts: [
                .init(title: "静息心率", unit: "BPM", color: .vitlRed, style: .line, values: visibleSnapshots.map { $0.restingHeartRate }),
                .init(title: "HRV", unit: "ms", color: .pink, style: .line, values: visibleSnapshots.map { $0.hrv }),
                .init(title: "心肺健康 VO₂ max", unit: "mL/kg/min", color: .red, style: .line, values: visibleSnapshots.map { $0.cardioFitness })
            ]),
            .init(id: "sleep", title: "睡眠", icon: "moon.fill", color: .vitlPurple, charts: [
                .init(title: "睡眠评分", unit: "分", color: .vitlPurple, style: .bar, values: visibleSnapshots.map { Double($0.sleepScore) }),
                .init(title: "总睡眠时长", unit: "h", color: .purple, style: .bar, values: visibleSnapshots.map { $0.sleepTotal }),
                .init(title: "睡眠效率", unit: "%", color: .indigo, style: .line, values: visibleSnapshots.map { $0.sleepEfficiency })
            ])
        ]
    }

    @MainActor
    private func loadPeriodData() async {
        let snapshots = await healthKit.fetchRecentSnapshots(days: period.days)
        appState.replaceSnapshots(snapshots)
        await loadJourneyInsight(force: false)
    }

    @MainActor
    private func loadJourneyInsight(force: Bool) async {
        guard subscription.isPro else { return }
        if force == false, appState.state.journeyInsight != nil { return }
        guard AIConfiguration.apiKey != nil else {
            journeyError = "未配置 API Key，展示本地趋势文案"
            return
        }
        isLoadingJourney = true
        journeyError = nil
        do {
            let insight = try await AIService.shared.analyzeJourney(history: visibleSnapshots)
            appState.setJourneyInsight(insight)
        } catch {
            journeyError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isLoadingJourney = false
    }
}

private struct ChartGroup: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let charts: [ChartItem]
}

private struct ChartItem: Identifiable {
    let id = UUID()
    let title: String
    let unit: String
    let color: Color
    let style: MiniChart.Style
    let values: [Double]
}

private struct ChartGroupCard: View {
    let group: ChartGroup
    @Binding var expandedGroup: String?

    var isExpanded: Bool { expandedGroup == group.id }

    var body: some View {
        VitlCard {
            VStack(spacing: 0) {
                Button {
                    withAnimation { expandedGroup = isExpanded ? nil : group.id }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: group.icon)
                            .foregroundStyle(group.color)
                            .frame(width: 34, height: 34)
                            .background(group.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Text(group.title).font(.system(size: 15, weight: .bold))
                        Spacer()
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
                    VStack(spacing: 18) {
                        ForEach(group.charts) { chart in
                            VStack(alignment: .leading, spacing: 9) {
                                Text(chart.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                MiniChart(values: chart.values, color: chart.color, style: chart.style)
                                    .frame(height: 84)
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}
