import Foundation
import StoreKit
import Security

//--------------- Timed Free Trial ------------------
///The key is the current version and build, the data is the date this version was first installed

class TrialLicenceManager {
    public static var shared = TrialLicenceManager()
    private let service = "com.musicmastereducation.ScalesAcademy"
    private let account = "licence_key"
    private let trialTimeSeconds = 60.0 * 60.0 * 24.0 * 7.0
    private var trialStartDate:Date? = nil
    //private var trialExpiryDate:Date? = nil

    init() {
        self.trialStartDate = self.readFromKeychain()
        if self.trialStartDate == nil {
            self.writeToKeychain()
            self.trialStartDate = Date()
        }
//        guard let trialStartDate = self.trialStartDate else {
//            return
//        }
    }
    
    public func isTrialExpired() -> Bool {
        guard let trialStartDate = self.trialStartDate else {
            return true
        }
        let trialExpiryDate = trialStartDate.addingTimeInterval(trialTimeSeconds)
        let expired = Date() > trialExpiryDate
        log("isTrialExpired :\(expired)", false)
        return expired
    }
    
    public func getStatus() -> String {
        guard let startDate = self.trialStartDate else {
            return ""
        }
        let expiryDate = startDate.addingTimeInterval(trialTimeSeconds)
        let expiry = self.dateToStr(expiryDate)
        if Date() > expiryDate {
            return "Your trial licence expired on \(expiry)"
        }
        else {
            return "Your trial licence expires on \(expiry)"
        }
    }
    
    private func getKey() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build:String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        ///change string to simulate a first install of the app
        return "trial_licence_5a_\(version)_(\(build))"
    }
    
    private func log(_ msg:String, _ error:Bool) {
        let msg = "\(error ? "🟥" : "🟩")  Licence \(msg)"
        if error  {
            AppLogger.shared.reportError(self, msg)
        }
        else {
            //AppLogger.shared.log(self, msg)
        }
    }
    
    private func dateToStr(_ date:Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = .current
        formatter.dateFormat = "d MMMM yyyy 'at' h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")  // Ensures consistent AM/PM formatting
        let formattedDate = formatter.string(from: date)
        return formattedDate
    }
    
    func readFromKeychain() -> Date? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.getKey(),
            kSecAttrSynchronizable as String: true,  // Must match write
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
                
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                log("Item not found in keychain", false)
            } else {
                log("Error reading from keychain: \(status)", true)
            }
            return nil
        }
        
        guard let storedData = result as? Data else {
            log("Cannot convert keychain to data", true)
            return nil
        }

        let restoredTimestamp = storedData.withUnsafeBytes {
            $0.load(as: TimeInterval.self)
        }
        let restoredDate = Date(timeIntervalSince1970: restoredTimestamp)
        print("Retrieved:", self.dateToStr(restoredDate))
        return restoredDate
    }

    func writeToKeychain() {
        if false {
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: self.getKey(),
                kSecAttrSynchronizable as String: true
            ]
            SecItemDelete(deleteQuery as CFDictionary)
        }

        let date = Date()
        let timestamp = date.timeIntervalSince1970  // Double
        var time = timestamp
        let data = Data(bytes: &time, count: MemoryLayout.size(ofValue: time))
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.getKey(),
            kSecValueData as String: data as Any,
            kSecAttrSynchronizable as String: true,  // Sync across devices via iCloud
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked  // Survives app deletion
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            self.log("Cant save trial licence to keychain. status:\(status)", true)
        }
    }
}

//--------------- Licensing ------------------
///Test with Sandbox user davidmurphy+sbx1@musicmastereducation.co.nz

// MARK: - Licensing (StoreKit 2)
@MainActor
final class LicenceManager: ObservableObject {
    static let shared = LicenceManager()

    // Published state you can bind to in UI
    @Published private(set) var products: [Product] = []
    @Published private(set) var isInBillingRetry: Bool = false
    @Published private(set) var lastExpirationDate: Date?
    @Published private(set) var statusMessage1: String?
    @Published private(set) var willAutoRenew: Bool? = nil  // nil => no purchased subscriptions
    @Published private(set) var licenceType: LicenceType = .none

    // Configuration
    private var productIDs: [String] = []
    private var hasStartedListener = false
    private var transactionListenerTask: Task<Void, Never>?
    private let trialLicenceManager = TrialLicenceManager.shared
    let logger = AppLogger.shared

    enum LicenceType {
        case none
        case notNeeded
        case trialActive
        case trialExpired
        case subscribed
    }

