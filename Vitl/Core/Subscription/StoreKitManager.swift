import Foundation
import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {
    @Published var isPro: Bool {
        didSet { UserDefaults.standard.set(isPro, forKey: "subscription.isPro") }
    }

    @Published var selectedPlan: SubscriptionPlan = .lifetime

    init() {
        isPro = UserDefaults.standard.bool(forKey: "subscription.isPro")
    }

    func purchaseSelectedPlan() async {
        isPro = true
    }

    func restorePurchases() async {
        isPro = true
    }

    func cancelLocalPrototypeSubscription() {
        isPro = false
    }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case lifetime
    case year
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lifetime: "永久会员"
        case .year: "年度会员"
        case .month: "月度会员"
        }
    }

    var price: String {
        switch self {
        case .lifetime: "¥168.00"
        case .year: "¥98.00 / 年"
        case .month: "¥18.00 / 月"
        }
    }

    var originalPrice: String {
        switch self {
        case .lifetime: "原价 ¥298.00"
        case .year: "¥128.00 -> ¥98.00"
        case .month: "随时取消"
        }
    }

    var subtitle: String {
        switch self {
        case .lifetime: "一次付费，永久使用"
        case .year: "7 天免费试用"
        case .month: "灵活体验"
        }
    }

    var badge: String? {
        switch self {
        case .lifetime: "43% 优惠"
        case .year: "23% 优惠"
        case .month: nil
        }
    }

    var bullets: [String] {
        switch self {
        case .lifetime:
            ["一次付费", "永久解锁"]
        case .year:
            ["7 天免费试用", "家庭共享"]
        case .month:
            ["按月续订", "随时取消"]
        }
    }

    var cta: String { "继续" }
}
