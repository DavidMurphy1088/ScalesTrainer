//import Foundation
//import SwiftUI
//import StoreKit
//
//import Foundation
//import Combine
//import SwiftUI
//import WebKit
//import AVFoundation
//import AVKit
//import UIKit
//
//public struct LicenseManagerView: View {
//    @Environment(\.presentationMode) var presentationMode
//    //let contentSection:ContentSection
//    //let email:String
//    //@ObservedObject var iapManager = LicenceManager.shared
//    @State var isPopupPresented = false
//    var yearString = ""
//    let compact = UIDevice.current.userInterfaceIdiom == .phone
//    //let licenceManager = LicenceManager.shared
//    @StateObject private var licence = LicenceManager.shared
//    
////    public init(contentSection:ContentSection, email:String) {
////        //self.contentSection = contentSection
////        self.email = email
////        let currentYear = Calendar.current.component(.year, from: Date())
////        let formatter = NumberFormatter()
////        formatter.numberStyle = .none // This ensures no comma formatting
////        yearString = formatter.string(from: NSNumber(value: currentYear)) ?? ""
////        //SKPaymentQueue.default().add(self)
////    }
////    deinit {
////            SKPaymentQueue.default().remove(self)
////    }
//    
//    func getProducts() -> [Product] {
////        let products = LicenceManager.shared.purchaseableProducts.values.sorted { (product1, product2) -> Bool in
////            return product1.price.compare(product2.price) == .orderedAscending
////        }
////        return products
////        return licence.products
//    }
//    
//    struct InfoView:View {
//        //let contentSection:ContentSection
//        let yearString:String
//        public var body: some View {
//            VStack() {
//                let info = "Purchasing a subscription provides you with access to all the Scales Academy content.\nThe subscription types are listed above."
//                //\n\nFree licensing is available for NZMEB teachers. Please contact sales@musicmastereducation.co.nz for more details."
//                Text(info).padding()
//            }
//        }
//    }
//    
////    func getSubscriptionName() -> String {
////        if let licence = SubscriptionTransactionReceipt.load() {
////            return licence.getDescription()
////        }
////        else {
////            return "No stored subscription"
////        }
////    }
//    
//    func DetailedLicensesView() -> some View {
//        VStack {
//            if false { //licenceManager.isLicensed() {
//                let settings = Settings.shared
//                VStack {
//                    if settings.isCurrentUserDefined() {
//                        let user = settings.getCurrentUser("License manager")
//                        Text("Your current subscription is ").font(.title2).padding()
////                        if LicenceManager.shared.emailIsLicensed(email:user.email) {
////                            Text("Email \(user.email)").font(.title2).foregroundColor(.green).bold().padding()
////                        }
////                        else {
////                            Text(getSubscriptionName()).font(.title2).foregroundColor(.green).bold().padding()
////                        }
//                        Text("This subscription provides you with access to all Scales Academy content.").font(.title2).padding().padding().padding()
//                    }
//                }
//            }
//            else {
//                Text("Available Subscriptions").font(.title).padding(compact ? .zero : 16.0)
//                if iapManager.isLicenseAvailableToPurchase(grade: contentSection.name) {
//                    List {
//                        ForEach(getProducts(), id: \.self) { product in
//                            HStack {
//                                Text(product.localizedTitle)
//                                Spacer()
//                                let currency = product.priceLocale.localizedString(forCurrencyCode: product.priceLocale.currencyCode!)
//                                Text(currency ?? "")
//                                let price:String = product.price.description
//                                Text(price)
////                                Button(action: {
////                                    iapManager.buyProductSubscription(product: product)
////                                }) {
////                                    Text("Purchase")
////                                        .font(.title)
////                                        .padding()
////                                }
//                                FigmaButton("Purchase", action: {
//                                    iapManager.buyProductSubscription(product: product)
//                                })
//                            }
//                        }
//                    }
//                    .listStyle(.plain)
//                    .padding()
//                    .border(.red)
//                    .navigationTitle("Available Subscriptions")
//                    .frame(width: UIScreen.main.bounds.width * (compact ? 0.6 : 0.4),
//                           height: UIScreen.main.bounds.height * (compact ? 0.4 : 0.2))
//                    if compact {
//                        if false {
//                            Button(action: {
//                                isPopupPresented.toggle()
//                            }) {
//                                VStack {
//                                    Image(systemName: "questionmark.circle")
//                                }
//                            }
//                            .padding()
//                            .popover(isPresented: $isPopupPresented) {
//                                InfoView(contentSection: contentSection, yearString: yearString)
//                            }
//                        }
//                    }
//                    else {
//                        HStack {
//                            Text("                  ").padding()
//                            InfoView(contentSection: contentSection, yearString: yearString)
//                            Text("                  ").padding()
//                        }
//                    }
//                    if iapManager.isInPurchasingState {
//                        Text("Purchase in progress. Please standby...").font(.title2).foregroundColor(.green).bold().padding()
//                    }
//                }
//                else {
//                    Text("Sorry, no subscription is available yet")
//#if targetEnvironment(simulator)
//                    Text("SIMULATOR CANNOT DO LICENSING")
//#endif
//                }
//            }
//            VStack {
//                FigmaButton("Restore Subscriptions", action: {
//                    iapManager.restoreTransactions()
//                    }
//                )
//            }
//        }
//    }
//    
//    public var body: some View {
//        NavigationStack {
//            DetailedLicensesView()
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .navigationTitle("Subscriptions")
//                .navigationBarTitleDisplayMode(.inline)
//                .commonToolbar(
//                    title: "Subscriptions", helpMsg: "Use this screen to mange your Scales Academy subscriptions", onBack: {}
//                )
//        }
//    }
//}

