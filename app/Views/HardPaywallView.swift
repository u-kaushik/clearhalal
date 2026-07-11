import SwiftUI

struct HardPaywallView: View {
    @EnvironmentObject private var subscription: SubscriptionStore
    let onStartTrial: () -> Void
    let onRestore: () -> Void

    @State private var selectedPlan: PaywallPlan = .annual
    @State private var focusedBenefit = 0
    private let benefitTimer = Timer.publish(every: 2.8, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ClearHalalTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ClearHalalWordmark()
                        .padding(.top, 10)
                        .fadeInOnAppear(delay: 0.02)

                    VStack(spacing: 6) {
                        Text("Check every label\nwith more confidence")
                            .font(ClearHalalTheme.display(31, weight: .semibold))
                            .foregroundStyle(ClearHalalTheme.deepForest)
                            .multilineTextAlignment(.center)
                            .lineSpacing(1)

                        Text("Unlimited scans, saved checks, clearer explanations.")
                            .font(.subheadline)
                            .foregroundStyle(ClearHalalTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .fadeInOnAppear(delay: 0.08)

                    BenefitCarousel(focusedBenefit: $focusedBenefit)
                        .fadeInOnAppear(delay: 0.14)
                        .onReceive(benefitTimer) { _ in
                            withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                                focusedBenefit = (focusedBenefit + 1) % PaywallBenefit.allCases.count
                            }
                        }

                    VStack(spacing: 8) {
                        ForEach(PaywallPlan.allCases) { plan in
                            PaywallPlanRow(
                                plan: plan,
                                isSelected: selectedPlan == plan,
                                isLoading: subscription.isLoading
                            ) {
                                selectedPlan = plan
                            }
                        }
                    }
                    .fadeInOnAppear(delay: 0.2)

                    if let message = subscription.statusMessage, !subscription.isPremium {
                        Text(message)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(ClearHalalTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 214)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PaywallBottomBar(
                selectedPlan: selectedPlan,
                isLoading: subscription.isLoading,
                isRevenueCatConfigured: subscription.isRevenueCatConfigured,
                onPurchase: {
                    if subscription.isRevenueCatConfigured {
                        subscription.purchase(productID: selectedPlan.productID)
                    } else {
                        onStartTrial()
                    }
                },
                onRestore: {
                    if subscription.isRevenueCatConfigured {
                        subscription.restorePurchases()
                    } else {
                        onRestore()
                    }
                }
            )
        }
        .onAppear {
            #if canImport(RevenueCat)
            if subscription.isRevenueCatConfigured {
                subscription.loadOfferings()
            }
            #endif
        }
    }
}

private enum PaywallBenefit: Int, CaseIterable, Identifiable {
    case scan
    case explain
    case history

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .scan: return "Scan without counting labels"
        case .explain: return "Understand mushbooh ingredients"
        case .history: return "Keep trusted products saved"
        }
    }

    var subtitle: String {
        switch self {
        case .scan: return "Unlimited checks for shops, menus, and pantry restocks."
        case .explain: return "Source notes for gelatin, E-numbers, and additives."
        case .history: return "Revisit trusted products while shopping."
        }
    }

    var icon: String {
        switch self {
        case .scan: return "viewfinder"
        case .explain: return "text.magnifyingglass"
        case .history: return "clock.arrow.circlepath"
        }
    }

    var tint: Color {
        switch self {
        case .scan: return ClearHalalTheme.deepForest
        case .explain: return ClearHalalTheme.caution
        case .history: return ClearHalalTheme.positive
        }
    }
}

private struct BenefitCarousel: View {
    @Binding var focusedBenefit: Int

