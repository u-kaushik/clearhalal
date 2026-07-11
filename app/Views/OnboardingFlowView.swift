import SwiftUI

struct OnboardingFlowView: View {
    let onComplete: () -> Void
    @State private var page = 0
    @State private var selectedUseCases: Set<String> = ["Groceries for family"]

    private let useCases = ["Snacks and sweets", "Groceries for family", "Restaurant menus", "E-numbers and additives", "Imported foods"]
    private let maxSelectedUseCases = 2

    var body: some View {
        ZStack {
            ClearHalalTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    ClearHalalWordmark(compact: true)
                    Spacer()
                    OnboardingProgressDots(currentPage: page, pageCount: 5)
                }
                .padding(.top, 28)
                .padding(.horizontal, 28)

                TabView(selection: $page) {
                    painScreen.tag(0)
                    mechanismScreen.tag(1)
                    sampleResultScreen.tag(2)
                    personalizationScreen.tag(3)
                    trustScreen.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Button {
                    if page < 4 {
                        withAnimation(.snappy) { page += 1 }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(page == 4 ? "See Plans" : "Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ClearHalalTheme.deepForest)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .padding(.horizontal, 28)

                Button("Skip") {
                    onComplete()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(ClearHalalTheme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
    }

    private var painScreen: some View {
        OnboardingPage(title: "Know what's\ninside.", subtitle: "Ingredients like gelatin, E471, enzymes, and flavourings can be unclear when the source is not shown.", isActive: page == 0) {
            LabelPreviewCard()
        }
    }

    private var mechanismScreen: some View {
        OnboardingPage(title: "Scan the label.\nSee the concern.", subtitle: "ClearHalal reads visible ingredients, flags uncertain sources, and explains what to check next.", isActive: page == 1) {
            VStack(spacing: 16) {
                FlowRow(number: "1", title: "Read label", color: ClearHalalTheme.pantryGreen)
                FlowRow(number: "2", title: "Flag sources", color: ClearHalalTheme.caution)
                FlowRow(number: "3", title: "Explain next step", color: ClearHalalTheme.deepForest)
            }
            .padding(28)
            .clearHalalCard()
        }
    }

    private var sampleResultScreen: some View {
        OnboardingPage(title: "Save what\nyou trust.", subtitle: "Keep products you check often, and revisit anything unclear when you shop again.", isActive: page == 2) {
            SavedProductsPreviewCard()
        }
    }

    private var personalizationScreen: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("What do you\nusually check?")
                .font(ClearHalalTheme.display(32, weight: .semibold))
                .foregroundStyle(ClearHalalTheme.primaryText)
                .fadeInWhenActive(page == 3, delay: 0.04)

            Text("Choose up to two. We will tailor examples and shortcuts around them.")
                .font(.body)
                .foregroundStyle(ClearHalalTheme.secondaryText)
                .fadeInWhenActive(page == 3, delay: 0.12)

            VStack(spacing: 12) {
                ForEach(Array(useCases.enumerated()), id: \.element) { index, useCase in
                    let isSelected = selectedUseCases.contains(useCase)

                    Button {
                        toggleUseCase(useCase)
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? ClearHalalTheme.deepForest : ClearHalalTheme.border.opacity(0.65))
                                    .frame(width: 24, height: 24)

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }

                            Text(useCase)
                                .font(.headline)
                                .foregroundStyle(isSelected ? ClearHalalTheme.deepForest : ClearHalalTheme.primaryText)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 17)
                        .background(isSelected ? ClearHalalTheme.positiveSoft : ClearHalalTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(isSelected ? ClearHalalTheme.deepForest : ClearHalalTheme.border, lineWidth: isSelected ? 2 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .fadeInWhenActive(page == 3, delay: 0.18 + Double(index) * 0.05)
                }
            }

            Text("\(selectedUseCases.count) of \(maxSelectedUseCases) selected")
                .font(.caption.weight(.medium))
                .foregroundStyle(ClearHalalTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .center)
                .fadeInWhenActive(page == 3, delay: 0.46)

            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
    }

    private func toggleUseCase(_ useCase: String) {
        if selectedUseCases.contains(useCase) {
            if selectedUseCases.count > 1 {
                selectedUseCases.remove(useCase)
            }
            return
        }

        if selectedUseCases.count < maxSelectedUseCases {
            selectedUseCases.insert(useCase)
        }
    }

    private var trustScreen: some View {
        OnboardingPage(title: "Ready for\nevery shop.", subtitle: "Unlimited scans, saved checks, and clearer explanations when ingredients need context.", isActive: page == 4) {
            ShoppingTripPreviewCard()
        }
    }
}

private struct OnboardingProgressDots: View {
    let currentPage: Int
    let pageCount: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? ClearHalalTheme.deepForest : ClearHalalTheme.border)
                    .frame(width: index == currentPage ? 24 : 7, height: 7)
                    .animation(.snappy(duration: 0.22), value: currentPage)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding step \(currentPage + 1) of \(pageCount)")
    }
}

private struct OnboardingPage<Content: View>: View {
    let title: String
    let subtitle: String
    let isActive: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .font(ClearHalalTheme.display(34, weight: .semibold))
                .foregroundStyle(ClearHalalTheme.primaryText)
                .padding(.top, 24)
                .fadeInWhenActive(isActive, delay: 0.04)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(ClearHalalTheme.secondaryText)
                .lineSpacing(4)
                .fadeInWhenActive(isActive, delay: 0.12)

            Spacer(minLength: 12)
            content
                .fadeInWhenActive(isActive, delay: 0.22)
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}

private struct LabelPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Ingredients: Sugar, glucose syrup, gelatin, citric acid, natural flavourings, E471.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(ClearHalalTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .overlay(ClearHalalTheme.border)

                HStack(spacing: 8) {
                    IngredientFlag(title: "Gelatin")
                    IngredientFlag(title: "E471")
                }
            }
            .padding(18)
            .background(ClearHalalTheme.soft)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .clearHalalCard()
    }
}

private struct IngredientFlag: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(ClearHalalTheme.caution)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ClearHalalTheme.cautionSoft)
            .clipShape(Capsule())
    }
}

