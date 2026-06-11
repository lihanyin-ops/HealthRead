import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var appState: AppStateStore
    @StateObject private var motion = MotionTiltModel()
    @State private var page = 0

    private var snapshot: DailyHealthSnapshot { appState.today }
    private let pages = [0, 1, 2]

    var body: some View {
        TabView(selection: $page) {
            WatchEnergyPage(snapshot: snapshot, avatar: preferences.avatarType, tiltX: motion.tiltX, tiltY: motion.tiltY)
                .tag(0)
            WatchStatsPage(snapshot: snapshot)
                .tag(1)
            WatchAIPage(snapshot: snapshot, summary: appState.state.aiSummary)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color.black.ignoresSafeArea())
        .overlay(alignment: .bottom) {
            HStack(spacing: 5) {
                ForEach(pages, id: \.self) { item in
                    Capsule()
                        .fill(item == page ? .white : .white.opacity(0.3))
                        .frame(width: item == page ? 16 : 5, height: 5)
                }
            }
            .padding(.bottom, 3)
        }
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
    }
}

private struct WatchEnergyPage: View {
    let snapshot: DailyHealthSnapshot
    let avatar: AvatarType
    let tiltX: Double
    let tiltY: Double

    var body: some View {
        let style = VitlEnergyStyle.style(for: snapshot.energyScore)
        VStack(spacing: 7) {
            Text("今日能量")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1.6)
            ZStack(alignment: .bottomTrailing) {
                LiquidAvatarView(energy: snapshot.energyScore, avatarType: avatar, size: 106, tiltX: tiltX, tiltY: tiltY)
                Text("\(snapshot.energyScore)")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(style.color, in: Capsule())
                    .offset(x: 1, y: -2)
            }
            Text("\(style.label) \(style.emoji)")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 14)
    }
}

private struct WatchStatsPage: View {
    let snapshot: DailyHealthSnapshot

    var body: some View {
        VStack(spacing: 8) {
            Text("健康数据")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(1.6)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 7), GridItem(.flexible(), spacing: 7)], spacing: 7) {
                WatchStat(icon: "figure.walk", label: "步数", value: snapshot.steps.formatted(), color: .vitlGreen)
                WatchStat(icon: "heart.fill", label: "心率", value: "\(Int(snapshot.restingHeartRate)) BPM", color: .vitlRed)
                WatchStat(icon: "moon.fill", label: "睡眠", value: "\(String(format: "%.1f", snapshot.sleepTotal))h", color: .vitlPurple)
                WatchStat(icon: "waveform.path.ecg", label: "HRV", value: "\(Int(snapshot.hrv))ms", color: .vitlTeal)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct WatchStat: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.78)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct WatchAIPage: View {
    let snapshot: DailyHealthSnapshot
    let summary: AIHealthSummary?

    var body: some View {
        let style = VitlEnergyStyle.style(for: snapshot.energyScore)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 18, height: 18)
                    .background(style.color, in: Circle())
                Text("AI 建议")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(style.color)
            }
            Text(summary?.statusTitle ?? (snapshot.energyScore >= 70 ? "状态不错，可以安排一次跑步。" : "睡眠不足，今天别太拼。"))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .lineSpacing(3)
            Text(summary?.actionableAdvice ?? "HRV偏低，建议午休20分钟，晚10点前入睡。")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.42))
                .lineSpacing(3)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
