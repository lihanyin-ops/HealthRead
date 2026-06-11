import SwiftUI
#if os(iOS)
import UIKit
#endif

struct HomeView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var healthKit: HealthKitManager
    @EnvironmentObject private var appState: AppStateStore

    let showInsight: () -> Void

    @StateObject private var motion = MotionTiltModel()
    @State private var selectedDay = 8
    @State private var waterIntake = VitlMockData.today.waterIntake
    @State private var waterAmount = ""
    @State private var isRefreshing = false
    @State private var showingEnergyTip = false
    @State private var showingWaterSheet = false
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?
    @State private var shareURL: URL?

    private var snapshot: DailyHealthSnapshot {
        appState.snapshot(for: selectedDay)
    }

    private var energyStyle: VitlEnergyStyle {
        VitlEnergyStyle.style(for: snapshot.energyScore)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                header
                dateStrip
                energyCard
                aiCTA
                dailyMetrics
                sleepSummary
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
        .background(Color.vitlBackground)
        .refreshable {
            isRefreshing = true
            let snapshots = await healthKit.fetchRecentSnapshots(days: 7)
            appState.replaceSnapshots(snapshots)
            selectedDay = appState.today.day
            waterIntake = appState.today.waterIntake
            try? await Task.sleep(nanoseconds: 700_000_000)
            isRefreshing = false
        }
        .onChange(of: selectedDay) { _, _ in waterIntake = snapshot.waterIntake }
        .onAppear {
            selectedDay = appState.today.day
            waterIntake = appState.today.waterIntake
            motion.start()
        }
        .onChange(of: appState.state.updatedAt) { _, _ in
            waterIntake = snapshot.waterIntake
        }
        .onDisappear { motion.stop() }
        .sheet(isPresented: $showingEnergyTip) { energyTipSheet }
        .sheet(isPresented: $showingWaterSheet) { waterSheet }
        .sheet(isPresented: $showingShareSheet) { shareSheet }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("2026年6月")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("今天")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.vitlInk)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("周二")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("10")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.vitlInk)
            }
        }
    }

    private var dateStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 7) {
                ForEach(appState.snapshots) { day in
                    let style = VitlEnergyStyle.style(for: day.energyScore)
                    Button {
                        selectedDay = day.day
                    } label: {
                        VStack(spacing: 3) {
                            Text(style.emoji).font(.system(size: 16))
                            Text(day.isToday ? "今天" : day.weekday)
                                .font(.system(size: 11, weight: .semibold))
                            Text("\(day.day)")
                                .font(.system(size: 10, weight: .medium))
                                .opacity(0.62)
                        }
                        .frame(minWidth: 49)
                        .padding(.vertical, 8)
                        .background(selectedDay == day.day ? Color.vitlInk : .white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(selectedDay == day.day ? .white : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var energyCard: some View {
        VitlCard(cornerRadius: 24) {
            VStack(spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("今日能量")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(snapshot.energyScore)")
                                .font(.system(size: 42, weight: .black))
                                .foregroundStyle(Color.vitlInk)
                            Text("/ 100")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            Text(energyStyle.label)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(energyStyle.color)
                        }
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        IconCircleButton(systemName: "exclamationmark", action: { showingEnergyTip = true })
                        IconCircleButton(systemName: "square.and.arrow.up", action: { showingShareSheet = true })
                    }
                }

                LiquidAvatarView(
                    energy: snapshot.energyScore,
                    avatarType: preferences.avatarType,
                    size: 190,
                    tiltX: motion.tiltX,
                    tiltY: motion.tiltY
                )
                Text("轻点模型产生气泡 · 移动设备支持陀螺仪")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(18)
        }
    }

    private var aiCTA: some View {
        Button(action: showInsight) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.vitlGreen, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("今日 AI 健康洞察")
                        .font(.system(size: 14, weight: .semibold))
                    Text(snapshot.energyScore >= 70 ? "状态不错，保持节奏" : snapshot.energyScore >= 50 ? "有改善空间，查看建议" : "需要关注，点击查看分析")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .foregroundStyle(.white)
            .background(Color.vitlInk, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var dailyMetrics: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("日常数据")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                MetricSquare(icon: "heart.fill", iconColor: .vitlRed, label: "心率", value: "\(Int(snapshot.restingHeartRate))", unit: "BPM", footer: "HRV \(Int(snapshot.hrv))ms", progress: nil, progressColor: .vitlRed)
                MetricSquare(icon: "figure.walk", iconColor: .vitlOrange, label: "步数", value: String(format: "%.1f", Double(snapshot.steps) / 1000), unit: "k步", footer: nil, progress: Double(snapshot.steps) / 10000, progressColor: .vitlOrange)
                MetricSquare(icon: "flame.fill", iconColor: .vitlRed, label: "消耗", value: "\(Int(snapshot.moveCalories))", unit: "千卡", footer: nil, progress: snapshot.moveCalories / snapshot.moveGoal, progressColor: .vitlRed)
                MetricSquare(icon: "lungs.fill", iconColor: .vitlTeal, label: "血氧", value: "\(Int(snapshot.oxygenSaturation))", unit: "%", footer: snapshot.oxygenSaturation >= 98 ? "正常" : "偏低", progress: nil, progressColor: .vitlTeal)
                MetricSquare(icon: "brain.head.profile", iconColor: .vitlPurple, label: "压力", value: "\(snapshot.stressLevel)", unit: "/100", footer: stressLabel(snapshot.stressLevel), progress: nil, progressColor: .vitlPurple)
                waterMetric
            }
        }
    }

    private var waterMetric: some View {
        Button { showingWaterSheet = true } label: {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(waterColor)
                    Text("喝水")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(waterColor)
                        .frame(width: 22, height: 22)
                        .background(waterColor.opacity(0.13), in: Circle())
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(waterIntake >= 1000 ? String(format: "%.1f", Double(waterIntake) / 1000) : "\(waterIntake)")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Color.vitlInk)
                    Text(waterIntake >= 1000 ? "L" : "mL")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                ProgressPill(value: Double(waterIntake) / Double(preferences.waterGoal), tint: waterColor)
            }
            .padding(12)
            .aspectRatio(1, contentMode: .fit)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.035), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var sleepSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("昨晚睡眠情况")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VitlCard {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundStyle(Color.vitlPurple)
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(String(format: "%.1f", snapshot.sleepTotal))h 睡眠")
                                .font(.system(size: 15, weight: .bold))
                            Text("评分 \(snapshot.sleepScore)")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(sleepBadge.label)
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .foregroundStyle(sleepBadge.color)
                            .background(sleepBadge.color.opacity(0.12), in: Capsule())
                    }
                    .padding(16)

                    Divider().opacity(0.5)

                    VStack(spacing: 8) {
                        SleepStageBar(snapshot: snapshot)
                        HStack(spacing: 10) {
                            StageLegend(color: .vitlPurple, text: "深睡 \(String(format: "%.1f", snapshot.sleepDeep))h")
                            StageLegend(color: .vitlBlue, text: "REM \(String(format: "%.1f", snapshot.sleepREM))h")
                            StageLegend(color: .vitlTeal, text: "浅睡 \(String(format: "%.1f", snapshot.sleepLight))h")
                        }
                    }
                    .padding(16)

                    Divider().opacity(0.5)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        NightVital(icon: "heart.fill", label: "睡眠心率", value: "\(Int(snapshot.nightHeartRateAvg)) BPM", color: .vitlRed)
                        NightVital(icon: "thermometer.medium", label: "手腕温度", value: "\(snapshot.nightWristTemperature >= 0 ? "+" : "")\(String(format: "%.1f", snapshot.nightWristTemperature))°C", color: .vitlOrange)
                        NightVital(icon: "wind", label: "呼吸频率", value: "\(Int(snapshot.nightRespiratoryRate)) 次/分", color: .vitlPurple)
                        NightVital(icon: "lungs.fill", label: "夜间血氧", value: "\(Int(snapshot.nightOxygenSaturation))%", color: .vitlBlue)
                    }
                    .padding(16)
                }
            }
        }
    }

    private var waterColor: Color {
        if waterIntake >= 2000 { return .vitlBlue }
        if waterIntake >= 1200 { return .vitlTeal }
        return Color(red: 90 / 255, green: 200 / 255, blue: 250 / 255)
    }

    private var sleepBadge: (label: String, color: Color) {
        if snapshot.sleepScore >= 85 { return ("优质", .vitlGreen) }
        if snapshot.sleepScore >= 70 { return ("良好", .vitlBlue) }
        if snapshot.sleepScore >= 55 { return ("一般", .vitlOrange) }
        return ("不足", .vitlRed)
    }

    private func stressLabel(_ value: Int) -> String {
        if value <= 25 { return "放松" }
        if value <= 50 { return "平稳" }
        if value <= 75 { return "偏高" }
        return "紧张"
    }

    private var energyTipSheet: some View {
        SheetChrome {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("能量值说明")
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                }
                Text("今日能量值（0-100）综合了你的多项健康数据，反映你当前的整体身体状态。")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 13) {
                    EnergyWeightRow(label: "昨晚睡眠质量", weight: "35%", color: .vitlPurple)
                    EnergyWeightRow(label: "静息心率 / HRV", weight: "25%", color: .vitlRed)
                    EnergyWeightRow(label: "今日活动量", weight: "20%", color: .vitlOrange)
                    EnergyWeightRow(label: "血氧饱和度", weight: "10%", color: .vitlBlue)
                    EnergyWeightRow(label: "夜间生命体征", weight: "10%", color: .vitlTeal)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private var waterSheet: some View {
        SheetChrome {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "drop.fill").foregroundStyle(waterColor)
                    Text("记录喝水").font(.system(size: 20, weight: .bold))
                    Spacer()
                }
                HStack {
                    Text("今日已记录")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(waterIntake) ")
                        .font(.system(size: 22, weight: .black))
                    + Text("mL")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .background(Color.vitlBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("快速添加")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach([100, 250, 500, 750, 1000], id: \.self) { amount in
                        Button {
                            addWater(amount)
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: "drop.fill")
                                Text(amount < 1000 ? "\(amount)" : "\(amount / 1000)L")
                                    .font(.system(size: 11, weight: .bold))
                                Text("mL").font(.system(size: 9))
                            }
                            .foregroundStyle(waterColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(waterColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("自定义")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    TextField("输入 mL 数量", text: $waterAmount)
                        .keyboardType(.numberPad)
                        .font(.system(size: 14))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(Color.vitlBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Button("添加") {
                        addWater(Int(waterAmount) ?? 0)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 13)
                    .background(waterColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private var shareSheet: some View {
        SheetChrome {
            VStack(alignment: .leading, spacing: 16) {
                Text("分享今日状态")
                    .font(.system(size: 20, weight: .bold))
                ShareCardView(snapshot: snapshot, waterIntake: waterIntake, avatar: preferences.avatarType)
                    .onAppear { renderShareAsset() }
                if let shareURL, let shareImage {
                    ShareLink(item: shareURL, preview: SharePreview("Vitl 今日状态", image: Image(uiImage: shareImage))) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("系统分享")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.vitlInk, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                } else {
                    Button("生成分享卡") {
                        renderShareAsset()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.vitlInk, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func addWater(_ amount: Int) {
        guard amount > 0 else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            waterIntake += amount
            appState.addWater(amount: amount, day: selectedDay)
            waterAmount = ""
            showingWaterSheet = false
        }
        if selectedDay == appState.today.day {
            Task { await healthKit.addWater(amount: amount) }
        }
    }

    private func renderShareAsset() {
        let card = ShareCardView(snapshot: snapshot, waterIntake: waterIntake, avatar: preferences.avatarType)
            .frame(width: 320)
            .padding(16)
            .background(Color.white)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage,
              let data = image.pngData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("vitl-share-\(snapshot.day).png")
        try? data.write(to: url, options: .atomic)
        shareImage = image
        shareURL = url
    }
}

private struct EnergyWeightRow: View {
    let label: String
    let weight: String
    let color: Color

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(Color.vitlInk)
            Spacer()
            Text(weight)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct ShareCardView: View {
    let snapshot: DailyHealthSnapshot
    let waterIntake: Int
    let avatar: AvatarType

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Vitl · 今日能量")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("\(snapshot.energyScore)")
                        .font(.system(size: 34, weight: .black))
                    + Text(" / 100")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    Text(VitlEnergyStyle.style(for: snapshot.energyScore).label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(VitlEnergyStyle.style(for: snapshot.energyScore).color)
                }
                Spacer()
                LiquidAvatarView(energy: snapshot.energyScore, avatarType: avatar, size: 72)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 10) {
                ShareMetric(text: "睡眠 \(String(format: "%.1f", snapshot.sleepTotal))h")
                ShareMetric(text: "步数 \(snapshot.steps.formatted())")
                ShareMetric(text: "心率 \(Int(snapshot.restingHeartRate))")
                ShareMetric(text: "血氧 \(Int(snapshot.oxygenSaturation))%")
                ShareMetric(text: "消耗 \(Int(snapshot.moveCalories))")
                ShareMetric(text: "饮水 \(waterIntake)")
            }
            HStack {
                Text("vitl.app")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.secondary.opacity(0.25))
                    .frame(width: 34, height: 34)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .background(Color.vitlBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ShareMetric: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct IconCircleButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 33, height: 33)
                .background(Color.vitlBackground, in: Circle())
        }
        .buttonStyle(.plain)
    }
}

private struct MetricSquare: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    let unit: String
    let footer: String?
    let progress: Double?
    let progressColor: Color

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(Color.vitlInk)
                    .minimumScaleFactor(0.72)
                Text(unit)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
            if let footer {
                Text(footer)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(progressColor)
            }
            if let progress {
                ProgressPill(value: progress, tint: progressColor)
            }
        }
        .padding(12)
        .aspectRatio(1, contentMode: .fit)
        .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.035), radius: 8, y: 2)
    }
}

private struct SleepStageBar: View {
    let snapshot: DailyHealthSnapshot

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 2) {
                stage(width: snapshot.sleepDeep, color: .vitlPurple, total: snapshot.sleepTotal, proxy: proxy)
                stage(width: snapshot.sleepREM, color: .vitlBlue, total: snapshot.sleepTotal, proxy: proxy)
                stage(width: snapshot.sleepLight, color: .vitlTeal, total: snapshot.sleepTotal, proxy: proxy)
                stage(width: snapshot.sleepAwake, color: Color.gray.opacity(0.25), total: snapshot.sleepTotal, proxy: proxy)
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
    }

    private func stage(width: Double, color: Color, total: Double, proxy: GeometryProxy) -> some View {
        color.frame(width: proxy.size.width * CGFloat(width / max(total, 0.1)))
    }
}

private struct StageLegend: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct NightVital: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
                Text(value).font(.system(size: 13, weight: .bold)).foregroundStyle(color)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.vitlBackground.opacity(0.8), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
