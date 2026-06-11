import SwiftUI

enum VitlTab: String, CaseIterable {
    case home
    case insight
    case journey
    case settings

    var title: String {
        switch self {
        case .home: return "首页"
        case .insight: return "洞察"
        case .journey: return "历程"
        case .settings: return "设置"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .insight: return "chart.bar.xaxis"
        case .journey: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct RootTabView: View {
    @State private var selectedTab: VitlTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.vitlBackground.ignoresSafeArea()
            Group {
                switch selectedTab {
                case .home:
                    HomeView(showInsight: { selectedTab = .insight })
                case .insight:
                    InsightView(navigate: { selectedTab = $0 })
                case .journey:
                    JourneyView(navigate: { selectedTab = $0 })
                case .settings:
                    SettingsView()
                }
            }
            .safeAreaPadding(.bottom, 76)

            VitlTabBar(selectedTab: $selectedTab)
        }
    }
}

struct VitlTabBar: View {
    @Binding var selectedTab: VitlTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(VitlTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 21, weight: selectedTab == tab ? .semibold : .regular))
                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular))
                    }
                    .foregroundStyle(selectedTab == tab ? Color.vitlInk : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 9)
        .frame(height: 70)
        .background(.white)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.black.opacity(0.05)).frame(height: 0.5)
        }
    }
}
