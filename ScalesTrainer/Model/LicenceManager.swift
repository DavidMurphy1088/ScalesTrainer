import Foundation
import StoreKit

/// StoreKit 2 subscription manager (iOS 15+)
/// Singleton usage: `LicenceManager.shared.configure(productIDs: [...])`
@MainActor
final class LicenceManagerNew: ObservableObject {

    static let shared = LicenceManagerNew()
    private init() {}

    @Published private(set) var products: [Product] = []
    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var lastExpirationDate: Date?
    @Published private(set) var statusMessage1: String?

    // MARK: - Config
    private var productIDs: [String] = []
    private var hasStartedListener = false
    private var transactionListenerTask: Task<Void, Never>?
    let logger = AppLogger.shared
    
    /// Call once early (e.g., App init) with your product IDs.
    func configure(productIDs: [String]) {
        self.productIDs = productIDs
        if !hasStartedListener { startTransactionListener() }
        Task {
            await refreshProducts()
            await refreshEntitlementsAndStatus()
        }
    }

    // MARK: - Product loading
    func refreshProducts() async {
        guard !productIDs.isEmpty else {
            log("LicenceManager: No product IDs configured.", true)
            products = []
            return
        }
        do {
            let loaded = try await Product.products(for: productIDs)
            products = loaded.filter { $0.type == .autoRenewable }
            if products.isEmpty {
                log("No auto-renewable subscription products found.", true)
            } else {
                log("Loaded \(products.count) products.", false)
            }
        } catch {
            log("Failed to load products: \(error.localizedDescription)", true)
        }
    }

    // MARK: - Purchasing
    func purchase(productID: String) async {
        guard let product = products.first(where: { $0.id == productID }) else {
            log("Unknown product: \(productID)", true)
            return
        }
        await purchase(product)
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await handleVerified(transaction)
                    log("Purchase successful.", false)
                } else {
                    log("Purchase could not be verified.", true)
                }
            case .userCancelled:
                log("Purchase cancelled.", false)
            case .pending:
                log("Purchase pending.", false)
            @unknown default:
                log("Purchase returned an unknown result.", true)
            }
        } catch {
            log("Purchase failed: \(error.localizedDescription)", true)
        }
        await refreshEntitlementsAndStatus()
    }

    // MARK: - Restore
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            log("Restoring purchases…", false)
        } catch {
            log("Restore failed: \(error.localizedDescription)", true)
        }
        await refreshEntitlementsAndStatus()
    }

    // MARK: - Entitlements
