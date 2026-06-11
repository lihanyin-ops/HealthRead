import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var subscription: StoreKitManager
    @EnvironmentObject private var healthKit: HealthKitManager
    @EnvironmentObject private var appState: AppStateStore

    @State private var showingSubscribe = false
    @State private var showingBasicInfo = false
    @State private var showingAvatarPicker = false
    @State private var showingHRZones = false
    @State private var showingAISettings = false

    @State private var draftWeight = 68.0
    @State private var draftHeight = 175.0
    @State private var draftAge = 28
    @State private var draftAIKey = ""
    @State private var draftAIEndpoint = AIConfiguration.defaultEndpoint
    @State private var draftAIModel = AIConfiguration.defaultModel
    @State private var aiKeyConfigured = false

    @AppStorage(AIConfiguration.apiKeyDefaultsKey) private var storedAIKey = ""
    @AppStorage(AIConfiguration.endpointDefaultsKey) private var storedAIEndpoint = AIConfiguration.defaultEndpoint
    @AppStorage(AIConfiguration.modelDefaultsKey) private var storedAIModel = AIConfiguration.defaultModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                header
                subscriptionBanner
                personalSection
                healthSection
                aiSection
                aboutSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 18)
        }
        .background(Color.vitlBackground)
        .sheet(isPresented: $showingSubscribe) {
            SubscribeSheet()
                .environmentObject(subscription)
        }
        .sheet(isPresented: $showingBasicInfo) { basicInfoSheet }
        .sheet(isPresented: $showingAvatarPicker) { avatarPickerSheet }
        .sheet(isPresented: $showingHRZones) { heartRateZonesSheet }
        .sheet(isPresented: $showingAISettings) { aiSettingsSheet }
        .onAppear {
            draftWeight = preferences.weight
            draftHeight = preferences.height
            draftAge = preferences.age
            if let legacyKey = storedAIKey.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty {
                AIKeychain.save(legacyKey)
                storedAIKey = ""
            }
            draftAIKey = AIKeychain.load() ?? ""
            aiKeyConfigured = AIConfiguration.apiKey != nil
            draftAIEndpoint = storedAIEndpoint.isEmpty ? AIConfiguration.defaultEndpoint : storedAIEndpoint
            draftAIModel = storedAIModel.isEmpty ? AIConfiguration.defaultModel : storedAIModel
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("个人中心")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("设置")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.vitlInk)
        }
    }

    private var subscriptionBanner: some View {
        Group {
            if subscription.isPro {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Color.vitlInk)
                        .frame(width: 42, height: 42)
                        .background(Color(red: 1, green: 214 / 255, blue: 10 / 255), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Vitl Pro 已激活")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            Text("PRO")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(Color.vitlInk)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color(red: 1, green: 214 / 255, blue: 10 / 255), in: Capsule())
                        }
                        Text("所有高级功能已解锁")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    Button("取消") { subscription.cancelLocalPrototypeSubscription() }
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(16)
                .background(Color.vitlInk, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                Button { showingSubscribe = true } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(Color.vitlInk)
                            .frame(width: 42, height: 42)
                            .background(Color(red: 1, green: 214 / 255, blue: 10 / 255), in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text("升级 Vitl Pro")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            Text("解锁 AI 分析 · 历程追踪 · 全部功能")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .padding(16)
                    .background(LinearGradient(colors: [Color.vitlInk, Color(red: 58 / 255, green: 58 / 255, blue: 60 / 255)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var personalSection: some View {
        SettingsSection(title: "个人信息") {
            SettingsRow(label: "基础设定", subtitle: "\(Int(preferences.weight))kg · \(Int(preferences.height))cm · \(preferences.age)岁", icon: "ruler", action: { showingBasicInfo = true })
            Divider().padding(.leading, 54)
            SettingsRow(label: "自定义形象", subtitle: preferences.avatarType.label, icon: "person.crop.circle", action: { showingAvatarPicker = true }, leadingEmoji: preferences.avatarType.emoji)
        }
    }

    private var healthSection: some View {
        SettingsSection(title: "健康配置") {
            SettingsRow(label: "心率区间", subtitle: "Zone 1-5 自定义", icon: "heart.fill", action: { showingHRZones = true })
            Divider().padding(.leading, 54)
            SettingsRow(label: "Apple 健康授权", subtitle: healthKit.authorizationStatus, icon: "apple.logo", action: { Task { await healthKit.requestAuthorization() } })
        }
    }

    private var aiSection: some View {
        SettingsSection(title: "智能分析") {
            SettingsRow(
                label: "AI 分析接入",
                subtitle: aiKeyConfigured ? "已配置 · \(storedAIModel)" : "未配置 API Key",
                icon: "sparkles",
                action: {
                    draftAIKey = AIKeychain.load() ?? ""
                    draftAIEndpoint = storedAIEndpoint.isEmpty ? AIConfiguration.defaultEndpoint : storedAIEndpoint
                    draftAIModel = storedAIModel.isEmpty ? AIConfiguration.defaultModel : storedAIModel
                    showingAISettings = true
                }
            )
        }
    }

    private var aboutSection: some View {
        SettingsSection(title: "关于") {
            SettingsRow(label: "隐私政策", icon: "lock.fill", action: { openURL(URL(string: "https://vitl.app/privacy")!) })
            Divider().padding(.leading, 54)
            SettingsRow(label: "使用条款", icon: "doc.text.fill", action: { openURL(URL(string: "https://vitl.app/terms")!) })
            Divider().padding(.leading, 54)
            SettingsRow(label: "版本 1.0.0", icon: "info.circle.fill", action: {}, showChevron: false)
        }
    }

    private var basicInfoSheet: some View {
        SheetChrome {
            VStack(alignment: .leading, spacing: 18) {
                Text("基础设定")
                    .font(.system(size: 20, weight: .bold))
                NumberStepper(label: "体重", value: $draftWeight, unit: "kg", range: 30...200)
                NumberStepper(label: "身高", value: $draftHeight, unit: "cm", range: 100...250)
                IntStepper(label: "年龄", value: $draftAge, unit: "岁", range: 10...100)
                Button {
                    Task { await healthKit.requestAuthorization() }
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("从 Apple 健康同步")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.vitlInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.vitlInk, lineWidth: 1)
                    }
                }
                Button {
                    preferences.weight = draftWeight
                    preferences.height = draftHeight
                    preferences.age = draftAge
                    showingBasicInfo = false
                } label: {
                    Text("保存")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.vitlInk, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private var avatarPickerSheet: some View {
        SheetChrome {
            VStack(alignment: .leading, spacing: 16) {
                Text("选择形象")
                    .font(.system(size: 20, weight: .bold))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(AvatarType.allCases) { avatar in
                        Button {
                            preferences.avatarType = avatar
                            showingAvatarPicker = false
                        } label: {
                            VStack(spacing: 8) {
                                Text(avatar.emoji)
                                    .font(.system(size: 32))
                                Text(avatar.label)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .foregroundStyle(preferences.avatarType == avatar ? .white : Color.vitlInk)
                            .background(preferences.avatarType == avatar ? Color.vitlInk : Color.vitlBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private var heartRateZonesSheet: some View {
        SheetChrome {
            VStack(alignment: .leading, spacing: 16) {
                Text("心率区间")
                    .font(.system(size: 20, weight: .bold))
                VStack(spacing: 14) {
                    ForEach(appState.state.hrZones) { zone in
                        HRZoneRow(
                            zone: zone,
                            color: color(for: zone.id),
                            update: { appState.updateHRZone($0) }
                        )
                    }
                }
                Text("基于最大心率百分比")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private var aiSettingsSheet: some View {
        SheetChrome {
            VStack(alignment: .leading, spacing: 16) {
                Text("AI 分析接入")
                    .font(.system(size: 20, weight: .bold))

                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    SecureField("sk-...", text: $draftAIKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 14))
                        .padding(14)
                        .background(Color.vitlBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("接口地址")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField(AIConfiguration.defaultEndpoint, text: $draftAIEndpoint)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 14))
                        .padding(14)
                        .background(Color.vitlBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("模型")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField(AIConfiguration.defaultModel, text: $draftAIModel)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 14))
                        .padding(14)
                        .background(Color.vitlBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Text("密钥仅保存在本机设置中，用于调用 OpenAI-compatible chat completions 接口。")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    AIKeychain.save(draftAIKey.trimmingCharacters(in: .whitespacesAndNewlines))
                    storedAIKey = ""
                    storedAIEndpoint = draftAIEndpoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AIConfiguration.defaultEndpoint : draftAIEndpoint.trimmingCharacters(in: .whitespacesAndNewlines)
                    storedAIModel = draftAIModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AIConfiguration.defaultModel : draftAIModel.trimmingCharacters(in: .whitespacesAndNewlines)
                    aiKeyConfigured = AIConfiguration.apiKey != nil
                    showingAISettings = false
                } label: {
                    Text("保存配置")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.vitlInk, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
    }

    private func color(for id: Int) -> Color {
        switch id {
        case 1: return .vitlTeal
        case 2: return .vitlGreen
        case 3: return .yellow
        case 4: return .vitlOrange
        default: return .vitlRed
        }
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)
            VStack(spacing: 0) { content }
                .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.035), radius: 8, y: 2)
        }
    }
}

private struct SettingsRow: View {
    let label: String
    var subtitle: String?
    let icon: String
    let action: () -> Void
    var showChevron = true
    var leadingEmoji: String?

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let leadingEmoji {
                    Text(leadingEmoji).font(.system(size: 22)).frame(width: 30)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.vitlInk.opacity(0.75))
                        .frame(width: 30)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.vitlInk)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

private struct NumberStepper: View {
    let label: String
    @Binding var value: Double
    let unit: String
    let range: ClosedRange<Double>

    var body: some View {
        HStack {
            Text(label).font(.system(size: 14, weight: .medium))
            Spacer()
            Button { value = max(range.lowerBound, value - 1) } label: { stepIcon("minus") }
            Text("\(Int(value)) \(unit)")
                .font(.system(size: 16, weight: .bold))
                .frame(width: 82)
            Button { value = min(range.upperBound, value + 1) } label: { stepIcon("plus") }
        }
    }

    private func stepIcon(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.vitlInk)
            .frame(width: 32, height: 32)
            .background(Color.vitlBackground, in: Circle())
    }
}

private struct IntStepper: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(label).font(.system(size: 14, weight: .medium))
            Spacer()
            Button { value = max(range.lowerBound, value - 1) } label: { stepIcon("minus") }
            Text("\(value) \(unit)")
                .font(.system(size: 16, weight: .bold))
                .frame(width: 82)
            Button { value = min(range.upperBound, value + 1) } label: { stepIcon("plus") }
        }
    }

    private func stepIcon(_ icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.vitlInk)
            .frame(width: 32, height: 32)
            .background(Color.vitlBackground, in: Circle())
    }
}

private struct HRZoneRow: View {
    let zone: HRZone
    let color: Color
    let update: (HRZone) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Zone \(zone.id) · \(zone.label)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(zone.min)% - \(zone.max)%")
                    .font(.system(size: 13, weight: .bold))
            }
            HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4).fill(color).frame(width: 6, height: 34)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Stepper(value: Binding(
                        get: { zone.min },
                        set: { update(.init(id: zone.id, label: zone.label, min: min($0, zone.max - 1), max: zone.max)) }
                    ), in: 40...99) {
                        Text("起点").font(.system(size: 12))
                    }
                    Stepper(value: Binding(
                        get: { zone.max },
                        set: { update(.init(id: zone.id, label: zone.label, min: zone.min, max: max($0, zone.min + 1))) }
                    ), in: 41...100) {
                        Text("终点").font(.system(size: 12))
                    }
                }
                HStack(spacing: 8) {
                    Text("\(zone.min)%").font(.system(size: 14, weight: .bold))
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.vitlBackground)
                            Capsule()
                                .fill(color)
                                .frame(width: proxy.size.width * CGFloat(zone.max - zone.min) / 60)
                                .offset(x: proxy.size.width * CGFloat(zone.min - 40) / 60)
                        }
                    }
                    .frame(height: 6)
                    Text("\(zone.max)%").font(.system(size: 14, weight: .bold))
                }
            }
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
