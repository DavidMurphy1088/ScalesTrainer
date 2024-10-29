import Foundation
import SwiftUI
import StoreKit

import Foundation
import Combine
import SwiftUI
import WebKit
import AVFoundation
import AVKit
import UIKit

public enum ExamStatus {
    case notInExam
    case inExam
    case inExamReview
}

public class QuestionStatus: Codable, ObservableObject {
    public var status:Int = 0
    init(_ i:Int) {
        self.status = i
    }
    public func setStatus(_ i:Int) {
        DispatchQueue.main.async {
            self.status = i
        }
    }
}

public class ContentSectionData: Codable {
    public var type:String
    public var data:[String]
    public var row:Int
    public init(row:Int, type:String, data:[String]) {
        self.row = row
        self.type = type
        self.data = data
    }
}

public class ContentSection: ObservableObject, Identifiable { //Codable,
    public var name: String = ""
}



///The subscription transaction receipt
///All dates are GMT
public class SubscriptionTransactionReceipt: Encodable, Decodable { //, Encodable,
    public var expiryDate:Date
    let name:String
    let data:Data
    
    private static let storageKey = "subscription"
    
    init(name:String, data: Data, expiryDate:Date) {
        self.name = name
        self.data = data
        self.expiryDate = expiryDate
    }
    
    public func getDescription() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy h:mm a"
        dateFormatter.timeZone = TimeZone.current // Use the device's current time zone
        let localDateString = dateFormatter.string(from: expiryDate)
        return self.name + "\nexpiring " + localDateString
    }
    
    public func allDatesDescription() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let gmtDateString = dateFormatter.string(from: expiryDate)
        dateFormatter.timeZone = TimeZone.current // Use the device's current time zone
        let localDateString = dateFormatter.string(from: expiryDate)
        return "\(name) Expiry - GMT:[\(gmtDateString)] LocalTimeZone:[\(localDateString)]"
    }
    
    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601 // Since your dates are in GMT, ISO8601 is a good choice
        do {
            let encodedData = try encoder.encode(self)
            UserDefaults.standard.set(encodedData, forKey: "subscription")
        } catch {
            Logger.shared.reportError(self, "Failed to encode SubscriptionReceipt: \(error)")
        }
    }
    
    static public func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    static public func load() -> SubscriptionTransactionReceipt? {
        guard let encodedData = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let receipt = try decoder.decode(SubscriptionTransactionReceipt.self, from: encodedData)
            return receipt
        } catch {
            Logger.shared.reportError(self, "Failed to decode SubscriptionReceipt: \(error)")
            return nil
        }
    }
}

public class FreeLicenseUser:Hashable {
    public var email:String
    public var allowTest:Bool
    
    init(email:String, allowTest:Bool) {
        self.email = email
        self.allowTest = allowTest
    }
    
    public static func == (lhs: FreeLicenseUser, rhs: FreeLicenseUser) -> Bool {
        return lhs.email == rhs.email
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(email)
    }
}

