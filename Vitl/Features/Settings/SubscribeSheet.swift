import SwiftUI

struct SubscribeSheet: View {
    @EnvironmentObject private var subscription: StoreKitManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var navigate: ((VitlTab) -> Void)?

    var body: some View {
        GeometryReader { proxy in
            let horizontalPadding: CGFloat = 20
            let contentWidth = max(proxy.size.width - horizontalPadding * 2, 0)

            ZStack(alignment: .bottom) {
                Color(hex: 0xF5F6FB)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header(width: contentWidth)
                        selectedPlanBanner
                        planCarousel(width: proxy.size.width)
                        benefitsSection(width: contentWidth)
                        supportSection(width: contentWidth)
                        renewalNotice(width: contentWidth)
                    }
                    .frame(width: contentWidth)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 116)
                }

                bottomBar
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(0)
        .presentationBackground(Color(hex: 0xF5F6FB))
    }

    private func header(width: CGFloat) -> some View {
        VStack(spacing: 22) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color(hex: 0xB9BECE))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)

                Spacer()
            }

            VitlMembershipHero()
                .frame(width: min(width, 360), height: 285)

            VStack(spacing: 6) {
                Text("开启 Vitl 会员")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(Color.vitlInk)
                    .rotationEffect(.degrees(-4))
                Text("全面提升你的健康状态")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundStyle(Color(hex: 0x6F96E6))
                    .rotationEffect(.degrees(4))
            }
            .minimumScaleFactor(0.78)
            .multilineTextAlignment(.center)

            Text("选择你的会员计划")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: 0xA58BFF), Color(hex: 0xF0A9D8), Color(hex: 0xB58AF6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .white.opacity(0.95), radius: 0, x: 0, y: 3)
        }
    }

    private var selectedPlanBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 23, weight: .bold))
            Text("\(subscription.selectedPlan.title)已选择")
                .font(.system(size: 23, weight: .bold))
        }
        .foregroundStyle(Color(hex: 0x7199E5))
        .frame(maxWidth: .infinity)
    }

    private func planCarousel(width: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(SubscriptionPlan.allCases) { plan in
                    PlanCard(
                        plan: plan,
                        isSelected: subscription.selectedPlan == plan
                    ) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            subscription.selectedPlan = plan
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .scrollTargetLayout()
        }
        .frame(width: width)
        .scrollTargetBehavior(.viewAligned)
    }

    private func benefitsSection(width: CGFloat) -> some View {
        VStack(spacing: 24) {
            DividerWithHeart()

            Text("会员权益包含")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Color(hex: 0xEF7B78))
                .shadow(color: .white, radius: 0, x: 0, y: 4)

            VStack(spacing: 0) {
                benefit(icon: "medal.fill", iconColor: Color(hex: 0xE7C34D), text: "记录全部健康与运动习惯")
                benefit(icon: "applewatch", iconColor: Color(hex: 0x6A7CE6), text: "Apple Watch HRV 压力全功能版")
                benefit(icon: "heart.fill", iconColor: Color(hex: 0xF27288), text: "实时压力监测")
                benefit(icon: "cloud.fill", iconColor: Color(hex: 0x54D89A), text: "每日身体恢复度")
                benefit(icon: "hourglass", iconColor: Color(hex: 0xB58AF6), text: "身体年龄和变化趋势")
                benefit(icon: "trophy.fill", iconColor: Color(hex: 0xDDBA33), text: "无限参与挑战")
                benefit(icon: "figure.mind.and.body", iconColor: Color(hex: 0x59BF5B), text: "查看完整的身体指标")

                HStack(spacing: 12) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 18, weight: .bold))
                    Text("查看所有权益")
                        .font(.system(size: 20, weight: .bold))
                    Spacer()
                }
                .foregroundStyle(Color(hex: 0x7199E5))
                .padding(.top, 22)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 26)
            .frame(width: width)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        }
    }

    private func supportSection(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            settingsRow(icon: "arrow.clockwise.circle.fill", title: "恢复购买") {
                Task {
                    await subscription.restorePurchases()
                    dismiss()
                }
            }
            settingsRow(icon: "sparkles", title: "自动续费说明") {
                open("https://10m.com.cn/doc/dance/Subscription_Terms.html")
            }
            settingsRow(icon: "lock.shield.fill", title: "隐私政策") {
                open("https://10m.com.cn/doc/browser/Privacy_Policy.html")
            }
            settingsRow(icon: "doc.text.fill", title: "用户协议") {
                open("https://10m.com.cn/doc/browser/User_Agreement.html")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(width: width)
        .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private func renewalNotice(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("确认购买并支付后，将通过您的 iTunes 账号自动续订。苹果 iTunes 账户会在到期前 24 小时内扣费，扣费成功后订阅周期顺延一个订阅周期。如需取消续订，请在当前订阅周期到期前 24 小时以前，手动在 iTunes / Apple ID 设置管理中关闭自动续费功能。试用期内，iTunes 账户如不取消订阅，则会在试用期结束时自动开通订阅并扣款，未使用的试用时长在购买订阅之后将会自动作废。")
            Text("本服务由您自主选择是否取消，若您选择不取消，将为您开通下一个计费周期的续费服务。")
        }
        .font(.system(size: 15, weight: .semibold))
        .lineSpacing(3)
        .foregroundStyle(Color(hex: 0x8D92B1))
        .frame(width: width, alignment: .leading)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    await subscription.purchaseSelectedPlan()
                    dismiss()
                }
            } label: {
                Text(subscription.selectedPlan.cta)
                    .font(.system(size: 21, weight: .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: 0x6C95E4), Color(hex: 0x78A0E7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
                    .shadow(color: Color(hex: 0x6C95E4).opacity(0.28), radius: 22, y: 12)
            }
            .buttonStyle(.plain)

            Text("开通即表示同意会员服务和自动续费规则")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(hex: 0x9EA4BE))
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [Color(hex: 0xF5F6FB).opacity(0), Color(hex: 0xF5F6FB), Color(hex: 0xF5F6FB)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func benefit(icon: String, iconColor: Color, text: String) -> some View {
        HStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 25, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconColor)
                .frame(width: 42, height: 56)

            Text(text)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(Color(hex: 0x151B52))
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            Spacer(minLength: 10)

            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: 0x7199E5))
        }
        .frame(height: 70)
    }

    private func settingsRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 25, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color(hex: 0x7199E5))
                    .frame(width: 40)

                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(hex: 0x151B52))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: 0xBFC4D3))
            }
            .frame(height: 66)
        }
        .buttonStyle(.plain)
    }

    private func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        openURL(url)
    }
}

private struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(plan.title)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(Color(hex: 0x151B52))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let badge = plan.badge {
                        Text("✨\(badge)✨")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: 0xE889EA), Color(hex: 0xF1D46D)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    }

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 5) {
                    ForEach(plan.bullets, id: \.self) { bullet in
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                            Text(bullet)
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(Color(hex: 0x7199E5))
                    }
                }
                .frame(height: 46, alignment: .topLeading)

                Spacer(minLength: 6)

                Text(plan.price)
                    .font(.system(size: 23, weight: .heavy))
                    .foregroundStyle(Color(hex: 0x151B52))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(plan.originalPrice)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color(hex: 0x8D92B1))
                    .strikethrough(plan != .month, color: Color(hex: 0x8D92B1))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(24)
            .frame(width: 258, height: 176, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(isSelected ? Color(hex: 0x7199E5) : .clear, lineWidth: 4)
            }
            .shadow(color: isSelected ? Color(hex: 0x7199E5).opacity(0.22) : .black.opacity(0.04), radius: isSelected ? 18 : 10, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private struct DividerWithHeart: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .frame(height: 1)
            Image(systemName: "heart")
                .font(.system(size: 17, weight: .light))
                .padding(.horizontal, 10)
            Rectangle()
                .frame(height: 1)
        }
        .foregroundStyle(Color.black.opacity(0.14))
    }
}

