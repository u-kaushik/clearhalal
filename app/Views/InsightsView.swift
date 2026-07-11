import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var store: ScanHistoryStore
    @State private var selectedAchievement: ScannerCoachAchievement?
    @State private var showsClarifiedIngredients = false

    private let awardColumns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ClearHalalBrandHeader(title: "Progress")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Learn as you shop")
                        .font(ClearHalalTheme.display(36, weight: .semibold))
                        .foregroundStyle(ClearHalalTheme.primaryText)
                    Text("Private milestones from the labels and choices you clarify.")
                        .foregroundStyle(ClearHalalTheme.secondaryText)
                }

                Button {
                    showsClarifiedIngredients = true
                } label: {
                    ClarifiedIngredientsCard(
                        count: store.learnedIngredientItems.count,
                        hasItems: !store.learnedIngredientItems.isEmpty
                    )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "Awards", subtitle: "Private milestones from the labels and choices you have clarified.")
                    LazyVGrid(columns: awardColumns, spacing: 14) {
                        ForEach(store.achievements) { achievement in
                            Button {
                                selectedAchievement = achievement
                            } label: {
                                AwardCard(achievement: achievement)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(24)
            .padding(.bottom, ClearHalalTheme.tabBarScrollClearance)
        }
        .background(ClearHalalTheme.background)
        .fullScreenCover(item: $selectedAchievement) { achievement in
            AwardDetailView(achievement: achievement)
        }
        .sheet(isPresented: $showsClarifiedIngredients) {
            ClarifiedIngredientsDetailView(ingredients: store.learnedIngredientItems)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct ClarifiedIngredientsCard: View {
    let count: Int
    let hasItems: Bool

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Learning record")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: 0xD7E3DE))
                Text("\(count) ingredients clarified")
                    .font(ClearHalalTheme.display(28, weight: .semibold))
                    .foregroundStyle(.white)
                Text(hasItems ? "Review the ingredients ClearHalal has helped you understand." : "Start checking labels to build your ingredient record.")
                    .font(.subheadline)
                    .foregroundStyle(Color(hex: 0xEAF2EE))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.82))
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.12))
                .clipShape(Circle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(ClearHalalTheme.deepForest)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ClarifiedIngredientsDetailView: View {
    let ingredients: [EvidenceItem]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients clarified")
                            .font(ClearHalalTheme.display(32, weight: .semibold))
                            .foregroundStyle(ClearHalalTheme.primaryText)
                        Text("A simple record of ingredient names you have scanned or reviewed.")
                            .foregroundStyle(ClearHalalTheme.secondaryText)
                    }

                    if ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nothing here yet")
                                .font(.headline)
                                .foregroundStyle(ClearHalalTheme.primaryText)
                            Text("Scan or type a label to start building your ingredient record.")
                                .foregroundStyle(ClearHalalTheme.secondaryText)
                        }
                        .padding(18)
                        .clearHalalCard()
                    } else {
                        ForEach(ingredients) { ingredient in
                            NavigationLink(value: ingredient) {
                                HStack(spacing: 12) {
                                    Image(systemName: ingredient.verdict.iconName)
                                        .foregroundStyle(ingredient.verdict.color)
                                        .frame(width: 28, height: 28)
                                        .background(ingredient.verdict.softColor)
                                        .clipShape(Circle())
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(ingredient.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(ClearHalalTheme.primaryText)
                                        Text(ingredient.status)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(ingredient.verdict.color)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(ClearHalalTheme.secondaryText)
                                }
                                .padding(16)
                                .clearHalalCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(24)
            }
            .background(ClearHalalTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(ClearHalalTheme.deepForest)
                }
            }
            .navigationDestination(for: EvidenceItem.self) { item in
                IngredientDetailView(item: item)
            }
        }
    }
}

private struct AwardCard: View {
    let achievement: ScannerCoachAchievement
    @State private var hasPlayedUnlockPulse = false