public class LicenceManager: NSObject, ObservableObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    @Published public var purchaseableProducts:[String: SKProduct] = [:] ///Product id's that are returned from a product request to StoreKit
    var emailLicenses = Set<FreeLicenseUser>()
    @Published public var isInPurchasingState = false
    @Published public var configuredLicenceEmail:String = ""
    
    private let localSubscriptionStorageKey = "subscription"
    public static let shared = LicenceManager()
    public static var subscriptionURLLogged = false

    ///Product ID's that are known to the app
    //private let configuredProductIDs:[String] = ["MT_NZMEB_Subscription_Month_3", "MT_NZMEB_Subscription_Month_6", "MT_NZMEB_Subscription_Month_12"]
    private let configuredProductIDs:[String] = ["Trinity_Monthly_Test"]
    
    private override init() {
        super.init()
    }
    
    public func isLicensed() -> Bool {
        if emailIsLicensed(email: configuredLicenceEmail) {
            return true
        }
        else {
            if let subscription = SubscriptionTransactionReceipt.load() {
                //print("=============", "    Expire:", subscription.expiryDate, " now:", Date())
                return subscription.expiryDate >= Date()
            }
        }
        return false
    }
    ///Load email licenses (e.g. teachers)
    public func loadEmailLicenses(sheetRows:[[String]]) {
        for rowCells in sheetRows {
            if rowCells.count < 5 {
                continue
            }
            if rowCells[0].hasPrefix("//")  {
                continue
            }
            let email = rowCells[1]
            let allowTest = rowCells[2] == "Y"
            //DispatchQueue.main.async {
                self.emailLicenses.insert(FreeLicenseUser(email:email, allowTest: allowTest))
            //}
        }
    }
            
    public func emailIsLicensed(email:String) -> Bool {
        let toCheck:String = email.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        for emailInList in self.emailLicenses {
            if emailInList.email.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) == toCheck {
                return true
            }
        }
        return false
    }
    
    public func getFreeLicenceUser(email:String) -> FreeLicenseUser? {
        for user in self.emailLicenses {
            if user.email == email {
                return user
            }
        }
        return nil
    }
    
    public func isLicenseAvailableToPurchase(grade:String) -> Bool {
        return self.purchaseableProducts.keys.count > 0
    }
    
    ///Called at app startup to ask for the purchasable products defined for this app
    public func requestProducts() {
        for product in self.configuredProductIDs {
            let requested:Set<String> = [product]
            //Logger.logger.log(self, "Request purchaseable products from list of configured product IDs:\(configuredProductIDs)")
            Logger.shared.log(self, "Request purchaseable products for configured product ID:\(requested)")
            //let request = SKProductsRequest(productIdentifiers: configuredProductIDs)
            let request = SKProductsRequest(productIdentifiers: requested)
            request.delegate = self
            request.start()
        }
    }
    
    ///Load the licenses that are paid for
    ///Called at app startup
    public func restoreTransactions() {
        Logger.shared.log(self, "Restoring transactions")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    /// Response to requestProducts() - available products
    /// Sent immediately before -requestDidFinish
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            Logger.shared.log(self, "Products request reply, availabe products count:\(response.products.count)")
            if response.products.count > 0 {
                for product in response.products {
                    self.purchaseableProducts[product.productIdentifier] = product
                    Logger.shared.log(self, "  Available product ID:\(product.productIdentifier)")

                }
            } else {
                Logger.shared.reportError(self, "No products from product request")
            }
            
            if !response.invalidProductIdentifiers.isEmpty {
                for invalidIdentifier in response.invalidProductIdentifiers {
                    Logger.shared.reportError(self, "Invalid product \(invalidIdentifier)")
                }
            }
        }
    }

    ///Buy a subscription
    public func buyProductSubscription(product: SKProduct) {
        Logger.shared.log(self, "BuyProductSubscription, product id \(product.productIdentifier)")
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        Logger.shared.reportError(self, "didFailWithError", error)
    }
    
    ///Call Apple to verify the receipt and return the subscription expiry date
    func validateSubscriptionReceipt(ctx:String, receiptData: Data, onDone:@escaping (_:Date?)->Void) {
        func isTestFlight() -> Bool {
            guard let receiptURL = Bundle.main.appStoreReceiptURL else {
                return false
            }
            
            return receiptURL.lastPathComponent == "sandboxReceipt"
        }

        let base64encodedReceipt = receiptData.base64EncodedString()
        let appSharedSecret = "1e1adf0415b046edbf2a1aa7e0d09d64" ///generated in App Store Connect under App Information
        let requestBody = ["receipt-data": base64encodedReceipt, "password": appSharedSecret, "exclude-old-transactions": true] as [String: Any]
        
        ///To verify subscription receipts for an app running on TestFlight, you should use the following URL for the receipt validation
        ///if #debug is only true for an xcode run, not TestFlight
        ///https://sandbox.itunes.apple.com/verifyReceipt
        var url:URL? = nil
        #if DEBUG
        url = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")
        #else
        if isTestFlight() {
            url = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")
        }
        else {
            url = URL(string: "https://buy.itunes.apple.com/verifyReceipt")
        }
        #endif

        // Use the function to adjust the validation URL at runtime

        guard let url = url else {
            Logger.shared.reportError(self, "No subscription validation URL was available")
            return
        }
        if !LicenceManager.subscriptionURLLogged {
            Logger.shared.log(self, "Subscription validation URL is \(url)")
            LicenceManager.subscriptionURLLogged = true
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted)
            request.httpBody = jsonData
        } catch {
            Logger.shared.reportError(self, "Error creating verification JSON request body: \(error). Context:\(ctx)")
            onDone(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.shared.reportError(self, "Receipt validation failed with error: \(error). Context:\(ctx)")
                onDone(nil)
                return
            }
            guard let data = data else {
                Logger.shared.reportError(self, "No receipt validation data received to verify. Context:\(ctx)")
                onDone(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let latestReceipts = json["latest_receipt_info"] as? [Any] {
                        //let log = "Validating subscription receipt for \(ctx)"
                        //Logger.logger.log(self, log)
                        for i in 0..<latestReceipts.count {
                            if let latestReceipt = latestReceipts[i] as? [String: Any] {
                               // print(latestReceipt.keys)
                                if let expiresDate = latestReceipt["expires_date"] as? String {
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss 'Etc/GMT'"
                                    dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
                                    if let gmtDate = dateFormatter.date(from: expiresDate) {
                                        onDone(gmtDate)
                                    } else {
                                        Logger.shared.reportError(self, "Failed to parse licence date \(expiresDate). Context:\(ctx)")
                                        onDone(nil)
                                    }
                                }
                                else {
                                    Logger.shared.reportError(self, "Missing licence expiry date \(latestReceipt.keys). Context:\(ctx)")
                                    onDone(nil)
                                }
                            }
                        }
                    }
                    else {
                        Logger.shared.log(self, "Transaction verification returned no receipts. Context:\(ctx)")
                        onDone(nil)
                    }
                }
            } catch {
                Logger.shared.reportError(self, error.localizedDescription)
                onDone(nil)
            }
        }
        task.resume()
    }
    
    ///Get the receipt info from the subscription transaction when its purchased or renewed
    private func extractTransactionReceipt() -> Data? {
        guard let receiptURL = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: receiptURL.path) else {
            Logger.shared.reportError(self, "Receipt URL not found")
            return nil
        }
        do {
            let receiptData = try Data(contentsOf: receiptURL)
            return receiptData
        } catch {
            Logger.shared.reportError(self, "Error fetching receipt data in URL \(receiptURL) from transaction: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Store the receipt data locally for subscription expiry checking until the next subscription renewal
    func storeSubscriptionReceipt(ctx:String, name:String, receiptData: Data) {
        self.validateSubscriptionReceipt(ctx: "Storing new receipt", receiptData: receiptData, onDone: {expiryDate in
            if let expiryDate = expiryDate {
                let subscriptionReceipt = SubscriptionTransactionReceipt(name:name, data: receiptData, expiryDate: expiryDate)
                subscriptionReceipt.save()
                Logger.shared.log(self, "Stored new receipt locally:\(subscriptionReceipt.allDatesDescription()), context:\(ctx)")
                subscriptionReceipt.expiryDate = expiryDate
                //LicenceManager.shared.setLicensedBySubscription(expiryDate: expiryDate)
            }
            else {
                Logger.shared.reportError(self, "Receipt \(name) has no expiry date so clearing local storage")
                SubscriptionTransactionReceipt.clear()
            }
        })
    }
    
    ///Verify a subscription and save it if it has an expiry date. Otherwise clear any locally stored subscription.
    public func verifyStoredSubscriptionReceipt(ctx: String) {
        if let receipt = SubscriptionTransactionReceipt.load() {
            Logger.shared.log(self, "A stored subscription transaction exists so verifying it. Context:\(ctx)")
            self.validateSubscriptionReceipt(ctx: "Verifying stored subscription. Context:\(ctx)", receiptData: receipt.data, onDone: {expiryDate in
                if let expiryDate = expiryDate {
                    Logger.shared.log(self, "Stored subscription transaction verified and so set app's licence expiry to:[\(receipt.allDatesDescription())], Context:\(ctx)")
                    receipt.expiryDate = expiryDate
                    //LicenceManager.shared.setLicensedBySubscription(expiryDate: expiryDate)
                }
                else {
                    Logger.shared.log(self, "Stored subscription has no expiry date. Context:\(ctx)")
                    SubscriptionTransactionReceipt.clear()
                }
            })
        }
        else {
            Logger.shared.log(self, "No local subscription to verify. Context:\(ctx)")
            SubscriptionTransactionReceipt.clear()
        }
    }
    
    // SKPaymentTransactionObserver for purchased licenses and subscriptions. Called after product is purchased.
    ///For subscriptions the subscription only appears in the queue when the subscription is purchased or renewed.
    ///So the app must store the subscription receipt to be able to check that the subscription is still current.
    ///When a subscription is renewed the app must locally store the renewed subscription to ensure the subscription dates that the app checks are updated
    ///To determine the subscription expiry date the app must call Apple web API to verify the transaction receipt and that verification process then returns the subscription expiry date
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        //Logger.logger.log(self, "updatedTransactions")
        DispatchQueue.main.async {
            self.isInPurchasingState = false
            for transaction in transactions {
                switch transaction.transactionState {
                case .purchasing:
                    /// Transaction is being added to the server queue. Client should not complete the transaction.
                    Logger.shared.log(self, "Purchasing: \(transaction.payment.productIdentifier)")
                    self.isInPurchasingState = true
                case .purchased:
                    Logger.shared.log(self, "Purchased: \(transaction.payment.productIdentifier) ")
                    //self.purchasedProductIds.insert(transaction.payment.productIdentifier)
                    SKPaymentQueue.default().finishTransaction(transaction)
                    if let receiptData = self.extractTransactionReceipt() {
                        self.storeSubscriptionReceipt(ctx: "paymentQueue.purchased", name: transaction.payment.productIdentifier, receiptData: receiptData)
                    }
                case .restored:
                    /// Transaction was restored from user's purchase history.  Client should complete the transaction.
                    let restored:SKPayment = transaction.payment
                    //print("==============>>>", restored.applicationUsername, restored)
                    Logger.shared.log(self, "Purchased licences restored from history: \(transaction.payment.productIdentifier)")
                    //self.purchasedProductIds.insert(transaction.payment.productIdentifier)
                    SKPaymentQueue.default().finishTransaction(transaction)
                    if let receiptData = self.extractTransactionReceipt() {
                        self.storeSubscriptionReceipt(ctx: "paymentQueue.restored",  name:transaction.payment.productIdentifier, receiptData: receiptData)
                    }
                case .failed:
                    let err:String = transaction.error?.localizedDescription ?? ""
                    Logger.shared.reportError(self, "paymentQueue.failed didFailWithError \(err) or the user cancelled the purchase")
                    SKPaymentQueue.default().finishTransaction(transaction)
                default:
                    break
                }
            }
        }
    }

    func getStateName(_ st:SKPaymentTransactionState) -> (String, String) {
        var name = ""
        var desc = ""
        switch st {
        case .purchasing:
            name = "Purchasing..."
            desc = "Transaction is being added to the server queue."
        case .purchased:
            name = "Purchased"
            desc = "Transaction is in queue, user has been charged. Client should complete the transaction."
        case .failed:
            name = "Failed"
            desc = "Transaction was cancelled or failed before being added to the server queue."
        case .restored:
            name = "Restored"
            desc = "Transaction was restored from user's purchase history. Client should complete the transaction."
        case .deferred:
            name = "Deferred"
            desc = "The transaction is in the queue, but its final status is pending external action."
        default:
            break
        }
        return (name, desc)
    }
}

