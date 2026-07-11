import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: ScanHistoryStore
    @State private var selectedFilter: HistoryFilter = .all

    private var filteredHistory: [ScanResult] {
        store.history.filter { selectedFilter.includes($0) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ClearHalalBrandHeader(title: "History")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Every check in one place")
                            .font(ClearHalalTheme.display(36, weight: .semibold))
                            .foregroundStyle(ClearHalalTheme.primaryText)
                        Text("Recent scans, trusted products, and labels worth another look.")
                            .foregroundStyle(ClearHalalTheme.secondaryText)
                    }

                    HStack(spacing: 6) {
                        ForEach(HistoryFilter.allCases) { filter in
                            FilterPill(
                                filter.title,
                                color: filter.color,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation(.snappy(duration: 0.22)) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }

                    HStack {
                        MetricTile(value: "\(store.trustedCount)", label: "Trusted", color: ClearHalalTheme.positive)
                        MetricTile(value: "\(store.toVerifyCount)", label: "To verify", color: ClearHalalTheme.caution)
                        MetricTile(value: "\(store.avoidedCount)", label: "Avoided", color: ClearHalalTheme.concern)
                    }
                    .padding(18)
                    .clearHalalCard()

                    if filteredHistory.isEmpty {
                        EmptyHistoryFilterCard(filter: selectedFilter)
                    } else {
                        ForEach(filteredHistory) { result in
                            NavigationLink(value: result) {
                                HistoryRow(result: result)
                            }
                            .buttonStyle(.plain)
                        }
                    }
            }
            .padding(24)
            .padding(.bottom, ClearHalalTheme.tabBarScrollClearance)
            }
            .background(ClearHalalTheme.background.ignoresSafeArea())
            .navigationDestination(for: ScanResult.self) { result in
                ResultView(result: result)
            }
        }
        .background(ClearHalalTheme.background.ignoresSafeArea())
    }
}

private enum HistoryFilter: String, CaseIterable, Identifiable {
    case all
    case saved
    case trusted
    case toVerify
    case avoided

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .saved: return "Saved"
        case .trusted: return "Trusted"
        case .toVerify: return "Verify"
        case .avoided: return "Avoided"
        }
    }

    var color: Color {
        switch self {
        case .all: return ClearHalalTheme.primaryText
        case .saved: return ClearHalalTheme.deepForest
        case .trusted: return ClearHalalTheme.positive
        case .toVerify: return ClearHalalTheme.caution
        case .avoided: return ClearHalalTheme.concern
        }
    }

    func includes(_ result: ScanResult) -> Bool {
        switch self {
        case .all:
            return true
        case .saved:
            return result.isSaved
        case .trusted:
            return result.verdict == .likelyHalal || result.isSaved
        case .toVerify:
            return result.verdict == .sourceVaries || result.verdict == .unableToVerify
        case .avoided:
            return result.verdict == .haramConcern || result.wasAvoided
        }
    }
}

struct HistoryRow: View {
    let result: ScanResult

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: result.verdict.iconName)
                .font(.headline)
                .foregroundStyle(result.verdict.color)
                .frame(width: 38, height: 38)
                .background(result.verdict.softColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(displayTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ClearHalalTheme.primaryText)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(scanTimeText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(ClearHalalTheme.secondaryText)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Text(statusText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(result.verdict.color)

                    if result.isSaved {
                        Image(systemName: "bookmark.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ClearHalalTheme.deepForest)
                            .frame(width: 22, height: 22)
                            .background(ClearHalalTheme.soft)
                            .clipShape(Circle())
                            .accessibilityLabel("Saved")
                    }
                }
                .lineLimit(1)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(ClearHalalTheme.secondaryText)
        }
        .padding(16)
        .clearHalalCard()
    }

    private var displayTitle: String {
        result.displayTitle
    }

    private var statusText: String {
        switch result.verdict {
        case .likelyHalal: return "Trusted product"
        case .sourceVaries: return "Source varies"
        case .haramConcern: return "Concern: check before buying"
        case .unableToVerify: return "Needs clearer label"
        }
    }

    private var scanTimeText: String {
        result.createdAt.formatted(.relative(presentation: .named))
    }
}

private struct FilterPill: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    init(_ label: String, color: Color, isSelected: Bool, action: @escaping () -> Void) {
        self.label = label
        self.color = color
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.86)
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .background(isSelected ? color : color.opacity(0.12))
                .foregroundStyle(isSelected ? .white : color)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyHistoryFilterCard: View {
    let filter: HistoryFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No \(filter.title.lowercased()) checks yet")
                .font(.headline)
                .foregroundStyle(ClearHalalTheme.primaryText)
            Text("Checks will appear here as you scan products.")
                .font(.subheadline)
                .foregroundStyle(ClearHalalTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .clearHalalCard()
    }
}

private struct MetricTile: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(ClearHalalTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
