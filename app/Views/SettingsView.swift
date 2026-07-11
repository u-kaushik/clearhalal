import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var subscription: SubscriptionStore
    @EnvironmentObject private var store: ScanHistoryStore
    @AppStorage("clearhalal.firstName") private var firstName = ""
    private let config = ScannerCoachAppConfig.clearHalal

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ClearHalalBrandHeader(title: "Settings")

                    Text("App settings")
                        .font(ClearHalalTheme.display(36, weight: .semibold))
                        .foregroundStyle(ClearHalalTheme.primaryText)

                    SettingsRow(
                        icon: "creditcard",
                        title: "Subscription",
                        detail: subscription.isPremium ? "Premium member" : "Premium required",
                        destination: AnyView(PremiumMembershipView(isPremium: subscription.isPremium, progress: store.progress))
                    )

                    SettingsRow(
                        icon: "slider.horizontal.3",
                        title: "Shopping preferences",
                        detail: firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Tune examples and guidance" : "Tuned for \(firstName)",
                        destination: AnyView(ShoppingPreferencesView())
                    )

                    SettingsRow(
                        icon: "doc.text.magnifyingglass",
                        title: "Legal & privacy",
                        detail: "Terms, privacy, and disclaimer",
                        destination: AnyView(SettingsDetailView(
                            title: "Legal & privacy",
                            icon: "doc.text.magnifyingglass",
                            rows: [
                                SettingsDetailRow(
                                    label: "Terms",
                                    value: "Use ClearHalal as decision support",
                                    body: "ClearHalal helps interpret visible ingredient information so you can make more informed shopping decisions. Results depend on the label text available to the app.",
                                    linkTitle: "Read full terms",
                                    linkURL: URL(string: "https://halal.glenmontcircle.com/terms")
                                ),
                                SettingsDetailRow(
                                    label: "Privacy",
                                    value: "Photos are processed only when you choose them",
                                    body: "Camera and photo access are used for label scanning. ClearHalal does not scan your library in the background, and saved checks are stored on this device in this build.",
                                    linkTitle: "Read full privacy policy",
                                    linkURL: URL(string: "https://halal.glenmontcircle.com/privacy")
                                ),
                                SettingsDetailRow(
                                    label: "Disclaimer",
                                    value: "Not certification or a religious ruling",
                                    body: "ClearHalal is not a halal certification body or religious authority. When a product matters or the source is unclear, check a trusted certification mark or contact the manufacturer."
                                )
                            ]
                        ))
                    )

                    SettingsRow(
                        icon: "envelope",
                        title: "Support",
                        detail: "support@glenmontcircle.com",
                        destination: AnyView(SettingsDetailView(
                            title: "Support",
                            icon: "envelope",
                            rows: [
                                SettingsDetailRow(
                                    label: "Email",
                                    value: "support@glenmontcircle.com",
                                    body: "Reach us here if something looks wrong, a purchase does not restore, or an ingredient explanation needs review."
                                ),
                                SettingsDetailRow(
                                    label: "Best for",
                                    value: "Billing, scan issues, and product feedback",
                                    body: "The most useful reports are specific: what product you scanned, what result you expected, and what ClearHalal showed."
                                ),
                                SettingsDetailRow(
                                    label: "Include",
                                    value: "A screenshot and product label when helpful",
                                    body: "Screenshots help us understand layout issues and improve ingredient guidance without guessing."
                                )
                            ]
                        ))
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        ClearHalalWordmark(compact: true)
                            .padding(.bottom, 2)
                        Text("Careful by design")
                            .font(.headline)
                        Text(config.trustDisclaimer)
                            .font(.body)
                            .foregroundStyle(ClearHalalTheme.secondaryText)
                            .lineSpacing(3)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .clearHalalCard()
                    .padding(.top, 28)
                }
                .padding(24)
                .padding(.bottom, ClearHalalTheme.tabBarScrollClearance)
            }
            .background(ClearHalalTheme.background.ignoresSafeArea())
        }
        .background(ClearHalalTheme.background.ignoresSafeArea())
    }
}

private struct ShoppingPreferencesView: View {
    @AppStorage("clearhalal.firstName") private var firstName = ""
    @AppStorage("clearhalal.shoppingFocus") private var shoppingFocus = "Groceries for family"
    @AppStorage("clearhalal.guidanceStyle") private var guidanceStyle = "Balanced"
    @Environment(\.dismiss) private var dismiss

    private let focusOptions = ["Groceries for family", "Snacks and sweets", "Restaurant menus", "E-numbers and additives", "Imported foods"]
    private let guidanceOptions = ["Balanced", "More cautious", "Explain more"]