//    func refreshEntitlementsOld() async {
//        var active = false
//        var latestExpiry: Date?
//
//        for await entitlement in Transaction.currentEntitlements {
//            guard case .verified(let t) = entitlement else { continue }
//            guard t.productType == .autoRenewable else { continue }
//
//            let notRevoked = (t.revocationDate == nil)
//            let notExpired = (t.expirationDate ?? .distantFuture) > Date()
//            if notRevoked && notExpired {
//                active = true
//                if let exp = t.expirationDate {
//                    latestExpiry = max(latestExpiry ?? .distantPast, exp)
//                }
//
//            }
//
//        }
//
//        isSubscribed = active
//        lastExpirationDate = latestExpiry
//        statusMessage = active ? "Subscription active." : "No active subscription."
//    }
    
    @Published private(set) var willAutoRenew: Bool? = nil        // nil = unknown / not a sub
    
    //Transactions -
    //              "webOrderLineItemId": "0",
    //              "price": 1990,
    //              "productId": "100",
    //              "inAppOwnershipType": "PURCHASED",
    //              "environment": "Xcode",
    //              "currency": "USD",
    //              "originalPurchaseDate": 1759287023685,
    //              "transactionReason": "PURCHASE",
    //              "quantity": 1,
    //              "subscriptionGroupIdentifier": "DD5B5062",
    //              "deviceVerification": "dVGJIkETxBxowiSFaa3nIQF4kk80oclo/jzpgTTkufZPoS5KHNAi8cqgdRS0C/tl",
    //              "transactionId": "0",
    //              "isUpgraded": false,
    //              "purchaseDate": 1759287023685,
    //              "type": "Auto-Renewable Subscription",
    //              "bundleId": "com.musicmastereducation.ScalesStar",
    //              "originalTransactionId": "0",
    //              "deviceVerificationNonce": "2005b629-17b1-4b94-8fc6-b1a78dd21a47",
    //              "storefront": "USA",
    //              "signedDate": 1759288042847,
    //              "storefrontId": "143441",
    //              "expiresDate": 1761965423685
                //logger.log(self, String(data: t.jsonRepresentation, encoding: .utf8)!)

    @Published private(set) var isInBillingRetry: Bool = false  // optional signal for UI

    /// Recompute current entitlement + future renewal intent.
    /// Call this at launch, on foreground, and after purchase/updates.
    func refreshEntitlementsAndStatus() async {
        // ---------- 1) ACTIVE NOW? (transactions) ----------
        var activeNow = false
        var latestExpiry: Date?

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let t) = entitlement,
                  t.productType == .autoRenewable else { continue }

            let notRevoked = (t.revocationDate == nil)
            let notExpired = (t.expirationDate ?? .distantFuture) > Date()
            if notRevoked && notExpired {
                activeNow = true
                if let exp = t.expirationDate {
                    latestExpiry = max(latestExpiry ?? .distantPast, exp)
                }
            }
        }

        // Publish “now” state
        self.isSubscribed = activeNow
        self.lastExpirationDate = latestExpiry

        // If nothing is active, clear renewal flags and return early.
        guard activeNow else {
            self.willAutoRenew = nil
            self.isInBillingRetry = false
            log("No active entitlements", true)
            return
        }

        // ---------- 2) WILL IT RENEW? (status/renewalInfo) ----------
        // We’ll scan all loaded subscription products and AND the results
        // so any known “cancelled” status makes willAutoRenew == false.
        var autoRenew: Bool? = nil
        var billingRetry = false

        for product in products {
            guard let subscription = product.subscription else { continue }

            // `status` can return multiple entries (e.g. across devices/accounts)
            if let statuses = try? await subscription.status {
                for status in statuses where status.state == .subscribed {
                    // renewalInfo is a VerificationResult — must verify before use
                    if case .verified(let info) = status.renewalInfo {
                        // willAutoRenew is Bool
                        autoRenew = (autoRenew ?? true) && info.willAutoRenew

                        // Handle SDKs where isInBillingRetry is Bool OR Bool?
                        // This compiles either way (no “initializer for conditional binding” error).
                        let retryFlag = ((info.isInBillingRetry as Any) as? Bool) ?? false
                        billingRetry = billingRetry || retryFlag
                    } else {
                        // Unverified renewal info — be conservative (assume no auto-renew)
                        autoRenew = (autoRenew ?? true) && false
                    }
                }
            }
        }

        // Publish “future intent” state
        self.willAutoRenew = autoRenew     // true/false if known; nil if indeterminate
        self.isInBillingRetry = billingRetry
        if let auto = self.willAutoRenew {
            log("Entitlement auto-renew:\(auto)", false)
        }
        else {
            log("Entitlement auto-renew:NO_IDEA)", true)
        }
    }

    /// Check a specific product’s active status.
    func isActive(productID: String) async -> Bool {
        //if let latest = try? await Transaction.latest(for: productID),
        if let latest = await Transaction.latest(for: productID),
           case .verified(let t) = latest {
            return (t.revocationDate == nil) &&
                   ((t.expirationDate ?? .distantFuture) > Date())
        }
        return false
    }

    // MARK: - Transaction listener
    private func startTransactionListener() {
        log("start transaction listener", false)
        hasStartedListener = true
        transactionListenerTask?.cancel()
        transactionListenerTask = Task.detached(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                await log("▶️ Transaction received", false)
                if case .verified(let transaction) = update {
                    await self.handleVerified(transaction)
                    await self.refreshEntitlementsAndStatus()
                }
            }
        }
    }

    // MARK: - Helpers
    private func handleVerified(_ transaction: Transaction) async {
        // Unlock features here if you gate per product.
        await transaction.finish()
    }
    
    func log(_ msg:String, _ error:Bool) {
        
        print("============== \(error ? "🔴" : "🟢")  Licence \(msg)")
        statusMessage1 = msg
    }
}