    var body: some View {
        VStack(spacing: 10) {
            AwardMedal(achievement: achievement, size: 86)
                .padding(.top, 8)
                .scaleEffect(achievement.isUnlocked ? (hasPlayedUnlockPulse ? 1 : 0.94) : 1)
                .overlay {
                    if achievement.isUnlocked {
                        Circle()
                            .stroke(achievement.tint.opacity(hasPlayedUnlockPulse ? 0 : 0.32), lineWidth: 2)
                            .scaleEffect(hasPlayedUnlockPulse ? 1.28 : 0.88)
                    }
                }
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ClearHalalTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(achievement.statusText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(achievement.tierTextColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(achievement.tierFillColor)
                    .clipShape(Capsule())
            }
            ProgressView(value: achievement.progress)
                .tint(achievement.tint)
                .scaleEffect(y: 0.7)
                .opacity(0.78)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(ClearHalalTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(ClearHalalTheme.border)
        }
        .onAppear {
            guard achievement.isUnlocked, !hasPlayedUnlockPulse else { return }
            withAnimation(.spring(response: 0.52, dampingFraction: 0.72).delay(0.12)) {
                hasPlayedUnlockPulse = true
            }
        }
    }
}

struct AwardDetailView: View {
    let achievement: ScannerCoachAchievement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ClearHalalTheme.deepForest, achievement.tint.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(.white.opacity(0.14))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Award")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.86))
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)

                Spacer(minLength: 24)

                AwardMedal(achievement: achievement, size: 190)
                    .shadow(color: .black.opacity(0.24), radius: 24, y: 14)
                    .padding(.bottom, 26)

                VStack(spacing: 10) {
                    Text(achievement.title)
                        .font(ClearHalalTheme.display(36, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                    Text(achievement.isUnlocked ? achievement.levelName : "In progress")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(achievement.tierTextColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(achievement.tierFillColor)
                        .clipShape(Capsule())
                    Text(achievement.longDetail)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.top, 6)
                    Text(achievement.isUnlocked ? achievement.nextLevelDetail : "\(achievement.progressValue) of \(achievement.targetValue) completed")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 32)

                Spacer(minLength: 32)
            }
        }
    }
}

private struct AwardMedal: View {
    let achievement: ScannerCoachAchievement
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0xFBE7A8),
                            Color(hex: 0xD0A94F),
                            Color(hex: 0x8F5F18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Circle()
                .fill(
                    LinearGradient(
                        colors: medalColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(size * 0.075)
            Circle()
                .stroke(Color(hex: 0xFBE7A8), lineWidth: size * 0.055)
            Circle()
                .stroke(.black.opacity(0.18), lineWidth: 1)
                .padding(size * 0.08)
            ScallopedSealShape(waves: 10, amplitude: 0.045)
                .stroke(.white.opacity(0.16), lineWidth: size * 0.022)
                .frame(width: size * 0.48, height: size * 0.48)
            Image(systemName: achievement.icon)
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundStyle(achievement.isUnlocked ? .white : .white.opacity(0.54))
                .shadow(color: .black.opacity(0.16), radius: 4, y: 2)
            if !achievement.isUnlocked {
                Circle()
                    .fill(.black.opacity(0.34))
                    .padding(size * 0.075)
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
    }

    private var medalColors: [Color] {
        guard achievement.isUnlocked else {
            return [
                Color(hex: 0xF7D98A),
                achievement.tint.opacity(0.72),
                Color(hex: 0xA87520)
            ]
        }

        switch achievement.level {
        case 3:
            return [Color(hex: 0xFFE8A3), achievement.tint.opacity(0.82), Color(hex: 0x8F5F18)]
        case 2:
            return [Color(hex: 0xF2EFE6), achievement.tint.opacity(0.72), Color(hex: 0x8F8A7A)]
        default:
            return [Color(hex: 0xF8D293), achievement.tint.opacity(0.72), Color(hex: 0x9B5F26)]
        }
    }
}

private extension ScannerCoachAchievement {
    var tierFillColor: Color {
        guard isUnlocked else { return ClearHalalTheme.soft }
        switch level {
        case 3:
            return Color(hex: 0xF7D98A)
        case 2:
            return Color(hex: 0xE9ECE7)
        default:
            return Color(hex: 0xF6D3A3)
        }
    }

    var tierTextColor: Color {
        guard isUnlocked else { return ClearHalalTheme.secondaryText }
        switch level {
        case 3:
            return Color(hex: 0x4F3510)
        case 2:
            return Color(hex: 0x3D4642)
        default:
            return Color(hex: 0x704015)
        }
    }
}

private struct ScallopedSealShape: Shape {
    let waves: Int
    let amplitude: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let baseRadius = min(rect.width, rect.height) / 2
        let steps = max(waves * 28, 120)
        var path = Path()

        for index in 0...steps {
            let angle = CGFloat(index) / CGFloat(steps) * .pi * 2
            let wave = sin(angle * CGFloat(waves))
            let radius = baseRadius * (1 + amplitude * wave)
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}
