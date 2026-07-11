import SwiftUI

struct ResultView: View {
    @EnvironmentObject private var store: ScanHistoryStore
    let result: ScanResult
    @State private var showsCheckedLabel = false

    private var currentResult: ScanResult {
        store.history.first(where: { $0.id == result.id }) ?? store.latestResult.flatMap { $0.id == result.id ? $0 : nil } ?? result
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Button {
                    showsCheckedLabel = true
                } label: {
                    CheckedLabelCard(result: currentResult)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 18) {
                    Text("Scanned just now")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ClearHalalTheme.secondaryText)

                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: currentResult.verdict.iconName)
                            .font(.title2)
                            .foregroundStyle(currentResult.verdict.color)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(currentResult.verdict.rawValue)
                                .font(ClearHalalTheme.display(34, weight: .semibold))
                                .foregroundStyle(ClearHalalTheme.primaryText)
                            Text(currentResult.summary)
                                .font(.subheadline)
                                .foregroundStyle(ClearHalalTheme.secondaryText)
                                .lineSpacing(3)
                        }
                    }

                    HStack {
                        VerdictChip(title: currentResult.confidence.rawValue, verdict: currentResult.verdict)
                        Text("\(currentResult.evidence.count) checks")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(ClearHalalTheme.soft)
                            .foregroundStyle(ClearHalalTheme.secondaryText)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(22)
                .clearHalalCard()

                VStack(alignment: .leading, spacing: 14) {
                    SectionHeader(title: "What we found", subtitle: "Visible ingredients and source concerns")
                    ForEach(currentResult.evidence) { item in
                        NavigationLink(value: item) {
                            EvidenceRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "What to do next")
                    Text(currentResult.nextStep)
                        .font(.body)
                        .foregroundStyle(ClearHalalTheme.secondaryText)
                        .lineSpacing(3)
                }
                .padding(18)
                .background(ClearHalalTheme.cautionSoft.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    store.save(currentResult)
                } label: {
                    Label(currentResult.isSaved ? "Saved" : "Save result", systemImage: currentResult.isSaved ? "bookmark.fill" : "bookmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(currentResult.isSaved ? ClearHalalTheme.pantryGreen : ClearHalalTheme.deepForest)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .disabled(currentResult.isSaved)
            }
            .padding(24)
            .padding(.bottom, ClearHalalTheme.tabBarScrollClearance)
        }
        .background(ClearHalalTheme.background.ignoresSafeArea())
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: EvidenceItem.self) { item in
            IngredientDetailView(item: item)
        }
        .sheet(isPresented: $showsCheckedLabel) {
            CheckedLabelDetailView(result: currentResult)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .environmentObject(store)
        }
    }
}

struct EvidenceRow: View {
    let item: EvidenceItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.verdict.iconName)
                .font(.headline)
                .foregroundStyle(item.verdict.color)
                .frame(width: 34, height: 34)
                .background(item.verdict.softColor)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ClearHalalTheme.primaryText)
                Text(item.status)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(item.verdict.color)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(ClearHalalTheme.secondaryText)
        }
        .padding(16)
        .clearHalalCard()
    }
}

struct IngredientDetailView: View {
    let item: EvidenceItem

    var body: some View {
        ZStack {
            ClearHalalTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(item.title)
                            .font(ClearHalalTheme.display(38, weight: .semibold))
                            .foregroundStyle(ClearHalalTheme.primaryText)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                        VerdictChip(title: item.status, verdict: item.verdict)
                    }

                    VStack(alignment: .leading, spacing: 24) {
                        DetailSection(title: "What it is", copy: item.detail)
                        DetailSection(title: detailReasonTitle, copy: detailReasonCopy)
                        DetailSection(title: "What to do next", copy: detailNextStep)
                    }
                    .padding(20)
                    .clearHalalCard()
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, ClearHalalTheme.tabBarScrollClearance)
            }
        }
        .navigationTitle("Ingredient detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ClearHalalTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var detailReasonTitle: String {
        switch item.verdict {
        case .haramConcern:
            return "Why this matters"
        case .sourceVaries:
            return "Why this is uncertain"
        case .likelyHalal:
            return "What this means"
        case .unableToVerify:
            return "Why we cannot decide"
        }
    }

    private var detailReasonCopy: String {
        switch item.verdict {
        case .haramConcern:
            return "This is not a minor ambiguity. When a label shows a clear pork, alcohol, or other avoided ingredient, the safest reading is to avoid it."
        case .sourceVaries:
            return "Some ingredients can be plant-derived, animal-derived, synthetic, or process-dependent. If the source is not shown, the label alone does not settle it."
        case .likelyHalal:
            return "ClearHalal did not find common flagged terms in the visible text. This is useful, but it only reflects what was visible in the scan."
        case .unableToVerify:
            return "The scan did not provide enough clear ingredient information to support a useful recommendation."
        }
    }

    private var detailNextStep: String {
        switch item.verdict {
        case .haramConcern:
            return "Avoid this product unless the scan has misread the label or a trusted halal authority gives a clear reason it is acceptable."
        case .sourceVaries:
            return "Do not assume it is halal. Pick a certified option, look for a clear plant or halal source, or ask the manufacturer."
        case .likelyHalal:
            return "If this is a routine purchase, you can save it. If it matters for family or guests, still prefer products with clear certification."
        case .unableToVerify:
            return "Try a clearer photo, type the ingredient list, or ask for the full ingredients before deciding."
        }
    }
}