    var body: some View {
        VStack(spacing: 12) {
            TabView(selection: $focusedBenefit) {
                ForEach(PaywallBenefit.allCases) { benefit in
                    BenefitCard(benefit: benefit)
                        .tag(benefit.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 106)

            HStack(spacing: 8) {
                ForEach(PaywallBenefit.allCases) { benefit in
                    Capsule()
                        .fill(benefit.rawValue == focusedBenefit ? ClearHalalTheme.deepForest : ClearHalalTheme.border)
                        .frame(width: benefit.rawValue == focusedBenefit ? 26 : 8, height: 8)
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.9), value: focusedBenefit)
        }
    }
}

private struct BenefitCard: View {
    let benefit: PaywallBenefit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: benefit.icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(benefit.tint)
                    .frame(width: 34, height: 34)
                    .background(benefit.tint.opacity(0.12))
                    .clipShape(Circle())

                Spacer()

                Text("Premium")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClearHalalTheme.deepForest)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ClearHalalTheme.cautionSoft)
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.title)
                    .font(.headline)
                    .foregroundStyle(ClearHalalTheme.primaryText)

                Text(benefit.subtitle)
                    .font(.caption)
                    .foregroundStyle(ClearHalalTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.86)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clearHalalCard()
    }
}

private enum PaywallPlan: String, CaseIterable, Identifiable {
    case weekly
    case monthly
    case annual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }

    var price: String {
        switch self {
        case .weekly: return "$3.99/wk"
        case .monthly: return "$9.99/mo"
        case .annual: return "$39.99/yr"
        }
    }

    var detail: String {
        switch self {
        case .weekly: return "For focused shopping trips."
        case .monthly: return "For regular grocery checks."
        case .annual: return "$3.33/mo. Best value."
        }
    }

    var productID: String {
        switch self {
        case .weekly: return RevenueCatConfig.weeklyProductID
        case .monthly: return RevenueCatConfig.monthlyProductID
        case .annual: return RevenueCatConfig.annualProductID
        }
    }

    var ctaTitle: String {
        switch self {
        case .annual: return "Start 7-Day Free Trial"
        default: return "Continue"
        }
    }

    var legalCopy: String {
        switch self {
        case .weekly: return "Then $3.99/week. Cancel anytime. Terms & Privacy. Not certification or a religious ruling."
        case .monthly: return "Then $9.99/month. Cancel anytime. Terms & Privacy. Not certification or a religious ruling."
        case .annual: return "Then $39.99/year after trial. Cancel anytime. Terms & Privacy. Not certification or a religious ruling."
        }
    }

    var shortLegalCopy: String {
        switch self {
        case .weekly: return "$3.99/week. Cancel anytime."
        case .monthly: return "$9.99/month. Cancel anytime."
        case .annual: return "7-day trial, then $39.99/year. Cancel anytime."
        }
    }

    var badge: String? {
        self == .annual ? "BEST VALUE" : nil
    }
}

private struct PaywallPlanRow: View {
    let plan: PaywallPlan
    let isSelected: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(plan.title)
                            .font(.headline)
                            .foregroundStyle(ClearHalalTheme.primaryText)

                        if let badge = plan.badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(ClearHalalTheme.deepForest)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(ClearHalalTheme.caution)
                                .clipShape(Capsule())
                        }
                    }

                    Text(plan.price)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(ClearHalalTheme.deepForest)

                    Text(plan.detail)
                        .font(.caption)
                        .foregroundStyle(ClearHalalTheme.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? ClearHalalTheme.deepForest : ClearHalalTheme.border)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(ClearHalalTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? ClearHalalTheme.deepForest : ClearHalalTheme.border, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

private struct PaywallBottomBar: View {
    let selectedPlan: PaywallPlan
    let isLoading: Bool
    let isRevenueCatConfigured: Bool
    let onPurchase: () -> Void
    let onRestore: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            PremiumActionButton(
                title: selectedPlan.ctaTitle,
                icon: isLoading ? nil : "checkmark.seal.fill",
                action: onPurchase
            )
            .disabled(isLoading)
            .opacity(isLoading ? 0.65 : 1)

            HStack(spacing: 18) {
                Button("Restore") {
                    onRestore()
                }

                Text("Terms")

                Text("Privacy")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(ClearHalalTheme.secondaryText)

            Text(selectedPlan.shortLegalCopy)
                .font(.caption2)
                .foregroundStyle(ClearHalalTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .background(ClearHalalTheme.background.opacity(0.94))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ClearHalalTheme.border)
                .frame(height: 1)
        }
    }
}

#Preview("Native Paywall") {
    HardPaywallView(onStartTrial: {}, onRestore: {})
        .environmentObject(SubscriptionStore())
}