private struct VitlMembershipHero: View {
    var body: some View {
        ZStack {
            FeatureBubble(color: Color(hex: 0xAEEBFF), symbol: "person.fill", x: -116, y: -30)
            FeatureBubble(color: Color(hex: 0xFFD08A), symbol: "bag.fill", x: -40, y: -112)
            FeatureBubble(color: Color(hex: 0xFDB4AF), symbol: "flame.fill", x: 70, y: -102)
            FeatureBubble(color: Color(hex: 0xB3F3A4), symbol: "figure.walk", x: 132, y: -20)
            FeatureBubble(color: Color(hex: 0xDAE4FF), symbol: "drop.fill", x: -126, y: 70)
            FeatureBubble(color: Color(hex: 0xF7D7D4), symbol: "waveform.path.ecg", x: 120, y: 76)

            VStack(spacing: -4) {
                ZStack {
                    Circle()
                        .fill(Color(hex: 0xE4A96E))
                        .frame(width: 62, height: 62)
                    HairShape()
                        .fill(Color(hex: 0x3B0905))
                        .frame(width: 82, height: 56)
                        .offset(y: -20)
                    HStack(spacing: 16) {
                        Circle().frame(width: 5, height: 5)
                        Circle().frame(width: 5, height: 5)
                    }
                    .foregroundStyle(Color(hex: 0x1C0E0A))
                    .offset(y: -4)
                    Capsule()
                        .fill(Color(hex: 0xB94B23))
                        .frame(width: 5, height: 10)
                        .offset(y: 7)
                    Capsule()
                        .stroke(Color(hex: 0x1C0E0A), lineWidth: 2)
                        .frame(width: 13, height: 8)
                        .offset(x: 11, y: 18)
                }

                ZStack {
                    Capsule()
                        .fill(Color(hex: 0xE6AC76))
                        .frame(width: 46, height: 138)
                        .rotationEffect(.degrees(-55))
                        .offset(x: -88, y: -12)
                    Capsule()
                        .fill(Color(hex: 0xE6AC76))
                        .frame(width: 46, height: 138)
                        .rotationEffect(.degrees(55))
                        .offset(x: 88, y: -12)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(hex: 0xAE9BC5))
                        .frame(width: 126, height: 106)
                        .rotationEffect(.degrees(4))

                    HStack(spacing: 0) {
                        Capsule()
                            .fill(Color(hex: 0xD9D7D2))
                            .frame(width: 118, height: 48)
                            .rotationEffect(.degrees(-35))
                        Capsule()
                            .fill(Color(hex: 0xD9D7D2))
                            .frame(width: 118, height: 48)
                            .rotationEffect(.degrees(20))
                    }
                    .offset(y: 88)
                }
                .frame(height: 175)
            }
            .offset(y: 32)
        }
    }
}

private struct FeatureBubble: View {
    let color: Color
    let symbol: String
    let x: CGFloat
    let y: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.95), color.opacity(0.88), color.opacity(0.42)],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: 58
                    )
                )
            Circle()
                .fill(.white.opacity(0.38))
                .frame(width: 34, height: 22)
                .offset(x: 14, y: 12)
                .blur(radius: 1)
            Image(systemName: symbol)
                .font(.system(size: 27, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color.opacity(0.95))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 70, height: 70)
        .offset(x: x, y: y)
    }
}

private struct HairShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 8, y: rect.midY + 10))
        path.addCurve(to: CGPoint(x: rect.minX + 18, y: rect.minY + 8), control1: CGPoint(x: rect.minX + 2, y: rect.midY - 12), control2: CGPoint(x: rect.minX + 9, y: rect.minY + 8))
        path.addCurve(to: CGPoint(x: rect.midX - 2, y: rect.minY + 4), control1: CGPoint(x: rect.minX + 25, y: rect.minY - 4), control2: CGPoint(x: rect.midX - 16, y: rect.minY + 1))
        path.addCurve(to: CGPoint(x: rect.maxX - 9, y: rect.midY + 10), control1: CGPoint(x: rect.midX + 18, y: rect.minY), control2: CGPoint(x: rect.maxX + 2, y: rect.minY + 18))
        path.addCurve(to: CGPoint(x: rect.midX + 8, y: rect.maxY - 2), control1: CGPoint(x: rect.maxX - 16, y: rect.maxY - 8), control2: CGPoint(x: rect.midX + 24, y: rect.maxY - 2))
        path.addCurve(to: CGPoint(x: rect.minX + 8, y: rect.midY + 10), control1: CGPoint(x: rect.midX - 16, y: rect.maxY - 6), control2: CGPoint(x: rect.minX + 18, y: rect.maxY - 2))
        path.closeSubpath()
        return path
    }
}
