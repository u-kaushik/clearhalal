import Foundation
import SwiftUI

struct ScannerCoachProgress {
    let totalChecks: Int
    let trustedSaves: Int
    let cautiousAvoids: Int
    let uncertainFindings: Int

    var clearerChoices: Int {
        trustedSaves + cautiousAvoids
    }

    var weeklyProgress: Double {
        guard totalChecks > 0 else { return 0 }
        return min(Double(clearerChoices) / max(Double(totalChecks), 1), 1)
    }

    var summaryLine: String {
        "\(totalChecks) checks · \(trustedSaves) trusted saves · \(cautiousAvoids) source-varying choices avoided"
    }
}

struct ScannerCoachAchievement: Identifiable {
    let id: String
    let icon: String
    let title: String
    let detail: String
    let longDetail: String
    let isUnlocked: Bool
    let progressValue: Int
    let targetValue: Int
    let tint: Color

    var progress: Double {
        guard targetValue > 0 else { return isUnlocked ? 1 : 0 }
        return min(Double(progressValue) / Double(targetValue), 1)
    }

    var statusText: String {
        isUnlocked ? levelName : "In progress"
    }

    var level: Int {
        guard targetValue > 0 else { return isUnlocked ? 1 : 0 }
        return min(max(progressValue / targetValue, 0), 3)
    }

    var levelName: String {
        switch level {
        case 3: return "Gold"
        case 2: return "Silver"
        default: return "Bronze"
        }
    }

    var nextLevelDetail: String {
        guard isUnlocked, level < 3 else { return detail }
        let nextTarget = targetValue * (level + 1)
        return "\(progressValue) of \(nextTarget) toward \(nextLevelName)"
    }

    private var nextLevelName: String {
        switch level + 1 {
        case 3: return "Gold"
        case 2: return "Silver"
        default: return "Bronze"
        }
    }
}

enum ScannerCoachRewardEngine {
    static func achievements(for progress: ScannerCoachProgress, learnedItems: [String]) -> [ScannerCoachAchievement] {
        [
            ScannerCoachAchievement(
                id: "label-reader",
                icon: "viewfinder",
                title: "First Clear Check",
                detail: progress.totalChecks >= 10 ? "10 checks completed" : "\(progress.totalChecks)/10 checks completed",
                longDetail: "Awarded for building the habit of checking ingredient labels before deciding what belongs in your basket.",
                isUnlocked: progress.totalChecks >= 10,
                progressValue: progress.totalChecks,
                targetValue: 10,
                tint: ClearHalalTheme.deepForest
            ),
            ScannerCoachAchievement(
                id: "ingredient-learner",
                icon: "book.closed",
                title: "Ingredient Guide",
                detail: learnedItems.isEmpty ? "Open ingredient details to learn faster" : learnedItems.prefix(3).joined(separator: ", "),
                longDetail: "Awarded for learning the ingredient names that often need source context, including additives, enzymes, and flavourings.",
                isUnlocked: learnedItems.count >= 3,
                progressValue: learnedItems.count,
                targetValue: 3,
                tint: ClearHalalTheme.fig
            ),
            ScannerCoachAchievement(
                id: "trusted-pantry",
                icon: "bookmark",
                title: "Trusted Pantry",
                detail: progress.trustedSaves >= 5 ? "5 products saved" : "\(progress.trustedSaves)/5 products saved",
                longDetail: "Awarded for saving products you can return to with confidence on future shops.",
                isUnlocked: progress.trustedSaves >= 5,
                progressValue: progress.trustedSaves,
                targetValue: 5,
                tint: ClearHalalTheme.positive
            ),
            ScannerCoachAchievement(
                id: "careful-choice",
                icon: "exclamationmark.triangle",
                title: "Careful Choice",
                detail: progress.cautiousAvoids >= 3 ? "3 uncertain choices avoided" : "\(progress.cautiousAvoids)/3 uncertain choices avoided",
                longDetail: "Awarded for stepping away from labels with a clear source concern or an ingredient that deserves extra verification.",
                isUnlocked: progress.cautiousAvoids >= 3,
                progressValue: progress.cautiousAvoids,
                targetValue: 3,
                tint: ClearHalalTheme.caution
            ),
            ScannerCoachAchievement(
                id: "source-sleuth",
                icon: "text.magnifyingglass",
                title: "Source Sleuth",
                detail: progress.uncertainFindings >= 5 ? "5 uncertain ingredients reviewed" : "\(progress.uncertainFindings)/5 uncertain ingredients reviewed",
                longDetail: "Awarded for noticing when ingredients may vary by source and deserve a closer look.",
                isUnlocked: progress.uncertainFindings >= 5,
                progressValue: progress.uncertainFindings,
                targetValue: 5,
                tint: ClearHalalTheme.caution
            ),
            ScannerCoachAchievement(
                id: "grocery-record",
                icon: "basket",
                title: "Grocery Record",
                detail: progress.clearerChoices >= 12 ? "12 clearer choices recorded" : "\(progress.clearerChoices)/12 clearer choices recorded",
                longDetail: "Awarded for turning everyday scans into a useful record of products, ingredients, and decisions.",
                isUnlocked: progress.clearerChoices >= 12,
                progressValue: progress.clearerChoices,
                targetValue: 12,
                tint: ClearHalalTheme.pantryGreen
            )
        ]
    }
}