public struct LicenseManagerView: View {
    @Environment(\.presentationMode) var presentationMode
    let contentSection:ContentSection
    let email:String
    @ObservedObject var iapManager = LicenceManager.shared
    @State var isPopupPresented = false
    var yearString = ""
    
    public init(contentSection:ContentSection, email:String) {
        self.contentSection = contentSection
        self.email = email
        let currentYear = Calendar.current.component(.year, from: Date())
        let formatter = NumberFormatter()
        formatter.numberStyle = .none // This ensures no comma formatting
        yearString = formatter.string(from: NSNumber(value: currentYear)) ?? ""
    }
    
    func getProducts() -> [SKProduct] {
        let products = LicenceManager.shared.purchaseableProducts.values.sorted { (product1, product2) -> Bool in
            return product1.price.compare(product2.price) == .orderedAscending
        }
//        let filteredProducts = products.filter { product in {
//            let grade = contentSection.getPathTitle().replacingOccurrences(of: " ", with: "_")
//            if product.productIdentifier.hasPrefix("MT") {
//                return true
//            }
//            return product.productIdentifier.hasPrefix("NZMEB") && product.productIdentifier.contains(grade)
//        }()
//        }
        //return filteredProducts
        return products
    }
    
    struct InfoView:View {
        let contentSection:ContentSection
        let yearString:String
        public var body: some View {
            VStack() {
                let info = "Access to some content is restricted without a subscription.\n\nPurchasing a subscription provides you with access to all the NZMEB Musicianship practice examples and practice exams.\n\nFree licensing is available for NZMEB teachers. Please contact sales@musicmastereducation.co.nz for more details."
                Text(info).padding()
            }
        }
    }
    
