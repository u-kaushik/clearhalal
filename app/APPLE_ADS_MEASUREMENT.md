# Apple Ads purchase attribution

The release RevenueCat setup enables standard AdServices token collection immediately after SDK configuration. RevenueCat resolves the token with Apple and attaches available campaign information to the customer. No additional ATT prompt is introduced.

Complete both parts before launching a paid test:

1. In the ClearHalal RevenueCat project, enable Apple AdServices and connect Apple Ads Advanced with read-only access. Verify account 24711490 and campaign 2144863062 are available.
2. Build and publish an app version containing this SDK change. A source commit alone does not enable attribution in the current App Store build.

Keep age and gender targeting disabled: RevenueCat documents that Apple's attribution API cannot return campaign details for those ad groups from September 2026 onward.

Validate a production ad-acquired install after launch: check the customer's Apple Ads attribution in RevenueCat, then follow the trial through payment or cancellation. TestFlight data can contain placeholder attribution and does not prove production linkage. Exclude the developer's own purchases and sandbox events from the experiment.

Report separately: taps, installs, trials, completed payments and refunds. Unknown attribution must remain unknown; do not count every new payment as an ad conversion. Match acquisition cohorts and wait for the last seven-day trial to mature before judging the £50 experiment.

Reference: https://www.revenuecat.com/docs/integrations/attribution/apple-search-ads
