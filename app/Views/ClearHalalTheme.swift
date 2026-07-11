import SwiftUI

enum ClearHalalTheme {
    static let background = Color(hex: 0xF9F7F2)
    static let surface = Color.white
    static let primaryText = Color(hex: 0x183024)
    static let secondaryText = Color(hex: 0x6B705C)
    static let deepForest = Color(hex: 0x1B3022)
    static let pantryGreen = Color(hex: 0x31564A)
    static let fig = Color(hex: 0x6F4E7C)
    static let positive = Color(hex: 0x2F8F67)
    static let caution = Color(hex: 0xD97706)
    static let concern = Color(hex: 0xB94A3E)
    static let border = Color(hex: 0xE4DDD1)
    static let soft = Color(hex: 0xF2EDE3)
    static let cautionSoft = Color(hex: 0xF7E5BD)
    static let positiveSoft = Color(hex: 0xE4F1EA)
    static let concernSoft = Color(hex: 0xF4DDD9)

    static let displayFont = Font.custom("New York", size: 34, relativeTo: .largeTitle)
    static let tabBarScrollClearance: CGFloat = 132

    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("New York", size: size, relativeTo: .largeTitle).weight(weight)
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: opacity
        )
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ClearHalalTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ClearHalalTheme.border)
            }
    }
}

extension View {
    func clearHalalCard() -> some View {
        modifier(CardModifier())
    }

    func fadeInOnAppear(delay: Double = 0) -> some View {
        modifier(FadeInOnAppearModifier(delay: delay))
    }

    func fadeInWhenActive(_ isActive: Bool, delay: Double = 0) -> some View {
        modifier(FadeInWhenActiveModifier(isActive: isActive, delay: delay))
    }
}

private struct FadeInOnAppearModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.96)
            .offset(y: isVisible ? 0 : 18)
            .onAppear {
                withAnimation(.easeOut(duration: 0.62).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

private struct FadeInWhenActiveModifier: ViewModifier {
    let isActive: Bool
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.96)
            .offset(y: isVisible ? 0 : 18)
            .onAppear {
                updateVisibility(animated: false)
            }
            .onChange(of: isActive) { _, _ in
                updateVisibility(animated: true)
            }
    }

    private func updateVisibility(animated: Bool) {
        guard isActive else {
            isVisible = false
            return
        }

        if animated {
            withAnimation(.easeOut(duration: 0.62).delay(delay)) {
                isVisible = true
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                isVisible = true
            }
        }
    }
}

struct ClearHalalBrandMark: View {
    var size: CGFloat = 28
    var color: Color = ClearHalalTheme.deepForest

    var body: some View {
        Image("ClearHalalMark")
            .resizable()
            .renderingMode(.template)
            .foregroundStyle(color)
            .scaledToFit()
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct ClearHalalWordmark: View {
    var compact = false
    var color: Color = ClearHalalTheme.deepForest

    var body: some View {
        HStack(spacing: compact ? 4 : 7) {
            ClearHalalBrandMark(size: compact ? 29 : 34, color: color)
            Text("ClearHalal")
                .font(ClearHalalTheme.display(compact ? 20 : 24, weight: .semibold))
                .foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("ClearHalal")
    }
}

struct ClearHalalBrandHeader: View {
    var title: String?
    var trailingIcon: String?

    var body: some View {
        HStack {
            if let title {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(ClearHalalTheme.primaryText)
            } else {
                ClearHalalWordmark(compact: true)
            }
            Spacer()
            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.headline)
                    .foregroundStyle(ClearHalalTheme.deepForest)
                    .frame(width: 36, height: 36)
                    .background(ClearHalalTheme.surface)
                    .clipShape(Circle())
                    .overlay {
                        Circle().stroke(ClearHalalTheme.border)
                    }
            }
        }
    }
}

struct PremiumActionButton: View {
    let title: String
    var icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ClearHalalTheme.deepForest)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

struct VerdictChip: View {
    let title: String
    let verdict: Verdict

    var body: some View {
        Label(title, systemImage: verdict.iconName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(verdict.softColor)
            .foregroundStyle(verdict.color)
            .clipShape(Capsule())
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(ClearHalalTheme.primaryText)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(ClearHalalTheme.secondaryText)
            }
        }
    }
}

struct ScanBeam: View {
    var body: some View {
        LinearGradient(
            colors: [.clear, ClearHalalTheme.positive.opacity(0.18), ClearHalalTheme.positive, ClearHalalTheme.positive.opacity(0.18), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 4)
        .shadow(color: ClearHalalTheme.positive.opacity(0.45), radius: 10, y: 0)
        .accessibilityHidden(true)
    }
}