/*
 Awesome—here’s a tight, battle-tested checklist to move from Local StoreKit → TestFlight/Sandbox (the next level). No code changes are required for StoreKit 2; it’s all setup and environment.

 1) Clean up your project for Sandbox

 Remove the local .storekit file from the run scheme
 Xcode > Product > Scheme > Edit Scheme… > Options > StoreKit Configuration: Unset (or make a separate “Local” scheme that still points to it).

 Ensure target has In-App Purchase capability enabled.

 Keep your SK2 code as-is (use Product.products(for:), product.purchase(), Transaction.updates, etc.).

 2) Create IAPs in App Store Connect (ASC)

 App Store Connect → My Apps → Your app → In-App Purchases.

 Create your Auto-Renewable Subscription(s) inside a Subscription Group.

 Use the same product IDs you use in code.

 Fill required metadata (Reference Name, Pricing, Duration, Localizations).

 For TestFlight, IAPs do not need App Review, but they must exist and be in a usable state (“Ready to Submit / Ready to Use” is fine).

 3) Upload a TestFlight build with IAPs

 In Xcode, Archive and upload via Organizer (or use Transporter).

 After processing (a few minutes), the build appears in ASC → Your app → TestFlight.

 (Recommended) On the TestFlight page, confirm your IAPs are associated/visible with the build (ASC usually picks them up automatically once created).

 4) Set up Sandbox testers (per-device sign-in)

 ASC → Users and Access → Sandbox Testers → add at least one tester (email can be non-Apple).

 On the test device (not simulator recommended here):
 Settings → App Store → Sandbox Account → sign in with the sandbox tester.

 Do not sign in with a real Apple ID during sandbox purchase.

 You can leave your main Apple ID signed in for iCloud; just ensure the Sandbox Account is your tester.

 5) Install the app via TestFlight

 Invite yourself/others to the build (Internal Testing is instant; External Testing requires a brief Beta App Review).

 Install the app from the TestFlight app.

 6) Test the flows (what to expect)

 Load products: Your Product.products(for:) should now return items from ASC (not your .storekit file). If the list is empty → see Troubleshooting below.

 Purchase with SK2: try await product.purchase() will present the Sandbox purchase sheet.

 Auto-renew happens on Apple’s accelerated Sandbox clock (approx):

 1 week ≈ ~3 minutes

 1 month ≈ ~5 minutes

 2 months ≈ ~10 minutes

 3 months ≈ ~15 minutes

 6 months ≈ ~30 minutes

 1 year ≈ ~60 minutes

 Your listener (Transaction.updates) should receive a renewal each accelerated period. Keep the app foregrounded to observe them reliably.

 Manage / Cancel: If the user cancels in the manage sheet, renewalInfo.willAutoRenew becomes false; entitlement remains until the accelerated expirationDate, then drops.

 7) Optional but recommended

 Add a “Restore Purchases” button that calls:

 try? await AppStore.sync()
 await LicenceManager.shared.refreshEntitlementsAndStatus()


 (Only do this in Sandbox/Production; not in Local StoreKit.)

 Environment guard so you don’t call AppStore.sync() in Local mode:

 #if DEBUG
 let usingLocal = ProcessInfo.processInfo.environment["USE_LOCAL_STOREKIT"] == "1"
 #else
 let usingLocal = false
 #endif
 if !usingLocal { try? await AppStore.sync() }


 (If you have a server) switch receipt validation to the sandbox endpoint and/or enable App Store Server Notifications V2 (sandbox) to observe renewals server-side.

 8) Test scenarios to cover

 First purchase, success → finish().

 Auto-renew tick(s) → see Transaction.updates firing.

 Cancel auto-renew → willAutoRenew == false, entitlement expires at end.

 Billing retry / grace (if configured in ASC) → reflect in UI.

 Restore on a clean install/device → AppStore.sync() + entitlement recompute.

 Manage sheet while already subscribed → ensure your UI handles it gracefully.

 9) Troubleshooting cheatsheet

 Products array is empty

 Product IDs in code must match ASC exactly.

 Tester must be signed into Sandbox Account on device.

 Build must be installed via TestFlight, not Xcode run.

 Region/price issues: ensure the subscription is priced and available in the tester’s storefront.

 Purchase fails with “Cannot connect to iTunes Store”

 Sandbox account not signed in / network / ASC outage. Sign out/in of Sandbox Account.

 No renewals arriving

 Wait the accelerated time for your duration.

 Ensure you finish every transaction.

 Keep app foregrounded.

 Remember: no renewal-count in Sandbox; it keeps renewing until cancelled or the test session ends.

 10) What you do not need to change

 Your LicenceManager class, SK2 purchase flow, and Transaction.updates listener.

 No code switch between Local ↔︎ Sandbox beyond not calling AppStore.sync() in Local mode.

 Follow those steps and you’ll have a clean path from Local StoreKit to realistic TestFlight/Sandbox testing with accelerated renewals and real App Store purchase flows.
 */