    private init() {
        log("Licencing INIT", false)
    }

    func setLicenseType(_ type: LicenceType) {
        log("Changing licence type: \(self.licenceType) → \(type)", false)
        self.licenceType = type
    }

    /// Call once early (e.g., at app start) with your product IDs.
    func configure(enableLicensing: Bool) {
        if !enableLicensing {
            setLicenseType(.notNeeded)
            return
        }
        // Update with your real product IDs from App Store Connect.
        self.productIDs = ["Monthly_4"]

        if !hasStartedListener { startTransactionListener() }

        Task {
            await refreshProducts()
            await refreshEntitlementsAndStatus()
        }
    }

    // MARK: - Product Loading

    func refreshProducts() async {
        log("Loading product IDs: \(self.productIDs)", false)
        guard !productIDs.isEmpty else {
            log("No product IDs configured.", true)
            products = []
            return
        }

        // Helpful for diagnostics
        let storefront = await Storefront.current
        log("Storefront: id=\(String(describing: storefront?.id)) cc=\(String(describing: storefront?.countryCode))", false)

        // Robust fetch with a couple of retries
        for attempt in 1...3 {
            do {
                let loaded = try await Product.products(for: productIDs)
                products = loaded.filter { $0.type == .autoRenewable }
                if products.isEmpty {
                    log("No auto-renewable products found (attempt \(attempt)).", true)
                } else {
                    log("Loaded \(products.count) product(s).", false)
                    for p in products { log("  \(getProductDescription(p))", false) }
                    break
                }
            } catch {
                log("Failed to load products (attempt \(attempt)): \(error.localizedDescription)", true)
            }
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s
        }
    }

    func getProductDescription(_ product: Product) -> String {
        "id:[\(product.id)] displayName:[\(product.displayName)] description:[\(product.description)] displayPrice:[\(product.displayPrice)]"
    }

    // MARK: - Purchase / Restore / Manage

    /// Convenience by product ID
    func purchase(productID: String) async {
        guard let product = products.first(where: { $0.id == productID }) else {
            log("Unknown product: \(productID)", true)
            return
        }
        await purchase(product)
    }

