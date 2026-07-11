import SwiftUI

enum ScannerCoachTab: String, CaseIterable, Identifiable {
    case scan
    case history
    case insights
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scan: return "Scan"
        case .history: return "History"
        case .insights: return "Progress"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .scan: return "viewfinder"
        case .history: return "clock.arrow.circlepath"
        case .insights: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape"
        }
    }
}

struct ScannerCoachAppConfig {
    let appName: String
    let storageKeyPrefix: String
    let primaryActionTitle: String
    let primaryActionSubtitle: String
    let trustDisclaimer: String
    let tabs: [ScannerCoachTab]

    static let clearHalal = ScannerCoachAppConfig(
        appName: "ClearHalal",
        storageKeyPrefix: "clearhalal",
        primaryActionTitle: "Scan label",
        primaryActionSubtitle: "Ingredient list, menu, or packet",
        trustDisclaimer: "ClearHalal helps you understand visible ingredient information and common source concerns. It is not a halal certification body or religious authority.",
        tabs: ScannerCoachTab.allCases
    )
}