    private var selectedFocuses: Set<String> {
        get {
            let values = shoppingFocus
                .split(separator: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return Set(values.isEmpty ? ["Groceries for family"] : values)
        }
        nonmutating set {
            shoppingFocus = newValue.sorted { lhs, rhs in
                (focusOptions.firstIndex(of: lhs) ?? 0) < (focusOptions.firstIndex(of: rhs) ?? 0)
            }
            .joined(separator: "|")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    SettingsIcon(name: "slider.horizontal.3")
                    Text("Shopping preferences")
                        .font(ClearHalalTheme.display(36, weight: .semibold))
                        .foregroundStyle(ClearHalalTheme.primaryText)
                    Text("Optional details that help ClearHalal tune examples, shortcuts, and future AI explanations around how you actually shop.")
                        .font(.subheadline)
                        .foregroundStyle(ClearHalalTheme.secondaryText)
                        .lineSpacing(2)
                }

                VStack(alignment: .leading, spacing: 18) {
                    PreferenceTextField(title: "How would you like to be greeted?", placeholder: "Optional first name", text: $firstName)

                    MultiPreferencePicker(
                        title: "What do you check most?",
                        subtitle: "Choose up to two.",
                        selections: Binding(
                            get: { selectedFocuses },
                            set: { selectedFocuses = $0 }
                        ),
                        options: focusOptions,
                        maxSelections: 2
                    )

                    PreferencePicker(title: "Guidance style", selection: $guidanceStyle, options: guidanceOptions)

                    Text("These settings stay on this device. They do not create an account or change your Apple subscription.")
                        .font(.caption)
                        .foregroundStyle(ClearHalalTheme.secondaryText)
                        .lineSpacing(2)

                    HStack(spacing: 10) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Save")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(ClearHalalTheme.deepForest)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }

                        Button {
                            firstName = ""
                            shoppingFocus = "Groceries for family"
                            guidanceStyle = "Balanced"
                        } label: {
                            Text("Restore defaults")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(ClearHalalTheme.soft)
                                .foregroundStyle(ClearHalalTheme.primaryText)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(18)
                .clearHalalCard()
            }
            .padding(24)
        }
        .background(ClearHalalTheme.background.ignoresSafeArea())
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PreferenceTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ClearHalalTheme.secondaryText)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .font(.headline)
                .foregroundStyle(ClearHalalTheme.primaryText)
                .tint(ClearHalalTheme.deepForest)
                .padding(16)
                .background(ClearHalalTheme.soft)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct PreferencePicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ClearHalalTheme.secondaryText)

            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    PreferenceChip(title: option, isSelected: selection == option) {
                        selection = option
                    }
                }
            }
        }
    }
}

private struct MultiPreferencePicker: View {
    let title: String
    let subtitle: String
    @Binding var selections: Set<String>
    let options: [String]
    let maxSelections: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ClearHalalTheme.secondaryText)
                Spacer()
                Text("\(selections.count) of \(maxSelections)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(ClearHalalTheme.secondaryText)
            }

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(ClearHalalTheme.secondaryText)

            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    PreferenceChip(title: option, isSelected: selections.contains(option)) {
                        toggle(option)
                    }
                }
            }
        }
    }

    private func toggle(_ option: String) {
        if selections.contains(option) {
            if selections.count > 1 {
                selections.remove(option)
            }
            return
        }

        guard selections.count < maxSelections else { return }
        selections.insert(option)
    }
}

private struct PreferenceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.caption.weight(.bold))
                    .frame(width: 14)
                Text(title)
                    .lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? .white : ClearHalalTheme.primaryText)
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(isSelected ? ClearHalalTheme.deepForest : ClearHalalTheme.soft)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 320
        let rows = rows(for: subviews, maxWidth: maxWidth)
        return CGSize(width: maxWidth, height: rows.reduce(CGFloat.zero) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(for: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                item.subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [FlowRow] {
        var rows: [FlowRow] = []
        var current: [FlowItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let nextWidth = current.isEmpty ? size.width : currentWidth + spacing + size.width
            if nextWidth > maxWidth, !current.isEmpty {
                rows.append(FlowRow(items: current, height: currentHeight))
                current = [FlowItem(subview: subview, size: size)]
                currentWidth = size.width
                currentHeight = size.height
            } else {
                current.append(FlowItem(subview: subview, size: size))
                currentWidth = nextWidth
                currentHeight = max(currentHeight, size.height)
            }
        }

        if !current.isEmpty {
            rows.append(FlowRow(items: current, height: currentHeight))
        }

        return rows
    }
}

private struct FlowItem {
    let subview: LayoutSubviews.Element
    let size: CGSize
}

private struct FlowRow {
    let items: [FlowItem]
    let height: CGFloat
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let detail: String
    let destination: AnyView

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 14) {
                SettingsIcon(name: icon)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.headline)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(ClearHalalTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClearHalalTheme.secondaryText)
            }
            .foregroundStyle(ClearHalalTheme.primaryText)
            .padding(18)
            .clearHalalCard()
        }
        .buttonStyle(.plain)
    }
}