    /// Scene-anchored purchase (prevents “cannot present sheet” issues in review).
    func purchase(_ product: Product) async {
        log("Start purchase", false)
        do {
            let result: Product.PurchaseResult
            if let scene = activeForegroundScene() {
                // ✅ iOS 17+/18 API: anchors the confirmation sheet to your foreground scene
                result = try await product.purchase(confirmIn: scene, options: [])
            } else {
                // Fallback (still works if we can’t resolve a scene)
                result = try await product.purchase()
            }

            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await handleVerified(transaction)
                    log("Purchase successful.", false)
                } else {
                    log("Purchase could not be verified.", true)
                }
            case .userCancelled:
                log("Purchase cancelled by user.", false)
            case .pending:
                log("Purchase pending (Ask-to-Buy/extra verification).", false)
            @unknown default:
                log("Purchase returned an unknown result.", true)
            }
        } catch {
            log("Purchase failed: \(error.localizedDescription)", true)
        }

        await refreshEntitlementsAndStatus()
    }

    /// Visible “Restore Purchases” button should call this.
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            log("Restoring purchases…", false)
        } catch {
            log("Restore failed: \(error.localizedDescription)", true)
        }
        await refreshEntitlementsAndStatus()
    }

    /// Visible “Manage Subscription” button should call this.
    
    func showManageSubscriptions() async {
        // Must provide a UIWindowScene and handle throws
        guard let scene = activeForegroundScene() else {
            // Fallback: open Apple’s subscription management page in Safari
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                await MainActor.run { UIApplication.shared.open(url) }
            }
            log("No active scene; opened web subscriptions page.", false)
            return
        }

        do {
            try await AppStore.showManageSubscriptions(in: scene)
            log("Presented Manage Subscriptions sheet.", false)
        } catch {
            log("Failed to present Manage Subscriptions: \(error.localizedDescription)", true)
            // Fallback if the sheet fails
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                await MainActor.run { UIApplication.shared.open(url) }
            }
        }
    }

    // MARK: - Entitlements / Status

    /// Recompute current entitlement + future renewal intent.
    /// Call at launch, on foreground, and after purchase/restore/updates.
    func refreshEntitlementsAndStatus() async {
        log("RefreshEntitlementsAndStatus() starting…", false)

        var isActive = false
        var latestExpiry: Date?
        var autoRenew: Bool? = nil
        var billingRetry = false
        var inGrace = false

        // 1) What’s active *right now*?
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let t) = entitlement,
                  t.productType == .autoRenewable else { continue }

            let notRevoked = (t.revocationDate == nil)
            let notExpired = (t.expirationDate ?? .distantFuture) > Date()
            if notRevoked && notExpired {
                isActive = true
                if let exp = t.expirationDate {
                    latestExpiry = max(latestExpiry ?? .distantPast, exp)
                }
            }
        }

        // 2) Renewal intent & special states (grace / billing retry)
        for product in products {
            guard let subInfo = product.subscription else { continue }
            if let statuses = try? await subInfo.status {
                for status in statuses {
                    // We only rely on universally-available parts here.
                    if case .verified(let info) = status.renewalInfo {
                        // Will it auto-renew?
                        autoRenew = (autoRenew ?? true) && info.willAutoRenew

                        // Billing retry (newer SDKs expose this on RenewalInfo)
                        if #available(iOS 17.4, macOS 14.4, *) {
                            if info.isInBillingRetry {
                                billingRetry = true
                            }
                        } else {
                            // Older SDK: best-effort fallback (no direct API). Leave as false.
                        }

                        // Grace period (newer SDKs often expose a grace period expiry)
                        if #available(iOS 17.4, macOS 14.4, *) {
                            if let gp = info.gracePeriodExpirationDate, gp > Date() {
                                inGrace = true
                            }
                        } else {
                            // Older SDK: no direct way; keep false.
                        }
                    }

                    // Keep basic subscribed detection via entitlement scan above.
                    // Avoid switching on status.state cases that may not exist in your SDK.
                }
            }
        }

        // Publish
        self.lastExpirationDate = latestExpiry
        self.willAutoRenew = autoRenew
        self.isInBillingRetry = billingRetry

        if isActive || inGrace || billingRetry {
            setLicenseType(.subscribed)
        } else {
            self.willAutoRenew = nil
            self.isInBillingRetry = false
            if trialLicenceManager.isTrialExpired() {
                setLicenseType(.trialExpired)
            } else {
                setLicenseType(.trialActive)
            }
        }

        if let auto = self.willAutoRenew {
            log("Entitlement auto-renew: \(auto)", false)
        } else {
            log("Entitlement auto-renew: (none)", false)
        }
        if inGrace { log("User is in grace period.", false) }
        if billingRetry { log("User is in billing retry.", false) }
    }

    /// Quick check for one product’s active status.
    func isActive(productID: String) async -> Bool {
        if let res = await Transaction.latest(for: productID),
           case .verified(let t) = res {
            return t.revocationDate == nil && ((t.expirationDate ?? .distantFuture) > Date())
        }
        return false
    }

    // MARK: - Transaction listener

    private func startTransactionListener() {
        log("Start transaction listener", false)
        hasStartedListener = true
        transactionListenerTask?.cancel()
        transactionListenerTask = Task.detached(priority: .background) { [weak self] in
            for await update in Transaction.updates {
                guard let self else { continue }
                await self.log("▶️ Transaction received", false)
                if case .verified(let transaction) = update {
                    await self.handleVerified(transaction)
                    await self.refreshEntitlementsAndStatus()
                } else {
                    await self.log("Unverified transaction received (ignored).", true)
                }
            }
        }
    }

    private func handleVerified(_ transaction: Transaction) async {
        // Unlock features here if you gate per product.
        await transaction.finish()
    }

    // MARK: - Helpers

    private func activeForegroundScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    func log(_ msg: String, _ error: Bool) {
        let msg = "\(error ? "🔴" : "🟢") Licence \(msg)"
        if error {
            AppLogger.shared.reportError(self, msg)
        } else {
            AppLogger.shared.log(self, msg)
        }
        statusMessage1 = msg
    }

    // Convenience for external checks
    func isLicenced() -> Bool {
        [.notNeeded, .trialActive, .subscribed].contains(self.licenceType)
    }
}

//------------- OLD --------------------

