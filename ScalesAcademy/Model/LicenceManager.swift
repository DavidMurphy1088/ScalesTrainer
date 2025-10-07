import Foundation
import StoreKit

@MainActor
final class Licencing: ObservableObject {
    static let shared = Licencing()
    private init() {}

    @Published private(set) var products: [Product] = []
    @Published private(set) var isSubscribed: Bool = false
    @Published private(set) var lastExpirationDate: Date?
    @Published private(set) var statusMessage1: String?
    @Published private(set) var willAutoRenew: Bool? = nil        // nil = unknown / not a sub

    private var enableLicensing:Bool = false
    private var productIDs: [String] = []
    private var hasStartedListener = false
    private var transactionListenerTask: Task<Void, Never>?
    let logger = AppLogger.shared
    
    /// Call once early (e.g., App init) with your product IDs.
    /// apptesting2@musicmastereducation.co.nz
    func configure(enableLicensing:Bool, productIDs: [String]) {
        self.enableLicensing = enableLicensing
        if !enableLicensing {
            return
        }
        self.productIDs = productIDs
        if !hasStartedListener { startTransactionListener() }
        Task {
            await refreshProducts()
            await refreshEntitlementsAndStatus()
        }
    }

    func refreshProducts() async {
        log("Loading products \(self.productIDs)", false)
        guard !productIDs.isEmpty else {
            log("LicenceManager: No product IDs configured.", true)
            products = []
            return
        }
        print("🟢 Bundle at runtime:", Bundle.main.bundleIdentifier ?? "nil")
        let storefront = try await Storefront.current
        log("Storefront: \(storefront?.id) \(storefront?.countryCode)", false)
        print("🟢 Bundle:", Bundle.main.bundleIdentifier ?? "nil")
        print("🟢 Can make payments:", AppStore.canMakePayments)
        do {
            let sf = await Storefront.current
            print("🟢 Storefront:", sf?.id ?? "?", sf?.countryCode ?? "?")
            let prods = try await Product.products(for: productIDs)
            print("🟢 Found:", prods.map { "\($0.id) \($0.type) \($0.displayName)" })
        } catch {
            print("🔴 Probe error:", error)
        }

        for attempt in 1...3 {
            do {
                let loaded = try await Product.products(for: productIDs)
                products = loaded.filter { $0.type == .autoRenewable }
                if products.isEmpty {
                    log("No auto-renewable subscription products found. try:\(attempt)", true)
                } else {
                    log("Loaded \(products.count) products.", false)
                    break
                }
            } catch {
                log("Failed to load products: try: \(attempt) \(error.localizedDescription)", true)
            }
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s
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

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            log("Restoring purchases…", false)
        } catch {
            log("Restore failed: \(error.localizedDescription)", true)
        }
        await refreshEntitlementsAndStatus()
    }

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
            log("No active entitlements", false)
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
        let msg = "\(error ? "🔴" : "🟢")  Licence \(msg)"
        if error  {
            AppLogger.shared.reportError(self, msg)
        }
        else {
            AppLogger.shared.log(self, msg)
        }
        statusMessage1 = msg
    }
}