private struct CheckedLabelCard: View {
    let result: ScanResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.headline)
                    .foregroundStyle(ClearHalalTheme.deepForest)
                    .frame(width: 34, height: 34)
                    .background(ClearHalalTheme.soft)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text("Checked label")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ClearHalalTheme.secondaryText)
                    Text(result.displayTitle)
                        .font(.headline)
                        .foregroundStyle(ClearHalalTheme.primaryText)
                }
            }

            Text(result.labelPreview)
                .font(.caption)
                .foregroundStyle(ClearHalalTheme.secondaryText)
                .lineLimit(3)
                .lineSpacing(2)

            HStack(spacing: 6) {
                Text("View label text")
                Image(systemName: "chevron.up.forward")
                    .font(.caption2.weight(.bold))
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(ClearHalalTheme.deepForest)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .clearHalalCard()
    }
}

private struct CheckedLabelDetailView: View {
    let result: ScanResult
    @EnvironmentObject private var store: ScanHistoryStore
    @Environment(\.dismiss) private var dismiss
    @State private var draftDisplayName = ""

    private var ingredients: [String] {
        result.input
            .replacingOccurrences(of: "\n", with: ",")
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { $0.count > 1 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(result.displayTitle)
                            .font(ClearHalalTheme.display(32, weight: .semibold))
                            .foregroundStyle(ClearHalalTheme.primaryText)
                        Text("Full text captured from the label. Use this to check what ClearHalal read before deciding.")
                            .font(.subheadline)
                            .foregroundStyle(ClearHalalTheme.secondaryText)
                            .lineSpacing(2)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Display name", subtitle: "This changes the label in history, not the scan text.")

                        TextField("Example: Heinz baked beans", text: $draftDisplayName)
                            .font(.body.weight(.medium))
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background(ClearHalalTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(ClearHalalTheme.border)
                            }
                            .onChange(of: draftDisplayName) { _, newValue in
                                if newValue.count > 34 {
                                    draftDisplayName = String(newValue.prefix(34))
                                }
                            }

                        HStack(spacing: 10) {
                            Button {
                                store.rename(result, to: draftDisplayName)
                            } label: {
                                Text("Save name")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 9)
                                    .background(ClearHalalTheme.deepForest)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                            .disabled(draftDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(draftDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)

                            Button {
                                draftDisplayName = ""
                                store.rename(result, to: nil)
                            } label: {
                                Text("Reset")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 9)
                                    .background(ClearHalalTheme.soft)
                                    .foregroundStyle(ClearHalalTheme.deepForest)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    if !ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Detected ingredients", subtitle: "Split from the captured text")

                            VStack(spacing: 8) {
                                ForEach(Array(ingredients.prefix(18).enumerated()), id: \.offset) { _, ingredient in
                                    HStack(spacing: 10) {
                                        Image(systemName: "smallcircle.filled.circle")
                                            .font(.caption2)
                                            .foregroundStyle(ClearHalalTheme.secondaryText)
                                        Text(ingredient)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(ClearHalalTheme.primaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: 0)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .background(ClearHalalTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(ClearHalalTheme.border)
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Raw scan text")
                        Text(result.input)
                            .font(.subheadline)
                            .foregroundStyle(ClearHalalTheme.secondaryText)
                            .textSelection(.enabled)
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .clearHalalCard()
                    }
                }
                .padding(24)
                .padding(.bottom, 40)
            }
            .background(ClearHalalTheme.background.ignoresSafeArea())
            .navigationTitle("Checked label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(ClearHalalTheme.deepForest)
                }
            }
            .onAppear {
                draftDisplayName = result.displayName ?? ""
            }
        }
    }
}

private struct DetailSection: View {
    let title: String
    let copy: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(ClearHalalTheme.primaryText)
            Text(copy)
                .font(.body)
                .foregroundStyle(ClearHalalTheme.secondaryText)
                .lineSpacing(3)
        }
    }
}
