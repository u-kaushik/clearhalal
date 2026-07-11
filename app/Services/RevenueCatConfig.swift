import Foundation

enum RevenueCatConfig {
    static let publicSDKKey = "appl_uCWUojQAsoxruHYpdNLezZpJHpa"
    static let premiumEntitlementID = "premium"
    static let offeringID = "default"
    static let weeklyProductID = "clearhalal_weekly"
    static let monthlyProductID = "clearhalal_monthly"
    static let annualProductID = "clearhalal_annual"

    static var isConfigured: Bool {
        !publicSDKKey.contains("REPLACE_WITH")
    }
}