private struct SavedProductsPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SavedProductRow(
                icon: "checkmark.seal.fill",
                title: "KitKat Chunky",
                subtitle: "Likely Halal",
                color: ClearHalalTheme.positive,
                background: ClearHalalTheme.positiveSoft
            )

            SavedProductRow(
                icon: "exclamationmark.triangle.fill",
                title: "E471 additive",
                subtitle: "Review source later",
                color: ClearHalalTheme.caution,
                background: ClearHalalTheme.cautionSoft
            )

            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ClearHalalTheme.deepForest)
                Text("Saved checks stay in your history.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(ClearHalalTheme.primaryText)
            }
            .padding(.top, 4)
        }
        .padding(18)
        .clearHalalCard()
    }
}

private struct SavedProductRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let background: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(background)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(ClearHalalTheme.primaryText)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }

            Spacer()

            Image(systemName: "bookmark.fill")
                .font(.subheadline)
                .foregroundStyle(ClearHalalTheme.deepForest)
        }
        .padding(14)
        .background(ClearHalalTheme.soft.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct ShoppingTripPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today’s shop")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ClearHalalTheme.secondaryText)
                    Text("Quick summary")
                        .font(.headline)
                        .foregroundStyle(ClearHalalTheme.primaryText)
                }

                Spacer()

                Image(systemName: "basket.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(ClearHalalTheme.deepForest)
                    .frame(width: 38, height: 38)
                    .background(ClearHalalTheme.positiveSoft)
                    .clipShape(Circle())
            }

            VStack(spacing: 10) {
                TripMetricRow(value: "3", label: "labels checked", color: ClearHalalTheme.deepForest)
                TripMetricRow(value: "2", label: "trusted products saved", color: ClearHalalTheme.positive)
                TripMetricRow(value: "1", label: "ingredient to verify", color: ClearHalalTheme.caution)
            }

            Text("Decision support, not certification.")
                .font(.caption2)
                .foregroundStyle(ClearHalalTheme.secondaryText)
                .lineSpacing(2)
                .padding(.top, 2)
        }
        .padding(18)
        .clearHalalCard()
    }
}

private struct TripMetricRow: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ClearHalalTheme.primaryText)

            Spacer()
        }
        .padding(12)
        .background(ClearHalalTheme.soft.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private struct FlowRow: View {
    let number: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Text(number)
                .font(.headline)
                .frame(width: 42, height: 42)
                .background(color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(title)
                .font(.headline)
                .foregroundStyle(ClearHalalTheme.primaryText)
            Spacer()
        }
    }
}
