# ClearHalal iOS

ClearHalal is a native SwiftUI food-label companion that uses on-device text recognition and an explainable rules engine to surface halal-relevant ingredient concerns.

Reusable loop:

`onboarding -> hard paywall -> input/scan -> processing -> result -> explanation -> history -> insights -> settings`

## Shared Layer

- `Shared/ScannerCoach/ScannerCoachConfig.swift`: app name, tab shell, primary action labels, trust disclaimer.
- `Shared/ScannerCoach/ScannerCoachRewards.swift`: generic behaviour-change progress and achievement rules.
- `Services/RevenueCatConfig.swift`: RevenueCat public SDK key and premium entitlement identifier.

## ClearHalal Skin

- `Views/ClearHalalTheme.swift`: palette, card treatment, app visual style.
- `Models/ScanModels.swift`: halal-specific verdicts and evidence.
- `Services/HalalClassifier.swift`: halal-specific local classifier.

## RevenueCat Setup

The app uses a native SwiftUI paywall for full visual control and uses RevenueCat for subscription products, purchase, restore, and entitlement state. Until a real public iOS SDK key is set, the hard paywall runs in development mode.

Production setup:

1. Create the app in RevenueCat.
2. Add App Store Connect products for weekly, monthly, and annual subscriptions.
3. Attach those products to the default RevenueCat offering.
4. Create/confirm the entitlement identifier: `premium`.
5. Replace `RevenueCatConfig.publicSDKKey` with the public iOS SDK key.
6. Confirm the RevenueCat offering exposes the expected subscription products.

The app grants premium access when `CustomerInfo.entitlements.active["premium"]` exists.

Product IDs expected by the app config:

- `clearhalal_weekly`
- `clearhalal_monthly`
- `clearhalal_annual`
