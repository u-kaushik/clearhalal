import SwiftUI

@main
struct ClearHalalApp: App {
    @AppStorage("clearhalal.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("clearhalal.hasSeenPaywall") private var hasSeenPaywall = false
    @StateObject private var store = ScanHistoryStore()
    @StateObject private var subscription = SubscriptionStore()

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if let screenshotScreen = ScreenshotScreen.current {
                    ScreenshotHostView(screen: screenshotScreen)
                } else if !hasCompletedOnboarding {
                    OnboardingFlowView {
                        hasCompletedOnboarding = true
                    }
                } else if !hasSeenPaywall && !subscription.isPremium {
                    HardPaywallView {
                        subscription.startTrial()
                        hasSeenPaywall = true
                    } onRestore: {
                        subscription.restoreForPrototype()
                        hasSeenPaywall = true
                    }
                } else {
                    ContentView()
                }
                #else
                if !hasCompletedOnboarding {
                    OnboardingFlowView {
                        hasCompletedOnboarding = true
                    }
                } else if !hasSeenPaywall && !subscription.isPremium {
                    HardPaywallView {
                        subscription.startTrial()
                        hasSeenPaywall = true
                    } onRestore: {
                        subscription.restoreForPrototype()
                        hasSeenPaywall = true
                    }
                } else {
                    ContentView()
                }
                #endif
            }
            .environmentObject(store)
            .environmentObject(subscription)
            .task {
                subscription.configure()
            }
        }
    }
}

#if DEBUG
enum ScreenshotScreen: String {
    case home
    case result
    case ingredientDetail = "ingredient-detail"
    case history
    case progress
    case awardUnlock = "award-unlock"
    case settings

    static var current: ScreenshotScreen? {
        guard let index = CommandLine.arguments.firstIndex(of: "--clearhalal-screenshot"),
              CommandLine.arguments.indices.contains(index + 1) else {
            return nil
        }
        return ScreenshotScreen(rawValue: CommandLine.arguments[index + 1])
    }
}

struct ScreenshotHostView: View {
    @EnvironmentObject private var store: ScanHistoryStore
    let screen: ScreenshotScreen

    private var featuredResult: ScanResult {
        store.history.first(where: { $0.verdict == .haramConcern }) ?? store.history[0]
    }

    private var featuredIngredient: EvidenceItem {
        featuredResult.evidence.first(where: { $0.verdict == .haramConcern }) ?? featuredResult.evidence[0]
    }

    private var featuredAchievement: ScannerCoachAchievement {
        store.achievements.first(where: { $0.id == "ingredient-learner" && $0.isUnlocked })
            ?? store.achievements.first(where: { $0.isUnlocked })
            ?? store.achievements[0]
    }

    var body: some View {
        Group {
            switch screen {
            case .home:
                ContentView(initialTab: .scan)
            case .history:
                ContentView(initialTab: .history)
            case .progress:
                ContentView(initialTab: .insights)
            case .awardUnlock:
                AwardDetailView(achievement: featuredAchievement)
            case .settings:
                ContentView(initialTab: .settings)
            case .result:
                NavigationStack {
                    ResultView(result: featuredResult)
                }
                .background(ClearHalalTheme.background.ignoresSafeArea())
                .overlay(alignment: .bottom) {
                    ScreenshotTabBar(selectedTab: .history)
                }
            case .ingredientDetail:
                NavigationStack {
                    ScreenshotIngredientDetailScreen(result: featuredResult, item: featuredIngredient)
                }
                .background(ClearHalalTheme.background.ignoresSafeArea())
                .overlay(alignment: .bottom) {
                    ScreenshotTabBar(selectedTab: .history)
                }
            }
        }
    }
}

private struct ScreenshotTabBar: View {
    let selectedTab: ScannerCoachTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ScannerCoachTab.allCases) { tab in
                ScreenshotTabItem(tab: tab, isSelected: selectedTab == tab)
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

private struct ScreenshotTabItem: View {
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
    }
}

private struct ScreenshotIngredientDetailScreen: View {
    let result: ScanResult
    let item: EvidenceItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CheckedLabelContextCard(result: result)
                IngredientDetailView(item: item)
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, 18)
        }
        .background(ClearHalalTheme.background.ignoresSafeArea())
        .navigationTitle("Ingredient detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ClearHalalTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct CheckedLabelContextCard: View {
    let result: ScanResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("From checked label")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ClearHalalTheme.secondaryText)
            Text(result.displayTitle)
                .font(.headline)
                .foregroundStyle(ClearHalalTheme.primaryText)
            Text(result.labelPreview)
                .font(.caption)
                .foregroundStyle(ClearHalalTheme.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .clearHalalCard()
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }
}
#endif