private struct PremiumMembershipView: View {
    let isPremium: Bool
    let progress: ScannerCoachProgress

    var body: some View {
        ScrollView {
            PremiumMemberCard(isPremium: isPremium, progress: progress)
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, ClearHalalTheme.tabBarScrollClearance)
        }
        .background(ClearHalalTheme.background.ignoresSafeArea())
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PremiumMemberCard: View {
    let isPremium: Bool
    let progress: ScannerCoachProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ClearHalalWordmark(compact: true, color: .white)
                Spacer()
                Text("PREMIUM")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ClearHalalTheme.deepForest)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.9))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(isPremium ? "Clearer choices are active." : "Unlock clearer choices.")
                    .font(ClearHalalTheme.display(30, weight: .semibold))
                    .foregroundStyle(.white)
                Text(isPremium ? "Unlimited scans, saved products, and clearer source guidance." : "Unlock unlimited checks, saved products, and deeper ingredient guidance.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineSpacing(2)
            }

            VStack(spacing: 6) {
                PremiumBenefitRow(icon: "viewfinder", label: "Unlimited label scans")
                PremiumBenefitRow(icon: "bookmark", label: "Saved trusted products")
                PremiumBenefitRow(icon: "text.magnifyingglass", label: "Clear ingredient context")
                PremiumBenefitRow(icon: "clock.arrow.circlepath", label: "Full scan history")
                PremiumBenefitRow(icon: "checkmark.shield", label: "Careful source guidance")
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Your record")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.76))
                    Spacer()
                    Text("Active")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ClearHalalTheme.deepForest)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.9))
                        .clipShape(Capsule())
                }

                HStack(spacing: 8) {
                    PremiumStat(value: "\(progress.totalChecks)", label: "checked")
                    PremiumStat(value: "\(progress.trustedSaves)", label: "saved")
                    PremiumStat(value: "\(progress.cautiousAvoids)", label: "avoided")
                }
            }
            .padding(12)
            .background(.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [ClearHalalTheme.deepForest, ClearHalalTheme.pantryGreen],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: ClearHalalTheme.deepForest.opacity(0.18), radius: 18, y: 10)
    }
}

private struct PremiumBenefitRow: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .frame(width: 24, height: 24)
                .background(.white.opacity(0.16))
                .clipShape(Circle())
            Text(label)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.88)
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct PremiumStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsIcon: View {
    let name: String

    var body: some View {
        Image(systemName: name)
            .font(.headline)
            .foregroundStyle(ClearHalalTheme.deepForest)
            .frame(width: 36, height: 36)
            .background(ClearHalalTheme.soft)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct SettingsDetailRow: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let body: String
    var linkTitle: String?
    var linkURL: URL?
}

private struct SettingsDetailView: View {
    let title: String
    let icon: String
    let rows: [SettingsDetailRow]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    SettingsIcon(name: icon)
                    Text(title)
                        .font(ClearHalalTheme.display(36, weight: .semibold))
                        .foregroundStyle(ClearHalalTheme.primaryText)
                }

                VStack(spacing: 0) {
                    ForEach(rows) { row in
                        SettingsDetailTextBlock(label: row.label, value: row.value, copy: row.body, linkTitle: row.linkTitle, linkURL: row.linkURL)
                        .padding(.vertical, 16)

                        if row.id != rows.last?.id {
                            Divider()
                                .background(ClearHalalTheme.border)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .clearHalalCard()
            }
            .padding(24)
        }
        .background(ClearHalalTheme.background.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SettingsDetailTextBlock: View {
    let label: String
    let value: String
    let copy: String
    var linkTitle: String?
    var linkURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ClearHalalTheme.secondaryText)
            Text(value)
                .font(.body.weight(.medium))
                .foregroundStyle(ClearHalalTheme.primaryText)
            Text(copy)
                .font(.subheadline)
                .foregroundStyle(ClearHalalTheme.secondaryText)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            if let linkTitle, let linkURL {
                Link(linkTitle, destination: linkURL)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ClearHalalTheme.deepForest)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