    func getSubscriptionName() -> String {
        if let licence = SubscriptionTransactionReceipt.load() {
            return licence.getDescription()
        }
        else {
            return "No stored subscription"
        }
    }
    
    func DetailedLicensesView() -> some View {
        VStack {
            Text("Available Subscriptions").font(.title).padding()
            if LicenceManager.shared.isLicensed() {
                VStack {
                    Text("Your current subscription is ").padding()
                    if LicenceManager.shared.emailIsLicensed(email:LicenceManager.shared.configuredLicenceEmail) {
                        Text("Teacher email \(LicenceManager.shared.configuredLicenceEmail)").foregroundColor(.green).bold().padding()
                    }
                    else {
                        Text(getSubscriptionName()).foregroundColor(.green).bold().padding()
                    }
                }
                .padding()
                Text("This subscription provides you with access to all the NZMEB Musicianship practice examples and practice exams.").padding().padding().padding()
            }
            else {
                if iapManager.isLicenseAvailableToPurchase(grade: contentSection.name) {
                    List {
                        ForEach(getProducts(), id: \.self) { product in
                            HStack {
                                Text(product.localizedTitle)
                                Spacer()
                                let currency = product.priceLocale.localizedString(forCurrencyCode: product.priceLocale.currencyCode!)
                                Text(currency ?? "")
                                let price:String = product.price.description
                                Text(price)
                                Button(action: {
                                    //iapManager.buyProduct(grade: contentSection.name)
                                    iapManager.buyProductSubscription(product: product)
                                }) {
                                    Text("Purchase")
                                        .font(.title)
                                        .padding()
                                }
                            }
                        }
                    }
                    .padding()
                    .navigationTitle("Available Products")
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Button(action: {
                            isPopupPresented.toggle()
                        }) {
                            VStack {
                                Image(systemName: "questionmark.circle")
                            }
                        }
                        .padding()
                        .popover(isPresented: $isPopupPresented) {
                            InfoView(contentSection: contentSection, yearString: yearString)
                        }
                    }
                    else {
                        HStack {
                            Text("                  ").padding()
                            InfoView(contentSection: contentSection, yearString: yearString)
                            Text("                  ").padding()
                        }
                    }
                    if iapManager.isInPurchasingState {
                        Text("Purchase in progress. Please standby...").font(.title).foregroundColor(.green).bold().padding()
                    }

                }
                else {
                    Text("Sorry, no subscription is available yet")
#if targetEnvironment(simulator)
                    Text("SIMULATOR CANNOT DO LICENSING")
#endif
                }
            }
            VStack {
                Button(action: {
                    iapManager.restoreTransactions()
                }) {
                    Text("Restore Subscriptions")
                        .font(.title)
                        .padding()
                }
            }

            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Dismiss")
                        .font(.title)
                        .padding()
                }
            }
        }
    }
    
    public var body: some View {
        NavigationStack {
            VStack {
                TitleView(screenName: "Licence Subscriptions", showGrade: true).commonFrameStyle()
                DetailedLicensesView()
                    .commonFrameStyle()
                    .padding()
            }
            .frame(width: UIScreen.main.bounds.width * UIGlobals.shared.screenWidth) //, height: UIScreen.main.bounds.height * 0.9)
        }
    }

}

