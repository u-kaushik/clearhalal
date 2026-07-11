import Foundation
#if canImport(RevenueCat)
import RevenueCat
#endif

@MainActor
final class SubscriptionStore: NSObject, ObservableObject {
    @Published var isPremium = false
    @Published var trialStartedAt: Date?
    @Published var isLoading = false
    @Published var statusMessage: String?
    #if canImport(RevenueCat)
    @Published private(set) var availablePackages: [Package] = []
    #endif
    private var hasConfiguredRevenueCat = false

    var isRevenueCatConfigured: Bool {
        #if DEBUG || CLEARHALAL_FORCE_PREMIUM
        false
        #else
        RevenueCatConfig.isConfigured
        #endif
    }

    override init() {
        super.init()
    }

    func configure() {
        #if DEBUG || CLEARHALAL_FORCE_PREMIUM
        unlockForPrototype()
        statusMessage = "Premium active for device testing."
        #else
        guard RevenueCatConfig.isConfigured else {
            statusMessage = "RevenueCat SDK key is not configured yet."
            return
        }

        #if canImport(RevenueCat)
        guard !hasConfiguredRevenueCat else {
            refreshCustomerInfo()
            return
        }
        hasConfiguredRevenueCat = true
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: RevenueCatConfig.publicSDKKey)
        Purchases.shared.delegate = self
        loadOfferings()
        refreshCustomerInfo()
        #endif
        #endif
    }

    func startTrial() {
        unlockForPrototype()
    }

    func unlockForPrototype() {
        trialStartedAt = Date()
        isPremium = true
    }

    func restoreForPrototype() {
        isPremium = true
    }

    func refreshCustomerInfo() {
        guard RevenueCatConfig.isConfigured else { return }

        #if canImport(RevenueCat)
        isLoading = true
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            Task { @MainActor in
                self?.isLoading = false
                if let error {
                    self?.statusMessage = error.localizedDescription
                    return
                }
                self?.apply(customerInfo)
            }
        }
        #endif
    }

    func restorePurchases() {
        guard RevenueCatConfig.isConfigured else {
            restoreForPrototype()
            return
        }

        #if canImport(RevenueCat)
        isLoading = true
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            Task { @MainActor in
                self?.isLoading = false
                if let error {
                    self?.statusMessage = error.localizedDescription
                    return
                }
                self?.apply(customerInfo)
            }
        }
        #endif
    }

    #if canImport(RevenueCat)
    func loadOfferings() {
        guard RevenueCatConfig.isConfigured else { return }

        isLoading = true
        Purchases.shared.getOfferings { [weak self] offerings, error in
            Task { @MainActor in
                self?.isLoading = false
                if let error {
                    self?.statusMessage = error.localizedDescription
                    return
                }

                let offering = offerings?.offering(identifier: RevenueCatConfig.offeringID) ?? offerings?.current
                self?.availablePackages = offering?.availablePackages ?? []
            }
        }
    }

    func package(for productID: String) -> Package? {
        availablePackages.first { package in
            package.storeProduct.productIdentifier == productID
        }
    }

    func purchase(productID: String) {
        guard RevenueCatConfig.isConfigured else {
            unlockForPrototype()
            return
        }

        guard let package = package(for: productID) else {
            NSLog("ClearHalal purchase requested before package was available: %@", productID)
            statusMessage = "Subscription option is still loading. Please try again."
            loadOfferings()
            return
        }

        NSLog("ClearHalal starting purchase for product: %@", productID)
        isLoading = true
        Purchases.shared.purchase(package: package) { [weak self] _, customerInfo, error, userCancelled in
            Task { @MainActor in
                self?.isLoading = false
                if userCancelled {
                    NSLog("ClearHalal purchase cancelled for product: %@", productID)
                    #if DEBUG
                    #if targetEnvironment(simulator)
                    self?.statusMessage = "Simulator sandbox cancelled. Premium unlocked for local testing."
                    self?.unlockForPrototype()
                    return
                    #endif
                    #endif
                    self?.statusMessage = "Purchase was cancelled by Apple. Please try again or use a different sandbox tester."
                    return
                }
                if let error {
                    NSLog("ClearHalal purchase failed for product %@: %@", productID, error.localizedDescription)
                    self?.statusMessage = error.localizedDescription
                    return
                }
                NSLog("ClearHalal purchase finished for product: %@", productID)
                self?.apply(customerInfo)
            }
        }
    }

    private func apply(_ customerInfo: CustomerInfo?) {
        isPremium = customerInfo?.entitlements.active[RevenueCatConfig.premiumEntitlementID] != nil
        statusMessage = isPremium ? "Premium active" : nil
    }
    #endif
}

#if canImport(RevenueCat)
extension SubscriptionStore: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            apply(customerInfo)
        }
    }
}
#endif
