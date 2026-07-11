import Foundation

@MainActor
final class ScanHistoryStore: ObservableObject {
    @Published var history: [ScanResult] = []
    @Published var latestResult: ScanResult?

    private let classifier = HalalClassifier()

    init() {
        seed()
    }

    func check(_ input: String) {
        var result = classifier.classify(input)
        if result.verdict == .likelyHalal {
            result.isSaved = true
        }
        latestResult = result
        history.insert(result, at: 0)
    }

    func save(_ result: ScanResult) {
        if let index = history.firstIndex(where: { $0.id == result.id }) {
            history[index].isSaved = true
            latestResult = history[index]
        }
    }

    func rename(_ result: ScanResult, to displayName: String?) {
        let cleanedName = displayName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix(34)

        let nextName = cleanedName.map(String.init).flatMap { $0.isEmpty ? nil : $0 }

        if let index = history.firstIndex(where: { $0.id == result.id }) {
            history[index].displayName = nextName
            latestResult = history[index]
        } else if latestResult?.id == result.id {
            latestResult?.displayName = nextName
        }
    }

    var trustedCount: Int { history.filter { $0.verdict == .likelyHalal || $0.isSaved }.count }
    var toVerifyCount: Int { history.filter { $0.verdict == .sourceVaries }.count }
    var avoidedCount: Int { history.filter { $0.verdict == .haramConcern || $0.wasAvoided }.count }
    var uncertainCount: Int { history.filter { $0.verdict == .sourceVaries || $0.verdict == .unableToVerify }.count }

    var progress: ScannerCoachProgress {
        ScannerCoachProgress(
            totalChecks: history.count,
            trustedSaves: trustedCount,
            cautiousAvoids: avoidedCount,
            uncertainFindings: uncertainCount
        )
    }

    var learnedIngredients: [String] {
        learnedIngredientItems.map(\.title)
    }

    var learnedIngredientItems: [EvidenceItem] {
        var seen = Set<String>()
        return history
            .flatMap(\.evidence)
            .filter { item in
                let key = item.title.lowercased()
                guard !seen.contains(key) else { return false }
                seen.insert(key)
                return true
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var achievements: [ScannerCoachAchievement] {
        ScannerCoachRewardEngine.achievements(for: progress, learnedItems: learnedIngredients)
    }

    private func seed() {
        history = [
            HalalClassifier().classify("Chicken flavour crisps, potato starch, pork fat, smoke flavouring, salt"),
            HalalClassifier().classify("Sugar, glucose syrup, beef gelatin, citric acid, flavourings"),
            HalalClassifier().classify("Wheat flour, sugar, cocoa butter, milk powder, sunflower lecithin"),
            HalalClassifier().classify("Noodles, seasoning, flavourings, E471, soy sauce"),
            HalalClassifier().classify("Potatoes, sunflower oil, salt")
        ]
    }
}
