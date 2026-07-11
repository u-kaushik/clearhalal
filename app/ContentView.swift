import SwiftUI

struct ContentView: View {
    private let config = ScannerCoachAppConfig.clearHalal
    @State private var selectedTab: ScannerCoachTab

    init(initialTab: ScannerCoachTab = .scan) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack {
            StableTabPage(tab: .scan, selectedTab: selectedTab) {
                HomeView()
            }

            StableTabPage(tab: .history, selectedTab: selectedTab) {
                HistoryView()
            }

            StableTabPage(tab: .insights, selectedTab: selectedTab) {
                InsightsView()
            }

            StableTabPage(tab: .settings, selectedTab: selectedTab) {
                SettingsView()
            }
        }
        .accessibilityIdentifier("\(config.storageKeyPrefix).tab-shell")
        .background(ClearHalalTheme.background.ignoresSafeArea())
        .overlay(alignment: .top) {
            TopSafeAreaShield()
        }
        .overlay(alignment: .bottom) {
            ClearHalalTabBar(selectedTab: $selectedTab)
        }
    }
}

private struct TopSafeAreaShield: View {
    var body: some View {
        GeometryReader { proxy in
            ClearHalalTheme.background
                .frame(height: proxy.safeAreaInsets.top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
        }
    }
}

private struct StableTabPage<Content: View>: View {
    let tab: ScannerCoachTab
    let selectedTab: ScannerCoachTab
    @ViewBuilder let content: Content

    var body: some View {
        content
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
            .animation(nil, value: selectedTab)
    }
}

private struct ClearHalalTabBar: View {
    @Binding var selectedTab: ScannerCoachTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ScannerCoachTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    ClearHalalTabItem(tab: tab, isSelected: selectedTab == tab)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(6)
        .background(
            Capsule(style: .continuous)
                .fill(ClearHalalTheme.surface)
                .shadow(color: ClearHalalTheme.deepForest.opacity(0.12), radius: 18, y: 8)
        )
        .overlay {
            Capsule(style: .continuous)
                .stroke(ClearHalalTheme.border.opacity(0.8), lineWidth: 1)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
}

private struct ClearHalalTabItem: View {
    let tab: ScannerCoachTab
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: tab.icon)
                .font(.system(size: 21, weight: .semibold))
            Text(tab.title)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundStyle(isSelected ? ClearHalalTheme.deepForest : ClearHalalTheme.primaryText)
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background {
            if isSelected {
                Capsule(style: .continuous)
                    .fill(ClearHalalTheme.soft)
            }
        }
        .contentShape(Rectangle())
    }
}