import SwiftUI
import StoreKit

struct SubscriptionsView: View {
    @ObservedObject private var licenceManager = Licencing.shared
    @State private var isLoading = true
    let compact = UIDevice.current.userInterfaceIdiom == .phone
    
    func willAutoRenew() -> Bool {
        if let autoRenew = licenceManager.willAutoRenew {
            return autoRenew
        }
        return true
    }
    
    func getRenewDateTime(_ date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        let dateTimeString = formatter.string(from: date)
        return dateTimeString // e.g., "2025-10-01 14:23:45"
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading && licenceManager.products.isEmpty {
                    ProgressView("Loading subscriptions…")
                } else if licenceManager.products.isEmpty {
                    VStack(spacing: 12) {
                        Text("No subscriptions found")
                            .font(.headline)
                        Button("Retry") {
                            Task {
                                isLoading = true
                                await licenceManager.refreshProducts()
                                await licenceManager.refreshEntitlementsAndStatus()
                                isLoading = false
                            }
                        }
                    }
                } else {
                    VStack {
                        List {
                            if licenceManager.isSubscribed {
                                Section {
                                    HStack {
                                        Image(systemName: "checkmark.seal.fill")
                                        VStack(alignment: .leading) {
                                            Text("Subscription Active").font(.headline)
                                            if self.willAutoRenew() {
                                                if let exp = licenceManager.lastExpirationDate {
                                                    //Text("Renews on \(exp.formatted(date: .abbreviated, time: .omitted))")
                                                    Text("Renews on \(self.getRenewDateTime(exp))")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            else {
                                                Text("No automatic renewal")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            ///▶️ Note that when a subscription is cancelled it it not deleted. It is set to no auto-renew and will disappear at the
                            ///start of the next subscription period. So when a user deletes a subscription via "manage" then they are only told it
                            ///wont renew.
                            if true || !licenceManager.isSubscribed {
                                // Products
                                Section("Subscriptions") {
                                    ForEach(licenceManager.products, id: \.id) { product in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(product.displayName)
                                                    .font(.headline)
                                                Text(product.displayPrice)
                                            }
                                            Spacer()
                                            FigmaButton(licenceManager.isSubscribed ? "Manage" : "Purchase", action: {
                                                Task { await licenceManager.purchase(product) }
                                            })
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            Task { await licenceManager.purchase(product) }
                                        }
                                    }
//                                    FigmaButton("TEST", action: {
//                                        Task {
//                                            //try? await AppStore.sync()         // prompts StoreKit to resync entitlements
//                                            //await licenceManager.refreshEntitlementsAndStatus()
//                                            Task { await licenceManager.refreshEntitlementsAndStatus() }
//                                        }
//                                    })
                                }
                            }
                            
                            // Restore
                            Section {
                                Button("Restore Purchases") {
                                    Task { await licenceManager.restorePurchases() }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        VStack() {
                            let info = "Purchasing a subscription provides you with access to all the Scales Academy content. The subscription types are listed above."
                            //\n\nFree licensing is available for NZMEB teachers. Please contact sales@musicmastereducation.co.nz for more details."
                            Text(info).padding()
                        }
                        HStack {
                            if let statusMsg = self.licenceManager.statusMessage1 {
                                Text("status: \(statusMsg)")
                            }
                        }

                    }
                    .padding()
                    .figmaRoundedBackgroundWithBorder()
                    .frame(width: UIScreen.main.bounds.width * (compact ? 0.6 : 0.4),
                            height: UIScreen.main.bounds.height * (compact ? 0.7 : 0.6))
                }
            }
            
            .navigationTitle("Subscriptions")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
            .commonToolbar(
                title: "Subscriptions", helpMsg: "Use this screen to mange your Scales Academy subscriptions", onBack: {}
            )
        }

        .task {
            // Initial load
            await licenceManager.refreshProducts()
            await licenceManager.refreshEntitlementsAndStatus()
            isLoading = false
        }
//        .overlay(alignment: .bottom) {
//            if let msg = licence.statusMessage, !msg.isEmpty {
//                Text(msg)
//                    .font(.footnote)
//                    .padding(10)
//                    .background(.ultraThinMaterial, in: Capsule())
//                    .padding(.bottom, 12)
//                    .transition(.opacity)
//            }
//        }
    }

}

// Handy label for period (month/year) from StoreKit 2 Product
private extension Product {
    var subscriptionPeriodLabel: String {
        guard let info = subscription?.subscriptionPeriod else { return "Auto-renewing" }
        switch (info.unit, info.value) {
        case (.day, 1): return "Daily"
        case (.day, let v): return "Every \(v) days"
        case (.week, 1): return "Weekly"
        case (.week, let v): return "Every \(v) weeks"
        case (.month, 1): return "Monthly"
        case (.month, let v): return "Every \(v) months"
        case (.year, 1): return "Yearly"
        case (.year, let v): return "Every \(v) years"
        @unknown default:  return "Auto-renewing"
        }
    }
}
