import Foundation
import SwiftUI

enum Verdict: String, Codable, CaseIterable {
    case likelyHalal = "Likely halal"
    case sourceVaries = "Source varies"
    case haramConcern = "Haram concern"
    case unableToVerify = "Unable to verify"

    var color: Color {
        switch self {
        case .likelyHalal: return ClearHalalTheme.positive
        case .sourceVaries: return ClearHalalTheme.caution
        case .haramConcern: return ClearHalalTheme.concern
        case .unableToVerify: return ClearHalalTheme.secondaryText
        }
    }

    var softColor: Color {
        switch self {
        case .likelyHalal: return ClearHalalTheme.positiveSoft
        case .sourceVaries: return ClearHalalTheme.cautionSoft
        case .haramConcern: return ClearHalalTheme.concernSoft
        case .unableToVerify: return Color(hex: 0xECE7DD)
        }
    }

    var iconName: String {
        switch self {
        case .likelyHalal: return "checkmark.circle.fill"
        case .sourceVaries: return "exclamationmark.triangle.fill"
        case .haramConcern: return "xmark.octagon.fill"
        case .unableToVerify: return "questionmark.circle.fill"
        }
    }
}

enum ConfidenceLevel: String, Codable {
    case clear = "Clear"
    case likely = "Likely"
    case uncertain = "Uncertain"
    case unableToVerify = "Unable to verify"
}

struct EvidenceItem: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let status: String
    let detail: String
    let verdict: Verdict

    init(id: UUID = UUID(), title: String, status: String, detail: String, verdict: Verdict) {
        self.id = id
        self.title = title
        self.status = status
        self.detail = detail
        self.verdict = verdict
    }
}

struct ScanResult: Identifiable, Codable, Hashable {
    let id: UUID
    let input: String
    let verdict: Verdict
    let confidence: ConfidenceLevel
    let summary: String
    let nextStep: String
    let evidence: [EvidenceItem]
    let createdAt: Date
    var displayName: String?
    var isSaved: Bool
    var wasAvoided: Bool

    init(
        id: UUID = UUID(),
        input: String,
        verdict: Verdict,
        confidence: ConfidenceLevel,
        summary: String,
        nextStep: String,
        evidence: [EvidenceItem],
        createdAt: Date = Date(),
        displayName: String? = nil,
        isSaved: Bool = false,
        wasAvoided: Bool = false
    ) {
        self.id = id
        self.input = input
        self.verdict = verdict
        self.confidence = confidence
        self.summary = summary
        self.nextStep = nextStep
        self.evidence = evidence
        self.createdAt = createdAt
        self.displayName = displayName
        self.isSaved = isSaved
        self.wasAvoided = wasAvoided
    }
}

extension ScanResult {
    var displayTitle: String {
        if let displayName {
            let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                return Self.truncatedTitle(trimmedName)
            }
        }

        return Self.truncatedTitle(sourceTitle)
    }

    private static func truncatedTitle(_ title: String) -> String {
        if title.count <= 34 { return title }
        return String(title.prefix(34)) + "..."
    }

    var sourceTitle: String {
        let normalized = input
            .replacingOccurrences(of: "\n", with: " ")
            .split(separator: " ")
            .joined(separator: " ")

        if let productCue = productCueTitle(from: normalized) {
            return productCue
        }

        let candidates = input
            .components(separatedBy: CharacterSet(charactersIn: "\n,.;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { Self.isUsefulDisplayCandidate($0) }

        if let productLike = candidates.first(where: Self.looksLikeProductName) {
            return Self.titleCased(productLike)
        }

        if let firstIngredient = candidates.first {
            return Self.titleCased(firstIngredient)
        }

        return "Label scan"
    }

    var labelPreview: String {
        let normalized = input
            .replacingOccurrences(of: "\n", with: " ")
            .split(separator: " ")
            .joined(separator: " ")

        if normalized.count <= 120 { return normalized }
        return String(normalized.prefix(120)) + "..."
    }

    private func productCueTitle(from text: String) -> String? {
        let lowercased = text.lowercased()
        let cues = [
            "dark chocolate",
            "milk chocolate",
            "white chocolate",
            "chicken flavour crisps",
            "chicken flavor crisps",
            "instant noodles"
        ]

        return cues.first(where: { lowercased.contains($0) }).map(Self.titleCased)
    }

    private static func isUsefulDisplayCandidate(_ candidate: String) -> Bool {
        let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()
        let digits = trimmed.filter(\.isNumber).count
        let letters = trimmed.filter(\.isLetter).count

        guard trimmed.count >= 3, trimmed.count <= 42, letters >= 2 else { return false }
        guard digits < max(4, trimmed.count / 2) else { return false }

        let rejectedFragments = [
            "ingredients",
            "nutrition",
            "barcode",
            "best before",
            "this fine",
            "impresses",
            "components",
            "sweetness",
            "manufacturer",
            "produced by"
        ]

        return !rejectedFragments.contains { lowercased.contains($0) }
    }

    private static func looksLikeProductName(_ candidate: String) -> Bool {
        let words = candidate.split(separator: " ")
        guard words.count <= 4 else { return false }

        let lowercased = candidate.lowercased()
        let ingredientTerms = [
            "sugar",
            "salt",
            "flour",
            "glucose",
            "gelatin",
            "gelatine",
            "flavourings",
            "flavorings",
            "emulsifier",
            "lecithin"
        ]

        return !ingredientTerms.contains { lowercased.contains($0) }
    }

    private static func titleCased(_ text: String) -> String {
        text
            .split(separator: " ")
            .map { word in
                if word.allSatisfy({ $0.isNumber }) { return String(word) }
                if word.contains(".") { return String(word).uppercased() }
                return word.prefix(1).uppercased() + word.dropFirst().lowercased()
            }
            .joined(separator: " ")
    }
}