//@MainActor
//final class LicenceManagerOld: ObservableObject {
//    static let shared = LicenceManagerOld()
//    @Published private(set) var products: [Product] = []
//    @Published private(set) var isInBillingRetry: Bool = false  //signal for UI
//    @Published private(set) var lastExpirationDate: Date?
//    @Published private(set) var statusMessage1: String?
//    @Published private(set) var willAutoRenew: Bool? = nil  //nil => no purchased subscriptions
//
//    private var productIDs: [String] = []
//    private var hasStartedListener = false
//    private var transactionListenerTask: Task<Void, Never>?
//    private let trialLicenceManager = TrialLicenceManager.shared
//    let logger = AppLogger.shared
//    
//    enum LicenceType {
//        case none
//        case notNeeded
//        case trialActive
//        case trialExpired
//        case subscribed
//    }
//    
//    @Published private(set) var licenceType:LicenceType = .none
//    
//    func isLicenced() -> Bool {
//        return [.notNeeded, .trialActive, .subscribed].contains(self.licenceType)
//    }
//    
//    private init() {
//        print("🟢 Licencing INIT")
//    }
//    
//    func setLicenseType(_ type:LicenceType) {
//        print("🟢 Changeing lic type old:\(self.licenceType) new:\(type)")
//        self.licenceType = type
//    }
//    
//    /// Call once early (e.g., App init) with your product IDs.
//    func configure(enableLicensing:Bool) {
//        if !enableLicensing {
//            self.setLicenseType(.notNeeded)
//            return
//        }
//        //self.productIDs = ["Monthly_3", "Monthly_4"]
//        self.productIDs = ["Monthly_4"]
//        if !hasStartedListener { startTransactionListener() }
//        Task {
//            await refreshProducts()
//            await refreshEntitlementsAndStatus()
//        }
//    }
//    
//    func refreshProducts() async {
//        log("Loading product IDs: \(self.productIDs)", false)
//        guard !productIDs.isEmpty else {
//            log("LicenceManager: No product IDs configured.", true)
//            products = []
//            return
//        }
//        let storefront = await Storefront.current
//        log("Storefront: \(String(describing: storefront?.id)) \(String(describing: storefront?.countryCode))", false)
//        do {
//            let sf = await Storefront.current
//            let prods = try await Product.products(for: productIDs)
//            print("🟢 Found:", prods.map { "\($0.id) \($0.type) \($0.displayName)" })
//        } catch {
//            print("🔴 Probe error:", error)
//        }
//
//        for attempt in 1...3 {
//            do {
//                let loaded = try await Product.products(for: productIDs)
//                products = loaded.filter { $0.type == .autoRenewable }
//                if products.isEmpty {
//                    log("No auto-renewable subscription products found. try:\(attempt)", true)
//                } else {
//                    log("Loaded \(products.count) product IDs.", false)
//                    for product in products {
//                        log("  \(getProductDescription(product))", false)
//                    }
//                    break
//                }
//            } catch {
//                log("Failed to load products: try: \(attempt) \(error.localizedDescription)", true)
//            }
//            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s
//        }
//        
//    }
//
//    func getProductDescription(_ product:Product) -> String {
//        var desc = ""
//        desc += " id:[\(product.id)" + "]"
//        desc += " displayName:[" + product.displayName + "]"
//        desc += " description:[" + product.description + "]"
//        desc += " displayPrice:[" + product.displayPrice + "]"
//        //desc += " " + String(product.price)
//        return desc
//        
//    }
//    
//    func purchase(productID: String) async {
//        guard let product = products.first(where: { $0.id == productID }) else {
//            log("Unknown product: \(productID)", true)
//            return
//        }
//        await purchase(product)
//    }
//
//    ///Purchase or Cancel subscription
//    ///Cancels - You don’t cancel inside your app. The user cancels through Apple’s subscription management UI that you launch from your app.
//    ///NB A canceled sub stays active until the current period ends (in Sandbox that’s minutes, not days). So your entitlement remains valid until expiry.
//    ///Nothing in your app is “called” by Apple when the user taps Cancel Subscription. There’s no callback. Your job is to refresh state when the manage sheet is dismissed or when your app becomes active again, and then update the UI.
//
//    func purchase(_ product: Product) async {
//        log("start purchase", false)
//        do {
//            let result = try await product.purchase()
//            switch result {
//            case .success(let verification):
//                if case .verified(let transaction) = verification {
//                    await handleVerified(transaction)
//                    log("Purchase successful.", false)
//                } else {
//                    log("Purchase could not be verified.", true)
//                }
//            case .userCancelled:
//                log("Purchase cancelled.", false)
//            case .pending:
//                log("Purchase pending.", false)
//            @unknown default:
//                log("Purchase returned an unknown result.", true)
//            }
//        } catch {
//            log("Purchase failed: \(error.localizedDescription)", true)
//        }
//        await refreshEntitlementsAndStatus()
//    }
//
//    func restorePurchases() async {
//        do {
//            try await AppStore.sync()
//            log("Restoring purchases…", false)
//        } catch {
//            log("Restore failed: \(error.localizedDescription)", true)
//        }
//        await refreshEntitlementsAndStatus()
//    }
//
//    /// Recompute current entitlement + future renewal intent.
//    /// Call this at launch, on foreground, and after purchase/updates.
//    func refreshEntitlementsAndStatus() async {
//        log("RefreshEntitlementsAndStatus() starting...", false)
//        var activeNow = false
//        var latestExpiry: Date?
//
//        for await entitlement in Transaction.currentEntitlements {
//            guard case .verified(let t) = entitlement,
//                  t.productType == .autoRenewable else { continue }
//
//            let notRevoked = (t.revocationDate == nil)
//            let notExpired = (t.expirationDate ?? .distantFuture) > Date()
//            if notRevoked && notExpired {
//                activeNow = true
//                if let exp = t.expirationDate {
//                    latestExpiry = max(latestExpiry ?? .distantPast, exp)
//                }
//            }
//        }
//
//        // Publish state
//        self.lastExpirationDate = latestExpiry
//
//        // If nothing is active, clear renewal flags and use trial license
//        guard activeNow else {
//            self.willAutoRenew = nil
//            self.isInBillingRetry = false
//            log("No active entitlements", false)
//            if self.trialLicenceManager.isTrialExpired() {
//                self.setLicenseType(.trialExpired)
//            }
//            else {
//                self.setLicenseType(.trialActive)
//            }
//            return
//        }
//        
//        self.setLicenseType(.subscribed)
//
//        /// Will subscrioption renew? Cancelled are not removed until end of period but their auto renew goes to false
//        /// Scan all loaded subscription products and AND the results so any known “cancelled” status makes willAutoRenew == false.
//        var autoRenew: Bool? = nil
//        var billingRetry = false
//
//        for product in products {
//            guard let subscription = product.subscription else { continue }
//
//            // `status` can return multiple entries (e.g. across devices/accounts)
//            if let statuses = try? await subscription.status {
//                for status in statuses where status.state == .subscribed {
//                    if case .verified(let info) = status.renewalInfo {
//                        // willAutoRenew is Bool
//                        autoRenew = (autoRenew ?? true) && info.willAutoRenew
//
//                        // Handle SDKs where isInBillingRetry is Bool OR Bool?
//                        // This compiles either way (no “initializer for conditional binding” error).
//                        let retryFlag = ((info.isInBillingRetry as Any) as? Bool) ?? false
//                        billingRetry = billingRetry || retryFlag
//                    } else {
//                        // Unverified renewal info — be conservative (assume no auto-renew)
//                        autoRenew = (autoRenew ?? true) && false
//                    }
//                }
//            }
//        }
//
//        // cancelled subscriptions wont auto renew, but stay active till end of current period
//        self.willAutoRenew = autoRenew     
//        self.isInBillingRetry = billingRetry
//        if let auto = self.willAutoRenew {
//            log("Entitlement auto-renew:\(auto)", false)
//        }
//        else {
//            log("Entitlement auto-renew:NO_IDEA)", true)
//        }
//    }
//
//    /// Check a specific product’s active status.
//    func isActive(productID: String) async -> Bool {
//        //if let latest = try? await Transaction.latest(for: productID),
//        if let latest = await Transaction.latest(for: productID),
//           case .verified(let t) = latest {
//            return (t.revocationDate == nil) &&
//                   ((t.expirationDate ?? .distantFuture) > Date())
//        }
//        return false
//    }
//
//    ///Listen for transaction updates
//    private func startTransactionListener() {
//        log("start transaction listener", false)
//        hasStartedListener = true
//        transactionListenerTask?.cancel()
//        transactionListenerTask = Task.detached(priority: .background) { [weak self] in
//            for await update in Transaction.updates {
//                guard let self else { continue }
//                await log("▶️ Transaction received", false)
//                if case .verified(let transaction) = update {
//                    await self.handleVerified(transaction)
//                    await self.refreshEntitlementsAndStatus()
//                }
//            }
//        }
//    }
//
//    private func handleVerified(_ transaction: Transaction) async {
//        // Unlock features here if you gate per product.
//        await transaction.finish()
//    }
//    
//    func log(_ msg:String, _ error:Bool) {
//        let msg = "\(error ? "🔴" : "🟢")  Licence \(msg)"
//        if error  {
//            AppLogger.shared.reportError(self, msg)
//        }
//        else {
//            AppLogger.shared.log(self, msg)
//        }
//        statusMessage1 = msg
//    }
//}

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
